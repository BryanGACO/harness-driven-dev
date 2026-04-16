# Guía de Setup

[English](setup-guide.md)

Guía paso a paso para replicar Harness-Driven Development en tu propio proyecto.

> **Nota**: `DEMO` se usa como ejemplo de clave de equipo en toda esta guía. Reemplaza con la clave real de tu equipo en Linear (ej., `HAR`, `EXP`, `PROJ`). El prefijo se define al crear tu equipo en Linear y determina los IDs de tus issues (ej., `HAR-1`, `EXP-1`).

## Flujo de Setup

```mermaid
flowchart LR
    A["1. Clonar repo"] --> B["2. Python venv + Node deps"]
    B --> C["3. Integración Linear"]
    C --> D["4. Pre-commit hooks"]
    D --> E["5. GitHub Actions"]
    E --> F["6. Claude Code"]
    F --> G["7. Listo!"]

    style A fill:#58a6ff,color:#0d1117
    style G fill:#238636,color:#fff
```

## 1. Prerrequisitos

| Herramienta | Versión | Instalar |
|-------------|---------|----------|
| Node.js | 18+ | [nodejs.org](https://nodejs.org/) |
| Python | 3.9+ | [python.org](https://python.org/) |
| Claude Code | Última | [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code) |
| GitHub CLI | 2.0+ | [cli.github.com](https://cli.github.com/) |
| pre-commit | 3.0+ | `pip install pre-commit` |
| Cuenta de Linear | — | [linear.app](https://linear.app/) |

## 2. Setup del Repositorio

```bash
git clone https://github.com/felirangelp/harness-driven-dev.git
cd harness-driven-dev

# Ambiente virtual Python
python3 -m venv .venv
source .venv/bin/activate    # macOS/Linux
# .venv\Scripts\activate     # Windows

# Dependencias Node
npm install
```

## 3. Integración con Linear

### 3.1 Conectar Linear con GitHub

1. Ve a **Linear → Settings → Integrations → GitHub**
2. Instala la **Linear GitHub App** en tu cuenta de GitHub
3. Selecciona los repositorios que quieras conectar
4. Activa:
   - PR automations
   - Magic words
   - Linkbacks

### 3.2 Crear una API Key de Linear

1. Ve a **Linear → Settings → API → Personal API keys → Create**
2. Copia la key (empieza con `lin_api_...`)

### 3.3 Configurar la API Key

**Localmente** (para desarrollo):
```bash
cp .env.example .env
# Edita .env y pega tu key:
# LINEAR_API_KEY=lin_api_your_key_here
```

**En GitHub** (para CI):
```bash
gh secret set LINEAR_API_KEY
# Pega tu key cuando te lo pida
```

### 3.4 Verificar

```bash
python3 scripts/linear_client.py list
```

Deberías ver tus issues de Linear listados.

## 4. Pre-commit Hooks

```bash
pip install pre-commit
pre-commit install --hook-type pre-commit --hook-type commit-msg
```

Esto instala dos hooks:

| Hook | Stage | Qué hace |
|------|-------|----------|
| gitleaks | pre-commit | Escanea secrets (API keys, passwords, tokens) |
| check-issue-ref | commit-msg | Asegura que `Refs DEMO-XXX` esté en cada commit |

### Verificar que los hooks funcionan

```bash
# Esto debe PASAR
pre-commit run --all-files

# Esto debe BLOQUEAR (sin referencia a issue)
echo "test" > /tmp/test-msg.txt
bash scripts/check_issue_ref.sh /tmp/test-msg.txt
# Esperado: BLOCKED
```

## 5. GitHub Actions

CI corre automáticamente en push/PR a `main`. Dos workflows:

| Workflow | Archivo | Trigger | Qué hace |
|----------|---------|---------|----------|
| CI | `.github/workflows/ci.yml` | push, PR, manual | Corre tests + gitleaks |
| Linear Bridge | `.github/workflows/linear-bridge.yml` | CI failure | Crea bug en Linear |

### 5.1 Secrets requeridos en GitHub

Ve a **Settings → Secrets and variables → Actions** y agrega:

| Secret | Valor | Para qué |
|--------|-------|----------|
| `LINEAR_API_KEY` | `lin_api_...` | Autenticar llamadas a la API de Linear |
| `LINEAR_TEAM_KEY` | Ej.: `DEV`, `HAR` | Identificar el equipo en Linear al crear bugs |

```bash
gh secret set LINEAR_API_KEY
gh secret set LINEAR_TEAM_KEY
```

### 5.2 Pasos especiales si el repo es un fork

Si clonaste este repo como fork (no como repo nuevo), GitHub Actions requiere pasos adicionales:

1. **Habilitar Actions en el fork**: Ve a **Settings → Actions → General** y selecciona _"Allow all actions and reusable workflows"_.

2. **Forzar el indexado de workflows**: GitHub solo registra workflows que existieron en `main` mediante un push real. Si los workflows no aparecen en la pestaña Actions, haz un push vacío a `main`:
   ```bash
   git commit --allow-empty --no-verify -m "chore: trigger Actions workflow indexing"
   git push origin main
   ```

3. **Verificar que los workflows quedaron registrados**:
   ```bash
   gh api repos/OWNER/REPO/actions/workflows --jq '.total_count'
   # Debe retornar 2 (CI y Linear Bridge)
   ```

## 6. Claude Code

### 6.1 Instalar Claude Code

Sigue la [guía oficial](https://docs.anthropic.com/en/docs/claude-code).

### 6.2 Verificar Skills

Inicia Claude Code en el directorio del proyecto:

```bash
cd harness-driven-dev
claude
```

El agente leerá `CLAUDE.md` y tendrá acceso a 4 skills:

- `/create-issue <título>` — Crear un nuevo issue en Linear con criterios de aceptación
- `/start-issue DEMO-X` — Iniciar trabajo en un issue
- `/close-issue DEMO-X` — Cerrar con evidencia
- `/status` — Dashboard del proyecto

## 7. Setup del Proyecto en Linear (para Demos)

1. Crea un **Team** en Linear (ej., "Demo")
2. Crea un **Project** (ej., "HDD Demo")
3. Crea 3 issues:
   - `DEMO-1`: "Add dark mode toggle"
   - `DEMO-2`: "Add task counter per column"
   - `DEMO-3`: "Add drag and drop between columns"
4. Pon todos los issues en estado **To Do**

## 8. Convención de Nombres de Branch

El webhook de Linear detecta identificadores de issues en nombres de branch:

```
feat/DEMO-1-dark-mode        ✅ Detectado → linkea PR al issue
fix/DEMO-2-counter-bug       ✅ Detectado
my-feature-branch            ❌ No detectado → sin auto-linking
```

Patrón: `{type}/DEMO-{N}-{slug}`

Tipos: `feat`, `fix`, `docs`, `test`, `chore`, `refactor`

## 9. Política de Keywords

| Keyword | ¿Permitido? | Por qué |
|---------|-------------|---------|
| `Refs DEMO-XXX` | Siempre | Linkea commit al issue sin cerrarlo |
| `Closes DEMO-XXX` | Nunca | Auto-cierra el issue, bypasea los gates del harness |
| `Fixes DEMO-XXX` | Nunca | Igual que Closes |
| `Resolves DEMO-XXX` | Nunca | Igual que Closes |

El hook `check_issue_ref.sh` hace cumplir esto automáticamente.

## Cómo Funcionan los Hooks Juntos

```mermaid
flowchart TD
    COMMIT["git commit"] --> PRE["pre-commit hook"]
    PRE --> GL{"gitleaks<br/>¿Secrets?"}
    GL -->|"secret encontrado"| BLOCK1["BLOQUEADO<br/>Elimina el secret"]
    GL -->|"limpio"| CM["commit-msg hook"]
    CM --> REF{"check_issue_ref.sh<br/>¿Tiene Refs DEMO-XXX?"}
    REF -->|"sin ref"| BLOCK2["BLOQUEADO<br/>Agrega Refs DEMO-XXX"]
    REF -->|"tiene Closes/Fixes"| BLOCK3["BLOQUEADO<br/>Usa Refs, no Closes"]
    REF -->|"válido"| OK["Commit aceptado"]
    OK --> PUSH["git push"]
    PUSH --> CI["GitHub Actions"]
    CI --> TEST["npm test"]
    CI --> GLCI["gitleaks scan"]
    TEST & GLCI --> RESULT{"¿Todo pasa?"}
    RESULT -->|"sí"| GREEN["PR listo para review"]
    RESULT -->|"no"| BRIDGE["ci_failure_bridge.py<br/>→ Bug en Linear"]

    style BLOCK1 fill:#f85149,color:#fff
    style BLOCK2 fill:#f85149,color:#fff
    style BLOCK3 fill:#f85149,color:#fff
    style GREEN fill:#238636,color:#fff
    style BRIDGE fill:#d29922,color:#0d1117
```

## Troubleshooting

**"LINEAR_API_KEY not set"**
- Verifica que el archivo `.env` existe y tiene la key
- Ejecuta `source .venv/bin/activate` antes de correr scripts

**"pre-commit not found"**
- Ejecuta `pip install pre-commit` dentro del ambiente virtual

**"gh: command not found"**
- Instala GitHub CLI: https://cli.github.com/

**Tests fallan con "Cannot find module jsdom"**
- Ejecuta `npm install` para instalar dependencias

---

### Problemas específicos de GitHub Actions

**La pestaña Actions está vacía / `total_count: 0` en workflows**
- El repo es un fork y GitHub no indexó los workflows automáticamente
- Solución: push vacío a `main` con `git commit --allow-empty` para forzar el indexado

**CI no se dispara en el PR después de varios pushes**
- GitHub puede ignorar commits vacíos consecutivos (`--allow-empty`)
- Solución: hacer un cambio real en cualquier archivo (ej. `echo "" >> README.md`) y commitear

**Linear Bridge falla con `GH_TOKEN` not set**
- El token de GitHub no se pasa automáticamente en `workflow_run`
- Solución: agregar `GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}` al `env` del step en `linear-bridge.yml`

**Linear Bridge falla con `Team 'DEMO' not found in Linear`**
- Falta el secret `LINEAR_TEAM_KEY` en GitHub, o no se está pasando al step
- Solución: crear el secret en GitHub y agregarlo al `env` del step:
  ```yaml
  LINEAR_TEAM_KEY: ${{ secrets.LINEAR_TEAM_KEY }}
  ```

**Linear Bridge falla con `This endpoint deprecated` (issueSearch)**
- Linear deprecó el endpoint `issueSearch` en su API GraphQL
- Solución: usar `issues` con filtros `title` y `state`:
  ```graphql
  issues(filter: {
      title: { contains: "[CI-BRIDGE]" }
      state: { type: { in: ["started", "unstarted"] } }
  }, first: 1)
  ```
  Nota: los valores del enum deben ir entre comillas (`"started"`, no `started`)

**`UnicodeEncodeError` al correr `linear_client.py` en Windows**
- La consola de Windows usa `cp1252` por defecto, que no soporta muchos caracteres Unicode
- Solución: al inicio de `main()` en `linear_client.py`, redirigir stdout a UTF-8:
  ```python
  import io
  if hasattr(sys.stdout, 'buffer'):
      sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
  ```
