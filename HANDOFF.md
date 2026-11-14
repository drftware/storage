# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 151 (a look at S1-10d1's menu, no ticket) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **The machine's menu, seen in Studio Play for the first time** (S1-10d1, D-161; desktop window
  1162×761, the test hall's floor 3 car, ride held): Buy on the glass opens it; the panel shows
  the sign with the keyhole coin, three lit rows with their tubes, each thing's picture, its paper
  label and its LED price; with 4 coins the bays you can't pay go dim (picture and price), and the
  batteries are dim with a full torch. A real buy (bubble wrap, 30 coins to 25) dropped the panel
  away in 0.2 s, the roll flew to the hand, the panel rose again 1.8 s later with that coil's
  price showing dashes. Walking about 9 studs off slid it away. Nothing needed fixing. Not seen:
  phone size, the rows waking, the real button sinking, a refused pick. Studio left in Edit.

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
2. Seen S1-10d1: the menu's bottom edge meets the hotbar's Lay and Drop buttons; watch on a phone.
3. Found S1-10d2: the narrower drop leaves a tumbling saw's box corner up to 0.05 past the glass
   as it tips (a box estimate; likely unseen). If the owner sees it, a gentler `TIP` fixes it.
4. Found S1-10d1: a tool pick with every slot full presses and clicks, then nothing (the server
   refuses quietly, the menu stays up). Show it on the bay instead (dim, like a full torch's
   battery) once the client knows the slots are full.
5. Found S2-04b: monsters called to one spot (the keypad, a door) all go to the same point and
   nothing keeps them apart, so four may stand inside each other at the keypad (inferred from
   distances, not seen). Spreading them round the spot is a small brain change worth a ticket.
6. Found S2-04a: Output's `ContentId: rbxassetid://89260803894903 ... No asset content
   representation found` ×27 as a dealt unit rolled up; not in the repo, cause unfound.
7. Found S2-03b: loose keepers hear a pounding door and go to look (a feature; watch it); a
   woken unit's Studio line says "asleep". S2-03a: waves can pass `Deal.awakeCap` (six bound it).
8. Found S2-02c: only a wandering Mannequin takes the errand; one standing awake that has never
   been out (Watching) doesn't. S2-02b: nobody can throw the breaker by hand (S2-06 may need it).
9. Found S1-12: no saved cash total shows yet; a climb left mid-way makes no cash (D-151).
   S1-11: a friend's beam doesn't show the mark. S1-10c2a: Output's `203785492` (wrong type) and
   texture permission errors, unchecked whether any are the machine's.
10. Small: S1-07b coin piles and batteries show Take through a shut door; S1-09 a kept player's
   torch drains if left on; S1-07a 16 in 100 units hold nothing (owner's call); unseen: S1-06 a
   kept find's save, S1-05 a find can be walked through, S1-04b2 keepers don't know about stuff.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
