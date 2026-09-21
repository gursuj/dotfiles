# Writing Preferences (public-facing text: comments, tickets, emails)

Derived from contrasting an AI-drafted bug report comment against my actual edit
(WordPress trac ticket, 2026-09-22). Scope: comments/tickets/emails meant for someone
else to read — not code, not internal notes.

## Cut

- Throat-clearing preambles. No "Quick note before the results:" — start with the fact.
- Redundant emphasis. If "No NS_ERROR_FAILURE" is said, don't also add "No console errors
  at all" — one confirmation is enough.
- Meta-commentary that explains why evidence should be believed (e.g. "so this isn't a
  'the code path never ran' false negative"). State the fact, let it stand.
- Verification-method padding. "Checked manually and again via WebDriver BiDi, same
  result both times" — cut unless the redundant check itself is the point being made.

## Verify before stating

- Don't assert something is "presumably fixed by now" — check the actual bug status and
  say what it is ("was marked as fixed").
- Don't editorialize about *why* something changed (e.g. guessing WP swaps in a block
  equivalent automatically) unless verified. Either confirm it or drop the claim.

## Tone

- Soften decisive verdicts on other people's tickets. "I think this can be closed" over
  "I'd close this as worksforme" — the latter reads as presumptuous when it's not my
  ticket to close.
- Plain word choice over dev shorthand in prose meant for non-dev or mixed readers:
  "wp-cli and database queries" not "wp-cli/DB".

## Structure

- Break long compound sentences into two. A parenthetical aside explaining *why* a step
  was taken reads better as its own short sentence than as a `(...)` tucked into a longer
  one.

## Open question

Is "no fluff, no filler, direct" (WPC/CLAUDE.md tone) the same target as "make it read
less AI-generated"? Mostly yes, but the AI-generated tell here wasn't fluff-as-verbosity —
it was overconfidence (unverified claims stated as fact) and over-justification
(explaining why evidence counts, instead of just giving it). Worth keeping as a distinct
axis when merging, not folding straight into the terseness rule.
