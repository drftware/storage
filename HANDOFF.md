# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-12, session 108 (L-08e1b2), night run session 9 of 15 · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-08e1b2 done (D-121).** The first one into a lobby car hosts. A "Host" button inside the
  car on the keypad's side (others aboard: "View") opens `CarPanel`: Open / Friends, the player
  count over six seats, Normal (the only difficulty), Go; greyed for all but the host. One remote
  (`Remotes.CarPanel`: types, range, rate, then `Boarding`'s rules); the choices replicate on the
  car (`FriendsOnly`, `Players`). Go runs the count out now. A stranger the choices close a car to
  is set down outside with "Car full" or "Friends only" (`IsFriendsWith` asked once, kept).
- Verified in Studio Play, one player on a computer: the panel opens on E, Friends and 2 land on
  the car, the ride runs with them; Go shuts the gate at once and the ride reaches floor 1; a held
  count greys Go; the greyed view and the headline on this screen alone. Output clean but the
  known lines. Two players and a phone: `OWNER.md`.
- Studio: left in Edit, play stopped, nothing imported, place not changed.

## Next task: L-08e1c A server of the group's own
The moment: the gate slams on you and two friends, the shaft slides by, and you open on floor 1
of a building that's only yours: nobody else's climb, nobody else's end.
1. Owner test results first, if pasted.
2. Read ROADMAP L-08e1c, `docs/FRAMEWORK.md`'s ENG-13 row, D-120 and D-121. Check `../engine`
   (read only, never edit it) for a teleport or match piece at our pin.
3. Smallest stand-in if Brix has none: at the post, the server reserves a server
   (`TeleportService:ReserveServer`, verify on create.roblox.com and note it in STUDIO.md) and
   teleports the riders with TeleportData: who's in the group, the host, the difficulty
   (`Boarding.Difficulties`). Write the missing piece for Brix in FRAMEWORK.md and OWNER.md in
   neutral terms (tonight nobody edits Brix).
4. The reserved server knows it's one (`game.PrivateServerId ~= ""` and no owner) and starts the
   climb on floor 1 for those who arrive, no lobby cars there; a public server keeps the lobby.
5. A failed trip (`TeleportInitFailed`): everyone back in the car, a short headline, the count
   again. Studio can't teleport: there the ride stays on this server as now (D-120), so Studio
   play keeps working.
**Acceptance:** checks green; Studio Play still rides from a car to floor 1 on this server with
Output clean but 203785492, 120448020095820 and the known rbxassethash lines; the live trip
written into `OWNER.md` as exact steps (it's the owner's to run on live servers).
**Read first:** ROADMAP L-08e1c; FRAMEWORK.md's ENG-13 row; DECISIONS D-120, D-121;
`src/server/LobbyCars.luau` (`departed`); `src/server/Climbs.luau` (`ready`, `board`).

## Queue (tonight's run order, owner Nov 11 night; ROADMAP Phase 1's order paragraph)
1. L-08e1c (next), then L-08e2 to L-08e4 (GDD "The lobby", D-112); split L-08e4 into
   green-ending sessions too (the cart's art script first, then the ride).
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
   stray `DoorDent_M` model at the origin; everyone on the server counts in a climb's end, even
   someone who stayed in the lobby (until L-08e1c and L-08e2); you hold the flashlight out in
   the lobby (put it away there?); the panel's host line is blank if the host's Player isn't
   found (left mid-update); the turned-away headline sits over the room's far wall, red on teal.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
