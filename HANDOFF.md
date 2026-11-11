# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 85 · **Checks:** green · **Git:** `main`, pushed to `origin` (github.com/drftware/storage).

## State
- **L-07c done (D-097): banging.** Kept, a Bang button comes up in the dark (`CaughtView`); each
  press is `Remotes.Bang`, and `KeptPlayers` bangs your door through `Doors:move` (the trapped
  keeper's thud, shake and hearing, 70 studs along the halls), at most one per 0.4 s. The floor's
  model carries each bang (`Kept.BangsAttribute`): friends see a blue mark with your name over the
  door through walls (`BangMarks`) and a ringing dot on the corner map; a kept friend's own map
  dot is hidden. `UnderDoor` draws the hall light's warm line under your door while it's lit.
- **Session 85 was planning only:** the owner set the order of the next 15 tickets, through the
  first run with friends (ROADMAP's "The order from here"). L-08 is split into five, and L-15 to
  L-18 and L-09a are new. L-07d's full spec now lives in its ROADMAP entry.
- **Owner, Nov 10:** the code is on GitHub (`origin`). The owner saves the place every session and
  tests as they go, so don't add save reminders to `OWNER.md`.

## Next task: L-14e The blanket and glow sticks out of the deal
The cut tools (D-091) still come out of the deal's bag, and `Deals` lays nothing for a tool
that isn't built, so about one tool unit in five opens empty. Taking them out makes every
tool deal a real tool.
1. Owner test results first, if pasted.
2. `src/shared/Deal.luau`: take `MovingBlanket` and `GlowSticks` out of the `Tool` type,
   `Deal.Tools` and `Deal.Bag`. Floors 1 and 2 still deal the saw first.
3. Fix what counted on them: `tests/deal.spec.luau`, `tests/carry.spec.luau` (reads the bag)
   and `scripts/floor-deal.luau`.
4. Leave `Deals`' "not built yet" path (`src/server/Deals.luau` near line 141) as a guard, but
   it should no longer fire on any floor.
5. Find a seed again with a Mannequin awake on floor 1 for L-07d's Studio check (seed 7's 157
   moves with the reshuffle), and write it into L-07d's ROADMAP entry.
**Acceptance:** checks green; `lune run scripts/floor-deal` over a few seeds and floors 1 to 10
deals no blanket or glow sticks; in Studio, opening a dozen units on floor 1 prints no "not built
yet"; Output clean.
**Read first:** ROADMAP L-14e; D-091; `src/shared/Deal.luau`; `tests/deal.spec.luau`;
`src/server/Deals.luau` (lines 120 to 150); `scripts/floor-deal.luau`.

## Queue (the next run's order, from ROADMAP)
1. L-07d Cut free (its spec is in ROADMAP), then L-07e the padlock (a warning before it locks).
2. L-06c1 a walk that frightens, L-06c2 the catch as a jump scare.
3. L-08a the ride, L-08b the next floor, L-08c left behind, L-08d the climb ends (the Missing
   board, "Again", a stand-in top at floor 3), L-08e the start (a countdown once all are in).
4. L-15 keepers hear the keypad, dropped tools, the saw, crawls, the ladder and drop-ins.
5. L-16a and L-16b, the fix pass before friends play (the old Queue's bugs and checks, now
   listed in ROADMAP).
6. L-17 every button on a phone at once; L-18 the art saved with the code (optional).
7. L-09a the first run with friends, floors 1 to 3. L-14b2d only if the owner asks.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
