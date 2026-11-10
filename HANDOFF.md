# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 81 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-10 done (D-094): the corner map.** Top right under the top bar, it slides in on a floor and
  follows you: halls fill in as you walk them, the lobby and car drawn from the start, the gate's
  amber mark held on the edge while it's off the window, opened units green with a tick, friends
  as blue dots (`Minimap.Friends`). North stays up. Roblox's player list is off.
- Pure core `src/shared/Minimap.luau` (Lune-tested); `Minimaps` on the server sends the layout as
  shapes, never the seed (the seed would give away the code and every unit); `MinimapView` (the
  window) and `MinimapDrawing` (the drawing, reusable for a full map later).
- **Verified in Studio** at Galaxy A16 size, seed 7, floor 1: walked halls filled in, unit 103
  opened went green and ticked, the gate's mark on the edge, buttons clear, Output clean.
- Owner played the pops Nov 10 ("better"); the rustling pop sound is in ROADMAP's polish list.

## Next task: L-07 Getting kept and rescued
The moment: the keeper's hands close, the screen goes dark, and you wake shrink-wrapped in a unit
somewhere on the floor, banging on the door so your friends can find you before it's padlocked.
1. Owner test results first, if pasted.
2. Read the GDD's "Getting kept" section (docs tools, never WebFetch) and ROADMAP L-07. It is
   big: split it in ROADMAP before starting (likely: the wrap and being stored in a unit; the
   banging that pings friends, on the map too; cutting free; the padlock if left too long).
   Name each part's hit-game precedent (AGENTS.md); anything without one goes to OWNER.md.
3. Brix first (`docs/FRAMEWORK.md`): nothing planned covers this; build it on `Keepers.caught`.
4. Do the first part only: pure rules with a failing Lune test first, then server, then screen.
   It replaces the stand-ins: DevCorridor's move to the lobby, `Caught`'s blackout hold
   (`CaughtView`) and `Caught.Out`. What you carried drops where you stood.
5. Fix the repeat catch: a keeper that chased you to the lobby catches you again every 2 s.
**Acceptance (first part):** checks green; in Studio on seed 7, floor 1, let the awake Mannequin
in Unit 157 catch you (D-069's recipe in docs/STUDIO.md): you end up wrapped in a unit, not the
lobby, can't walk, and nothing catches you twice; Output clean.
**Read first:** ROADMAP L-07; GDD "Getting kept"; D-077; `src/shared/Caught.luau`; DevCorridor's
catch stand-in (`keepers.caught`); CODEMAP's `Keepers` and `CaughtView` rows.

## Queue (the next run's order, from ROADMAP)
1. L-07 (takes `Keepers.caught`); D-064, D-068 to D-094. L-14b2d if the owner asks. Then L-08, L-09.
2. **Small, own session:** cut `MovingBlanket`, `GlowSticks` from `Deal.Tools`/`Deal.Bag` (D-091);
   it reshuffles every seed, so recheck the units `OWNER.md`'s steps name (seed 7, floors 1, 3).
3. **Check, small:** caught (moved to the lobby), the MCP's Client couldn't move the character
   54 s on; a Server pivot could. Can a real player walk after a catch? Caught crawling or on the
   ladder, `CrawlView`/`LadderView` may keep holding PlatformStand.
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
