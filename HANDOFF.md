# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-12, session 109 (L-08e1c), night run session 10 of 15 · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-08e1c done (D-122).** At the post a car's riders fade to black ("Going up") and are sent in
  one `TeleportAsync` to a new reserved server (`ReservedServerId`, a GUID), group and difficulty
  as checked data (`Trip`). That server (`Trips:own()`) lays floor 1, waits for the group (or
  10 s), stands them in its car 3.4 s into its ride (`Elevators:ride`, `Climbs:arrive`); the
  black lifts on the shaft. Failed trip: back in the car, "Teleport failed", the count again; two
  in a row and the lobby rides groups up on its own server. Studio rides on its own server;
  Workspace `DevTrip` "Arrive" / "Send" / "Fail" tries the rest (STUDIO.md).
- Verified in Studio, one player: the ride here; the arrival; the whole trip through Studio's
  test teleport; two failed trips then the ride here. Output clean but the known lines.
- Studio: left in Edit, play stopped, `DevTrip` cleared, nothing imported. The place was saved
  (version 34, never published) so the test teleport's server ran tonight's code.
- `rojo serve` didn't pick up the new `ReplicatedFirst` entry (read at start only): `OWNER.md`.

## Next task: L-08e2 Back in your car
The moment: the climb ends and you're standing in the same car with the same friends, results on
the wall, the count running for another go.
1. Owner test results first, if pasted.
2. Read ROADMAP L-08e2 and the GDD's "The lobby" (results on the wall); D-106 (the end), D-122.
3. Default (OWNER.md if the GDD says otherwise): on a group's own server the front office's cars
   open too (`LobbyCars` with `Trips:sends()` false there, so they ride up on that server, as in
   Studio); the trip's data carries the bay (`Trip.Version` 2, `decode` still reads 1).
4. At the end, instead of `ClimbEnds.go`'s fresh floor 1: everyone in the climb back in the car
   they left from (its bay), stood at `Trip.spot`, joined in their old order (host first, the
   choices kept), its count running; the results on the car's back wall (a SurfaceGui, phone
   size), the end's screen out of the way. Anyone can step out and back in.
5. Same on a lobby server where the climb rode up (Studio, or the fallback).
**Acceptance:** checks green; Studio Play: ride up from a car, end the climb (a dev way, e.g.
DevCorridor), stand in the same car with the count and the results, step out and in, ride again;
Output clean but 203785492, 120448020095820 and the known rbxassethash lines.
**Read first:** ROADMAP L-08e2; GDD "The lobby"; DECISIONS D-106, D-122;
`src/server/ClimbEnds.luau` (`go`); `src/server/LobbyCars.luau`.

## Queue (tonight's run order, owner Nov 11 night; ROADMAP Phase 1's order paragraph)
1. L-08e2 (next), then L-08e3 and L-08e4 (GDD "The lobby", D-112); split L-08e4 into
   green-ending sessions (the cart's art script first, then the ride).
2. With sessions left: the Seen fixes below, L-18, then honing tonight's work (ROADMAP polish).
   Never new keepers, no store or paid items, proven mechanics only, never edit Brix.
3. Seen: the elevator's gate cache (`posings`, Elevator/init.luau) is a weak table keyed by the
   car, so it rebuilds after each garbage pass (allocates; works); a ladder stood on a floor
   when it's cleared should go with it (untested); anyone still in the car 6 s after it opens is
   shut in (`OWNER.md`'s L-08a decision 2); watching a friend ride doesn't draw their shaft;
   DevCorridor's "Walk a floor" sign keeps the old floor's number after "Again" (Studio only);
   the ladder can't be knocked flat yet (D-107); tools of a player lost below the world land at
   the world's middle with no Pick up (`Slots.dropAll` with no root drops at `Vector3.zero`);
   FlashlightView's and HornView's screens once stayed on with the jump hidden (cause unknown,
   STUDIO.md); Output lines at Play, "rbxassethash://... Requester does not have permission for
   Asset" (cause unknown); turning right round at a run's end the crawl stops for about a third
   of a second (D-110's turn-first rule; judge with the owner's L-16d test first); the "Alt
   Cursor" chip showed on the Galaxy A16 view at the lobby's spawn; Workspace in Edit holds a
   stray `DoorDent_M` model at the origin; in Studio (and a fallback lobby) everyone on the
   server counts in a climb's end, even someone who stayed in the lobby (live trips fix it);
   you hold the flashlight out in the lobby (put it away there?); the panel's host line is blank
   if the host's Player isn't found; the turned-away headline sits over the room's far wall, red
   on teal; on a Studio test server made a group's own, LobbyCars has already opened its cars
   (harmless, Studio only).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
