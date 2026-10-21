# fork-tree

Fork an OpenCode session into a branch, and hand the new branch a **system-context**
summary of the work it just left behind.

```
/fork    pick a message -> fork there -> summarize the abandoned branch -> attach it
/forks   browse the branch tree and jump between branches
```

Both are also in the command palette (`Ctrl+P`).

## How it works

1. **Pick a point.** `/fork` lists the session's user messages (searchable) and forks the
   session at that point with `POST /api/session/{id}/fork {before}`.
   OpenCode stores the fork as a child session with `fork.sessionID` + `fork.boundary`,
   so the branch tree is persisted for free.

2. **Summarize the abandoned branch.** The discarded messages (from the fork point to the
   end) are serialized into a transcript and summarized by the session's own model via
   `POST /api/session/{id}/generate`. The prompt follows Claude Code's compaction prompt
   (analysis checklist, numbered sections, worked example) with Cursor's framing
   (rendered transcript, "never refer to summarization") and the branch-specific section
   list pi uses for branch summaries.

3. **Attach it to the new branch's system prompt.** The summary is written to the fork's
   instruction entry `branch-context`
   (`PUT /api/experimental/session/{id}/instructions/entries/branch-context`). OpenCode
   renders instruction entries into the **system prompt** of every model request for that
   session, so the successor agent learns about the abandoned branch from the system
   channel - not from a user turn it could mistake for a request - and the context
   survives compaction.

4. **Leave a trace.** A short note is added to the fork's transcript
   (`session.synthetic`) and the fork's metadata records the branch point
   (`metadata.forkTree`).

5. **Recover details on demand.** The system context points the model at the
   `forktree_read_branch` tool, which returns the abandoned branch's full transcript.
   `forktree_list_branches` lists every branch of the conversation.

## Files

| Path | Role |
| --- | --- |
| `index.ts` | server plugin: registers the two branch tools |
| `tui.ts` | CLI plugin: `/fork` and `/forks` commands |
| `core.ts` | shared logic: transcript serialization, prompts, branch tree |

Discovered automatically from `<global-config>/plugins/fork-tree/`.

## Notes and limits

- Instruction entries are under `/api/experimental`; that is the only supported way to
  put durable, session-scoped content in the system prompt.
- The fork is a snapshot: messages that arrive in the source session after the fork are
  not copied into the branch.
- `session.fork` does not set `parentID`, so forks are not part of OpenCode's
  parent/child (subagent) tree. `/forks` builds the tree from the `fork.sessionID`
  edges instead.
- Message ids are rewritten when a branch is copied, so the stable cross-branch
  reference is `fork.boundary.messageID`, which points at the *source* message.

## Prompt sources

The summarization prompt is assembled from:

- Claude Code's compaction prompt (structure, checklist, attribution guard, security
  constraint preservation) - extracted from Anthropic's shipped binary.
- Cursor's classic compaction prompt (transcript framing, "never refer to
  summarization") - leaked from Cursor's client-side `agent-summarization` package.
- pi's branch summary sections (`Goal` / `Constraints & Preferences` / `Progress` /
  `Key Decisions` / `Next Steps`).
