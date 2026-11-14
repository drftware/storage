# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 152 (two fixes to S1-10d1's menu, no ticket) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **The machine's menu** (S1-10d1, D-161), seen working in Studio Play in session 151 on a
  desktop window (opening, dim bays, a real buy, walking off). Session 152 fixed two rough edges.
  While the menu is up the tool wheel with Lay and Drop slides off the bottom of the screen as
  when you're kept (`Tools.StowAttribute`, set by the menu on your own Player) and comes back
  when it shuts: verified in Studio Play by setting the attribute (the wheel went from y 285 to
  409 on a 411-tall window and back to 285; Output clean of script errors), not with the menu
  itself. With all three slots full the tool bays go dim and dead like a full torch's battery
  (`Buy.tile`'s new `room`, with spec lines): passes checks, untested in Studio. Not seen: phone
  size, the rows waking, a refused pick. Studio left in Edit.

## Next task: S2-04c The hall lights go out for the alarm
ROADMAP S2-04c: today a wrong code turns every hall light on (`MotionLights.flash`), freezing the
Mannequins, so guessing makes a team safer. The GDD: the hall lights go out for the length of the
alarm instead (the elevator keeps its own light), with their own sound and a flicker as they cut
and come back. The moment: a wrong code, the bell, and the floor drops to black around the car
while the monsters it called come for you.
1. Read ROADMAP S2-04c, D-159 and D-160, and the GDD's lines on the alarm (search "alarm").
2. In `src/server/MotionLights.luau`, replace `flash` with a cut for the alarm's length: the
   breaker's `cut(zone, isCut)` (S2-02) already powers lights off per zone; check how it differs
   from what the alarm needs (every zone on that floor, not the car's lamp, back on after).
3. `src/server/Elevators.luau` (~line 358) calls `lights:flash(entry.floor)`: call the cut with
   the alarm's length (`Keypad.dead`'s span or the bell's), then restore. Pure timing goes in a
   pure module with a Lune spec.
4. Feedback in the same ticket: the lights' flicker as they cut and as they return (the client's
   `HallLights.luau`), a cut sound. No text.
5. Verify in Play: punch a wrong code on a floor with Mannequins out; the halls go dark, the
   Mannequins move in the dark, the lights come back.
**Acceptance:** checks green; a wrong code darkens that floor's halls for the alarm and brings
them back; the car's lamp stays; freed Mannequins aren't frozen by it; Output clean.
**Read first:** ROADMAP S2-04c; DECISIONS D-159, D-160; `src/server/MotionLights.luau` (header,
`flash`, `cut`); `src/server/Elevators.luau` (header, ~line 340-370); `src/client/HallLights.luau`
(header).

## Queue (next sessions per ROADMAP Phase 2)
1. S2-04c (next), then S2-05 (the tap when you shut a door on a sleeper). S2-06 and L-08e3c
   wait on `OWNER.md`. R-01 is for later.
2. S1-10d1 fixes (session 152): the wheel's slide was checked by attribute, not with the menu
   open; the dim tool bays with full slots are unseen. Watch both in the playtest (OWNER.md).
3. Found S1-10d2: the narrower drop leaves a tumbling saw's box corner up to 0.05 past the glass
   as it tips (a box estimate; likely unseen). If the owner sees it, a gentler `TIP` fixes it.
4. Found S2-04b: monsters called to one spot (the keypad, a door) all go to the same point and
   nothing keeps them apart, so four may stand inside each other at the keypad (inferred from
   distances, not seen). Spreading them round the spot is a small brain change worth a ticket.
5. Found S2-04a: Output's `ContentId: rbxassetid://89260803894903 ... No asset content
   representation found` ×27 as a dealt unit rolled up; not in the repo, cause unfound.
6. Found S2-03b: loose keepers hear a pounding door and go to look (a feature; watch it); a
   woken unit's Studio line says "asleep". S2-03a: waves can pass `Deal.awakeCap` (six bound it).
7. Found S2-02c: only a wandering Mannequin takes the errand; one standing awake that has never
   been out (Watching) doesn't. S2-02b: nobody can throw the breaker by hand (S2-06 may need it).
8. Found S1-12: no saved cash total shows yet; a climb left mid-way makes no cash (D-151).
   S1-11: a friend's beam doesn't show the mark. S1-10c2a: Output's `203785492` (wrong type) and
   texture permission errors, unchecked whether any are the machine's.
9. Small: S1-07b coin piles and batteries show Take through a shut door; S1-09 a kept player's
   torch drains if left on; S1-07a 16 in 100 units hold nothing (owner's call); unseen: S1-06 a
   kept find's save, S1-05 a find can be walked through, S1-04b2 keepers don't know about stuff.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
