# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 78 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-14b2a done (D-090): laying the bubble wrap.** Lay (HornView's round button, now every
  verb tool's) unrolls the whole roll into one sheet square across the hall at your toes
  (`Wrap.place`, `Wraps`); refused off a hall ("Lay it in a hall"). Every screen unrolls it
  (`WrapView`). Verified in Studio: placement and the unroll; the press untested (the MCP
  couldn't pick the roll up, docs/STUDIO.md). Crossing a sheet does nothing yet.
- **Owner calls (D-091):** bubbles softened (looks swapped in the open place, unsaved); blanket
  and glow sticks cut; the minimap shows friends (a Config switch) and comes next after this.

## Next task: L-14b2b The pops
The moment: you laid a sheet behind you; seconds later, round the corner, it pops: something is
coming, and every keeper on the floor heard it too.
1. Owner test results first, if pasted.
2. A failing test first: `Wrap.crosses(sheet frame, from, to)` in `tests/wrap.spec.luau`: a
   foot entering the sheet's rectangle (`Across` x `Deep`, a little slack), or a step passing
   clean over it, crosses; leaving it or walking along beside it doesn't.
3. Server (`Wraps`): keep each laid sheet (its frame, unpopped) and last positions; each step
   check living players' feet (root, down to the floor) and keepers' feet. A keeper's `at` is
   in its floor's coordinates: add a small read on `Keepers` (each keeper's world feet) rather
   than reaching into it. Only sheets on a floor with someone near need checking.
4. A crossing pops it once: stamp `Popped` (server clock) on the sheet; `Keepers` gains a
   general `hear(at, reach)` beside `hearHorn` (refactor `hearHorn` onto it), the pop's reach
   a door's open (110, D-069), in `Wrap`. Friends pop it too; so do you.
5. Every screen (`WrapView`): a loud burst of pops at the sheet (measure Pro Sound Effects'
   bubble wrap pops with AudioAnalyzer, docs/STUDIO.md), heard as far as keepers hear it; the
   sheet goes flat (its colour darkened a touch, or a flatter look); a small kick if it's under
   you. Default: a popped sheet stays, flat and silent (`OWNER.md`).
**Acceptance:** checks green; in Studio on the walked floor (seed 7), lay a sheet (or, if the
MCP can't pick up, lay one from the Server as `Wraps` does), walk the character over it: the pop
plays once, Output says a keeper heard it and comes; a stand-in friend (a second character or a
keeper's walk) pops another; Output clean.
**Read first:** ROADMAP L-14b2b; D-090; `Tools/Wrap.luau`; `server/Wraps.luau`; `Keepers:hearHorn`
and `gather` in `server/Keepers.luau`; `client/WrapView.luau`.

## Queue (the next run's order, from ROADMAP)
1. L-14b2b (the pops); D-064, D-068 to D-091. Then L-10 (the minimap), L-07 (takes
   `Keepers.caught`), L-08, L-09.
2. **Small, own session:** cut `MovingBlanket`, `GlowSticks` from `Deal.Tools`/`Deal.Bag` (D-091);
   it reshuffles every seed, so recheck the units `OWNER.md`'s steps name (seed 7, floors 1, 3).
3. **Check, small:** caught (moved to the lobby), the MCP's Client couldn't move the character
   54 s on; a Server pivot could. Can a real player walk after a catch? Caught crawling or on the
   ladder, `CrawlView`/`LadderView` may keep holding PlatformStand. A keeper that chased you to
   the lobby catches you there again every 2 s (L-07's to fix).
4. **Check, small:** a press made the moment you arrive reaches the server while it still sees you
   a few studs back (D-085): Saws, Ladders and a door's Cut and Lock check where you stand; allow
   for it as `Crawling.counts` does if one drops. Server facing is 0.4 s late (D-084).
5. **Checks on the tops, small:** Climb or Drop down lying behind a sawn hole slides you across
   it; a friend's drop-in lands 0.2 under the floor; crawlers should be refused a door's buttons
   and the ladder (`Ladders:crawling`). A horn blown up there is heard from the unit under you.
6. **Bugs, small:** FlashlightView's `motor()` takes only `Motor6D` (shoulders are
   `AnimationConstraint`s), so a friend's torch arm never raises; DoorSounds' first slam lands up
   to 0.35 s late (`SoundPrimer.prime`). HornView now carries every verb tool's button: rename it
   (`UseButton`) when a third tool needs it.
7. **Check:** G is a door's Slam and a tool's Drop: which wins at an open door? A left click
   blows a horn (or lays wrap) even while clicking the slots' bar. Output's "rbxassetid://
   203785492 ... Asset type does not match" on Play: in none of our code, templates or services.
8. Keepers should hear the keypad, a dropped tool, the saw, a crawl, the ladder and a drop in
   (D-059, D-066) through L-14b2b's `hear`. **Small:** a trapped keeper's every blow prints.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
