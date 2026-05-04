# Vendor policy

How third-party skill/agent/command packs are vendored into NGOSkills, why they
are pinned, and what to check before bumping a pin.

## What gets vendored

Upstream repos that ship agent instructions (skills, agents, slash commands) we
want the whole team to use. Today:

| slug | upstream | ref | what we link |
|---|---|---|---|
| `superpowers` | `obra/superpowers` | tagged releases (e.g. `v5.0.7`) | `skills/*/` (per-skill dirs), `commands/*.md`, `agents/*.md` |
| `gsd` | `gsd-build/get-shit-done` | tagged releases (e.g. `v1.40.0`) | `agents/*.md`, `commands/gsd/`, `hooks/gsd-*`, and the `get-shit-done/` runtime payload |
| `gstack` | `garrytan/gstack` | rolling `main` (no version tags) | 45 cognitive-gear skills linked as `gstack-*` via its own `./setup` script, invoked by `scripts/vendor-hooks/gstack-post-install.sh` |

Add a new vendor by appending a line to `vendor-pins.txt` and running
`scripts/vendor-install.sh <slug>`. The fan-out into `~/.claude` and `~/.cursor`
is handled by `scripts/sync-skills.sh` as soon as the new tree lands in
`.vendor/<slug>/`.

### Per-vendor post-install hooks

Some vendors need more than a symlink fan-out. Drop a `scripts/vendor-hooks/<slug>-post-install.sh`
and `vendor-install.sh` will run it after the pinned SHA is checked out
(skipped in `--verify` mode so read-only drift audits stay side-effect-free).
Hooks are idempotent and get two args: the slug and the vendor directory.

Today:

- `gstack-post-install.sh` — invokes gstack's own `./setup --host claude --prefix --quiet`,
  which rebuilds its Bun-compiled Chromium binary (`.vendor/gstack/browse/dist/browse`)
  if sources changed, installs Playwright Chromium into `~/Library/Caches/ms-playwright/`
  if missing, and fans out `gstack-*` symlinks into `~/.claude/skills/`. The hook
  gracefully skips if `bun` isn't installed — surfaces a warning rather than aborting
  the rest of `vendor-install.sh`.

Prerequisite note for gstack: `bun` must be on PATH. Install via
`brew install oven-sh/bun/bun` (Homebrew-verified) rather than the upstream
`curl | sh` installer.

## Why pin

The files in `skills/`, `agents/`, and `commands/` are instructions the
assistant executes. An upstream compromise — malicious or accidental — could
land a destructive instruction in any of them. Pinning to a reviewed SHA means:

- Every machine that runs `scripts/setup.sh` ends up with bit-identical instructions.
- Bumping a pin is a PR with a one-line diff anyone on the team can review
  against the upstream changelog.
- Rollback is a `git revert` on that one line plus a re-run of `setup.sh`.

## What NOT to auto-link

`sync-skills.sh` intentionally skips `hooks/` directories inside vendor repos.
Hooks run shell commands on session events (e.g. `session-start`) and have more
authority than skills. If you want a vendor hook enabled, read it, then install
it explicitly into your own settings — don't let the sync script do it.

## Bumping a pin

1. **See what's new upstream** (read-only; no writes):

   ```bash
   scripts/vendor-update.sh                # all vendors
   scripts/vendor-update.sh superpowers    # just one
   ```

   Output shows how many commits behind and the exact commands to view the diff.

2. **Read the upstream diff before you decide to bump**:

   ```bash
   git -C .vendor/superpowers log --oneline <old>..<new>
   git -C .vendor/superpowers diff <old>..<new> -- 'skills/**/SKILL.md' 'agents/**' 'commands/**'
   ```

   Red flags that warrant extra scrutiny or a "no":

   - Skills that newly reference `rm`, `curl | sh`, `eval`, `sudo`, force-push,
     or write outside the skill's own directory.
   - New instructions to exfiltrate env vars, tokens, or config files.
   - New auto-triggers that could apply in scope you didn't intend (e.g. skills
     that trigger "on every PR" or "on every commit" without user intent).
   - Deletions or drastic rewrites of a skill you already rely on — the
     behavior you validated last review may have silently changed.

3. **Bump the pin**:

   ```bash
   scripts/vendor-update.sh superpowers --apply            # tracks origin's default branch tip
   scripts/vendor-update.sh superpowers --apply --ref v5.1.0   # specific tag or SHA
   ```

   This rewrites `vendor-pins.txt`. It does NOT commit.

4. **Materialize the new tree and re-link**:

   ```bash
   scripts/vendor-install.sh superpowers
   scripts/sync-skills.sh --fix
   ```

5. **Commit and open a PR**:

   ```bash
   git add vendor-pins.txt
   git commit -m "vendor: bump superpowers to v5.1.0

   <summary of notable skill/agent changes from the upstream diff>"
   ```

   Include links to the upstream release notes and call out anything in the diff
   that changed behavior. Reviewers should read the diff themselves before
   approving — this is the review, not a formality.

6. **After merge**, every teammate runs `scripts/setup.sh` to pick up the new
   SHA. `vendor-install.sh` will check out the new SHA and `sync-skills.sh`
   will add/remove symlinks to match.

## Removing a vendor

1. Delete its line from `vendor-pins.txt`.
2. Remove the `.vendor/<slug>/` directory (gitignored, safe to `rm -rf`).
3. `scripts/sync-skills.sh --check` — it will report the now-orphaned symlinks
   in `~/.claude/skills`, `~/.claude/agents`, `~/.claude/commands`, and their
   Cursor counterparts as "unexpected" but will never delete them automatically.
   Remove those manually: they're plain symlinks, `rm path/to/link` is enough.
4. Commit `vendor-pins.txt`.

## Collision policy

If a vendor ships a skill/agent/command with the same name as one in NGOSkills
or `skills-cursor/`, the canonical NGOSkills version wins because it is linked
first by `sync-skills.sh`. The vendor version is skipped and reported as drift
on the next `--check` run. Resolve by renaming — either file an issue upstream
or keep NGOSkills' name and drop that vendor entry from the link set.

## Trust boundary

- `vendor-pins.txt`: committed, reviewed per PR.
- `.vendor/`: gitignored; generated from the pin file. Never edit files here —
  your changes will be blown away by the next `vendor-install.sh` checkout.
- Vendor hooks: inspect, install manually if desired, never symlink from the sync
  script.
