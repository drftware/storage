# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 65 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-06b3b done (D-076):** light freezes the Mannequin (`freezesInLight` on its row). Each step
  the server tells its brain whether a lit hall light's pool (13 studs round a lit fixture,
  `MotionLights.lightOn`) is on it and each player's torch (head, facing, aim); `Keeper.step`
  decides (`lit`: a hall light only in a hall, a beam within 42 studs and 27 degrees along a line
  the map clears, `Keeper.inTorch`). Frozen it neither walks, turns nor counts time, still sees;
  a freeze goes to screens at once. Verified in Studio on seed 7, floor 1 (torch and hall light).
- **The brain:** pure `src/shared/Keeper.luau`, rows in `KeeperRows.luau`, run by
  `src/server/Keepers.luau`; screens follow `KeeperMotion` records (D-075). Keeper spec: 51,410
  checks. Testing a chase or a freeze from the MCP: `docs/STUDIO.md`.

## Next task: L-06b3c The catch
The moment: you stood still too long in the dark, and it's there; its hand closes on you. A
hunting keeper that reaches you catches you, and the event fires for L-07 (getting kept).
1. Owner test results first, if pasted.
2. Check Brix's cone reach (`docs/FRAMEWORK.md`, the reaches; its source in `vendor/brix`) and
   use it for the catch: a hunting keeper catches the player it hunts within arm's reach
   (`Keeper.Close` and a little) in front of it, along a line `KeeperMap.clear` passes, so never
   through a wall, a shut door or from up on the tops. Never while a light holds it (`lit`), so a
   torch on it saves you (D-076), and never asleep.
3. The server fires a `caught` signal (keeper body, player) that L-07 will take. Until L-07, a
   sensible stand-in (default: the caught player is put back in the lobby, the keeper stands its
   linger, then roams); list it in OWNER.md. Every action answers: the catch's own feedback in
   this ticket (at least a jolt on the caught player's screen and Output's line); the sting and
   sounds are L-06b4b's.
4. Output in Studio: "the Mannequin catches (you)".
5. Lune checks: caught exactly within the reach and cone, never through a wall or shut door,
   never frozen or asleep, only the one it hunts; a warm catch check allocates nothing.
**Acceptance:** checks green; in Studio on seed 7, floor 1, open 126 in the dark (take the
`TripsLights` tag off your root) and stand still: it comes and catches you, and Output says so;
again with your torch on it: it never does.
**Read first:** ROADMAP L-06b3c and L-07; the GDD's "Getting kept" section only;
`docs/FRAMEWORK.md` (the reaches); `vendor/brix/src/Reaches` (the cone); `src/shared/Keeper.luau`
(`step`, `Close`, `look`); `src/server/Keepers.luau` (`system.step`, `traceSight`).

## Queue (the next run's order, from ROADMAP)
1. L-06b3c, L-06b3d (the break-out), L-06b5 (the guarded note), L-06b4b (its sounds, the sting
   on sight, and the freeze predicted on your own screen); D-064, D-068 to D-076. L-12c needs
   L-06b3d. Then L-14; L-07 to L-10.
2. **Check, small:** Climb or Drop down lying behind a sawn hole slides you across the hole.
3. **Look, small:** a friend's drop-in from behind the hole lunges toward the door; landing dips
   your feet 0.2 under the floor. **GDD, small:** its ladder line still says open mesh (D-058/9).
4. **Check, small:** lying at a unit's front, are that door's own buttons (Open, Slam) in reach
   from the tops? If so, refuse them for crawlers (`Ladders:crawling` says who's up).
5. **Check, small:** up top, switching to a two-handed tool in your other slot (the ladder) would
   put it on your shoulder while you lie; refuse it for crawlers ("Not up here").
6. **Bug, small:** FlashlightView's `motor()` takes only `Motor6D`, but players' shoulders here
   are `AnimationConstraint`s (docs/STUDIO.md), so a friend's torch arm likely never raises.
7. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
8. **Check:** G is a door's Slam and a tool's Drop: at an open door, tool in hand, which?
9. L-06b's keepers hear doors (done), the keypad, a dropped tool, the saw (`kind`), a crawl, the
   ladder and a drop in (D-059, D-066), and see a torch. The map already keeps them off the tops.
10. **Check:** Output's "rbxassetid://203785492 ... Asset type does not match" (five per Play) and
   "rbxassetid://139561946838090 ... content representation is being generated" (about thirty
   on reaching the walked floor); neither id is in our code, templates or the place's services.
11. **Later:** keepers can't see into the elevator car (should a hunter come to the gate?), nor
   between the tops and the halls, so a torch from the tops never freezes one (OWNER.md asks).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
