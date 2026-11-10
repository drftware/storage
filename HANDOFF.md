# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 68 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-06b3d2 done (D-079), so L-06b3 is done:** each blow bows the slammed door out toward the
  hall. The server keeps the share of the keeper's time gone on the unit (`DoorDent`, never back;
  `RollUpDoor.dent`, pure `Dent.luau`); screens show one of three baked steps (pocket from the
  first blow, bowed from 36 s, buckling a stud out from 68 s), bowed rib copies from
  `Props.DoorDent_M`/`_S` (`art/unit/dent.py`, `scripts/art.sh dent`) swapped into the chain;
  a rib goes flat as it rolls up behind the header. 1,540 dent checks. Verified in Studio on seed 7,
  floor 1: steps at the first blow, 38.5 s, 68 s; flat-out at the burst; reads at Level21.
- **Fixed with it:** a trapped keeper's arm poked 2 studs through its door; it stands 3.4 in now.
- **The brain:** pure `src/shared/Keeper.luau`, rows in `KeeperRows.luau`, run by
  `src/server/Keepers.luau`. MCP recipes for the chase, catch, trap and hall shots: `docs/STUDIO.md`.

## Next task: L-06b5 The guarded note
The moment: you peek a unit, see feet standing, and know the note you still need is in there with
it, so this floor can't be cleared without a chase (DOORS puts the library's code hints in the room
Figure walks; the GDD's floor 5 does it with Dale).
1. Owner test results first, if pasted.
2. The floor's build picks one guarded unit from the units holding notes, seeded from the floor's
   Random, and marks it in the floor's data (pure, in `Floor` or the deal's deck, wherever the
   notes' units are chosen; read how notes are placed first).
3. The deal always deals that unit a keeper, awake, standing clear of the note's sight line
   (`DealSpot`). The guard holds one of the floor's awake places from the floor's start: on
   floors 1 and 2 (one place) every other keeper is dealt asleep until the guard is trapped or
   the cap otherwise frees a place (`Keepers.awakeOn`, `Keeper.loose`, `Deal.open`'s `awake`).
4. Every action answers: nothing new on screen; the peek (feet in view) is the tell. If a guard's
   stance needs a look (standing awake vs slumped asleep), check what the peek shows today first.
5. Lune over seeded floors (say 400): exactly one guarded unit per floor, always holding a note,
   its keeper always awake, the cap never exceeded with the guard counted.
6. One guarded note per floor is a default: list it in `OWNER.md`.
**Acceptance:** checks green; in Studio on seed 7, floor 1, Output names the guarded unit; peeking
it shows standing feet; opening it, its keeper hunts you; other keepers that floor deal asleep.
**Read first:** ROADMAP L-06b5; D-072; `src/shared/Deal.luau` (`open`, the deck); `src/server/Deals.luau`
(how keepers are dealt, `awakeOn`); `src/shared/DealSpot.luau`; `src/shared/Floor.luau` (the notes).

## Queue (the next run's order, from ROADMAP)
1. L-06b5 (the guarded note), L-06b4b (its sounds, the sting on sight, the freeze predicted on
   your screen); D-064, D-068 to D-079. L-12c needs L-06b3d (done). Then L-14; L-07 (takes
   `Keepers.caught`) to L-10.
2. **Check, small:** caught crawling a hole or on the ladder, the stand-in's move may leave
   `CrawlView`/`LadderView` holding PlatformStand; if a keeper can reach you there, end it.
3. **Checks on the tops, small:** Climb or Drop down lying behind a sawn hole slides you across
   it; a friend's drop-in lunges toward the door and lands 0.2 under the floor; a door's own
   buttons in reach while lying at its front, or the ladder to your shoulder while lying, should
   be refused for crawlers (`Ladders:crawling`). **GDD:** its ladder line says open mesh (D-058/9).
4. **Bugs, small:** FlashlightView's `motor()` takes only `Motor6D`, but shoulders are
   `AnimationConstraint`s, so a friend's torch arm never raises; DoorSounds' first slam lands up
   to 0.35 s late (swap `preload` for `SoundPrimer.prime`), and the trap's first blow may too.
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

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
