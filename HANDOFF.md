# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 64 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-06b4a done (D-075):** the server sends each keeper's motion as a short record on its body's
  `KeeperMotion` attribute only when it changes (`KeeperMotion.due`), leaves its joints at rest and
  moves its root only with a record or every 8 studs. Each screen's `src/client/KeeperView.luau`
  follows the records 0.1 s behind the server (turns and stops exact, late ones eased, never past a
  stop) and poses it through Motor6D `Transform` in one of 33 frames (`Pose.frame`). Verified in
  Studio on seed 7, floor 1: chase drawn at its pace (median 14.4, p99 15.4 studs/s, no stalls),
  roam at 7.2, parts within 0.0001 of `Pose.solve`, no joint writes, about 6 records a second.
- **The brain:** pure `src/shared/Keeper.luau` (Asleep, Watching, Going, Waiting, Roaming,
  Hunting, Searching; `pace`, `left`), rows in `KeeperRows.luau`, run by `src/server/Keepers.luau`.
  Specs: keeper 47,058 checks, keepermap 73,126, keepermotion 253, mannequin 35,405. Testing a
  chase from the MCP, and what a frame draws when, are in `docs/STUDIO.md`.

## Next task: L-06b3b Light freezes it
The moment: your torch finds it mid-stride in the hall and it stops dead, reaching for you; the
light goes and it's a step closer. The GDD's Mannequin: it moves only while no light is on it.
1. Owner test results first, if pasted.
2. Each step, for each awake keeper, the server decides whether a light is on it: a lit hall
   fixture over it (`MotionLights`, the server's; what "on it" means for a tube's reach), or a
   player's torch beam (`Flashlights:isOn`, `aim`, their facing; a cone, within the torch's reach,
   along a line `KeeperMap.clear` passes, so never through a wall or shut door).
3. Lit, it freezes: its walk to look, its roam and its hunt all stop where it stands, keeping its
   state and trip; it walks on the moment no light is on it. A freeze is a stop record, so screens
   already hold it on `Pose.freeze`'s key (D-075). Decide whether a frozen keeper still sees and
   turns (default: still sees, never turns; OWNER.md).
4. Output in Studio: "the Mannequin freezes in (your) torch" / "in the light", and "walks on".
5. Lune checks: lit, it never moves however long; unlit, it carries on the same trip; light
   through a wall, a shut door or from behind a corner doesn't freeze it.
**Acceptance:** checks green; in Studio on seed 7, floor 1, open 126 and run, turn your torch on
it mid-chase: it stops on a stride and Output says so; torch off, it comes on.
**Read first:** ROADMAP L-06b3b; the GDD's Keepers section, the Mannequin only; headers of
`src/server/Flashlights.luau`, `src/server/MotionLights.luau` and `src/shared/MotionLight.luau`;
`src/shared/Keeper.luau` (`step`) and `src/server/Keepers.luau` (`system.step`, `publish`).

## Queue (the next run's order, from ROADMAP)
1. L-06b3b, L-06b3c (the catch, within `Keeper.Close`), L-06b3d (the break-out), L-06b5 (the
   guarded note), L-06b4b (its sounds, now with the sting on sight); D-064, D-068 to D-075.
   L-12c needs L-06b3d. Then L-14; L-07 to L-10.
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
