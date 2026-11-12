# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-12, session 106 (L-08e1a), night run session 7 of 15 · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-08e1a done (D-119).** `art/lobby/` builds Everkeep's front office (120 by 48, six bays for
  the climb's own landing, glass front, counter and shelves, empty cart rack, striped zones),
  wearing the unit's baked sets and the corridor's deck, joists and walls. Asset 80376262399856,
  template `ReplicatedStorage.Props.Lobby`, place saved (version 33). `src/shared/Lobby` lays it
  (paint, numbers, boxes, hall lights glowing, two fills, porch light, the climb's car untagged in
  each bay); the server's `FrontOffice` lays it at `Lobby.Origin` (0, 0, 600).
- Verified in Studio on a computer and the Galaxy A16: the six cars read from the spawn, Output
  clean but the known lines; the test hall's "Go to the lobby" (R) and the lobby's "Come back" (E)
  both pressed and work. A real phone's frame rate and the colours: `OWNER.md`.
- Studio: left in Edit, play stopped, Device Simulator off, the place saved.

## Next task: L-08e1b1 Step in and the count
The moment: you and a friend run into car 3, the count starts, the last one sprints in at 2 and
the gate slams behind them. Split L-08e1b1 again in ROADMAP first if it won't fit one session.
1. Owner test results first, if pasted.
2. Read ROADMAP L-08e1b1, GDD "The lobby" (its elevators bullet only), D-112 and D-119.
3. Each lobby car a group: a Brix zone over the car (`Departure.carBox`, as the climb's elevator
   does) joins you as you step in and drops you as you step out; the server owns who's aboard.
4. The count: 20 s from the first step in, 5 s once six are aboard; shown on the car (its keypad
   readout and the climb's gate clock, reused, or the keypad hidden: decide, `OWNER.md`). Feel
   numbers in shared config with comments; the pure rules in a Lune-tested module.
5. At zero: the climb's gate slam and sound, the ride's sway and the black (RideView), then the
   group's climb begins on this server as "Walk a floor" does (`Climbs`). Tag or wire the lobby's
   cars only as far as this needs; the climb's own keypad must not wake on them.
6. Players load in at the lobby's spawn facing the cars (turn the camera too: a teleport keeps
   its old look). The test hall goes to Studio only (D-109) once this works; keep its posts there.
**Acceptance:** checks green; in Studio Play, stepping in starts the count on that car, stepping
out leaves, at zero the gate slams and the ride runs, then floor 1 of a climb; you load in at the
lobby; Output clean but 203785492 and the known rbxassethash lines; shots `docs/art/L-08e1b1-*`.
**Read first:** ROADMAP L-08e1b1; DECISIONS D-119 and D-112; `src/shared/Lobby/init.luau`;
`src/shared/Elevator/Departure.luau`; `src/server/Climbs.luau` (begin and the hand-off);
`src/server/Elevators.luau` (how the climb's gate slams and the ride starts).

## Queue (tonight's run order, owner Nov 11 night; ROADMAP Phase 1's order paragraph)
1. L-08e1b1 (next), L-08e1b2 (the host's panel), L-08e1c (a server of the group's own), then
   L-08e2 to L-08e4 (GDD "The lobby", D-112); split L-08e4 into green-ending sessions too (the
   cart's art script first, then the ride).
2. With sessions left: the Seen fixes below, L-18, then honing tonight's work (ROADMAP polish).
   Never new keepers, no store or paid items, proven mechanics only, never edit Brix.
3. Seen: the elevator's gate cache (`posings`, Elevator/init.luau) is a weak table keyed by the
   car, so it rebuilds after each garbage pass (allocates; works); a ladder stood on a floor
   when it's cleared should go with it (untested); anyone still in the car 6 s after it opens is
   shut in (`OWNER.md`'s L-08a decision 2); watching a friend ride doesn't draw their shaft;
   DevCorridor's "Walk a floor" sign keeps the old floor's number after "Again" (Studio only);
   the ladder can't be knocked flat yet (D-107); tools of a player lost below the world land at
   the world's middle with no Pick up (`Slots.dropAll` with no root drops at `Vector3.zero` and
   the prompt never comes back); FlashlightView's and HornView's screens once stayed on with the
   jump hidden (cause unknown, STUDIO.md); Output lines at Play, "rbxassethash://... Requester
   does not have permission for Asset" (cause unknown); turning right round at a run's end the
   crawl stops for about a third of a second before it moves off (D-110's turn-first rule; judge
   with the owner's L-16d test before changing it); the "Alt Cursor" chip showed on the Galaxy
   A16 view at the lobby's spawn (a computer hint on a phone? Studio's simulator has a keyboard);
   Workspace in Edit holds a stray `DoorDent_M` model at the origin (there before session 7).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
