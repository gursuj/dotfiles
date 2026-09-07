---
name: wp-plugin-update-check
description: |
  Decide whether it's safe to update WordPress plugins from their current version to latest, before actually running the update. Use whenever someone asks "is it safe to update [plugin]", "should I update these plugins", "check for plugin update issues", "any breaking changes in [plugin] latest version", "plugin update safety check", or pastes/describes a list of outdated plugins from a site (or multiple sites) wanting to know what's safe to push. Checks vulnerability feeds, changelogs across every intervening version (not just the target), community reports of regressions (support forums, GitHub, Reddit), and site-specific compatibility risk. Outputs a severity-tiered recommendation (update now / this week / test on staging first / hold), not just a yes/no. Does not perform the update itself — research and judgment only.
---

## Goal

Given one or more outdated WordPress plugins, decide what's actually safe to update and how urgently — without blindly trusting "latest is always best" or over-cautiously freezing everything.

Output a per-plugin, severity-tiered recommendation with reasoning, not a flat yes/no.

---

## Step 0: Get the plugin list

Ask the user which situation applies, since it changes how they pull the list:

**Single site** — have them open the site's wp-admin **Plugins** page and use the `wp-plugin-update-extractor.user.js` Tampermonkey script (in the shared `userscripts` folder). It adds two Tampermonkey menu commands:

- **📋 Copy plugin list (JSON)** — copies the extracted list straight to clipboard
- **💾 Export plugin list (JSON file)** — downloads it as `[sitename]-plugin-updates-[date].json`

It extracts **every installed plugin**, not just the ones flagged for update — reading each plugin row's own `.plugin-version-author-uri` element rather than only rows with an update notice. This matters for Step 1 below. They hand you back JSON shaped like:

```json
[{ "name": "...", "slug": "aryo-activity-log", "active": true, "current": "6.8.7", "updateAvailable": true, "new": "6.8.8" },
 { "name": "...", "slug": "...", "active": false, "current": "6.3.1", "updateAvailable": false, "new": null }]
```

When reading it in, treat `current` as `currentVersion` and `new` as `latestVersion` for the rest of this skill — same data, different key names. `updateAvailable: false` means WordPress itself isn't flagging an update for that plugin (not that none exists — see Step 1). If they paste a downloaded file's contents instead of clipboard text, that's the same format, just read it directly.

`slug` is the plugin's actual wp.org/vendor slug, read straight from the row's `data-slug` attribute — use it (not the display name) for every lookup in this skill. Display names are unreliable for matching against wp.org/vendor/CVE data (e.g. "Activity Log" as shown in wp-admin is really `aryo-activity-log`, not the differently-named plugin the display name suggests) — a slug mismatch is exactly how a plugin gets misidentified and researched against the wrong changelog/CVE history.

`active` is read straight from the row's own active/inactive class — always check it before assigning urgency. An inactive plugin isn't running, so a CVE on its current version isn't a live attack surface on this site right now; don't tier it as "update now" on vuln grounds alone (see Step 6). On network/plugins.php specifically, `active` means *network-activated*, not "active on every subsite" — a plugin can show inactive there while still being active on individual subsites, so say so rather than assuming inactive-everywhere.

If Tampermonkey or the script isn't set up on their machine, fall back to this console snippet pasted into the wp-admin Plugins page's browser console (note: this fallback only captures plugins that already have an update flagged, so it can't feed Step 1's cross-check):

```js
[...document.querySelectorAll('tr[data-plugin]')].map(row => {
  const name = row.querySelector('.plugin-title strong')?.textContent.trim();
  const versionText = row.querySelector('.plugin-version-author-uri')?.textContent || '';
  const currentVersion = versionText.match(/Version ([\d.]+)/)?.[1];
  const updateNotice = row.querySelector('.update-message');
  const latestVersion = updateNotice?.textContent.match(/version ([\d.]+)/i)?.[1];
  return { name, currentVersion, latestVersion: latestVersion || currentVersion };
});
```

Have them copy the resulting output (via the userscript's copy button, `copy(...)` wrapped around the console expression, or right-click → Copy object) and paste it back.

**Multiple sites via ManageWP** — ManageWP's dashboard already shows available plugin/theme/core updates across every managed site in one place, so there's no need for the console snippet per site. Ask the user to pull the plugin + current + available version list straight from that dashboard view for the sites in scope. If they want a per-site breakdown outside ManageWP (e.g. a site not yet added to it), fall back to the single-site snippet above for that one. Note: ManageWP, like WordPress core's own update check, can also be behind — Step 1's cross-check still applies.

Either way, end this step with a list of `{ plugin name, current version, latest version, update flagged by WP? }` per site.

---

## Step 1: Cross-check for unreported updates

WordPress's own update check (and ManageWP's) can be wrong — stale transients, a premium/self-hosted plugin that doesn't hook into the wp.org update API, or a vendor who released a fix out of band. Don't just trust `updateAvailable` from Step 0.

**On a large plugin list, do this in two passes to avoid burning research budget on plugins that are almost certainly fine:**

**Pass A — full research, no need to ask first.** Every plugin where `updateAvailable: true`. These already have a known update to investigate, so run the full Step 1 check plus Steps 2–5 against them straight away.

**Pass B — lightweight check first, deep-dive only on request.** Every plugin where `updateAvailable: false`. For these, do a *cheap* version-only lookup — no vuln scan, no changelog read, no regression search, just: "what does wp.org (or the vendor page) say the actual latest release is, right now, using `slug`?"

- `https://api.wordpress.org/plugins/info/1.2/?action=plugin_information&request[slug]=[slug]` for wp.org-hosted plugins
- the vendor's own changelog/pricing/download page for premium/self-hosted plugins

If that lightweight check turns up a newer version than the site's `current` (an unreported update), flag it and promote that plugin into full Steps 2–5 research, same as Pass A.

If the lightweight check confirms the plugin is genuinely current, stop there for that plugin — **don't** run the full vuln/changelog/regression research on it. Once all lightweight checks are done, tell the user how many `updateAvailable: false` plugins came back genuinely current vs. flagged as unreported, and ask whether they want full Steps 2–5 research run on the "genuinely current" ones anyway (there's still a small chance of an unpatched 0-day even on the latest version) or whether the lightweight version check is enough for those. Don't run the deeper research on them without asking — that's the expensive step this two-pass split exists to gate.

Don't silently skip the lightweight check itself for plugins that look current — the whole point is catching the ones a lazy trust-the-dashboard pass would miss. It's only the *expensive* follow-up research that's gated behind asking.

---

## Step 2: Vulnerability check (this and the unreported-update check above take priority — they can override everything else)

For every plugin where the *current* (not target) version has a known vulnerability, that forces an update regardless of what Steps 2–4 find. Check at least two of:

- WPScan vulnerability database
- Wordfence vulnerability feed
- Patchstack database

Note severity (critical/high/medium/low) and whether it's confirmed exploited in the wild — that distinction drives the urgency tier in Step 5.

---

## Step 3: Changelog diff across every intervening version

Don't just read the target version's changelog — read every version between current and target. A breaking change three versions back still hits the site the moment it jumps straight to latest.

Look for, per version:
- "Requires PHP X+" bumps
- Removed features, removed hooks/filters, renamed functions
- Database schema changes / migrations
- Major version jumps (often signal breaking changes even without explicit notes)

Source: the plugin's own changelog tab on wordpress.org (`https://wordpress.org/plugins/[slug]/#developers`), or the plugin's changelog.txt/readme.txt if self-hosted or premium.

---

## Step 4: Real-world regression reports

Changelogs under-report breakage — plenty of regressions never make it into official notes. Search, scoped to roughly the last 60 days relative to the target version's release:

- WordPress.org support forum for the plugin (`https://wordpress.org/support/plugin/[slug]/`)
- GitHub issues, if the plugin is open source and has a public repo
- Reddit (r/Wordpress, r/ProWordPress) — search `"[plugin name]" [version] reddit broke` or `"[plugin name]" update issue reddit` — people often post about a bad update here before it's reflected anywhere official

Flag anything describing: white screen / fatal error after update, conflicts with specific page builders or caching plugins, data loss, or a since-yanked release.

---

## Step 5: Compatibility surface (site-specific — ask, don't assume)

This is the part that can't be generalised from the plugin's own history. Ask the user (or infer from the plugin list already gathered) what else is active on the site:

- Page builder (Elementor, Divi, Bricks, etc.)
- Caching / performance plugin
- SEO plugin
- Any custom code or must-use plugins known to hook into this plugin

Cross-reference known conflicts from Step 4's search results against this specific stack. A regression report that only affects Elementor users is irrelevant to a site running Bricks, and shouldn't inflate that site's risk tier.

---

## Step 6: Output — severity-tiered recommendation

For each plugin, give one of:

- **Update now** — active exploit or critical CVE on the current version, **and the plugin is active** (or network-active/active-on-a-subsite)
- **Update this week** — patched vulnerability exists, not yet seen exploited, or a high-severity issue with no urgency signal
- **Update, but test on staging first** — breaking changes or regressions surfaced in Steps 3–4 that could hit this site's specific stack
- **Hold** — known regression in the target version with no fix yet, or the update requires a PHP/WP core bump the site can't currently support

If a plugin is **inactive**, downgrade whatever tier the vulnerability alone would suggest — a CVE on dormant code isn't an active risk. Say so plainly (e.g. "Critical CVE on current version, but plugin is inactive — no live exposure; update before reactivating, not urgent otherwise") rather than flagging it at the same severity as an active plugin with the same CVE. Breaking-change/regression findings (Steps 3–4) still apply as normal if the plugin ever gets reactivated or updated, though — inactive only changes urgency, not the underlying research.

If Step 1 caught an unreported update, say so plainly in that plugin's entry (e.g. "WordPress shows this as up to date, but vendor has actually shipped 3.94 — flagged separately") so the recommendation isn't mistaken for a dashboard-reported one.

If the user only wants the bare minimum (security-only) update pass, filter the output to plugins in the "update now" / "update this week" tiers and explicitly list which plugins were left out and why (e.g. "no known vulnerability, feature update only") — never silently drop plugins from the list without saying so.

After delivering the recommendation, ask whether they also want a **post-update QA checklist** — a per-plugin list of specific pages/actions to click through after pushing each update (e.g. "submit a test form entry", "load an Elementor page", "check the consent banner still appears"), scoped to whichever plugins they're actually planning to update. Don't produce this unasked — it's a distinct, sometimes lengthy deliverable, not an automatic part of the severity-tiered output.

---

## Notes on scope

- This skill decides *what's safe to update*, not how to deploy it. For pushing the update itself, use WP-CLI (`wp-wpcli-and-ops` skill) for a single site, or ManageWP's bulk update for many.
- No persistent cache of plugin safety verdicts across sessions — this data goes stale within days of a new release, and a shared "looks safe" verdict reused across client sites is exactly how one bad call propagates. If checking many sites that share plugins in a single run, it's fine to reuse a lookup already done earlier in that same session — just don't carry it into a future session.
