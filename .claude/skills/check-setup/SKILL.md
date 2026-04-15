---
name: check-setup
description: Verify that the harness environment is fully configured and ready to use
user-invocable: true
allowed-tools: Bash(bash scripts/check_setup.sh)
---

# Check Setup

Run the harness environment health check and display the results as a dashboard.

## Steps

1. **Run the health check script**:
   ```bash
   bash scripts/check_setup.sh
   ```

2. **Parse the output** and present results in this dashboard format:

```
┌─────────────────────────────────────────┐
│         HARNESS SETUP CHECK             │
├─────────────────────────────────────────┤
│ Check 1/7 — GitHub CLI       ✓ PASS    │
│ Check 2/7 — Git remote       ✓ PASS    │
│ Check 3/7 — Variables .env   ✓ PASS    │
│ Check 4/7 — Linear API       ✓ PASS    │
│ Check 5/7 — Hooks instalados ✓ PASS    │
│ Check 6/7 — Node deps        ✓ PASS    │
│ Check 7/7 — Tests            ✓ PASS    │
├─────────────────────────────────────────┤
│  ✓ LISTO — 7/7 checks pasaron          │
└─────────────────────────────────────────┘
```

- Use `✓` for PASS, `✗` for FAIL, `⚠` for WARN
- If any check FAILs, show below the dashboard a **"Fixes necesarios"** section listing each failed check and its fix instruction
- If all pass, show: `El harness está listo. Puedes comenzar con /create-issue o /start-issue.`
