---
name: issue-reporter
description: |
  Help users find existing bug reports or file new ones for software issues. Use this skill whenever a user describes a bug, crash, error, unexpected behavior, or broken feature in any software — even if they haven't explicitly said "I want to report this." Triggers include: "I found a bug", "this isn't working", "is this a known issue", "where do I report X", "how do I file a bug", any description of reproducible wrong behavior, or when a user asks what they should do about a problem they're having with a tool. The skill searches issue trackers, forums, and GitHub with multiple query variations to find existing reports before suggesting a new one is filed.
---

## Goal

1. Find the right place to report the issue (GitHub, forums, etc.)
2. Thoroughly search for existing reports using many different search angles
3. If nothing found, ask the user to also search before assuming it's unreported
4. If still nothing, guide them through filing a clear, useful report

---

## Formatting Conventions

Backtick anything code-shaped (errors, commands, paths, versions, config keys). Fence multi-line content (stack traces, logs, the draft report body).

### Linking to source lines: use commit-pinned permalinks, not branch URLs

When a draft (or a search-results summary) points at specific lines of code — `blob/main/...#L42`, `blob/trunk/...#L210-L219` — GitHub only guarantees the `#L` line-highlight lands correctly if the URL is pinned to a commit SHA, not a branch name. A branch link (`blob/trunk/...`) still opens and still *has* a `#L210-L219` fragment, but as soon as the branch moves past that commit, the highlighted lines silently drift to whatever now sits at those line numbers — which may be unrelated code, or may not exist at all. A maintainer clicking it later sees the wrong thing with no indication anything moved.

Always convert to a permalink before putting a line-anchored link in a report:

1. Get the commit SHA the reference should be pinned to — almost always "the commit currently on the default branch" (i.e. what you actually read):
   ```bash
   gh api repos/{owner}/{repo}/commits/{branch} --jq '.sha'
   ```
   (`{branch}` = the repo's default branch — `main`, `trunk`, `master`, etc. — check `default_branch` from `gh api repos/{owner}/{repo}` if unsure.)
2. Build the URL with that SHA in place of the branch name:
   ```
   https://github.com/{owner}/{repo}/blob/{sha}/{path/to/file.php}#L{start}-L{end}
   ```
   Example: `https://github.com/johngodley/search-regex/blob/cdc29b726c97371763e1f44f2b67c91a798dc1fc/includes/api/route/class-source-route.php#L210-L219`

This is exactly what GitHub's own "Copy permalink" button does (press `y` on a blob view, or use the line-number dropdown → "Copy permalink") — it swaps the ref in the URL for the current commit SHA. Doing it via `gh api` gets the same result without a browser.

Do this for every line-anchored link in a filed report or reopen comment — not just the first one. Plain `.../blob/{owner-page}` links (no branch or line anchor, e.g. linking to a whole file or a forum thread) don't need this — the drift risk is specific to branch name + line-range combinations.

**Don't also paste the referenced code as a fenced snippet once it's a permalink.** A commit-pinned `#L`-anchored link already renders the exact lines, syntax-highlighted, when clicked — copying the same lines into a code block in the report body is pure duplication and something that can drift out of sync with the link if you edit the draft. Link to it, describe what it does and why it's wrong in prose, and let the permalink carry the code. Reserve fenced code blocks in the report for things that aren't already sitting in the repo at a citable line: the user's own repro script, a minimal standalone reproduction, actual error/log output, or a suggested diff/fix.

---

## Recommended Setup: gh CLI

This skill works noticeably better with the `gh` CLI installed and authenticated. It's what powers the `config.yml` redirect check in Phase 2, scoped issue/discussion search in Phase 3, and direct filing in Phase 5 — without it, everything falls back to slower web search and the user has to file manually through a browser link.

Minimum needed:

- **Classic PAT**: `repo` scope (works, but grants full read/write on every private repo the account can see — broader than this skill needs).
- **Fine-grained PAT** (preferred): scoped to the repos you care about, with **Contents: Read-only**, **Issues: Read-only**, **Pull requests: Read-only**, **Discussions: Read-only**. Covers Phases 1–4 (searching, checking `config.yml`, reading closed issues) fully read-only.

Optional, only if you want Phase 5 to file directly via `gh issue create` / `gh discussion create` instead of handing over a link:

- **Issues: Read and write**
- **Discussions: Read and write**

Without write scope, the skill still drafts the full report — it just gives the user the "Open issue" link to submit it themselves instead of filing it on their behalf.

---

## Phase 1: Clarify the Issue

Before searching, make sure you have enough to work with:

- **Software name** and version (if known)
- **What happened** vs **what was expected**
- **Exact error message** (if any — copy-paste is better than paraphrase)
- **Environment**: OS, relevant config, anything unusual about their setup
- **When it started**: always, or after a specific change/update?

If the user gave you most of this, proceed. Don't interrogate them over details you can infer. Ask only for what's genuinely missing.

### Auto-detect environment info before asking

If you're running in a terminal on the same machine as the software in question, try to detect environment details yourself before asking the user to go look them up. Only ask for whatever detection couldn't find or confirm.

- **OS + OS version**: usually already known from your own session environment (platform, OS version string) — use it directly, don't ask.
- **App version**:
  - CLI tools: try `<command> --version`, `<command> -v`, or `<command> version`
  - Windows desktop apps: check installed-apps registry (`Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*`, and the `WOW6432Node` equivalent), `winget list --id <id>`, or a version string in the app's own config/log directory
  - macOS: `mdls -name kMDItemVersion /Applications/<App>.app` or `defaults read /Applications/<App>.app/Contents/Info.plist CFBundleShortVersionString`
  - Linux: `dpkg -s <pkg>`, `flatpak info <id>`, `snap list <name>`, `pacman -Qi <pkg>`
  - Browser extensions: read the version field from the extension's `manifest.json` in the browser's profile folder
  - **WordPress plugins/themes**: grep the `Version:` header line directly out of the plugin's main PHP file (or the theme's `style.css`) — a single targeted grep, not a full file read. If WP-CLI is available, `wp plugin list --format=json` or `wp theme list --format=json` returns version *and* whether an update is available in one call, which is cheaper than grepping when you need to check several plugins at once.
  - If Phase 2 already found the project's GitHub repo, cross-check the detected version against the Releases page — flag it if it's out of date

**Keep detection cheap.** Auto-detection is only worth doing when it costs a single targeted read: one grep for a version header, one WP-CLI/`winget`/registry call, one `manifest.json` read. Don't recursively scan a plugins directory or read whole source files just to find a version string — if the targeted lookup fails, fall back to asking rather than searching harder for it.

- **Install channel**: infer from the install path or whichever package manager surfaced the version (`Program Files` vs `WindowsApps` vs user `AppData` vs Homebrew `Cellar` vs Flatpak vs Snap vs AUR)
- **The setting/config the bug is actually about**: if the software stores it in a locally readable file (dotfile, SQLite db, JSON/YAML config) and you can read it safely, check it directly rather than taking the user's description on faith — e.g. confirm a "default time" setting is really saved as the value they think it is

Always show what you detected and where it came from, so the user can correct it before it goes in the report — e.g. "Detected: v1.0.5 (via `winget list`), Windows 11 Pro (session environment)." If detection fails, or the software isn't running locally (mobile-only app, remote server, no CLI/API), fall back to asking. Never guess a version or OS — detect it, ask for it, or explicitly mark it unknown in the draft.

### Checking version against changelog before searching for reports

If the user is behind the latest version, check whether the gap has already been closed — no point drafting a report for something already fixed upstream.

- **Prefer the plugin/project's raw changelog data over its rendered changelog page.** Rendered changelog pages are often JS-driven (SPA/Vue) and return nothing useful to a page fetch. Look for the underlying data source instead — check the page's HTML for an inline script exposing a base data URL (e.g. a `baseURI`/`apiUrl` config object), then request `<baseURI>/<plugin-slug>.json` or similar directly. This is far cheaper than rendering the page and works when a plain fetch of the visible page returns empty.
- **Diff only the versions between the user's version and latest** — not the whole changelog history. Skim entries newest-first and stop once you've passed the user's installed version.
- **Read entries verbatim, don't summarize from a keyword grep alone** — a fix relevant to the report may not use the same words the user or you would pick (e.g. the user says "reorder resets," the changelog says "Relations. Improve items sort persistence"). Read the actual entry text for every version in range.
- If the changelog doesn't mention it, that's a real finding worth stating plainly ("checked every entry from 3.8.8.1 to 3.8.11.2 — no relations/ordering fix mentioned") before moving to Phase 3's report search.

---

## Phase 1.5: Check If It Already Exists in the Software

Before searching for bug reports or filing anything, check whether the issue can already be resolved by an existing setting, feature, or workflow in the software.

Search the product's documentation, changelog, and support forums for the capability the user described. If you find it:
- Tell them where to find it (exact setting name, menu path, or docs link)
- Don't proceed to Phase 2 unless there's still a genuine gap (e.g. the setting exists but is broken, or only partially covers their use case)

If you're unsure whether a feature exists, say so and suggest they check the docs too — don't assume it's missing just because you didn't find it quickly.

---

## Phase 2: Find the Issue Tracker

**First: check for an in-app reporting tool.** Many products have a built-in feedback or bug command that's faster and sends richer context than a manual report. Examples: `/feedback` or `/bug` in CLI tools, Help → Report Issue in desktop apps, in-app chat with a bug tag. If one exists, mention it as the easiest path alongside the manual tracker.

Then find the official issue tracker. Try in this order:

1. GitHub — search `[software name] github` and find the official repo (correct org, linked from docs/website). Check whether Issues are actually enabled on the repo — some projects use GitHub only for releases and direct bugs to a forum.
2. GitLab, Jira, Bugzilla, Linear — some projects host their own
3. Discourse forum, Reddit community, Discord server — for projects without a formal tracker
4. The project's own documentation or website — usually links to where bugs go

Note the platform found. For GitHub, record `owner/repo` — you'll need it for scoped search later.

### GitHub — check config.yml for redirects

Once you have the repo, fetch the issue template config before assuming Issues is the right destination:

```bash
gh api repos/{owner}/{repo}/contents/.github/ISSUE_TEMPLATE/config.yml --jq '.content' | base64 -d
```

If the file exists, parse it for two things:

1. **`blank_issues_enabled: false`** — the "Open a blank issue" option is hidden. All reporters must use a template or a contact link.
2. **`contact_links`** — each entry has a `name`, `url`, and `about`. The URL tells you where that report type should go. Common destinations:

   | URL pattern | What it means |
   |---|---|
   | `.../discussions` or `.../discussions/categories/...` | Feature requests / ideas go to GitHub Discussions |
   | `linear.app/...`, `jira.atlassian.net/...`, `youtrack...` | External issue tracker — file there, not in GitHub Issues |
   | `mailto:security@...` or `.../security/advisories/new` | Vuln reports go private |
   | `forum.example.com`, `discourse...` | Support questions go to a hosted forum |
   | `discord.gg/...`, `slack...` | Community support only |
   | `docs.example.com/...` | "Check here first" — not a filing destination |

To detect whether a feature request belongs in Issues or Discussions: look for any `contact_links` entry whose `name` matches "feature", "idea", "request", or "enhancement" (case-insensitive) and whose `url` contains `/discussions`. If found — and there is no `feature_request.yml` template in the template list — features go to Discussions, not Issues.

If `config.yml` does not exist, the repo uses GitHub Issues for everything (or has no templates at all).

---

## Phase 3: Search for Existing Reports

This is the most important phase, and the most common place to fail. The same bug can be described in dozens of different ways. Don't rely on two or three queries — use at least **6 distinct search angles** and work through all of them before concluding nothing exists.

### Why variation matters

A user reporting "VS Code freezes when I paste code" and another reporting "editor becomes unresponsive after clipboard paste in large files" are describing the same bug. A search for one phrase will not find the other. Your job is to cover enough of the conceptual space that you'd catch either.

### The 8 search angles — work through all of them

1. **Exact error text** — if there's an error message, search it verbatim (in quotes). Error strings are often unique enough to find duplicates even when the description differs.

2. **Symptom + feature area** — pair the symptom with the feature where it happens: "PDF export crash", "autocomplete freezes", "dark mode flicker"

3. **Plain English symptom** — strip the software name and any jargon, describe it how anyone would: "freezes when pasting large text", "crash on startup"

4. **Technical rephrasing** — if your previous queries used plain language, go more technical (or vice versa). Try the subsystem name, internal component, or relevant protocol/format: "clipboard paste OOM", "LSP timeout on large files"

5. **Expected vs actual** — frame as what should happen vs what does: "formatter should run on save", "autosave not triggering", "selection not preserved after undo"

6. **Community shorthand** — think about how this project's community talks. Abbreviations, internal names, release codenames: "HMR broken", "tree-shaking regression", "v3 migration crash"

7. **Related component or dependency** — the issue might be filed under a different repo or a dependency: if it's a plugin, search the host app; if it uses a library, search that library's issues too

8. **Recency framing** — if it appeared after an update: "regression", "broke in X.Y", "after update", "since version"

### Always quote the product name

Wrap the software or plugin name in quotes in every query — `"forminator"`, `"VS Code"`, `"WooCommerce"`. Aggregator sites like WordPress.org, GitHub search, and Google serve results for many products; without quotes, a search for `forminator publish changes` can return threads about completely unrelated plugins that share the words "publish" or "changes". Quoting the name forces exact-match and keeps results scoped to the right product.

### WordPress.org plugin forums — use Google, not the native search

WordPress.org's own forum search engine is poor — it returns far fewer results than Google and misses obvious matches. **Never search the wordpress.org forum directly, and never hand the user a `wordpress.org/support/plugin/...?query=` link.** Always search via Google (or another external engine) instead.

Build the query with the plugin path **glued into `site:`** (no space) so Google scopes to that plugin's forum, and quote the plugin name:

```
site:wordpress.org/support/plugin/elementor "elementor" global classes missing after update
```

Do **not** split the path into a separate term (`site:wordpress.org /support/plugin/elementor ...`) — that form does not reliably return forum posts. Keep the path attached to `site:`.

If a scoped query returns nothing, that's usually a real signal the issue isn't reported there — but confirm it's not just too niche by loosening the terms (drop the symptom words, keep only `site:wordpress.org/support/plugin/[slug] "[plugin-name]"`) to check the scope itself still returns posts.

### GitHub-specific search tips

- Search **both Issues and Discussions** — many projects move support questions to Discussions
- Include closed issues: `is:issue <terms>` catches fixed bugs, won't-fix decisions, and duplicates that were closed
- Scoped search: `repo:owner/repo <terms>` to limit noise
- Unscoped search on github.com sometimes finds issues in related repos (forks, dependencies)

### Present findings clearly

List every query you tried, whether it returned results, and direct links to the top 2–3 most relevant hits per query. Don't bury the results — lead with what you found. If you find a likely duplicate, say so confidently and link it.

---

## Phase 4: Ask the User to Search Too

Always do this step — even if you found related issues. Your searches won't cover every way someone might phrase the same problem, and the user may recognise a match you dismissed.

**Give them links, not just instructions.** Don't just say "try searching here with these terms" — construct the actual search URLs and present them as clickable links. The user should be able to scan the results in one click, not have to build the query themselves.

For WordPress.org plugin forums, **do not link the native forum search** (`wordpress.org/support/plugin/[slug]/?query=...`) — it barely works, per the Phase 3 rule above. Build a **Google** search link instead, with the plugin path glued into `site:` (no space):
`https://www.google.com/search?q=site%3Awordpress.org%2Fsupport%2Fplugin%2F[slug]+%22[plugin-name]%22+your+terms`

For GitHub, link directly to a filtered search:
`https://github.com/[owner]/[repo]/issues?q=your+terms`

**If you found nothing:** share 2–3 ready-to-click search links and ask them to scan before filing:

> "I tried [N] search variations and came up empty. Before we file a new one, could you scan these searches too? A different pair of eyes sometimes finds what I missed:
> - [Search: publish changes]([direct URL])
> - [Search: auto-save draft]([direct URL])
> - [Search: unpublished warning]([direct URL])
> If you find something, paste the URL."

**If you found related but not-exact matches:** share what you found plus extra search links to check:

> "I found [N] related issues but none are an exact match. Worth scanning these too before we file: [links]. If you spot a closer match, paste the URL."

**If the user finds an existing report:**
- Note what worked: "Good find — '[their terms]' was a better angle. I'll keep that in mind."
- Link them to the report and ask if they want to add a comment with their reproduction details (a +1 with fresh repro steps helps get a fix prioritised)

**If the user confirms nothing exists**, proceed to Phase 5.

---

## Phase 5: File the Report

**Always get explicit go-ahead before actually filing anything** — creating an issue, discussion, or PR is visible to the project maintainers and not something to quietly undo. Present the finished draft (title + body + destination) and wait for the user to say "yes / go ahead / create it" before running `gh issue create`, `gh discussion create`, or equivalent. Drafting, refining, and even fetching the exact URL/template are fine to do unprompted — only the actual creation call requires a clear go-ahead each time. One approval covers the single issue being discussed, not a standing license to file future ones without asking again.

### For GitHub repos

**If `config.yml` redirected feature requests to Discussions**, do not use `gh issue create`. File a discussion instead:

```bash
gh discussion create --repo owner/repo --title "..." --body "..." --category "Ideas"
```

List available categories first to find the right one:

```bash
gh api graphql -f query='{ repository(owner:"owner",name:"repo") { discussionCategories(first:20) { nodes { name slug } } } }'
```

If the gh CLI does not support `discussion create` in the installed version, give the user the direct URL: `https://github.com/[owner]/[repo]/discussions/new?category=ideas` (adjust the category slug to match).

For any other `contact_links` redirect (external tracker, forum, Discord): give the user the exact URL from the `contact_links` entry and the `about` text as filing guidance.

---

**If Issues is the right destination**, first check whether the repo has issue templates by fetching `https://github.com/[owner]/[repo]/issues/new/choose`. If templates exist, pick the right one — it matters:

- **Crash / runtime error / unexpected behaviour** → use "Bug Report" or "Integration" template
- **Wrong formatting output, bad indentation, style issue** → use "Formatting" template (where it exists)
- **Missing feature** → use "Feature Request" template

Don't default to the Formatting template for crashes — it's a common mistake that sends the report to the wrong triage queue. If in doubt, use the Bug/Integration template.

If there are no templates, use this structure:

```
**Title**: Short, specific — describes the symptom, not "it's broken"
Example: "Editor freezes for ~5s when pasting >5000 chars from clipboard on Windows"

**Describe the bug**
What actually happens.

**Expected behavior**
What should have happened.

**Steps to reproduce**
1. Step one
2. Step two
3. ...
Minimal and specific. If you can reproduce it consistently, say so.

**Environment**
- OS and version
- Software version
- Relevant config, plugins, settings

**Error output / logs**
Paste exact error text. Don't paraphrase.
```

After presenting the draft, always include a direct link to open the new issue form — the user should be able to click straight through without hunting for it:

- GitHub without templates: `https://github.com/[owner]/[repo]/issues/new`
- GitHub with templates: `https://github.com/[owner]/[repo]/issues/new/choose`

Present it plainly at the end of the draft, e.g. "**Open issue:** [github.com/owner/repo/issues/new](URL)"

**Present the draft body inside a ` ```markdown ` fence** so backticks and formatting characters are preserved as literals for copying. Commentary (title, filing link) goes outside the fence.

**Adapt to the user's writing style.** Before drafting, check your memory system for the user's writing-style / voice preferences (e.g. a `user_writing_style` memory) and apply them — tone, sentence length, framing. Do this lookup every time, even if the user hasn't mentioned it — don't wait for a reason to check. A draft that sounds like them will need less editing before they post it.

**Match formatting to the platform.** GitHub issues expect markdown (headers, bullets, code blocks). Forum posts (WPMU DEV, WordPress.org, Discourse) are prose — use inline labels ("Auto-publish toggle: ...") not bold headers, and let ideas flow as short paragraphs rather than structured sections.

### For other platforms (forums, Discourse, Discord)

Give step-by-step instructions:
1. Exact URL to post at
2. Which category or channel
3. What to include (same structure as above, adapted to the platform's norms)

---

## Reminders

- **Closed issues are valuable.** A bug reported, fixed, and closed last year might be the exact same root cause — or the fix might have regressed. Always include closed issues in your search.
- **The right repo isn't always obvious.** A VS Code extension bug might belong in the extension's repo, not Microsoft/vscode. A React crash might be in a bundler, not facebook/react. Check before assuming.
- **Version matters.** If the user is on an old version, the issue might be fixed upstream. Check.
- **Don't over-ask.** If the user gave you most of what you need, proceed and note any assumptions. Only block on truly missing info.
