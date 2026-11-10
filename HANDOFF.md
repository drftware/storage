# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 60 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-06b2b is done** (D-070): a keeper the deal puts behind a door stands where it was laid as
  the door first lifts. Asleep: slack in its shop pose, still, until the first loud sound that
  reaches it through its open doorway wakes it (its own door's open doesn't); then it goes to
  look and stays awake. Awake: it holds a stride square to the doorway and steps out to look the
  moment its door is all the way up. The deal's cap counts `Keepers:awakeOn`. Verified in Studio
  on seed 7, floor 1 (Units 112 asleep, 126 awake, 154 asleep). Feel is the owner's (`OWNER.md`).
- **The brain:** pure `src/shared/Keeper.luau`, states Asleep (dealt asleep), Watching (awake,
  standing), Going, Waiting, Returning; `hear`, `lookOut`, `awake`, `step`. Rows in
  `KeeperRows.luau`; run by `src/server/Keepers.luau` (`add`, `stand`, `awakeOn`, `remove`,
  `hallOff`; takes `Deals.dealt`). `tests/keeper.spec.luau`: 20,572 checks.
- **Dev:** "Stand one" in the walked floor's lobby stands a sleeping Mannequin 60 studs down the
  halls. Output traces what each keeper hears and does; each body carries `KeeperState`.

## Next task: L-06b3a It sees you and hunts
The moment: it steps out of the unit you opened, sees you, and comes, never faster than you run.
1. Owner test results first, if pasted.
2. Decide whether `Brix.Pursuit` runs the chase (only if it fits with no new Brix work, D-064):
   Grep `../engine` for Pursuit's exports and read `docs/FRAMEWORK.md`'s keeper lines. Record it.
3. Sight in the row (`KeeperRows`): how far and how wide it sees, from the GDD and a precedent
   (Granny's sight, Left 4 Dead's specials); line of sight on the map (`KeeperMap`), never
   through a wall or a shut door. Asleep sees nothing; Watching, Waiting and looking out notice.
4. A Hunting state in `Keeper`: chase the seen player by the map at the row's top speed (0.9 of
   your run), re-planning as they move; lose them, go to where it last saw them, look (linger),
   go back (Granny's search). The server feeds players' positions in the floor's coordinates.
5. Lune checks on the pure part (sees through no wall, never faster than its speed, gives up);
   in Studio on the walked floor, open Unit 126 first (dealt awake) and watch it come for you.
**Acceptance:** checks green; in Studio an awake Mannequin notices a player in its sight, hunts
them along the halls at no more than 0.9 of their run, and gives up after losing them.
**Read first:** ROADMAP L-06b3a; DECISIONS D-064, D-070; `src/shared/Keeper.luau` (header,
`hear`, `step`, `lookOut`); `src/server/Keepers.luau` (header, `onActed`, `system.step`);
`docs/FRAMEWORK.md` (Grep `Pursuit`); the GDD's keepers section (docs tools).

## Queue (the next run's order, from ROADMAP)
1. L-06b3a, L-06b3b (light freezes it), L-06b3c (the catch), L-06b4 (D-064, D-068, D-069,
   D-070); L-12c needs L-06b. Then L-14; L-07 to L-10.
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
