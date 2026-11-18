# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, the room editor and recipe plan (D-436) · **Checks:** green · **Git:** `main`, not pushed; Brix `7f25310`.

## State
- **The owner's new priority (D-436):** rebuild Arrange into a room editor with The Sims' level
  of control (S5-03j), then a recipe system so finds change other finds, data only (S5-03k).
  The plan: Claude Doc https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (read only the section
  your ticket names, with the docs tools). Tickets in ROADMAP under S5-03j and S5-03k, with
  Brix's ENG-26c, ENG-27, ENG-28 and ENG-29. Order: ENG-27, ENG-28, S5-03j1, ENG-26c, j2 to j7,
  ENG-29, k1 to k6.
- **L-11a2 done** (D-435): off, your torch drops out of view and comes back up lit; the phone
  switch sits right of the (moved) jump button. Phone and iPad checks: OWNER.md.
- **The home (S5-03) a to i is done**; its three "Polish:" lines under S5-03g2b wait (Queue).
- Studio hooks: `CardTest`; `ShelfTest` "take"; `ArrangeTest` "take", "own", "place", "rows",
  "fromShelf", "shelfAway", "size"; `GrowTest` "cash"; Trips' `DevTripFinds`. Home doc:
  https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww. Test save: Medium, card Stencil (Unit1),
  cash 38, no card styles owned, Boombox 10, Skates 1.
- **Climb run (on hold until S5-03j and k are done, the owner, Nov 18):** left: S5-01d's held
  torch over the car's board, S5-02b2c2, then S4-06, S4-07, S5-04, S5-06.

## Next task: ENG-27 Gestures, in Brix (the first piece of S5-03j)
The room editor's input reader: every finger, mouse and gamepad event in, one clear intent out,
so the camera and the dragging never fight over a touch. Built in `../engine` by Brix's own
AGENTS.md (neutral names, its checks, its own commit), then the game's pin moves (D-252).
1. Read Brix's AGENTS.md and HANDOFF.md, and one existing contract as the pattern
   (`../engine/src/Contracts/Placements.luau`). Add ENG-27 to Brix's ROADMAP.
2. Write the contract and its suite first: pointer events in (id, screen position, began,
   moved or ended, time; mouse buttons and wheel; gamepad sticks as their own events); intents
   out: tap, double tap, hold, drag (on a thing or on empty floor, asked of the game through a
   function it passes in), pinch (scale), twist (angle), two-finger slide (tilt), with slop
   and timing numbers the game can set. A second finger joining a drag on a thing becomes a
   twist of that thing, not a camera pinch. Pure, no Roblox services.
3. Implement until the suite passes; a module page in Brix's `docs/modules/`.
4. Commit in Brix; move `vendor/brix` to it in the game; note it in `docs/FRAMEWORK.md`.
**Acceptance:** each promise fails its suite when broken; `scripts/check.sh` green here and
Brix's checks green there; nothing in the game uses it yet (S5-03j1 wires it).
**Read first:** the doc's "How it's built" section; ROADMAP's S5-03j block (grep `S5-03j`);
`../engine/AGENTS.md`; `../engine/src/Contracts/Placements.luau`; `docs/FRAMEWORK.md`;
`src/client/ArrangeView.luau` 2148-2230 (today's touch handling).

## Queue (next sessions, the owner's ticket order)
0. After S5-03j and k: the home's three "Polish:" lines under S5-03g2b (the hand-over's shade,
   D-326, D-327; the mirror keeping the old look; the floor's wipe under the tray, D-328), then
   g3b's plate swapping in plays (ROADMAP's "Polish (g3b)").
1. Small's doorway's inside boards are oak, not the picked paint (D-355). Sitting's leftovers
   (D-353): cross-legged on the blanket needs our own animation; lying on the bed.
2. Home leftovers: a lamp left on kept through a rejoin (D-351); a lit find taken comes unlit;
   the cubby finds' own buttons; a friend's take shows before the flying copy lands; the steel
   shelf's lower tiers; Arrange shows the job box's "Open" and the door's buttons; a lifted lit
   piece's light; a grow while Arrange is open closes it (D-356); Robux unit and gift cards
   unseen; the XL limit bar; Take through a wall; a refused cubby place (D-352). A taken-out
   find comes out whole even when the save has it cracked. Several of these may fall out of
   S5-03j's rebuild: check each against it before building.
3. The home's warm fill (D-290): faces turned from the bulb go near black. Brix (in
   `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a PlayerSaves hook
   before a leaving save's last write.
4. The item catalog and design docs' finds need D-250, D-251, D-259, D-277, D-297, D-299 to 361.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. A spare home unpadlocked
   (D-275); the hat's first-Wear dark screen; the body after a respawn (D-282); late arrivals
   off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error. Counter and job
   box cash isn't sent to analytics. One `CaughtSeized` string. Lobby sheets: no plates.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
