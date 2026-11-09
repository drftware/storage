# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 58 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-06b1, the keepers' map, is done** (D-068). `src/shared/KeeperMap.luau` lays a floor as
  places (hall pieces, junction middles and arms, the lobby, units) joined by passages (joints,
  doorways shut while their doors are down). Trips are A* over the passages, kept to Brix's
  Pathing contract (`length`, `advance`, `route`). Pure; nothing on screen yet. Its spec runs
  62,000 checks over 60 seeded floors; a length across a full floor takes about 10 µs.
- **Abilities per keeper** (owner, Nov 9): a passage may need "Climb" or "Crawl", and each keeper
  walks through `KeeperMap.pathing(map, row.abilities)`. The tops (raised places) and ladders or
  sawn holes (passages) can be added while a floor runs, so a climbing or crawling keeper is a
  row plus those calls, never a new map. The Mannequin has none.
- **Defaults the owner accepted:** a doorway lets keepers through only while its door is all
  the way up (`KeeperMap.letsThrough`); keepers walk the halls' middles; the elevator car is off
  the map (the GDD: keepers can't ride it).
- The owner judged L-13b2d3a and L-13b2d3b in Studio ("looking good"); both left `OWNER.md`.

## Next task: L-06b2a It hears a door and walks to it
The moment: you slam a door and, two halls off, something starts walking toward it.
1. Owner test results first, if pasted.
2. Read the GDD's keepers and tech plan sections (docs tools; the doc says each row has a top
   speed as a share of player sprint) and how `FloorBuilder.lay` places a floor (its origin).
3. The keepers' system on the Host's clock (D-064), server side: rows as data (the Mannequin's:
   speed, `abilities = {}`, how far it hears); states asleep, going to look, waiting there, going
   back; each keeper keeps one `route` from its pathing and steps it each tick while it moves.
4. The map per floor: `KeeperMap.build` as `FloorBuilder` lays it; `Doors`' state changes fed
   through `letsThrough` into `setDoor`; world positions into the floor's own and back.
5. Hearing: a door's open, slam or lift from inside reaches a keeper within that action's reach
   from `DoorSound.Actions`, measured along the map (`length`), so no sound goes through walls.
6. The body: `Mannequin.clone`, anchored, moved by its HumanoidRootPart; posed with
   `Pose.at(travelled)` on the server for now (L-06b4 moves it to clients). A dev command stands
   one in a hall of the walked floor.
7. Lune checks on the pure parts (the states, hearing along the map); in Studio on the walked
   floor, slam a door two halls off and watch it come, wait, then go back.
**Acceptance:** checks green; in Studio a slam brings it the shortest way and a shut door stops
it; numbers the GDD doesn't give (wait, hearing) are Config defaults listed in `OWNER.md`.
**Read first:** ROADMAP L-06b (the ticket and its parts); DECISIONS D-064 and D-068;
`src/shared/KeeperMap.luau` (its header and the exported functions); `src/server/Doors.luau`
(Grep its Signal and states); `src/shared/StorageUnit/DoorSound.luau` (`Actions`); the GDD's
keepers and tech plan sections (docs tools).

## Queue (the next run's order, from ROADMAP)
1. L-06b2a, L-06b2b, L-06b3, L-06b4 (D-064, D-068); L-12c needs L-06b. Then L-14; L-07 to L-10.
2. **Check, small:** Climb down or Drop down while lying behind a sawn hole (a small unit) slides
   your body across the hole on the way to the edge; refuse it there or go round.
3. **Look, small:** from a friend's view, dropping in from behind the hole lunges you toward the
   door before your legs go down; the landing crouch dips your feet 0.2 under the floor.
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
10. L-06b's keepers hear doors, the keypad, a dropped tool, the saw (`kind`), a crawl, the
   ladder and a drop in (D-059, D-066), and see a torch. The map already keeps them off the tops.
11. **Check:** Output's "rbxassetid://203785492 ... Asset type does not match" (six per Play).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
