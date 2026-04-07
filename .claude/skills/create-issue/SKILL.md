---
name: create-issue
description: Create a new issue in Linear with title, description, and acceptance criteria
user-invocable: true
allowed-tools: Bash(python3 scripts/*)
argument-hint: "<TITLE> [description or acceptance criteria]"
---

# Create Issue

Create a new issue in Linear.

## Usage Examples

```
/create-issue Add dark mode toggle
/create-issue Add task counter per column
/create-issue Fix login bug on mobile
```

## Steps

1. **Parse the request**: Extract the title and any description or acceptance criteria from the user's input.

2. **Build the description**: If the user provides acceptance criteria or requirements, format them as:
   ```markdown
   ## Acceptance Criteria
   - [ ] First criterion
   - [ ] Second criterion
   - [ ] Third criterion
   ```

3. **Create the issue**:
   ```bash
   python3 scripts/linear_client.py create "<TITLE>" "<DESCRIPTION>"
   ```

4. **Confirm** to the user:
   ```
   Created: DEMO-X  <title>
   URL: https://linear.app/...
   ```

## Rules

- Always include `## Acceptance Criteria` with `- [ ]` checkboxes when the user provides requirements.
- If the user doesn't specify criteria, ask what the acceptance criteria should be.
- The issue is created in the team defined by `LINEAR_TEAM_KEY` (default: `DEMO`).
