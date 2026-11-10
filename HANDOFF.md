# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 63 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-06b3a2 done (D-074):** a keeper awake in any state sees a player within its row's `sight`
  (48) and `sightAngle` (60 each side) along a line `KeeperMap.clear` passes (no wall, shut door
  or door post; never up on the tops or in the car), turns and hunts the nearest at its top speed
  to arm's length (`Keeper.Close`, 2.5); no sound pulls it off. Lost, it rushes to where it last
  saw them (Searching), stands its linger, then roams. Pursuit doesn't run it. Verified in Studio
  on seed 7, floor 1 (opened 126 on it, a 90-stud chase round a junction, lost, roamed, and a
  roaming one turned on a player 18 studs ahead).
- **The brain:** pure `src/shared/Keeper.luau` (Asleep, Watching, Going, Waiting, Roaming,
  Hunting, Searching), rows in `KeeperRows.luau`, run by `src/server/Keepers.luau`.
  `tests/keeper.spec.luau` 46,500 checks; `tests/keepermap.spec.luau` 73,126. Output traces
  what each keeper hears, sees and loses; testing a chase from the MCP is in `docs/STUDIO.md`.

## Next task: L-06b4a It moves smoothly on every screen
The moment: it comes down the hall at you and every screen, a phone included, sees one smooth
stiff-limbed walk, not a body hopping between server updates.
1. Owner test results first, if pasted.
2. Today `Keepers.place` sets the body's root CFrame every step and poses its joints (Motor6D C0)
   at most 20 a second, both replicated. Instead the server publishes each keeper's motion as an
   attribute on its body (where, facing, `travelled`, state, the server's time), only when it
   changes, the way a door's `DoorMotion` attribute carries RollUpDoor's motion to each screen.
3. A client view (new, `src/client/KeeperView.luau`, started by the Host like `DoorView`) moves
   each streamed-in body on this screen: its place smoothed between the server's updates (no
   overshoot past a stop, a snap on a jump of more than a few studs), and posed locally with
   `Pose.at(travelled)` (walking) or the held stride (stopped) through Motor6D `Transform`, never
   C0, so nothing per joint replicates. The server keeps the true position for the brain.
4. Only bodies in motion are stepped; nothing allocates per frame; connections go with the body.
5. Lune checks for any pure smoothing (e.g. a `KeeperMotion` encode/decode and the eased place
   between two updates never overshooting).
**Acceptance:** checks green; in Studio on seed 7, floor 1, open 126 and run: the chase reads
smooth in the Client's view, Output still traces it, and far less replicates per second.
**Read first:** ROADMAP L-06b4a; `src/server/Keepers.luau` (`place`, `Body`, `POSE_EVERY`);
`src/shared/StorageUnit/RollUpDoor.luau` and `src/client/DoorView.luau` (headers: motion on an
attribute, played per screen); `src/shared/Mannequin/Pose.luau` and `init.luau` (`pose`).

## Queue (the next run's order, from ROADMAP)
1. L-06b4a, L-06b3b (light freezes it), L-06b3c (the catch, within `Keeper.Close`), L-06b3d (the
   break-out), L-06b5 (the guarded note), L-06b4b (its sounds, now with the sting on sight);
   D-064, D-068 to D-074. L-12c needs L-06b3d. Then L-14; L-07 to L-10.
2. **Check, small:** Climb or Drop down lying behind a sawn hole slides you across the hole.
3. **Look, small:** a friend's drop-in from behind the hole lunges toward the door; the landing
   crouch dips your feet 0.2 under the floor.
4. **GDD, small:** its ladder line still says open mesh tops you run across (D-058/D-059); fix it.
5. **Check, small:** lying at a unit's front, are that door's own buttons (Open, Slam) in reach
   from the tops? If so, refuse them for crawlers (`Ladders:crawling` says who's up).
6. **Check, small:** up top, switching to a two-handed tool in your other slot (the ladder) would
   put it on your shoulder while you lie; refuse it for crawlers ("Not up here").
7. **Bug, small:** FlashlightView's `motor()` takes only `Motor6D`, but players' shoulders here
   are `AnimationConstraint`s (docs/STUDIO.md), so a friend's torch arm likely never raises.
8. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
9. **Check, small:** G is a door's Slam and a tool's Drop: at an open door, tool in hand, which?
10. L-06b's keepers hear doors (done), the keypad, a dropped tool, the saw (`kind`), a crawl, the
   ladder and a drop in (D-059, D-066), and see a torch. The map already keeps them off the tops.
11. **Check:** Output's "rbxassetid://203785492 ... Asset type does not match" (six per Play) and
   "rbxassetid://139561946838090 ... content representation is being generated" (about thirty
   on reaching the walked floor); neither id is in our code, templates or the place's services.
12. **Later, the elevator:** keepers can't see into the car; should a hunter come to the gate?

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
