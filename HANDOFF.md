# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 75 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-14a1 done (D-086): the air horn's art.** L-14a is split into the art (this) and blowing
  it (L-14a2). The precedent is Lethal Company's air horn, which draws the monsters that hunt by
  sound. A marine air horn built from code (`art/airhorn/`, 6,000 triangles, one baked set): a
  white steel can, a black band with an orange sound-wave mark, a black collar, an orange
  trumpet standing straight up. `Props.Tools.AirHorn` (uploaded, prepared; the place needs
  saving, `OWNER.md`), a `Catalog` row with its hold, a friend's hold, pick-up and drop sounds,
  and `Specs/AirHorn` (the bell's `Mouth`). The test hall lays one beside the spawn's bolt
  cutters. Verified in Studio at desktop size: picked up, held, dropped upright, Output clean.
  A friend's hold, flipped to 90 after -90 measured facing the body, is unchecked (`OWNER.md`).

## Next task: L-14a2 Blowing the air horn
The moment: two halls off something is walking; you blow the horn by an open unit and duck away,
and it comes to the spot. Blow it in the wrong place and a sleeper nearby wakes too (GDD).
1. Owner test results first, if pasted.
2. Check Brix first (`docs/FRAMEWORK.md`: Signal, the presentation kit ENG-15, typed remotes).
3. The press: one verb, "Blow", with a key and a phone button, only while the horn is in your
   hand (the torch's input in `FlashlightView` is the pattern). A client→server remote, checked
   on the server (type, the horn in that player's hand, a cooldown) and rate-limited.
4. The hearing: a blast at the bell's mouth (`Specs/AirHorn.Mouth`) that keepers hear as they
   hear doors (`Keeper.hear`, `Keeper.Hears`, D-069), with its own reach in Config, so awake
   keepers in reach walk to the spot and look; sleepers in reach wake (pick a sensible reach, a
   bit over two hall pieces, and say so in `OWNER.md`). Pure rules Lune-tested.
5. Feedback on every screen: the blast (a Pro Sound Effects air horn, measured by
   AudioAnalyzer, heard far), the horn raised in your view and a small kick (`CameraShake`), a
   friend's arm raising it (the row's `use` pose). Polish that doesn't fit goes in ROADMAP.
**Acceptance:** checks green; Lune specs on the blow's rules; in Studio, carrying the test
hall's horn to floor 1 of seed 7 ("Walk a floor"), a roaming keeper two halls off walks to
where you blew it, and a sleeper behind an open door in reach wakes; Output clean.
**Read first:** ROADMAP L-14a2; D-069 (what keepers hear); D-086 (the horn); `src/shared/Keeper.luau`
(`Keeper.Hears`, `Keeper.hear`); `src/shared/Tools/Catalog.luau` (the AirHorn row); `docs/FRAMEWORK.md`.

## Queue (the next run's order, from ROADMAP)
1. L-14a2; D-064, D-068 to D-086. Then L-14b to L-14d; L-07 (takes `Keepers.caught`) to L-10.
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
