---
name: create-issue
description: Create a well-documented issue in Linear with objective, description, acceptance criteria, and technical notes
user-invocable: true
allowed-tools: Bash(python3 scripts/*)
argument-hint: "<TITLE> [details]"
---

# Create Issue

Create a well-documented issue in Linear following a standard template.

## Usage Examples

```
/create-issue Add dark mode toggle
/create-issue Add task counter per column
/create-issue Fix login bug on mobile
```

## Steps

1. **Parse the request**: Extract the title and any details the user provides.

2. **Build the description** using this standard template:

   ```markdown
   ## Objective
   Brief description of what this issue accomplishes and why it matters.

   ## Description
   Detailed explanation of the feature, bug, or task. Include context
   that helps understand the scope and approach.

   ## Acceptance Criteria
   - [ ] First measurable criterion
   - [ ] Second measurable criterion
   - [ ] Third measurable criterion

   ## Technical Notes
   - Relevant files, components, or areas of the codebase
   - Dependencies or constraints
   - Suggested approach (if applicable)
   ```

3. **Create the issue**:
   ```bash
   python3 scripts/linear_client.py create "<TITLE>" "<DESCRIPTION>"
   ```

4. **Confirm** to the user showing the issue ID, title, and URL.

## Template Rules

- **Objective**: Always include. One sentence explaining the "what" and "why".
- **Description**: Always include. 2-3 sentences with context, scope, and approach.
- **Acceptance Criteria**: Always include. Each criterion must be:
  - Specific and measurable (not vague like "works well")
  - Testable (can be verified as done or not done)
  - Written as `- [ ]` checkboxes (the harness gate 3 checks these)
- **Technical Notes**: Include when relevant. Files to modify, dependencies, constraints.

## Examples of Good vs Bad Criteria

**Bad:**
- [ ] Dark mode works
- [ ] Looks good

**Good:**
- [ ] Toggle button visible in the header area
- [ ] Clicking toggle switches all board styles between dark and light themes
- [ ] User preference persists across browser sessions via localStorage

## Rules

- If the user gives a vague request, infer reasonable acceptance criteria from the project context.
- If the user only gives a title, generate the full description based on the project (Task Board).
- The issue is created in the team defined by `LINEAR_TEAM_KEY` env var.
- Every issue must have at least: Objective, Description, and Acceptance Criteria.
