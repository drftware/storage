# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 51 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-13b2c2 is done** (D-060, from the owner's L-13b2c test: the torch and tools went through
  the roof and doors). Your torch and the tool in your other hand are drawn at a third of their
  size a third as far from your eye (`Hands.Scale`, `Model:ScaleTo`), so the screen shows the same
  thing but nothing reaches past 0.61 studs; where even that touches (lying on a top looking down)
  it pulls back at once and ducks out of view (`HandRoom.room`, a spherecast from behind your eye).
  The beam keeps its full-size spot but reaches there from the drawn lens only as far as it's
  clear; a friend's beam is checked from their head. `Hands.luau`, `HandRoom.luau`,
  `tests/hands.spec.luau` (20 checks).
- **Verified in Studio** (Play): nose to the dead end's wall (eye 1.45 from it, torch clear, beam
  short of the wall); a camera 0.6 over unit 102's top looking down, ahead, up and flat (nothing
  touches, it ducks looking down); the peek over the front looking down and out (beam lands on the
  hall floor). Output clean but for the known six asset warnings. Not checked: a tool in hand (its
  Take prompt never showed to a script), a friend's beam, the phone. Studio in Edit.
- The owner's L-13b2c results: the crawl and the drop look good; the rest of its checks stay in
  `OWNER.md`.

## Next task: L-13b2d Saw down into a unit
The moment: up on the tops with the saw, you hold Saw over a unit, the whole floor hears it, and
you drop in blind (your torch can look first), as Rainbow Six Siege's floor hatches; one-way.
1. Owner test results first (`OWNER.md`'s L-13b2c2, L-13b2c and L-13b2a sections).
2. Read ROADMAP L-13b2d, D-059, D-058, and how the wall hole was made (`art/hole/`, D-052/D-053
   by Grep in DECISIONS). Split in ROADMAP before starting if it won't fit (art first is likely
   its own session).
3. Art first: a steel top with a sawn hole, the hole kit's way (`art/hole/`, `scripts/art.sh`),
   sized for a body dropping through, judged at phone size.
4. Then the cut: Saw (held, the saw's 4 s, heard floor-wide) from lying on a unit's top, the
   server checking you're on that top (`Tops`, `Ladders`' crawler record); the hole appears for
   every screen; your torch can look down it (its beam reaches from the drawn lens, D-060).
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
8. **Look, small:** your torch's flared head shows as a flat black disc from behind (no light
   reaches its back); a faint rim or a little spill behind it may read better. Owner's call.
9. L-06b's keepers hear doors, the keypad, a dropped tool, the saw, a crawl and the ladder (see
   D-059's signals); see a torch; treat a holed wall as solid; can't reach the tops.
10. **Check:** Output warns six times per Play, "rbxassetid://203785492 failed: Asset type does
   not match": not our code; find what asks for it.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
