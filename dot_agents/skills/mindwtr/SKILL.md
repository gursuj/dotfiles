---
name: mindwtr
description: "Use when the user mentions mindwtr or GTD"
compatibility: "Requires the self-hosted Mindwtr Cloud instance (https://gtd.gurungsujal.com.np). REST API only"
---

# Mindwtr (GTD Task Management)

Mindwtr Cloud is self-hosted on the VPS (`gtd.gurungsujal.com.np`, Caddy reverse-proxying a Docker container bound to `127.0.0.1:8787`). All devices sync through it now.

## REST API

Base URL: `https://gtd.gurungsujal.com.np/v1` — every route below needs the `/v1` prefix (`/tasks` alone 404s). `/health` is the one exception, served unprefixed and without auth.

`POST /tasks` only reliably saves `title`; send `description` via a follow-up `PATCH` if it doesn't stick on create.

Avoid typographic punctuation (`·`, `—`, smart quotes) in request bodies sent from this Windows/Bash-tool environment — it's been observed corrupting to `�` in transit before reaching curl. Use plain ASCII (`-`, `"`) instead.

Every request needs `Authorization: Bearer <token>`. Store the token in the `MINDWTR_API_TOKEN` environment variable — never write it into a file. (VPS-side copy of the token lives at `/etc/mindwtr-cloud/token`, `640`, `root:mindwtr-secrets`.)

| Need | Request |
|------|---------|
| List next actions | `GET /tasks?status=next` |
| Search tasks + projects | `GET /search?query=@work` |
| Get one task | `GET /tasks/:id` |
| List projects | `GET /projects` |
| List areas | `GET /areas` |
| List sections | `GET /sections` |
| Create task | `POST /tasks` — body `{"title":"...","props":{"status":"next","contexts":["@phone"],"tags":["#errands"]}}` |
| Update task | `PATCH /tasks/:id` |
| Complete | `POST /tasks/:id/complete` |
| Archive | `POST /tasks/:id/archive` |
| Create/update project or area | `POST`/`PATCH /projects[/:id]`, `/areas[/:id]` |

There's no documented "restore" action — un-archiving a task likely goes through `PATCH /tasks/:id` (e.g. resetting `status`), not a dedicated endpoint. Check `GET /tasks/:id` on the archived task and confirm the field to flip before assuming a shape.

The API also exposes `DELETE /tasks/:id`, `/projects/:id`, `/areas/:id` — never call these (see Security Rules).

Example (Bash tool; PowerShell uses `$env:MINDWTR_API_TOKEN`):

```bash
curl -s 'https://gtd.gurungsujal.com.np/v1/tasks?status=next' \
  -H "Authorization: Bearer $MINDWTR_API_TOKEN" | jq .
```

## Security Rules — STRICT

1. **Read-only by default.** Never call a write endpoint (`POST`/`PATCH`) unless the user explicitly says to create, edit, or complete a task/project/area.
2. **NEVER delete anything.** `DELETE /tasks/:id`, `DELETE /projects/:id`, `DELETE /areas/:id` are FORBIDDEN in all cases — use `archive` instead if the user wants something out of the way.
3. **Always confirm writes.** Before calling any write endpoint, summarize what you're about to do and ask for confirmation.
4. **Preserve existing data.** When `PATCH`-ing a task, always include existing field values unless the user explicitly says to change them (partial patches that omit a field may clear it — check the API docs' patch semantics before assuming otherwise).

## Workflows

### 1) Get tasks for a specific area

1. `GET /areas` to find the area
2. `GET /projects` and filter client-side by `areaId`
3. For each project, `GET /tasks?projectId=<uuid>&status=next`

### 2) Quick capture a new task (write)

Only when the user explicitly asks:

```bash
curl -s -X POST 'https://gtd.gurungsujal.com.np/v1/tasks' \
  -H "Authorization: Bearer $MINDWTR_API_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"title":"Review Q3 budget +Finance /due:Friday #work @computer"}'
```

### 3) Update task description with AI findings (write)

Only when the user explicitly asks. Get the full task first (`GET /tasks/:id`) so the patch preserves existing fields, then:

```bash
curl -s -X PATCH 'https://gtd.gurungsujal.com.np/v1/tasks/<uuid>' \
  -H "Authorization: Bearer $MINDWTR_API_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"description":"Research summary:\n- Key finding 1\n- Key finding 2"}'
```

### 4) Weekly review

1. `GET /tasks?status=waiting` and `GET /tasks?status=someday` to find stalled items
2. Group by project
3. Summarize what's blocked or needs attention
4. Only update `reviewAt` or status if the user asks

### 5) Inbox triage (write)

Only when user asks:

1. `GET /tasks?status=inbox&sortBy=createdAt&sortOrder=desc`
2. For each task, classify status (`next`, `waiting`, `reference`, etc.) and add project/contexts/tags
3. Present the plan before executing

## Environment Variables

| Var | Value | Purpose |
|-----|-------|---------|
| `MINDWTR_API_TOKEN` | (bearer token) | Auth for every request to `gtd.gurungsujal.com.np` |

## References

Official docs (always up to date):

| Doc | URL | Use case |
|-----|-----|----------|
| Cloud API | `https://docs.mindwtr.app/developers/cloud-api` | REST API reference — endpoints, auth, request/response shapes |
| Cloud Deployment | `https://docs.mindwtr.app/data-sync/cloud-deployment` | Self-host setup, env vars, backup/restore (already done on the VPS — see `setup.md` in the VPS vault) |

Check the Cloud API doc before assuming a field name or endpoint shape that isn't already confirmed in this skill (e.g. project creation body, checklist fields) — it's been sparse on some details in the past, so verify rather than guess.

## Data Storage

- **Primary store:** the `mindwtr-cloud` container's data, persisted on the VPS at `/opt/mindwtr-cloud/data`. Always use the REST API to read/write — don't touch that path directly.

## Notes

- Task statuses: `inbox`, `next`, `waiting`, `someday`, `reference`, `done`, `archived`
- Project statuses: `active`, `someday`, `waiting`, `archived`
- Use `@context` for GTD contexts (e.g., `@computer`, `@phone`, `@errands`)
- Use `#tag` for GTD tags (e.g., `#work`, `#personal`, `#finance`)
- Tasks and projects may have descriptions, due dates, and notes
- **Checklists / sub-items on a task:** the REST API's checklist field isn't clearly documented — don't guess a JSON shape for it. Instead, write checklist/sub-task items as basic markdown todo syntax inside the task's `description` field (e.g. `- [ ] item one` / `- [x] done item`). This renders and is editable in the app, and doesn't depend on an unconfirmed API contract.
