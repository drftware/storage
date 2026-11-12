# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-12, session 107 (L-08e1b1), night run session 8 of 15 · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-08e1b1 done (D-120).** You load in at the lobby (`FrontOffice`'s `LobbySpawn`, the camera
  turned by `LobbyView`); the test hall is Studio only. The six cars are the climb's elevators,
  tagged and marked with their bay; `LobbyCars` (server) joins you by a Brix zone, runs the count
  on the climb's gate clock (`Boarding`: 20 s, 5 when six aboard), lays floor 1 out of play as a
  count starts (`Climbs:ready`) and at zero hands the ride to floor 1's car (`Climbs:board`,
  sharing `carry` with every floor's hand-off). The count: on screen for the group only, on the
  car's keypad readout for the room; keypad prompt gone; "L" on the floor readouts.
- Verified in Studio Play, one player on a computer: load-in facing the cars, step in (count),
  step out (stops), zero (slam, ride, L to 1), floor 1 of a fresh climb, the car back in its bay,
  another car held while that climb ran. Output clean but the known lines. Phone and friends:
  `OWNER.md`.
- Studio: left in Edit, play stopped, nothing imported, place not changed.

## Next task: L-08e1b2 The host's panel
The moment: first into car 3, you tap the panel, flip it to Friends only and 2 players, and hit
Go the second your friend is through the gate. Split it in ROADMAP first if it won't fit.
1. Owner test results first, if pasted.
2. Read ROADMAP L-08e1b2, GDD "The lobby" (its elevators bullet only) and D-120.
3. The host is the group's first (`Boarding` group[1]); if they step out, the next one hosts.
   Pure rules in `Boarding` (Lune): who hosts, the settings' ranges, who may join under them.
4. The panel: the car's keypad (`KeypadPad` skips lobby cars today) gets the host a prompt that
   opens a phone-first panel: Open / Friends only, 1 to 6 players, the difficulty (one only;
   say so in `OWNER.md`), Go. Everyone else aboard sees the choices, greyed. Copy: one word a
   control. Each change answers (motion, a click, the readout).
5. One remote, checked in order: types, range (in the car, the host), rate. Settings replicate
   on the car. Go is `Elevators:count(car, now)`. "Friends only" uses `Player:IsFriendsWith`
   (yields: ask once as someone steps in, cache it); a refused join needs a cause on screen.
**Acceptance:** checks green; in Studio Play the host's prompt opens the panel, each choice
shows on the car, Go slams the gate at once and the ride runs to floor 1; Output clean but
203785492, 120448020095820 and the known rbxassethash lines; shots `docs/art/L-08e1b2-*`.
**Read first:** ROADMAP L-08e1b2; DECISIONS D-120; `src/server/LobbyCars.luau`;
`src/shared/Lobby/Boarding.luau`; `src/client/KeypadPad.luau` (its prompt and pad);
`src/client/ButtonView.luau` (how prompts are drawn, if a new prompt is needed).

## Queue (tonight's run order, owner Nov 11 night; ROADMAP Phase 1's order paragraph)
1. L-08e1b2 (next), L-08e1c (a server of the group's own), then L-08e2 to L-08e4 (GDD "The
   lobby", D-112); split L-08e4 into green-ending sessions too (the cart's art script first,
   then the ride).
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
   Workspace in Edit holds a stray `DoorDent_M` model at the origin (there before session 7);
   everyone on the server counts in a climb's end, even someone who stayed in the lobby (until
   L-08e1c and L-08e2); you hold the flashlight out in the lobby (put it away there?).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
