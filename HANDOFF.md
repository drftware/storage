# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 80 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-14b2c done (D-093), from the owner's test:** the pops were silent on screens because
  `WrapView` dropped a sheet that reached the screen before its part; laid sheets now stream
  `Atomic` and `WrapView` waits for a late part. A sheet now pops three times (`Wrap.ready`,
  `Wrap.worn`, Lune-tested), not twice within 0.8 s, each pop at its own pitch and a step
  flatter, greyer and clearer, then lies spent and silent.
- **Verified in Studio** (test hall): lay, four walks across, Output "1 of 3" to "3 of 3" and
  no fourth; three sounds playing on the screen; the sheet worn to 0.3 high, 0.35 clear, grey.
  The MCP can pick the roll up now (docs/STUDIO.md). L-14b2d (a baked burst look) waits on OWNER.

## Next task: L-10 The minimap
The moment: deep in the building, a chase behind you, a glance at the corner map shows the way
back to the lobby and the gate; the halls you've walked are drawn, the rest is dark.
1. Owner test results first, if pasted (if the spent sheet doesn't read as popped, do L-14b2d
   first instead: ROADMAP).
2. Brix first: check `docs/FRAMEWORK.md` for any map or HUD piece; build here only what it
   lacks, and add a neutral line to Brix's ROADMAP if it's reusable.
3. Pure core with a failing test first (`tests/minimap.spec.luau`): from a `Floor.Floor`, the
   drawable pieces (each hall piece, the lobby, the elevator, each unit's door) and which piece a
   point is on, so "walked" fills in by piece. The lobby and elevator are always drawn.
4. A screen needs the floor's layout: FloorBuilder already sends the tops' map to screens as an
   attribute (`Tops.MapAttribute`, `Tops.encode`); send the floor the same way (or its seed and
   number, if `Floor.generate` rebuilds it the same on a screen: test that in Lune).
5. Client (`MinimapView`): a small corner map, phone first, clear of the buttons and the hall;
   halls fill in as you walk them, opened units ticked (their doors' state), you as an arrow,
   friends as dots behind one Config switch (owner, D-091). Never keepers or lit fixtures (the
   light board's job). Keep the drawing apart from its frame, so a full map behind a button is
   a small change later. Each change eases in (no snapping).
**Acceptance:** checks green; in Studio on seed 7, floor 1, walk two halls from the lobby: the
lobby and elevator show from the start, the walked halls fill in, an opened unit is ticked; at
Galaxy A16 size it leaves the buttons and the hall clear; Output clean.
**Read first:** ROADMAP L-10; D-091; `Floor.map` and the cell fields in `src/shared/Floor.luau`;
`Tops.encode` in `src/shared/Tops.luau`; `docs/FRAMEWORK.md`; CODEMAP's client rows.

## Queue (the next run's order, from ROADMAP)
1. L-10 (the minimap); D-064, D-068 to D-093. L-14b2d if the owner asks for it. Then L-07 (takes `Keepers.caught`), L-08, L-09.
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
   (D-059, D-066) through `Keepers:hear` (D-092). **Small:** a trapped keeper's every blow prints;
   a crawler's feet as `Wraps` reads them must sit within `Wrap.Under` (3), or crawling won't pop.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
