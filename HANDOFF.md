# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 145 (S2-03b sleepers stand and pound) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S2-03 is done (D-156, D-157).** A floor's waking clock starts the first step a player's feet
  are on its level (the floor above is laid early, so not at the lay). Each step `Keepers` asks
  `Waking.now`; picked units are dealt with the door still shut (`Deals:dealShut`), so the
  sleeper stands where a lift would have stood it, awake, and goes straight onto the trapped
  clock: it bangs, dents the door, keepers hear it, it bursts at 90 s; a padlocked door holds it.
  Studio's Workspace `WakeSleepers` skips to the first wave.
- **Verified in Studio Play** (dev floor 3, seed 7): the clock started; the first wave at 225 s
  woke 307, 327, 338, which banged (DoorMotion and DoorDent changing) and burst at 90 s; the
  second at 335 s woke 335 and padlocked 305; 335 burst, 305 gave one last blow and held.
  Output clean but the known asset lines. Not heard: whether players hear the bangs across the
  floor is the owner's (`OWNER.md`). Studio left in Edit.

## Next task: S2-04 A wrong code lets monsters out
The moment: you punch a wrong code, the alarm screams, the hall goes dark, and somewhere a door
rolls up by itself; every monster out there turns for the keypad you're standing at.
1. Read ROADMAP S2-04 and the GDD's "Codes" / wrong-code lines (docs tools, that section only).
   It's big: split it in ROADMAP first, likely (a) which units roll up and the keypad's lock
   growing 3.5, 7, 14 s, (b) the doors rolling up by themselves and loose monsters heading for
   the keypad, (c) the hall lights going out for the alarm (today a wrong code flashes every
   light on: check `MotionLights.flash` and the GDD; a conflict goes in `OWNER.md`).
2. Which units: ones with a monster in them, sleepers first (`Keepers:sleepers`), then dealt
   units holding one; 1 on the first wrong code, 3 on the second, 5 after (count per floor).
   A sleeper's unit rolling up can use `Deals:dealShut` then lift the door, so it stands asleep
   or awake as the deal says, and `lookOut` sends an awake one out.
3. Pure rules in a shared module with a Lune spec; feel numbers in Config with comments.
4. Verify in Studio Play on the dev floor: a wrong code (keypad code is 2274 on seed 7) rolls
   up one monster's door; the keypad stays dead longer each time; Output one line a wrong code.
**Acceptance:** checks green; a spec for the pure part; in Play the first piece works; Output
clean; Studio left in Edit.
**Read first:** ROADMAP S2-04; DECISIONS D-157; `src/server/Elevators.luau` (grep `wrong`,
`alarm`, `dead`, `acted`); `src/server/Keepers.luau` (grep `onKeypad`, `wakeDue`, `onDealt`);
`src/server/Deals.luau` (grep `dealShut`); `src/server/Doors.luau` (grep `function system.move`).

## Queue (next sessions per ROADMAP Phase 2)
1. S2-04 (next), then S2-05. S2-06 and L-08e3c wait on `OWNER.md`. R-01 (Remotes from Brix)
   is for later. Lobby polish waits.
2. Found S2-03b: loose keepers hear a pounding door and go to look, so a wave draws the floor's
   monsters toward the banging units (felt as a feature; watch it). Deals' Studio line for a
   woken unit says "asleep" (the deal's kind) though it stands awake: Output only.
3. Found S2-03a: with waves on, a floor can hold more loose keepers than the director's own cap
   (`Deal.awakeCap`); `Waking.AwakeMost` (six) bounds it. Watch it on a phone.
4. Found S2-02c: only a wandering Mannequin takes the errand; one standing awake that has never
   been out (Watching) doesn't. The dev command sets keepers' states directly (Studio only).
5. Found S2-02b: nobody can throw the breaker by hand; S2-06's light-sticking monster needs "off
   and on again", so its button can grow an Off then. S2-02a: from the box's left its lever
   hides but the grip.
6. Found S1-12: nothing shows a player's saved cash total yet (ROADMAP polish); a climb left
   mid-way makes no cash (D-151, owner's call in OWNER.md).
7. Found S1-11: a friend's beam doesn't show the mark (ROADMAP polish).
8. Found S1-10c2a: Output in Play lists `rbxassetid://203785492` (wrong type) failures and
   texture permission errors; unchecked whether any are the machine's.
9. Small: S1-07b coin piles and batteries show Take through a shut door; S1-09 a kept player's
   torch drains if left on; S1-07a 16 in 100 units hold nothing (owner's call); unseen: S1-06 a
   kept find's save, S1-05 a find can be walked through, S1-04b2 keepers don't know about stuff.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
