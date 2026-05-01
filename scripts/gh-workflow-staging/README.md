# GitHub Workflow Staging

This directory stages workflow YAML files that belong in `.github/workflows/` but cannot be pushed by an OAuth token lacking the `workflow` scope.

## Install

To activate the refresh-skills workflow, either:

**Option A — via GitHub web UI (no scope change needed):**
1. Navigate to https://github.com/bmillersf/NGOSkills
2. Click **Add file → Create new file**
3. Filename: `.github/workflows/refresh-skills.yml`
4. Paste the contents of [`refresh-skills.yml`](refresh-skills.yml) in this directory
5. Commit directly to the branch

**Option B — grant `workflow` scope to your PAT and move locally:**
```bash
mkdir -p .github/workflows
git mv scripts/gh-workflow-staging/refresh-skills.yml .github/workflows/refresh-skills.yml
git commit -m "Move refresh-skills workflow to canonical .github/workflows/"
git push
```

## After install

Enable "Allow GitHub Actions to create and approve pull requests" in repo Settings → Actions → General → Workflow permissions. Without this setting, the PR-creation step will 403.
