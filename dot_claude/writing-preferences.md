# Writing Preferences

Source of truth for public-facing writing: comments, tickets, emails, PR/issue
descriptions, proposals, client and formal comms. Not code, not internal notes,
not this terse-mode chat style.

Referenced from `~/.claude/CLAUDE.md` (Claude) and opencode's global
`instructions` config. Edit this file only — don't fork copies elsewhere.

## Voice & tone

- British/Australian English.
- Short sentences. No fluff, no corporate theatre.
- No em-dashes — use a full stop, colon, or line break instead.
- Frame in outcomes, not activities: not "we updated the CSS" but "the page
  loads 2 seconds faster, which should reduce bounce rate."
- Plain word choice over dev jargon in prose meant for non-dev or mixed
  readers: "wp-cli and database queries" not "wp-cli/DB"; "works as expected"
  not "happy path"; "no change to the normal case" not "idiomatic".

## Cut

- Throat-clearing preambles. No "Quick note before the results:" — start with
  the fact.
- Redundant emphasis. One confirmation is enough; don't restate the same point
  a second way.
- Meta-commentary that argues for its own credibility (e.g. "so this isn't a
  false negative"). State the fact and let it stand.
- Verification-method padding ("checked manually and again via X, same
  result") unless the redundant check itself is the point.
- False-contrast rhetorical filler — "this isn't X, it's Y", "a demonstrated
  pattern, not a guess". Reads as AI-generated marketing copy. State the claim
  plainly; give evidence directly instead of asserting "this is evidence."

## Verify before stating

- Don't assert something is "presumably fixed by now" — check the actual
  status and say what it is.
- Don't editorialise about *why* something changed unless verified. Confirm
  it or drop the claim.
- Acknowledge AI training-data limits when citing. Prefer primary sources
  (Reddit, WordPress.org, GitHub) over vendor marketing pages, and flag when
  a source is likely to omit caveats (e.g. vendor pricing pages on free-tier
  limits).

## Tone toward other people's work

- Soften decisive verdicts on other people's tickets/work: "I think this can
  be closed" over "I'd close this as worksforme" — the latter is presumptuous
  when it's not yours to close.
- Formal WPC comms: address Nirmal as "Hello Nirmal ji", not "Hey" — the "ji"
  suffix is standard at WPC for Nepali team members and conveys respect.

## Structure

- Break long compound sentences in two. A parenthetical aside explaining *why*
  a step was taken usually reads better as its own short sentence.
- Use "I" when describing personal experience or discovery — grounds the
  claim, adds credibility.
- Stack 3+ items vertically instead of running them into a sentence.
- Lead with the problem or observation, not the solution.
- Close with what you have now (evidence, notes, past work), not what needs
  building later.
- For incomplete ideas: say so plainly ("not fully fleshed out yet", "not sure
  on build or maintenance") — invites collaboration, isn't a weakness.

## Status/task summaries (emails, PR descriptions, updates for PMs/clients)

Plainer and more casual than default technical voice — read by non-technical
people, not just devs.

- Explain jargon inline, in the same sentence, rather than naming a term and
  moving on.
- Item structure: header + verdict on its own line, blank line, then the
  explanation as its own paragraph. Don't run verdict and explanation into one
  sentence.
- Lead with the verdict, then explain — especially for mixed results ("no
  clash, but fixed one other thing").
- No closing "Net: ..." wrap-up after a list that already states each item's
  outcome — end on the last point.
- Precise plain nouns over vague ones ("that subdomain" not "that link").
- Say a point once. Don't restate it at the end of the same paragraph.

## A distinct axis worth keeping separate

"No fluff, direct" (terseness) and "doesn't read AI-generated" are related but
not the same target. The AI tell caught in the trac-ticket edit wasn't
verbosity — it was overconfidence (unverified claims stated as fact) and
over-justification (arguing evidence should be believed, instead of just
giving it). Check for both, not just word count.
