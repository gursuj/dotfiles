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

**Single site** — have them open the site's wp-admin **Plugins** page and paste this into the browser console:

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

Note: WordPress only renders the "latest version" text for plugins that already have an update flagged — plugins showing no update won't have a `latestVersion` from this alone. That's fine for update-safety triage since those aren't the ones in question. Have them copy the resulting array (right-click the console output → Copy object, or `copy(...)` wrapped around the expression) and paste it back.

**Multiple sites via ManageWP** — ManageWP's dashboard already shows available plugin/theme/core updates across every managed site in one place, so there's no need for the console snippet per site. Ask the user to pull the plugin + current + available version list straight from that dashboard view for the sites in scope. If they want a per-site breakdown outside ManageWP (e.g. a site not yet added to it), fall back to the single-site snippet above for that one.

Either way, end this step with a list of `{ plugin name, current version, latest version }` per site.

---

## Step 1: Vulnerability check (do this first — it can override everything else)

For every plugin where the *current* (not target) version has a known vulnerability, that forces an update regardless of what Steps 2–4 find. Check at least two of:

- WPScan vulnerability database
- Wordfence vulnerability feed
- Patchstack database

Note severity (critical/high/medium/low) and whether it's confirmed exploited in the wild — that distinction drives the urgency tier in Step 5.

---

## Step 2: Changelog diff across every intervening version

Don't just read the target version's changelog — read every version between current and target. A breaking change three versions back still hits the site the moment it jumps straight to latest.

Look for, per version:
- "Requires PHP X+" bumps
- Removed features, removed hooks/filters, renamed functions
- Database schema changes / migrations
- Major version jumps (often signal breaking changes even without explicit notes)

Source: the plugin's own changelog tab on wordpress.org (`https://wordpress.org/plugins/[slug]/#developers`), or the plugin's changelog.txt/readme.txt if self-hosted or premium.

---

## Step 3: Real-world regression reports

Changelogs under-report breakage — plenty of regressions never make it into official notes. Search, scoped to roughly the last 60 days relative to the target version's release:

- WordPress.org support forum for the plugin (`https://wordpress.org/support/plugin/[slug]/`)
- GitHub issues, if the plugin is open source and has a public repo
- Reddit (r/Wordpress, r/ProWordPress) — search `"[plugin name]" [version] reddit broke` or `"[plugin name]" update issue reddit` — people often post about a bad update here before it's reflected anywhere official

Flag anything describing: white screen / fatal error after update, conflicts with specific page builders or caching plugins, data loss, or a since-yanked release.

---

## Step 4: Compatibility surface (site-specific — ask, don't assume)

This is the part that can't be generalised from the plugin's own history. Ask the user (or infer from the plugin list already gathered) what else is active on the site:

- Page builder (Elementor, Divi, Bricks, etc.)
- Caching / performance plugin
- SEO plugin
- Any custom code or must-use plugins known to hook into this plugin

Cross-reference known conflicts from Step 3's search results against this specific stack. A regression report that only affects Elementor users is irrelevant to a site running Bricks, and shouldn't inflate that site's risk tier.

---

## Step 5: Output — severity-tiered recommendation

For each plugin, give one of:

- **Update now** — active exploit or critical CVE on the current version
- **Update this week** — patched vulnerability exists, not yet seen exploited, or a high-severity issue with no urgency signal
- **Update, but test on staging first** — breaking changes or regressions surfaced in Steps 2–3 that could hit this site's specific stack
- **Hold** — known regression in the target version with no fix yet, or the update requires a PHP/WP core bump the site can't currently support

If the user only wants the bare minimum (security-only) update pass, filter the output to plugins in the "update now" / "update this week" tiers and explicitly list which plugins were left out and why (e.g. "no known vulnerability, feature update only") — never silently drop plugins from the list without saying so.

---

## Notes on scope

- This skill decides *what's safe to update*, not how to deploy it. For pushing the update itself, use WP-CLI (`wp-wpcli-and-ops` skill) for a single site, or ManageWP's bulk update for many.
- No persistent cache of plugin safety verdicts across sessions — this data goes stale within days of a new release, and a shared "looks safe" verdict reused across client sites is exactly how one bad call propagates. If checking many sites that share plugins in a single run, it's fine to reuse a lookup already done earlier in that same session — just don't carry it into a future session.
