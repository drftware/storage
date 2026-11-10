# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 73 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-06b4b3 done (D-084), and with it L-06b4 and L-06b, the Mannequin hunts.** Measured first:
  the server saw a player's turn up to 0.4 s late (Roblox eases a character in), so a hunter
  walked on under your torch and caught you. Now your torch sends its heading with its pitch (at
  once on a big swing or as your screen sees the beam land) and keepers test your beam along it;
  one beam test serves the brain and your screen (`Torch.lights` at `Keeper.beamPoint`; the
  screen's line a raycast). The frame your beam lands on a body shown walking, your screen holds
  it on its freeze key (`KeeperMotion.hold`), never sliding; once the server lets it go it makes
  the gap up as it walks. Verified in Studio on seed 7, floor 1: held the frame the beam landed,
  the server's freeze 0.03 s later, 1.66 studs on; through 157's shut door nothing. `OWNER.md`.

## Next task: L-12c The hole trap, end to end
The moment: it's on you, you dive into a unit, squeeze out through the hole you sawed, sprint
round and slam its door on it while it searches where you vanished (GDD "The hole trap"; name the
hit-game precedent the GDD gives it before building anything new).
1. Owner test results first, if pasted.
2. Read the GDD's "The hole trap" section only (docs tools, never WebFetch).
3. Play it end to end in Studio before changing anything: on seed 7, floor 1, saw a hole between
   two units in a row (a saw lies by the test hall's spawn; or cut one from the Server with
   `CrawlHole.saw`), let 157's guard hunt you into one, crawl out, run round, slam. Log its
   state each 0.25 s. Find what breaks: does it lose you through the wall, search at the hole,
   linger long enough for the run round, or walk out first? Can it follow through the hole (it
   mustn't: crawl holes are for crawlers, D-068)?
4. Fix only what stops the trap landing, in the brain (`Keeper`, pure, a failing Lune test first)
   or its numbers (the row, each with a comment on what it does to the player).
5. Every action answers: add feedback only where something is silent. Too big? Split first.
**Acceptance:** checks green; in Studio on seed 7, floor 1, the guard hunted into a unit loses you
through the hole, never comes through it, and is trapped by your slam after the run round
(Output: "trapped"); Output clean.
**Read first:** ROADMAP L-12c; GDD "The hole trap"; D-068, D-071, D-077; `src/shared/Keeper.luau`
(how it loses you and searches); `src/server/Crawls.luau`; `docs/STUDIO.md` (the trap, the
crawl and the chase recipes).

## Queue (the next run's order, from ROADMAP)
1. L-12c; D-064, D-068 to D-084. Then L-14; L-07 (takes `Keepers.caught`) to L-10.
2. **Check, small:** caught crawling a hole or on the ladder, the stand-in's move may leave
   `CrawlView`/`LadderView` holding PlatformStand; if a keeper can reach you there, end it.
3. **Checks on the tops, small:** Climb or Drop down lying behind a sawn hole slides you across
   it; a friend's drop-in lunges toward the door and lands 0.2 under the floor; a door's own
   buttons in reach while lying at its front, or the ladder to your shoulder while lying, should
   be refused for crawlers (`Ladders:crawling`). **GDD:** its ladder line says open mesh (D-058/9).
4. **Bugs, small:** FlashlightView's `motor()` takes only `Motor6D` (shoulders are
   `AnimationConstraint`s; KneelView's `joint()` takes both), so a friend's torch arm never
   raises; DoorSounds' first slam lands up to 0.35 s late (`SoundPrimer.prime`), the trap's too.
5. **Check:** G is a door's Slam and a tool's Drop: at an open door, tool in hand, which?
6. **Check:** Output's "rbxassetid://203785492 ... Asset type does not match" (six per Play)
   and "rbxassetid://139561946838090 ... content representation is being generated"; neither
   id is in our code, templates or the place's services.
7. Keepers hear doors and a trapped one's blows (done), and should hear the keypad, a dropped
   tool, the saw, a crawl, the ladder and a drop in (D-059, D-066). **Later:** they can't see
   into the elevator car, nor between the tops and the halls (OWNER.md asks).
8. **Small:** Output prints every blow of a trapped keeper (about 28 lines a trap); trim to the
   first, every tenth, the dent's steps and the last if it gets in the way.
9. **Check, small:** the walk holds an arm out level; a keeper stopped against any other wall or
   door may put its hand through it (L-06b3d2 fixed only the trapped stand).
10. **Check, small:** after a Peek from the MCP, that door's other buttons ignore presses until
    you step out of reach and back (docs/STUDIO.md); does a player's real press do the same?
    And any other server check of where a player faces sees the turn 0.4 s late (D-084).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
