# The Agent Harness: A First-Principles Dossier

**Concept**: Before an AI agent can do *real work* on a project, it must have a **harness** — an automated loop that boots the running software, lets the agent interact with it the way a user would, and validates the results. No harness → no feedback → no useful iteration.

**Status**: Extracted from production experience (MYOB Agentic Web Server, 2026-03-05)
**Provenance**: ADR-0001 (Agent-Driven Harness Loop), Workshop 008 (Agent Harness), `harness.mjs`

---

## 1. The Core Insight

Traditional development assumes a human sits in front of the software: clicking buttons, reading screens, typing commands. An AI agent has none of that by default. It can *write* code all day, but unless it can *run* the software and *observe the results*, it's flying blind.

**The harness is the agent's eyes, hands, and ears.**

Without it, an agent is reduced to:
- Writing code and hoping it works
- Asking the human to test after every change
- Running unit tests that pass while the real application is broken

With a harness, the agent can:
- Boot the full stack autonomously
- Interact with the running software exactly as a user would
- Capture evidence (screenshots, responses, terminal output)
- Iterate in ~30-60 second cycles instead of waiting for human review

### The Rule

> **Before starting any implementation phase, the agent MUST have a working harness that it can boot, interact with, and validate — autonomously. If no harness exists, building one IS the first task. Everything else is secondary.**

---

## 2. What Makes a Harness

A harness is NOT just a test suite. Tests verify isolated behavior. A harness runs the *whole thing* and lets the agent use it.

### The Three Capabilities

Every harness must provide:

| Capability | What it means | Examples |
|-----------|---------------|----------|
| **Boot** | Agent can start the full runtime from cold | Start server, launch browser, connect to database, spin up container |
| **Interact** | Agent can drive the software like a user | Send HTTP requests, type in terminal, click buttons, call APIs |
| **Observe** | Agent can capture what happened | Read responses, take screenshots, capture stdout, inspect DOM |

If any of the three is missing, the harness is incomplete:
- Boot + Interact but no Observe → agent can drive it but can't tell if it worked
- Boot + Observe but no Interact → agent can see it but can't do anything
- Interact + Observe but no Boot → agent depends on human to set things up first

### The Feedback Loop

```
┌─────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Boot   │ ──→ │ Interact │ ──→ │ Observe  │ ──→ │ Validate │
│ (start) │     │ (use it) │     │ (capture)│     │ (decide) │
└─────────┘     └──────────┘     └──────────┘     └──────────┘
     ↑                                                  │
     └──────────── iterate (change code, reboot) ───────┘
```

**Target cycle time: 30-60 seconds.** Anything longer and the agent loses momentum. Anything shorter is a bonus but rarely achievable for full-stack boots.

---

## 3. Harness Patterns by Software Type

The harness shape changes depending on what you're building. The three capabilities remain constant.

### Pattern A: Web Application

**Boot**: Start server process, launch browser (Playwright/Puppeteer), navigate to app
**Interact**: HTTP API calls, browser automation (click, type, navigate), injected JavaScript
**Observe**: HTTP response bodies, screenshots, DOM inspection, network interception

```
Agent ──→ spawn(server) ──→ playwright.launch() ──→ page.goto(app)
                                    │
                              page.click()
                              page.type()
                              page.evaluate()
                              fetch(api/endpoint)
                                    │
                              page.screenshot()
                              response.json()
                              page.textContent()
```

**Real example (this project)**:
- `harness.mjs` spawns server + browser
- `poke.mjs` launches Firefox with persistent auth profile
- Agent sends messages via `POST /api/chat`, polls `GET /api/chat/status`
- Screenshots via `page.screenshot()`, DOM via `page.evaluate()`
- Full cold boot → first validated interaction: ~40 seconds

**Key challenges**:
- Auth/login state (persistent browser profiles, cookie management)
- SPA boot time (React/Angular apps take 5-15s to stabilize)
- CSS/visual validation (screenshots needed, not just API responses)
- Browser profile locks (only one Playwright instance per profile)

### Pattern B: Terminal / CLI Application

**Boot**: Start the application in a controlled terminal (tmux/screen/pty)
**Interact**: Send keystrokes, pipe stdin, invoke subcommands
**Observe**: Capture stdout/stderr, read terminal buffer, parse output

```
Agent ──→ tmux new-session -d -s harness ──→ tmux send-keys 'app start'
                                    │
                              tmux send-keys 'command'
                              tmux send-keys 'q' (quit)
                              echo 'input' | app
                                    │
                              tmux capture-pane -p
                              app --json | parse
                              tail -f app.log
```

**Key challenges**:
- ANSI escape codes in terminal output (strip them for parsing)
- Timing (wait for prompt before sending next command)
- Interactive menus (arrow keys, tab completion, REPL prompts)
- Shell escaping (special characters in `send-keys` — use shell-safe escaping, NOT `JSON.stringify`)

**tmux as universal harness adapter**:
tmux is exceptionally powerful for terminal harnesses because it provides:
- Named windows/panes for multiple processes
- `send-keys` for keyboard input
- `capture-pane` for output reading
- Session persistence across agent restarts
- Detached execution (no TTY needed)

### Pattern C: MCP Server / Tool Server

**Boot**: Start the MCP server (stdio or HTTP transport)
**Interact**: Send JSON-RPC tool calls, invoke Copilot CLI against the server
**Observe**: Read JSON-RPC responses, check tool outputs, validate schema compliance

```
Agent ──→ spawn(mcp-server --stdio)
                    │
              send: {"jsonrpc":"2.0","method":"tools/call","params":{...}}
              recv: {"jsonrpc":"2.0","result":{...}}
                    │
              validate(result, expected_schema)
              copilot-cli --mcp-server ./my-server.mjs "test query"
```

**Alternatively, test via Copilot CLI**:
```bash
# Boot: start the MCP server
node my-mcp-server.mjs &

# Interact: ask Copilot to use the tools
copilot-cli chat "Use the calculator tool to add 2+2"

# Observe: check the response includes tool usage
copilot-cli chat --json "..." | jq '.tool_calls'
```

**Key challenges**:
- stdio transport (bidirectional pipe management, framing)
- Tool registration validation (schema must match what server advertises)
- Error propagation (tool errors vs protocol errors)
- Session state (some MCP servers are stateful between calls)

### Pattern D: API / Backend Service

**Boot**: Start server, migrate database, seed test data
**Interact**: HTTP requests (curl, fetch), gRPC calls, database queries
**Observe**: Response bodies, status codes, database state, logs

```
Agent ──→ docker-compose up -d ──→ migrate ──→ seed
                    │
              curl -X POST /api/users
              curl GET /api/users/1
              psql -c "SELECT * FROM users"
                    │
              assert(status === 201)
              assert(response.name === "test")
              assert(row_count === 1)
```

**Key challenges**:
- Database state management (fresh seed per test, or reset between iterations)
- External service dependencies (mock them or use test containers)
- Auth tokens (generate test tokens, or capture from OAuth flow)
- Port conflicts (randomize or check before boot)

### Pattern E: Mobile / Desktop Application

**Boot**: Build app, launch emulator/simulator, install and start
**Interact**: Appium/XCUITest/Espresso commands, accessibility tree navigation
**Observe**: Screenshots, accessibility tree dumps, log output

**Key challenges**:
- Build times (minutes, not seconds — cache aggressively)
- Emulator boot time (keep emulators warm/persistent)
- Platform-specific automation APIs
- Hardware feature mocking (camera, GPS, sensors)

### Pattern F: Infrastructure / IaC

**Boot**: `terraform plan` / `pulumi preview` (dry run first, then apply to test env)
**Interact**: Deploy resources, configure services, run smoke tests against infra
**Observe**: Plan output, resource state, endpoint health checks, cost estimates

**Key challenges**:
- Real cloud resources cost money and take time to provision
- State management (don't corrupt production state)
- Cleanup (destroy test resources after validation)
- Drift detection (plan vs actual)

---

## 4. Harness Design Principles

### Principle 1: One Command to Boot

The harness must start from a **single command**. If an agent needs to open three terminals, run five commands in sequence, and wait for each — it will fail.

```bash
# Good: single command
just chat              # boots server + browser + widget + auth
just dev               # same, different style
node harness.mjs       # same, raw Node.js

# Bad: manual multi-step
cd server && npm run dev &    # step 1
sleep 3                       # step 2
node poke.mjs --firefox &     # step 3
sleep 5                       # step 4
# now manually check things...
```

### Principle 2: Health Check Gate

After boot, the harness must provide a **single reliable signal** that everything is ready.

```bash
curl -sf http://localhost:6001/api/health | grep -q '"ok":true' && echo "READY"
```

The agent must NOT proceed until the health check passes. Everything else is unreliable:
- Process started ≠ process ready (server may still be compiling)
- Port open ≠ app ready (socket bound but routes not registered)
- No error ≠ success (silent failures are the worst kind)

### Principle 3: Idempotent Boot

Running the boot command twice must be safe. The harness should:
- Detect and reuse an already-running instance
- Kill and restart if the instance is stale/unhealthy
- Never leave orphan processes

```javascript
// Good: check before starting
try {
  const res = await fetch('http://localhost:6001/api/health');
  if (res.ok) return; // already running
} catch {} // not running, start it

// Bad: always spawn, hope it works
spawn('npm', ['run', 'dev']); // port conflict if already running
```

### Principle 4: Clean Shutdown

The harness must clean up after itself. Orphan processes, locked files, and stale ports are harness bugs.

```javascript
process.on('SIGINT', async () => {
  browser.kill('SIGTERM');
  server.kill('SIGTERM');
  await sleep(1000);
  process.exit(0);
});
```

### Principle 5: Two Modes — Full and API-Only

Most harnesses should support two interaction modes:

| Mode | When | Agent owns UI? | Speed |
|------|------|----------------|-------|
| **Full** | Cold start, visual validation needed | Yes | ~40s boot |
| **API-only** | Harness already running (human or previous agent started it) | No | Instant |

API-only mode is the **happy path** — the harness is already running, the agent just sends requests. Full mode is for cold boots and visual regression.

### Principle 6: Evidence Capture

The agent must be able to capture evidence of what it observed. Evidence types:

| Evidence | Use | How |
|----------|-----|-----|
| **Screenshots** | Visual layout, CSS rendering, injection success | `page.screenshot()` |
| **Response bodies** | API correctness, data validation | `fetch().then(r => r.json())` |
| **Terminal output** | CLI behavior, error messages | `tmux capture-pane -p` |
| **DOM snapshots** | Element presence, attribute values | `page.evaluate(() => document.querySelector(...))` |
| **Log output** | Server errors, timing, stack traces | `tail -f server.log` |

### Principle 7: Auth as Infrastructure

Almost every real application requires authentication. The harness must solve auth without human intervention on every boot.

Common patterns:
- **Persistent browser profile**: Store OAuth cookies in a reusable profile directory. Human logs in once (~24h validity), agent reuses the session.
- **Service account / API key**: If available, hardcode in `.env` (never commit). Best option but often unavailable.
- **Token file**: Capture tokens to a file (`~/.myob-cli/auth.json`), auto-inject on boot. Agent can detect expiry and alert human.
- **Auth capture loop**: Intercept network requests to sniff tokens from a live browser session.

> **Auth expiry is the #1 reason harnesses break.** Always implement expiry detection and clear error messages for the human.

---

## 5. The Harness Maturity Model

Harnesses evolve. Don't try to build the perfect one on day one.

### Level 0: No Harness
Agent writes code, asks human to test. Feedback cycle: minutes to hours.
*"I've made the changes. Can you check if the button works?"*

### Level 1: Manual Boot + API Interaction
Human starts the stack. Agent can send API requests and read responses.
*Health check works. Agent can `curl` the API. No visual validation.*

### Level 2: Automated Boot + API Interaction
Agent can start the stack from cold. Health check gate. API interaction.
*`just dev` boots everything. Agent sends requests, reads responses.*

### Level 3: Automated Boot + Full Interaction + Evidence
Agent boots everything, drives the UI (or terminal), captures screenshots/output.
*Agent launches browser, sends chat messages, takes screenshots, validates visually.*

### Level 4: Self-Healing Harness
Harness detects and recovers from common failures: port conflicts, stale processes, auth expiry, browser hangs.
*Auto-kill orphan processes, retry on timeout, detect auth expiry and warn.*

**Target: Level 3 minimum.** Level 4 is aspirational and builds naturally as you hit failure modes.

---

## 6. Anti-Patterns

### Anti-Pattern 1: "Tests Are Enough"

Unit tests and integration tests are valuable but insufficient. They test isolated behavior in a synthetic environment. The harness tests the **running software as a user experiences it**.

Example: All unit tests pass, but the chat widget doesn't render because the Shadow DOM injection conflicts with the host app's CSS. Only a harness with screenshot capture catches this.

### Anti-Pattern 2: "The Agent Can Figure It Out"

Agents need explicit instructions for the harness. Don't assume the agent will discover how to boot the stack by reading source code. Provide:
- A single command to start (`just chat`)
- A health check URL or command
- An API reference for interaction
- Example validation scripts

### Anti-Pattern 3: "We'll Add the Harness Later"

If you build features first and harness second, every feature is unvalidated. You accumulate bugs that compound. The harness is not overhead — it's the foundation that makes everything else possible.

### Anti-Pattern 4: "Screenshot Everything"

Screenshots are expensive (time, storage) and brittle (layout changes). Use them for visual regression only. Prefer API responses and structured output for logic validation.

### Anti-Pattern 5: "One Process Per Terminal"

Agents can't easily manage multiple terminal windows. The harness must orchestrate all processes from a single entry point with a single shutdown handler.

---

## 7. The Harness Checklist

Use this checklist when setting up a harness for any new project:

```
Boot
[ ] Single command starts the full stack
[ ] Health check endpoint/command exists
[ ] Boot is idempotent (safe to run twice)
[ ] Handles port conflicts (kill stale or fail fast)
[ ] Clean shutdown on Ctrl+C / SIGTERM / SIGINT

Interact
[ ] Agent can send input (HTTP, stdin, keystrokes)
[ ] Agent can trigger all user-facing actions
[ ] Auth is automated (persistent profile, token file, API key)
[ ] Auth expiry is detected with clear error message

Observe
[ ] Agent can read output (responses, stdout, DOM)
[ ] Evidence capture works (screenshots, logs, response files)
[ ] Structured output available (JSON, not just visual)

Operate
[ ] README/bootstrap doc explains the harness to a new agent
[ ] Example validation script exists (copy-paste ready)
[ ] `justfile` or equivalent provides named commands
[ ] Timing/delay table documented (what takes how long)
```

---

## 8. Case Study: MYOB Agentic Web Server

This is the concrete implementation that taught us these principles.

### The Stack
- **Next.js server** on `:6001` — Copilot SDK adapter, chat API, page control tools
- **Firefox browser** — Playwright-controlled, persistent auth profile, injected chat widget
- **MYOB Business SPA** — Third-party React app at `app.myob.com`
- **GitHub Copilot** — Connected via SDK, tools defined server-side

### Boot
```bash
just chat     # harness.mjs → server + browser + widget + event streaming
just dev      # justfile recipe → server + browser + auth check
just check    # health + CORS + auth validation
```

### Interact
```bash
# API-only (harness already running)
curl -X POST http://localhost:6001/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"list overdue invoices"}'

# Poll
curl http://localhost:6001/api/chat/status?since=evt-5
```

### Observe
- HTTP response JSON (events array with typed events)
- Playwright `page.screenshot()` for visual validation
- `page.evaluate()` for DOM inspection
- Terminal event streaming (harness.mjs prints events to stdout)

### What We Learned
1. **Auth is the hardest part** — MYOB uses external IDP with CAPTCHA/2FA. Only solution: persistent browser profile from human login.
2. **Two BFF auth tokens** — Main BFF and Reports BFF use different JWTs. Harness must capture both.
3. **Browser freeze on headful launch** — Firefox hangs ~10% of the time when launched from non-interactive shell. Need timeout + retry.
4. **SPA stabilization** — MYOB React app needs 10-15 seconds after `domcontentloaded` before DOM is interactive.
5. **Profile lock** — Only one Playwright instance per profile. Agent and human can't both use the browser.
6. **Shell escaping** — tmux `send-keys` needs shell-safe escaping, NOT `JSON.stringify`. Characters like `$`, `` ` ``, `"` will break.
7. **Visual bugs are real** — CSS conflicts, Shadow DOM viewport unit failures, pointer-events overlay bugs — all caught only by screenshot, never by unit tests.
8. **40-second cycle time** — Full cold boot → first validated interaction. Good enough for rapid iteration. API-only mode is instant.

### Key Files
| File | Role |
|------|------|
| `harness.mjs` | Full harness: server + browser + event streaming |
| `poke.mjs` | Browser launcher + auth capture + widget injection |
| `justfile` | Named commands for all harness operations |
| `AGENT_BOOTSTRAP.md` | Quick-start guide for new agents |
| `scratch/e2e-test.mjs` | Reference validation script |
| `docs/adr/adr-0001-agent-driven-harness-loop.md` | Architecture decision record |
| `docs/plans/006-myob-agentic-web-server/workshops/008-agent-harness.md` | Detailed workshop with tested findings |

---

## 9. Template: Minimal Harness for a New Project

Adapt this skeleton for any project:

```javascript
#!/usr/bin/env node
// harness.mjs — Agent Harness for [PROJECT_NAME]
import { spawn } from 'child_process';

const HEALTH_URL = 'http://localhost:PORT/health';
let procs = [];

// ─── Boot ───
async function boot() {
  // 1. Start the main process
  const server = spawn('npm', ['start'], { stdio: 'pipe' });
  procs.push(server);

  // 2. Wait for health
  for (let i = 0; i < 30; i++) {
    try {
      const res = await fetch(HEALTH_URL);
      if (res.ok) { console.log('✅ Ready'); return; }
    } catch {}
    await new Promise(r => setTimeout(r, 1000));
  }
  throw new Error('Boot failed — health check never passed');
}

// ─── Interact ───
async function interact(input) {
  // Send input to the running software
  // HTTP: fetch(url, { method: 'POST', body: JSON.stringify(input) })
  // Terminal: tmux send-keys -t harness "${input}" Enter
  // CLI: execSync(`app command ${input}`)
}

// ─── Observe ───
async function observe() {
  // Capture output from the running software
  // HTTP: await fetch(url).then(r => r.json())
  // Terminal: execSync('tmux capture-pane -t harness -p')
  // Screenshot: await page.screenshot({ path: '/tmp/evidence.png' })
}

// ─── Shutdown ───
async function shutdown() {
  for (const p of procs) {
    p.kill('SIGTERM');
  }
  process.exit(0);
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

// ─── Main ───
await boot();
const result = await interact({ message: 'test' });
const evidence = await observe();
console.log('Evidence:', evidence);
await shutdown();
```

---

## 10. Summary

| Principle | One-liner |
|-----------|-----------|
| Harness first | Build the harness before building the features |
| Boot → Interact → Observe | Every harness needs all three capabilities |
| One command to start | `just chat`, not a 5-step manual process |
| Health check gate | Don't proceed until the single health signal passes |
| Auth as infrastructure | Solve auth once, reuse forever (until it expires) |
| Evidence over hope | Screenshots, response bodies, terminal captures — not "it should work" |
| Two modes | Full (cold boot) and API-only (harness already running) |
| 30-60 second cycles | If iteration takes longer, optimize the boot |
| Self-healing (aspirational) | Detect and recover from common failures automatically |
| Document for the next agent | Bootstrap doc + example script + justfile = agent can land and go |

**The harness is not overhead. The harness is the work. Everything else is built on top of it.**
