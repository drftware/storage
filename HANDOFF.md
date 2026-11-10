# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 77 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-14b1 done (D-088): bubble wrap's art.** Its precedent is Minecraft's tripwire. A roll of
  large-bubble wrap on a cardboard core, taped shut (`Props.Tools.BubbleWrap`, its `Catalog`
  row), and the sheet it unrolls (`Props.BubbleSheet`, its own template), from `art/bubblewrap/`.
  One lies in the test hall beyond the horn. Picked up, held and dropped in Studio at desktop
  size; Output clean. No `verb` yet: L-14b2 adds Lay. Phone, friend, bubbles, sound: `OWNER.md`.
- **Owner calls (D-089):** a corner minimap; the blanket and glow sticks parked; the Moth out,
  and no other monster built until the roster's rework (`OWNER.md`). "Keepers" isn't their name.

## Next task: L-14b2 Laying the bubble wrap, and the pops
The moment: you lay a sheet across the hall behind you, and seconds later, round the corner, it
pops: something is coming, and every keeper on the floor heard it too.
1. Owner test results first, if pasted. Too big for a session? Split it (laying; the pops).
2. Lay: add `verb = "Lay"` to `Catalog.BubbleWrap`. On `Slots.used` (as `Horns` takes the horn),
   the server checks you're on a hall floor (not in a unit, not on the tops, not in the car),
   lays a `Props.BubbleSheet` clone across the hall at your feet (`Specs/BubbleWrap.Sheet`,
   along the hall piece's axis from `Floor`), and takes the roll from your slot (default: one
   sheet a roll; the GDD gives no count, so add it to `OWNER.md`).
3. The pop: a pure `Wrap` (`tests/wrap.spec.luau`) says when a step crosses a sheet; the server
   checks players' and keepers' feet each step. A crossing pops it, loud (measure Pro Sound
   Effects' pops, docs/STUDIO.md), and the sheet shows it; keepers hear it as a door: `Keepers`
   gains a general `hear(at, reach)` beside `hearHorn`. Friends pop it too. Default: a popped
   sheet stays, flat and silent (`OWNER.md`).
4. Every action answers: your view brings the roll out and down as you lay it (the row's `use`),
   an unrolling crinkle, the sheet unrolling across the floor rather than appearing.
**Acceptance:** checks green; in Studio, lay a sheet in the test hall, cross it: the pop plays,
a keeper on the floor comes to it; a friend's crossing (a second player or a stand-in) pops it
too; Output clean.
**Read first:** ROADMAP L-14b2; D-087 (the horn's press, the pattern); D-088;
`src/server/Horns.luau`; `src/shared/Tools/Horn.luau`; `Keepers:hearHorn` in
`src/server/Keepers.luau`.

## Queue (the next run's order, from ROADMAP)
1. L-14b2 (bubble wrap); D-064, D-068 to D-089. Then L-07 (takes `Keepers.caught`), L-08, L-10
   (the corner minimap; the owner may move it up), L-09. L-14c and L-14d are parked.
2. **Check, small:** caught (moved to the lobby), the MCP's Client couldn't move the character
   54 s on (CFrame or `MoveTo`); a Server pivot could. Can a real player walk after a catch?
   Caught crawling or on the ladder, `CrawlView`/`LadderView` may keep holding PlatformStand.
   And a keeper that chased you to the lobby catches you there again every 2 s (L-07's to fix).
3. **Check, small:** a press made the moment you arrive reaches the server while it still sees you
   a few studs back (D-085). Saws, Ladders (Lean, Climb, Drop down) and a door's Cut and Lock
   check where you stand: allow for it as `Crawling.counts` does if one drops. And any server
   check of where a player faces sees the turn 0.4 s late (D-084).
4. **Checks on the tops, small:** Climb or Drop down lying behind a sawn hole slides you across
   it; a friend's drop-in lands 0.2 under the floor; crawlers should be refused a door's buttons
   and the ladder (`Ladders:crawling`). A horn blown up there is heard from the unit under you.
5. **Bugs, small:** FlashlightView's `motor()` takes only `Motor6D` (shoulders are
   `AnimationConstraint`s; KneelView's `joint()` and HornView's take both), so a friend's torch
   arm never raises; DoorSounds' first slam lands up to 0.35 s late (`SoundPrimer.prime`).
6. **Check:** G is a door's Slam and a tool's Drop: which wins at an open door? A left click
   blows a horn even while clicking the slots' bar. Output's six "rbxassetid://203785492 ...
   Asset type does not match" a Play: the id is in none of our code, templates or services.
7. Keepers should hear the keypad, a dropped tool, the saw, a crawl, the ladder and a drop in
   (D-059, D-066): L-14b2's general sound on `Keepers` is the place. **Later:** they can't see
   into the car, nor between tops and halls (OWNER.md).
8. **Small:** a trapped keeper's every blow prints (about 28 a trap); a keeper stopped against a
   wall may put its hand through it; after an MCP Peek a door ignores presses (docs/STUDIO.md).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
