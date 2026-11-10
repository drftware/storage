# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 74 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-12c done (D-085), and with it L-12, the saw and the hole trap.** Played end to end first:
  three things broke it. Units two along a row passed as neighbours (`CrawlHole.between`), so a
  wall's Saw and Crawl buttons could go to the wrong unit; each door face must now stand half its
  unit's width from the wall. A Crawl pressed as you reached the hole was dropped (the server
  sees a run late); a press now counts where it sees you or 0.4 s on (`Crawling.counts`). Lost in
  a unit, the keeper stood on the wall's line, half through the hole; now it stops 3.4 studs off
  a unit's walls facing where it lost you (`KeeperMap.offWalls`). `tests/holetrap.spec.luau`.
  Verified in Studio on seed 7, floor 1: lured 157's guard from the junction, crawled 155 into
  153, it stood in 155 staring at the hole, my slam 0.9 s later trapped it. `OWNER.md`. L-14 is
  now split one tool a session (ROADMAP).

## Next task: L-14a The air horn
The moment: two halls off something is walking; you blow the horn by an open unit and duck away,
and it comes to the spot (GDD tool table: "Lures keepers to a spot", "Wakes dormant things
nearby"; with the bubble wrap or a unit's mouth it sets a trap).
1. Owner test results first, if pasted.
2. Read the GDD's tool table row and "Other traps" line only (docs tools, never WebFetch). Name
   its hit-game precedent (Lethal Company's noisemakers drawing the monsters that hunt by sound
   is the likely one: confirm it); none, and it goes to `OWNER.md` as an untested bet.
3. Check Brix first (`docs/FRAMEWORK.md`). Too big for one session? Split L-14a into the horn's
   art and blowing it, as L-12a and L-12b were, before starting.
4. Art first, the unit's way (`art/unit/README.md`; `art/saw/` is the nearest tool): a script,
   baked maps, FBX, Specs, look sheets; judged at phone size. A `Tools.Catalog` row.
5. Blowing it: a pressed use, server-checked (in hand, rate); a blast keepers hear as doors
   (`Keeper.hear`), so the awake go to look and sleepers in reach wake; feedback on every screen
   (the blast, your view's kick, a friend's arm). Pure rules Lune-tested, numbers in Config.
**Acceptance:** checks green; Lune checks on its rules; in Studio on seed 7, floor 1, a roaming
keeper two halls off walks to where you blew it, a sleeper behind an open door wakes; Output clean.
**Read first:** ROADMAP L-14; GDD tool table (the air horn row); D-069 (what keepers hear);
D-051 (the saw: a tool's art and its row); `src/shared/Tools` (the Catalog); `docs/FRAMEWORK.md`.

## Queue (the next run's order, from ROADMAP)
1. L-14a; D-064, D-068 to D-085. Then L-14b to L-14d; L-07 (takes `Keepers.caught`) to L-10.
2. **Check, small:** caught (moved to the lobby), the MCP's Client couldn't move the character
   54 s on (CFrame or `MoveTo`); a Server pivot could. Can a real player walk after a catch?
   Caught crawling or on the ladder, `CrawlView`/`LadderView` may keep holding PlatformStand.
3. **Check, small:** a press made the moment you arrive reaches the server while it still sees you
   a few studs back (D-085). Saws, Ladders (Lean, Climb, Drop down) and a door's Cut and Lock
   check where you stand: allow for it as `Crawling.counts` does if one drops. And any server
   check of where a player faces sees the turn 0.4 s late (D-084).
4. **Checks on the tops, small:** Climb or Drop down lying behind a sawn hole slides you across
   it; a friend's drop-in lunges toward the door and lands 0.2 under the floor; a door's own
   buttons in reach while lying at its front, or the ladder to your shoulder while lying, should
   be refused for crawlers (`Ladders:crawling`). **GDD:** its ladder line says open mesh (D-058/9).
5. **Bugs, small:** FlashlightView's `motor()` takes only `Motor6D` (shoulders are
   `AnimationConstraint`s; KneelView's `joint()` takes both), so a friend's torch arm never
   raises; DoorSounds' first slam lands up to 0.35 s late (`SoundPrimer.prime`), the trap's too.
6. **Check:** G is a door's Slam and a tool's Drop: at an open door, tool in hand, which?
7. **Check:** Output's "rbxassetid://203785492 ... Asset type does not match" (six per Play), and
   139561946838090's "being generated"; neither id is in our code, templates or services.
8. Keepers should hear the keypad, a dropped tool, the saw, a crawl, the ladder and a drop in
   (D-059, D-066). **Later:** they can't see into the car, nor between tops and halls (OWNER.md).
9. **Small:** Output prints every blow of a trapped keeper (about 28 a trap); trim if it's noise.
10. **Check, small:** the walk holds an arm out level; a keeper stopped against any other wall
    or door may put its hand through it (the trapped stand and a search in a unit are clear).
11. **Check, small:** after a Peek from the MCP, that door's other buttons ignore presses until
    you step out of reach and back (docs/STUDIO.md); does a player's real press do the same?

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
