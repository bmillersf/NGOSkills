# Sharing Protocol

How captured flows propagate from one user's machine to the rest of the team.

## The cycle

```
[Capture]                                    [Pull]
   │                                            ▲
   ▼                                            │
1. Agent runs Phase 2-4 (discover, compile,    7. SessionStart hook runs
   index)                                          auto-update-skills.sh
   │                                            │
   ▼                                            │
2. Auto-commit locally:                         6. Other user starts
   `learn(sf-ui-autonomous): add <id> flow`        Claude Code session
   │                                            ▲
   ▼                                            │
3. NEVER pushes automatically                  5. PR merges to public/main
   │                                            ▲
   ▼                                            │
4. User reviews via                             ▼
   `git log --grep='^learn(sf-ui-autonomous'  4. User pushes branch +
                                                 opens PR
```

## Commit convention

Mandatory format (matches CLAUDE.md §4):

```
learn(sf-ui-autonomous): <one-line summary>
```

Examples:

```
learn(sf-ui-autonomous): add contact-create-with-account flow (NPSP)
learn(sf-ui-autonomous): add npsp-recurring-donation flow (NPSP)
learn(sf-ui-autonomous): refresh app-launcher fragment for Spring '26 DOM
learn(sf-ui-autonomous): quarantine campaign-add-member after 3 replay failures
```

The `learn(sf-ui-autonomous` prefix lets the user run:

```bash
git log --grep='^learn(sf-ui-autonomous' --since='1 week ago'
```

and see exactly what was captured before deciding what to push.

## Branch safety

If the current branch is `main`, commit directly. On any other branch (feature, scratch), the commit lands on the current branch — that's fine, it merges with the branch. Exception: branch names starting with `learn/`, `wip/`, `scratch/`, `throwaway/` are treated as ephemeral and the commit is stashed to `~/.claude/skills-learnings-pending/sf-ui-autonomous-<ts>.md` instead. The next `main`-branch invocation flushes the stash.

## Redaction (mandatory, applied before commit)

The capture compiler runs each of these strippers and **refuses to commit** if any cannot be safely scrubbed:

| What | Action |
|---|---|
| 15/18-char Salesforce record IDs | Replace with `{{record_id}}` template var or remove from selector |
| Org usernames, My Domain names, sandbox URLs | Replace with `<org-redacted>` |
| Customer / org names | Replace with placeholder unless they're standard demo names ("By The Hand Club", "Acme Nonprofit") |
| Email addresses | Replace with `<email-redacted>@example.org` unless it's a documented demo email pattern |
| Phone numbers | Strip |
| Industry-specific namespace values that tie to one org (e.g., `npsp__CustomerXYZ_*`) | Replace with neutral example or strip |
| Numeric amounts that look like KPIs ($X.XM, etc.) | Replace with example values |

Standard objects, framework choices, and methodology references are kept — they're the value of the capture.

## Pull-side: how others receive captures

The existing supply chain (CLAUDE.md §5) handles distribution. No new infrastructure:

1. **SessionStart hook** runs `auto-update-skills.sh` → pulls NGOSkills updates
2. `vendor-pins.txt` SHA bump (one-line PR diff) reviewed and merged
3. `vendor-install.sh` materializes the new SHA into `.vendor/<slug>/`
4. `sync-skills.sh --fix` rebuilds the symlinks in `~/.claude/skills/sf-ui-autonomous`
5. New flows visible in the user's library on next session

## Conflict resolution

Two users capturing the same intent for the same `org_profile` produce conflicting `library.json` entries. Resolution rules:

1. **Most recent `last_verified`** wins
2. If tie: **lower `fragility_score`** wins
3. If still tie: keep both, suffix the `id` with `-v2` and surface to user for manual reconciliation

The capture compiler runs a pre-commit dedupe check and surfaces conflicts before they reach `git`.

## Never push

The skill never runs `git push` automatically. Pushing is always a user-initiated action. Recommended flow:

```bash
cd ~/Cursor/Skills/NGOSkills
git log --grep='^learn(sf-ui-autonomous'           # review
git rebase -i public/main                          # squash if desired
git push public HEAD                               # ship to GitHub
```

A future `scripts/push-learnings.sh` may automate the squash + push, but does not exist in the bootstrap.
