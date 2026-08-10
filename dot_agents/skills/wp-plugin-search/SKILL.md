---
name: wp-plugin-search
description: |
  Research and recommend WordPress plugins using high-quality, trustworthy sources — no SEO listicles or plugin marketing fluff. Use whenever someone asks "what plugin should I use for X", "find a WP plugin for X", "recommend a plugin for X", "is [plugin] any good", "is [plugin] still maintained", "does [plugin] have security issues", or wants a plugin compared against alternatives. Research-only: gathers findings and gives a recommendation, does not write anything to a wiki or repo. Sister skill to the wp-curated-plugins-wiki project's `add-wp-plugin` skill, which reuses this research method before writing a wiki entry.
---

## Goal

Given a need (a feature, a problem, or a specific plugin name), find the best WordPress plugin recommendation using sources that reflect real-world usage — not sources optimised to rank for "best X plugin 2026".

Output a recommendation with reasoning, not just a list of names.

---

## Step 1: Clarify the need

If the user named a specific plugin ("is Wordfence still good?"), skip to Step 3 — this is a validation lookup, not a discovery search.

If the user described a problem or feature ("I need a form plugin", "what's good for SEO?"), make sure you know:
- The specific use case (contact form vs multi-step quiz vs payment form — "forms" alone is too broad)
- Any hard constraints: free only, must be GPL, must work with their page builder/theme, site scale (a plugin fine for a 5-page brochure site may not suit a high-traffic WooCommerce store)

Don't interrogate — infer what you can from context and ask only for what's genuinely load-bearing to the recommendation.

### Preference order

Unless the user's constraint overrides it, prefer in this order: **free > freemium > premium**. A free plugin that does 90% of the job usually beats a premium plugin doing 100%, unless the missing 10% is something the user actually needs — check for that before defaulting to free.

---

## Step 2: Find candidates

Start broad to identify 2-4 candidate plugins worth evaluating:

- WordPress.org plugin directory search (`https://wordpress.org/plugins/search/[term]/`) — filter mentally by active install count and last-updated date shown in results
- Community discussions (Reddit r/Wordpress, r/ProWordPress) for real practitioner opinions
- WordPress.org support forums for the candidate plugins — read actual user complaints, not marketing copy

Do not rely on "best WordPress plugins for X" blog posts to pick candidates — most are SEO content, often paid placements or affiliate-link farms, and don't reflect real usage or current quality.

### Always search recent discussions too, even for well-established plugins

Don't stop at identifying the long-standing, well-known name in a category — a plugin's reputation can be years out of date in both directions:

- **Newer plugins** may have emerged in the last year or two that aren't yet reflected in older "best of" knowledge or your own training data. Search for them explicitly.
- **Long-established plugins can undergo enshittification** — acquired by a PE-backed roll-up, monetisation pushed harder into the free tier, support quality drops, bloat creeps in, a new owner changes the direction. A plugin that was the obvious pick three years ago may not be today.

For every category (not just unfamiliar ones), run at least one search scoped to the last 1-2 years, e.g. `"[category] plugin" reddit 2025`, `"[old favourite]" reddit acquired OR bloat OR decline OR alternative`, or `best "[category]" plugin 2026`. Look specifically for:
- Threads recommending a newer alternative to the plugin you'd otherwise default to
- Complaints about a well-known plugin changing hands, getting worse, or pushing more upsells than it used to
- Recent acquisition news (WP Tavern, WordPress.org news, or community threads) for any candidate — ownership changes are a leading indicator of enshittification even before user sentiment catches up

---

## Step 3: Validate each candidate

For every candidate plugin, gather:

1. **WordPress.org plugin page** (`https://wordpress.org/plugins/[slug]/`) — active installs, star rating, last updated, "tested up to" WP version, open support threads (unresolved count is a signal)
2. **Vulnerability databases — check at least two, not just Wordfence.** Coverage differs between them; a plugin with no Wordfence entry sometimes has one elsewhere.
   - **Wordfence Intelligence** (`https://www.wordfence.com/threat-intel/vulnerabilities/wordpress-plugins/[slug]`)
   - **WPScan** (`https://wpscan.com/plugin/[slug]/`) — frequently has entries Wordfence doesn't, and vice versa
   - **Patchstack** (`https://patchstack.com/database`) — independent researcher network, often fastest to disclose
   - If a specific CVE number is already known, the **NVD** (nvd.nist.gov) has the authoritative record
   - For a second opinion on plugins the bigger vendors haven't flagged, **PluginVulnerabilities.com** (White Fir Design) is a smaller independent researcher worth a quick check, especially for anything that touches file uploads or file management

   Always check this, don't skip it because the plugin seems reputable. This applies to **every plugin named in the output**, not just the top recommendation — a plugin mentioned as "also worth a look" or "a newer alternative to try" gets the same check as the winner, or it doesn't get named. Only after checking at least two sources and finding nothing should you say "no entry found" — and even then, say so explicitly and note that this likely reflects low install count/researcher attention rather than a clean bill of health. Don't let silence in one database read as safety.

   **First confirm the plugin is actually on WordPress.org.** A "no CVE found" result means something different depending on distribution channel:
   - **On WordPress.org, low install count** — plausibly just hasn't drawn researcher attention yet. Say so, but it's a soft caveat.
   - **Marketplace-only (CodeCanyon, AppSumo) or sold directly from the vendor's own site, never listed on WordPress.org** — this is a harder caveat, not a softer version of the same one. These plugins sit largely outside the ecosystem Wordfence/WPScan/Patchstack actually monitor: no public SVN history, usually no independent bug tracker, often no formal disclosure process at all. "Nothing found" here doesn't mean low risk, it means the standard tools can't see this plugin either way. State this distinction explicitly rather than reporting both cases as the same flavour of "unverified" — and note that for a marketplace-only plugin, the vendor's own changelog/support history is the best available substitute signal, weak as that is.

   Also check whether the plugin was ever **closed/pulled from the WordPress.org directory** (visible on its SVN page or via a directory banner) — a plugin closed for a security issue and later reinstated is a meaningful data point even when no formal CVE exists for it.
3. **Official site / source repo** (GitHub/GitLab if public) — commit recency, open issue backlog, whether it's a solo maintainer or a company/team. Also check the plugin's own **readme.txt changelog** for quiet security fixes ("hardening", "security fix") that never got a formal CVE.
3a. **WP Hive** (`https://wphive.com/plugins/[slug]/`) — shows install-count *trend* over time rather than WP.org's static snapshot, plus PHP-version compatibility. A declining install trend alongside a recent ownership change is a strong combined enshittification signal (see Step 2).
4. **License** — free, freemium (what's gated), or premium-only. Note GPL compatibility.
4a. **For any plugin that reorganises files (media folders, file managers, bulk movers/renamers)**: confirm whether it uses virtual organisation (database-level, doesn't touch the filesystem) or physically moves/renames files on disk. Physical moves risk breaking permalinks, hardcoded paths, and CDN/cache references — this is a pass/fail check, not a nice-to-have, and should be stated explicitly in the recommendation rather than assumed.
5. **Authentic community sentiment** — Reddit threads, WordPress.org support forum complaints, X/Twitter mentions from real developers. Look for recurring complaints (e.g. "breaks after every major WP update", "support is unresponsive", "bloats the database") — a single one-off complaint isn't a pattern, several independent ones are.

### Sources to avoid

Don't base the recommendation on:
- "Best WordPress plugins for X in 2026" roundup articles — near-universally SEO content or affiliate-driven, rarely reflects hands-on use
- The plugin's own marketing/landing page for anything except feature claims (verify claims elsewhere)
- Sponsored comparison pages

These can be skimmed for feature-list awareness but should never be the deciding source.

---

## Step 4: Present the recommendation

Lead with the answer, then the reasoning:

- **Recommended**: [Plugin name] — one-line why
- **Status**: active installs, last updated, license, any CVEs found (state "none found" explicitly, don't just omit it)
- **Why it wins**: the specific reasons, tied to the user's stated constraint/use case
- **Alternatives considered**: other candidates and why they lost out (better for a different use case, security concern, stale maintenance, etc.) — don't silently omit alternatives the user might reasonably expect to see
- **Flags**: anything the user should know before installing — recent CVE even if patched, freemium paywall on a feature they'll likely need, unusually small support team relative to install base, recent ownership change, or a well-known plugin showing signs of enshittification (worth flagging even if it's still your pick)

If validating a single named plugin rather than comparing candidates, skip the "recommended/alternatives" framing and just report status + flags + a maintained/not-recommended verdict.

If you find a materially better alternative to what the user asked about, say so clearly — don't silently substitute it, but don't hide it either.
