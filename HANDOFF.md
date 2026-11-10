# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 61 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **Session 61 was design, no code.** The owner judged L-06b2b (not bad; the walk jerky; keepers
  too easy to shut away) and agreed: a keeper out of its unit roams and never goes home; a trapped
  one breaks out at about 90 s and frees its place in the awake cap; no bonus for trapping (D-071);
  one note on every floor is guarded by an awake keeper, which is what the peek is for (D-072).
  The GDD, ROADMAP (L-06b3a1 to L-06b5, L-12c) and OWNER.md say so.
- **The brain:** pure `src/shared/Keeper.luau`, states Asleep (dealt asleep), Watching (awake,
  standing), Going, Waiting, Returning; `hear`, `lookOut`, `awake`, `step`. Rows in
  `KeeperRows.luau`; run by `src/server/Keepers.luau` (`add`, `stand`, `awakeOn`, `remove`,
  `hallOff`; takes `Deals.dealt`). `tests/keeper.spec.luau`: 20,572 checks.
- **Dev:** "Stand one" in the walked floor's lobby stands a sleeping Mannequin 60 studs down the
  halls. Output traces what each keeper hears and does; each body carries `KeeperState`.

## Next task: L-06b3a1 Once out, it roams
The moment: you let it walk off and it doesn't go home; now you don't know where it is.
1. Owner test results first, if pasted.
2. Read Keeper's Returning state and every place that keeps "where it woke"; read how
   `KeeperMap` tells a hall place from a unit and gives trip lengths.
3. A Roaming state in `Keeper` replacing Returning: after its linger at a noise, or after
   looking out of its own doorway, it picks a hall place (never a unit) some way along the
   halls that it hasn't visited lately, walks there at its looking speed, lingers, picks again.
   Picks come from the floor's seeded Random (Brix). A newer sound still sends it to look; a
   door coming down across its way makes it pick again. Watching (never yet out) and Asleep stay.
4. Remove D-069's "no way home, sleep where it stands"; a keeper out never sleeps again.
5. Roam numbers in the row (how far a pick may be, how long it lingers), each commented; list
   the defaults in `OWNER.md`.
6. Lune checks: once out it never re-enters its unit, never stops for good, keeps to the
   halls, avoids its recent places, and a sound interrupts a roam. In Studio on seed 7, floor 1:
   open Unit 126, it looks out and wanders off; slam 126 behind it and it keeps wandering.
**Acceptance:** checks green; in Studio an awake Mannequin out of its unit never goes back in and
keeps moving round the halls between noises.
**Read first:** ROADMAP L-06b3a1; DECISIONS D-069, D-070, D-071; `src/shared/Keeper.luau` (header,
Returning, `step`, `lookOut`); `src/server/Keepers.luau` (header, `onActed`, `system.step`);
`src/shared/KeeperMap.luau` (header, places); `tests/keeper.spec.luau` (its helpers).

## Queue (the next run's order, from ROADMAP)
1. L-06b3a1, L-06b3a2 (it sees you and hunts), L-06b4a (smooth on every screen), L-06b3b (light
   freezes it), L-06b3c (the catch), L-06b3d (the break-out), L-06b5 (the guarded note), L-06b4b
   (its sounds); D-064, D-068 to D-072. L-12c needs L-06b3d. Then L-14; L-07 to L-10.
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
