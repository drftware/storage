# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 62 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-06b3a1 done (D-073):** once out, a keeper roams. After looking at a noise or out of its
  doorway it walks to a hall piece's middle 40 to 120 studs off along the halls, not one of its
  last four stops, stops 3 s, picks again; a sound still takes it to look. Never into a unit, so
  its door shut behind it changes nothing. Verified in Studio on seed 7, floor 1.
- **The brain:** pure `src/shared/Keeper.luau`, states Asleep (dealt asleep), Watching (awake,
  never yet out, or shut in its unit), Going, Waiting (at a sound or a roam stop), Roaming;
  `new(row, map, random, ...)`, `hear`, `lookOut`, `awake`, `step`. Rows in `KeeperRows.luau`
  (roam numbers there); `KeeperMap`'s `stops` are the roam targets. Run by `src/server/Keepers.luau`
  (`add` now takes the floor's Random; `stand`, `awakeOn`, `remove`, `hallOff`).
  `tests/keeper.spec.luau`: 23,420 checks.
- **Dev:** Output traces what each keeper hears and does; each body carries `KeeperState`.

## Next task: L-06b3a2 It sees you and hunts
The moment: it rounds a corner, sees you, and comes at you; you break line of sight and it
searches where it last saw you, then gives up and roams again.
1. Owner test results first, if pasted.
2. Decide whether `Brix.Pursuit` runs the chase (only if the pinned Brix has it and it fits with
   no new Brix work, D-064); the pinned `vendor/brix` has `Contracts/Pursuit.luau` but check its
   exports before leaning on it. Record the answer in DECISIONS.
3. Sight in the row (how far, how wide, each commented), measured so it never sees through a wall
   or a shut door: a straight line of sight that the map confirms (both ends in places joined
   without a shut doorway between). Watching, looking out and roaming notice; Asleep sees nothing.
4. A Hunting state at its top speed (`speed`) along the map toward the player it sees; lost, it
   goes to where it last saw them, looks (its `linger`), then roams (D-073's roam is the give-up).
5. The server feeds players' positions to the brain (floor coordinates) and says in Output when
   it sees and loses someone; feel numbers in the row, defaults listed in `OWNER.md`.
6. Lune checks: never sees through a wall, sees within its cone and range, hunts no faster than
   its top speed (never over a player's run), goes to the last place seen, roams after.
**Acceptance:** checks green; in Studio on seed 7, floor 1, stand in the hall as 126's keeper
roams by: it turns and comes; duck behind a corner and it searches, then roams.
**Read first:** ROADMAP L-06b3a2; DECISIONS D-064, D-073; `docs/FRAMEWORK.md` (the Pursuit row);
`vendor/brix/src/Contracts/Pursuit.luau`; `src/shared/Keeper.luau` (header, `step`, `pick`); the
GDD's Keepers section (the Mannequin's senses).

## Queue (the next run's order, from ROADMAP)
1. L-06b3a2, L-06b4a (smooth on every screen), L-06b3b (light freezes it), L-06b3c (the catch),
   L-06b3d (the break-out), L-06b5 (the guarded note), L-06b4b (its sounds); D-064, D-068 to
   D-073. L-12c needs L-06b3d. Then L-14; L-07 to L-10.
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
10. L-06b's keepers hear doors (done), the keypad, a dropped tool, the saw (`kind`), a crawl, the
   ladder and a drop in (D-059, D-066), and see a torch. The map already keeps them off the tops.
11. **Check:** Output's "rbxassetid://203785492 ... Asset type does not match" (six per Play) and
   "rbxassetid://139561946838090 ... content representation is being generated" (about thirty
   on reaching the walked floor); neither id is in our code, templates or the place's services.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
