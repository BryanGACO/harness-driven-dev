#!/usr/bin/env bash
#
# check_setup.sh — Harness environment health check.
#
# Verifica que todas las piezas del harness esten configuradas y listas:
#   Check 1: GitHub CLI autenticado
#   Check 2: Git remote configurado
#   Check 3: .env con variables requeridas
#   Check 4: Linear API responde
#   Check 5: pre-commit hooks instalados
#   Check 6: Node dependencies instaladas
#   Check 7: Tests pasan
#
# Usage:
#   bash scripts/check_setup.sh
#

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

CHECKS_PASSED=0
CHECKS_TOTAL=8

pass() { echo -e "${GREEN}PASS${NC}"; CHECKS_PASSED=$((CHECKS_PASSED + 1)); }
fail() { echo -e "${RED}FAIL${NC}"; echo -e "${YELLOW}  Fix: $1${NC}"; }
warn() { echo -e "${YELLOW}WARN — $1${NC}"; CHECKS_PASSED=$((CHECKS_PASSED + 1)); }

echo ""
echo "========================================"
echo "  Harness Setup Check"
echo "========================================"
echo ""

# ── Check 1: GitHub CLI ──

echo -n "Check 1/7 — GitHub CLI autenticado... "
if ! command -v gh &>/dev/null; then
    fail "Instala GitHub CLI: https://cli.github.com"
else
    if gh auth status &>/dev/null; then
        ACCOUNT=$(gh auth status 2>&1 | grep "Logged in" | grep -oE 'account \S+' | awk '{print $2}' || echo "")
        echo -e "${GREEN}PASS${NC} ($ACCOUNT)"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        fail "Ejecuta: gh auth login"
    fi
fi

# ── Check 2: Git remote ──

echo -n "Check 2/7 — Git remote configurado... "
REMOTE=$(git -C "$PROJECT_DIR" remote get-url origin 2>/dev/null || echo "")
if [ -z "$REMOTE" ]; then
    fail "Configura el remote: git remote add origin <url>"
else
    echo -e "${GREEN}PASS${NC} ($REMOTE)"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

# ── Check 3: .env con variables requeridas ──

echo -n "Check 3/7 — Variables de entorno (.env)... "
ENV_FILE="$PROJECT_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    fail "Crea el archivo .env con LINEAR_API_KEY y LINEAR_TEAM_KEY"
else
    LINEAR_API_KEY=$(grep -E '^LINEAR_API_KEY=' "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'" | tr -d ' ')
    LINEAR_TEAM_KEY=$(grep -E '^LINEAR_TEAM_KEY=' "$ENV_FILE" | cut -d= -f2 | tr -d '"' | tr -d "'" | tr -d ' ')

    if [ -z "$LINEAR_API_KEY" ] && [ -z "$LINEAR_TEAM_KEY" ]; then
        fail "LINEAR_API_KEY y LINEAR_TEAM_KEY estan vacias en .env"
    elif [ -z "$LINEAR_API_KEY" ]; then
        fail "LINEAR_API_KEY esta vacia en .env"
    elif [ -z "$LINEAR_TEAM_KEY" ]; then
        fail "LINEAR_TEAM_KEY esta vacia en .env"
    else
        echo -e "${GREEN}PASS${NC} (team: $LINEAR_TEAM_KEY)"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    fi
fi

# ── Check 4: Linear API responde ──

echo -n "Check 4/8 — Linear API responde... "
LINEAR_RESPONSE=$(python3 "$SCRIPT_DIR/linear_client.py" list 2>&1)
LINEAR_EXIT=$?
if [ $LINEAR_EXIT -ne 0 ] || echo "$LINEAR_RESPONSE" | grep -qi "error\|unauthorized\|invalid"; then
    fail "Verifica que LINEAR_API_KEY en .env sea valida"
else
    pass
fi

# ── Check 5: Linear team key valida ──

echo -n "Check 5/8 — Linear team key valida... "
TEAM_KEY_FROM_ENV=$(grep -E '^LINEAR_TEAM_KEY=' "$PROJECT_DIR/.env" 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'" | tr -d ' ')
TEAM_RESPONSE=$(python3 "$SCRIPT_DIR/linear_client.py" check-team 2>&1)
TEAM_EXIT=$?
if [ $TEAM_EXIT -ne 0 ]; then
    fail "El team '$TEAM_KEY_FROM_ENV' no existe en Linear. Verifica LINEAR_TEAM_KEY en .env"
else
    echo -e "${GREEN}PASS${NC} (team: $TEAM_KEY_FROM_ENV)"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

# ── Check 6: pre-commit hooks instalados ──

echo -n "Check 6/8 — pre-commit hooks instalados... "
HOOKS_DIR="$PROJECT_DIR/.git/hooks"
MISSING=""
[ ! -f "$HOOKS_DIR/pre-commit" ] && MISSING="pre-commit"
[ ! -f "$HOOKS_DIR/commit-msg" ] && MISSING="$MISSING commit-msg"

if [ -n "$MISSING" ]; then
    fail "Ejecuta: python -m pre_commit install --hook-type pre-commit --hook-type commit-msg"
else
    pass
fi

# ── Check 7: Node dependencies ──

echo -n "Check 7/8 — Node dependencies instaladas... "
if [ ! -d "$PROJECT_DIR/node_modules" ]; then
    fail "Ejecuta: npm install"
else
    pass
fi

# ── Check 8: Tests pasan ──

echo -n "Check 8/8 — Tests pasan... "
TEST_OUTPUT=$(cd "$PROJECT_DIR" && npm test --silent 2>&1)
TEST_EXIT=$?
if [ $TEST_EXIT -ne 0 ]; then
    fail "Ejecuta 'npm test' y corrige los tests fallidos"
else
    PASSED=$(echo "$TEST_OUTPUT" | grep -oE '[0-9]+ passed' || echo "")
    echo -e "${GREEN}PASS${NC} ($PASSED)"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

# ── Resultado ──

echo ""
echo "========================================"
if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
    echo -e "${GREEN}  LISTO ($CHECKS_PASSED/$CHECKS_TOTAL checks pasaron)${NC}"
    echo "  El harness esta configurado y listo para usar."
else
    echo -e "${RED}  NO LISTO ($CHECKS_PASSED/$CHECKS_TOTAL checks pasaron)${NC}"
    echo "  Corrige los items marcados con FAIL y vuelve a correr este script."
fi
echo "========================================"
echo ""
