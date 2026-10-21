/**
 * Server side of the fork-tree plugin.
 *
 * Registers two tools that give the model a way to recover the details a
 * branch summary deliberately left out. The branch summary itself is delivered
 * through OpenCode's session instruction entries (see src/tui.ts), which land
 * in the *system prompt* of every model call for the forked session.
 */

import {
  TOOL_LIST_BRANCHES,
  TOOL_READ_BRANCH,
  buildBranchTree,
  serializeTranscript,
  truncate,
} from "./core.ts"

export default {
  id: "fork-tree",
  async setup(ctx: any) {
    // Nothing here is required for the fork flow itself, so never fail setup.
    if (!ctx?.tool?.transform) return

    await ctx.tool.transform((editor: any) => {
      editor.add({
        name: TOOL_READ_BRANCH,
        description:
          "Read the full transcript of another branch of this conversation (a sibling or parent session created by the fork-tree plugin). Use it when a branch summary omitted a detail you need - exact code, command output, error text, or precise wording.",
        input: {
          type: "object",
          properties: {
            sessionID: {
              type: "string",
              description: "The session id of the branch to read.",
            },
          },
          required: ["sessionID"],
          additionalProperties: false,
        },
        execute: async (input: any, _context: any) => {
          const sessionID = String(input?.sessionID ?? "").trim()
          if (!sessionID) return { content: "error: sessionID is required" }

          const messages = await ctx.session.context({ sessionID })
          const transcript = serializeTranscript(messages as any)
          if (!transcript.trim()) {
            return { content: `Branch ${sessionID} has no transcript (it may be empty, or not a session of this project).` }
          }
          return {
            content: `Transcript of branch ${sessionID}:\n\n${transcript}`,
          }
        },
      })

      editor.add({
        name: TOOL_LIST_BRANCHES,
        description:
          "List the branches of this conversation: every session that was forked from another session in this project, with its title, fork boundary and whether it carries a branch summary. Use it to discover work that happened on a sibling branch.",
        input: {
          type: "object",
          properties: {},
          additionalProperties: false,
        },
        execute: async (_input: any, context: any) => {
          const projectID = ctx.location?.project?.id
          const sessions = await ctx.session.list({
            project: projectID,
            directory: ctx.location?.directory,
            limit: 200,
          })
          const list = (sessions as any)?.data ?? (sessions as any) ?? []
          const currentID = context?.sessionID ?? ""
          const tree = buildBranchTree(Array.isArray(list) ? list : [], currentID)
          if (tree.length === 0) return { content: "No branches found in this project." }

          const lines = tree.map((node: any) => {
            const depth = node.depth ?? 0
            const indent = "  ".repeat(depth)
            const marker = node.isCurrent ? " (current)" : ""
            const boundary = node.boundary?.messageID ? ` @${node.boundary.messageID}` : ""
            const label = node.label ? ` - ${truncate(node.label, 120)}` : ""
            return `${indent}${depth > 0 ? "- " : ""}${node.title}${marker} [${node.id}]${boundary}${label}`
          })
          return { content: `Branches:\n${lines.join("\n")}` }
        },
      })
    })
  },
}
