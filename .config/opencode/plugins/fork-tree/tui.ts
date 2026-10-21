/**
 * Terminal side of the fork-tree plugin.
 *
 * Two commands:
 *   /fork   - pick a message, fork the session there, and hand the new branch a
 *             system-context summary of the work it left behind.
 *   /forks  - browse the branch tree of this conversation and jump around it.
 */

import {
  BRANCH_CONTEXT_KEY,
  buildBranchContext,
  buildBranchNote,
  buildBranchTree,
  buildSummaryPrompt,
  budgetTranscript,
  firstLine,
  formatTime,
  isUserMessage,
  messageText,
  serializeTranscript,
  truncate,
  type AnyMessage,
} from "./core.ts"

type Ctx = any

// ---------------------------------------------------------------------------
// Data helpers
// ---------------------------------------------------------------------------

function currentSessionID(context: Ctx): string | undefined {
  const route = context.ui.router.current()
  if (route?.type === "session" && route.sessionID) return route.sessionID
  return undefined
}

/** All messages of a session, oldest first. */
async function fetchMessages(context: Ctx, sessionID: string): Promise<AnyMessage[]> {
  const out: AnyMessage[] = []
  let cursor: string | undefined

  for (let page = 0; page < 100; page++) {
    // NB: the generated client exposes message listing as a top level
    // resource (`client.message.list`), not under `client.session`.
    //
    // The pagination cursor is opaque and already encodes the ordering, so
    // `order` may only be sent on the first request: the server rejects
    // "Cursor cannot be combined with order".
    const res: any = await context.client.message.list({
      sessionID,
      limit: 100,
      ...(cursor ? { cursor } : { order: "asc" }),
    })
    const data = res?.data ?? []
    out.push(...data)
    cursor = res?.cursor?.next ?? undefined
    if (!cursor || data.length === 0) break
  }

  return out
}

async function fetchSessions(context: Ctx, sessionID: string): Promise<any[]> {
  const info = context.data.session.get(sessionID)
  const projectID = info?.projectID
  const directory = info?.location?.directory ?? context.data.location.default()?.directory
  const out: any[] = []
  let cursor: string | undefined

  for (let page = 0; page < 50; page++) {
    const res: any = await context.client.session.list({
      project: projectID,
      directory: projectID ? undefined : directory,
      limit: 200,
      cursor,
    })
    out.push(...(res?.data ?? []))
    cursor = res?.cursor?.next ?? undefined
    if (!cursor) break
  }

  return out
}

async function resolveModel(context: Ctx, sessionID: string): Promise<any | undefined> {
  const uiModel = context.ui.model.current()
  if (uiModel?.providerID && (uiModel.modelID || uiModel.id)) {
    return { providerID: uiModel.providerID, id: uiModel.modelID ?? uiModel.id, variant: uiModel.variant }
  }
  const session = context.data.session.get(sessionID)
  const model = session?.model
  if (model?.providerID && (model.id || model.modelID)) {
    return { providerID: model.providerID, id: model.id ?? model.modelID, variant: model.variant }
  }
  return undefined
}

/**
 * Summarize a branch. Three strategies, in order of preference:
 *   1. the session itself (uses its own model, adds nothing to its history)
 *   2. a throwaway session pinned to the model the user is currently using
 *   3. a stateless generation against the server default
 */
async function summarize(
  context: Ctx,
  input: { sessionID: string; transcript: string; model?: any },
): Promise<string | undefined> {
  const prompt = buildSummaryPrompt(input.transcript)

  try {
    const res: any = await context.client.session.generate({ sessionID: input.sessionID, prompt })
    if (res?.text?.trim()) return res.text.trim()
  } catch {}

  if (input.model) {
    let temp: any
    try {
      temp = await context.client.session.create({ title: "fork-tree summary", model: input.model })
      const res: any = await context.client.session.generate({ sessionID: temp.id, prompt })
      if (res?.text?.trim()) return res.text.trim()
    } catch {
    } finally {
      if (temp?.id) {
        try {
          await context.client.session.remove({ sessionID: temp.id })
        } catch {}
      }
    }
  }

  try {
    const res: any = await context.client.generate.text({ prompt, model: input.model })
    if (res?.text?.trim()) return res.text.trim()
  } catch {}

  return undefined
}

function toast(context: Ctx, message: string, variant: "info" | "success" | "warning" | "error" = "info", duration = 4000) {
  context.ui.toast.show({ message, variant, duration })
}

function navigate(context: Ctx, sessionID: string) {
  if (context.ui.tabs?.enabled?.()) {
    context.ui.tabs.focus(sessionID)
    return
  }
  context.ui.router.navigate({ type: "session", sessionID })
}

// ---------------------------------------------------------------------------
// Fork flow
// ---------------------------------------------------------------------------

async function pickMessage(
  context: Ctx,
  sessionID: string,
  messages: AnyMessage[],
): Promise<AnyMessage | undefined> {
  const users = messages.filter(isUserMessage)
  if (users.length === 0) {
    toast(context, "This session has no user messages to fork from.", "warning")
    return undefined
  }

  const options = users.map((message, index) => ({
    title: firstLine(messageText(message), 100) || "(empty message)",
    value: message.id,
    description: `#${index + 1} · ${formatTime(message.time?.created)}`,
  }))

  const picked = await context.ui.dialog.select({
    title: "Fork from which message?",
    options,
    search: (query, items) => {
      const q = query.trim().toLowerCase()
      if (!q) return items
      return items.filter((item) => item.title.toLowerCase().includes(q))
    },
  })
  if (!picked) return undefined

  return messages.find((message) => message.id === picked)
}

async function forkFlow(context: Ctx, sourceSessionID?: string): Promise<void> {
  const sessionID = sourceSessionID ?? currentSessionID(context)
  if (!sessionID) {
    toast(context, "Open a session first.", "warning")
    return
  }

  const messages = await fetchMessages(context, sessionID)
  const chosen = await pickMessage(context, sessionID, messages)
  if (!chosen) return

  const chosenIndex = messages.findIndex((message) => message.id === chosen.id)
  if (chosenIndex <= 0) {
    toast(context, "Cannot fork before the first message - the new branch would be empty.", "warning")
    return
  }

  const mode = await context.ui.dialog.select({
    title: "Fork mode",
    options: [
      {
        title: "Fork with summary",
        value: "summary",
        description: "Summarize the branch you leave and put it in the new branch's system prompt",
      },
      {
        title: "Fork without summary",
        value: "plain",
        description: "Drop the abandoned branch entirely",
      },
    ],
  })
  if (!mode) return

  const sourceInfo = context.data.session.get(sessionID)
  const sourceTitle = sourceInfo?.title ?? "session"
  const label = firstLine(messageText(chosen), 160) || chosen.id

  let fork: any
  try {
    fork = await context.client.session.fork({ sessionID, before: chosen.id })
  } catch (error: any) {
    toast(context, `Fork failed: ${error?.message ?? error}`, "error", 8000)
    return
  }
  if (!fork?.id) {
    toast(context, "Fork failed: no session returned.", "error")
    return
  }

  let summarized = false
  if (mode === "summary") {
    const tail = messages.slice(chosenIndex)
    const transcript = budgetTranscript(serializeTranscript(tail))
    if (transcript.trim()) {
      toast(context, "Summarizing the branch you are leaving…", "info", 20000)
      const model = await resolveModel(context, sessionID)
      const summary = await summarize(context, { sessionID, transcript, model })
      if (summary) {
        const value = buildBranchContext({ sourceTitle, sourceID: sessionID, label, summary })
        try {
          await context.client.session.instructions.entry.put({
            sessionID: fork.id,
            key: BRANCH_CONTEXT_KEY,
            value,
          })
          summarized = true
        } catch (error: any) {
          toast(context, `Could not attach branch context: ${error?.message ?? error}`, "error", 8000)
        }
      } else {
        toast(context, "Summarization failed - the branch was forked without context.", "warning", 8000)
      }
    }
  }

  try {
    await context.client.session.synthetic({
      sessionID: fork.id,
      text: buildBranchNote({ sourceTitle, sourceID: sessionID, label, summarized }),
      description: "fork-tree: branch context",
      resume: false,
    })
  } catch {}

  try {
    await context.client.session.update({
      sessionID: fork.id,
      metadata: {
        forkTree: {
          source: sessionID,
          boundary: chosen.id,
          label,
          summarized,
          createdAt: Date.now(),
        },
      },
    })
  } catch {}

  toast(context, `Forked into "${fork.title ?? "new session"}".`, "success")
  navigate(context, fork.id)
}

// ---------------------------------------------------------------------------
// Tree flow
// ---------------------------------------------------------------------------

async function treeFlow(context: Ctx): Promise<void> {
  const sessionID = currentSessionID(context)
  if (!sessionID) {
    toast(context, "Open a session first.", "warning")
    return
  }

  let sessions: any[] = []
  try {
    sessions = await fetchSessions(context, sessionID)
  } catch (error: any) {
    toast(context, `Could not load sessions: ${error?.message ?? error}`, "error")
    return
  }

  const tree = buildBranchTree(sessions, sessionID)
  if (tree.length <= 1) {
    toast(context, "This conversation has no branches yet.", "info")
    return
  }

  const options = tree.map((node: any) => {
    const depth = node.depth ?? 0
    const indent = "  ".repeat(depth)
    const bullet = depth > 0 ? "- " : ""
    const current = node.isCurrent ? " (current)" : ""
    const label = node.label ? truncate(node.label, 90) : node.boundary?.messageID ?? ""
    return {
      title: `${indent}${bullet}${node.title}${current}`,
      value: node.id,
      description: label,
      category: depth === 0 ? "Root" : "Branches",
    }
  })

  const picked = await context.ui.dialog.select({
    title: "Branch tree",
    options,
    actions: [
      {
        bind: "ctrl+f",
        title: "Fork with summary from this branch",
        onTrigger: (value: string) => {
          context.ui.dialog.clear()
          void forkFlow(context, value)
        },
      },
    ],
  })
  if (!picked) return

  navigate(context, picked)
}

// ---------------------------------------------------------------------------
// Plugin entry
// ---------------------------------------------------------------------------

export default {
  id: "fork-tree.tui",
  setup(context: Ctx) {
    context.keymap.layer(() => ({
      mode: "global",
      commands: [
        {
          id: "forktree.fork",
          title: "Fork with summary",
          description: "Fork this session at a message and carry the abandoned branch into the new branch's system context",
          group: "Fork tree",
          palette: true,
          slash: { name: "fork" },
          run: async () => {
            try {
              await forkFlow(context)
            } catch (error: any) {
              toast(context, `Fork failed: ${error?.message ?? error}`, "error", 8000)
            }
          },
        },
        {
          id: "forktree.tree",
          title: "Fork tree",
          description: "Browse the branches of this conversation",
          group: "Fork tree",
          palette: true,
          slash: { name: "forks" },
          run: async () => {
            try {
              await treeFlow(context)
            } catch (error: any) {
              toast(context, `Failed: ${error?.message ?? error}`, "error", 8000)
            }
          },
        },
      ],
    }))
  },
}
