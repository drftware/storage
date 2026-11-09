# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 50 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-13b2c is done** (D-059): up a ladder, the stick steers your lying body over the steel, slow
  and low, held on the tops by the pure `Tops` map each floor publishes on its model (run slots,
  lids, a lip over each hall); your head can go just past a unit's front to look down. The server
  checks every crawler's place five times a second. Each pull booms on the steel for every screen
  (`climbed` "Crawl", 30 studs). Climb down sits over the ladder's top just past the edge; Drop
  down (F) over every unit's front takes you over, down, a crouch, a thud and a jolt. Take no
  longer waits for those up top. `Tops.luau`, `tests/tops.spec.luau` (34,372 checks).
- **Verified in Studio** (Play): 102 to 104 along a run, the peek (view 0.4 past the edge, the
  hall below), the drop (standing 1.9 out in the hall, body handed back), onto a lid on floor 1,
  backward, Climb down from 4.4 studs off; Output clean but for the known six asset warnings. Not
  checked: a corner onto another run, sounds by ear, two players, the phone. Studio in Edit.
- Owner's L-13b2b results applied: the steel tops and their sound are good; a torch may look down
  a sawn hole before you drop (now in ROADMAP L-13b2d).

## Next task: L-13b2d Saw down into a unit
The moment: up on the tops with the saw, you hold Saw over a unit, the whole floor hears it, and
you drop in blind (your torch can look first), as Rainbow Six Siege's floor hatches; one-way.
1. Owner test results first (`OWNER.md`'s L-13b2c and L-13b2a sections).
2. Read ROADMAP L-13b2d, D-059, D-058, and how the wall hole was made (`art/hole/`, D-052/D-053
   by Grep in DECISIONS). Split in ROADMAP before starting if it won't fit (art first is likely
   its own session).
3. Art first: a steel top with a sawn hole, the hole kit's way (`art/hole/`, `scripts/art.sh`),
   sized for a body dropping through, judged at phone size.
4. Then the cut: Saw (held, the saw's 4 s, heard floor-wide) from lying on a unit's top, the
   server checking you're on that top (`Tops`, `Ladders`' crawler record); the hole appears for
   every screen; your torch can look down it.
5. Then the drop in: a pressed move (as `Tops.drop`), landing inside; out only by an unlocked
   door rolled up from inside, sawing out sideways, or a friend cutting the lock.
**Acceptance:** checks green; in Studio saw a top and drop into the unit; phone-size judged.
**Read first:** ROADMAP L-13b2d; DECISIONS D-059 and the hole's (Grep "hole kit"); `art/hole/`
(its README or main script); `src/server/Saws.luau` (Grep `sawing`); `src/shared/Tops.luau`.

## Queue (the next run's order, from ROADMAP)
1. L-13b2d. L-06b the Mannequin hunts **waits on Brix**: ENG-07a/b (a chase in a place) aren't
   built, and this repo never edits Brix; a Brix session first. Worth doing soon: none of the
   escapes (saw, crawl hole, ladder, tops, drop) has been tried against a keeper. L-12c needs
   L-06b's keepers. Then L-14; L-07, L-08, L-10, L-09.
2. **GDD, small:** its ladder line still says open mesh tops you run across; D-058/D-059 close
   them and make the crawl steered. Update that line (a Claude Doc: the docs tools).
3. **Check, small:** lying at a unit's front, are that door's own buttons (Open, Slam) in reach
   from the tops? If so, refuse them for crawlers (`Ladders` knows who's up).
4. **Check, small:** up top, switching to a two-handed tool in your other slot (the ladder) would
   put it on your shoulder while you lie; refuse it for crawlers ("Not up here").
5. **Bug, small:** FlashlightView's `motor()` takes only `Motor6D`, but players' shoulders here
   are `AnimationConstraint`s (docs/STUDIO.md), so a friend's torch arm likely never raises.
6. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
7. **Check, small:** G is both a door's Slam and Drop: with a tool in hand, does G at an open
   door slam, drop, or both? Give Drop its own key if it clashes.
8. L-06b's keepers hear doors on `Doors.acted`, the keypad on `Elevators.acted`, a dropped tool on
   `Slots.changed`, the saw on `Saws.sawing` (200), a crawl on `Crawls.crawled` (35), the ladder
   on `Ladders.climbed` (60, 30; "Crawl" 30 every other pull, "Drop" 45); see a torch
   (`Flashlights.switched`); treat a holed wall as solid; can't reach the tops (`Tops` map,
   `Floor.runs`, lids) and never get the ladder's or the tops' buttons.
9. **Check:** Output warns six times per Play, "rbxassetid://203785492 failed: Asset type does
   not match": not our code; find what asks for it.
10. Studio traps (docs/STUDIO.md): press prompts with `InputHoldBegin`; stick: `MoveDirection`.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
