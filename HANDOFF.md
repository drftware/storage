# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-12, session 110 (L-08e2), night run session 11 of 15 · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-08e2 done (D-123).** Again now leads back to the car the climb left from: the group in its
  old order with the host's choices, facing the results board on the back wall (`CarResults`),
  the full 20 s count running; anyone can step out and in; the board goes as the car leaves. On a
  group's own server the trip's data (`Trip.Version` 2) names the car, its cars open once the
  group is home (`Trips:home`, `LobbyCars:home`/`welcome`) and the next climb rides up there.
  The black lifts with the count's chime, the camera turned to `ClimbEnd.StoodAttribute`.
- Verified in Studio, one player: Studio's own server (car 3: ride, wipe, Again, back, out and
  in, ride again) and a group's own ("Arrive": back in car 1, ride again there). Output clean but
  the known lines. Studio: Edit, play stopped, `DevTrip` cleared, place saved as version 35 (for
  Studio's test teleport), never published.

## Next task: L-08e3 Invite and the dials
The moment: a friend's not here, so you tap Invite on the car's panel and they're on their way;
from the door every car tells you who's in it, and a player alone is pointed to the fullest.
1. Owner test results first, if pasted. Read ROADMAP L-08e3, the GDD's "The lobby", D-121, D-123.
2. Verify on create.roblox.com, and note in STUDIO.md: `SocialService:PromptGameInvite` with
   `ExperienceInviteOptions` (and `CanSendGameInviteAsync`), and Roblox's share links for an
   experience (what Audience Expansion counts). Never invent an API.
3. Invite on the host's panel (CarPanel; any of the group may invite: a sensible default, in
   OWNER.md), one verb, with its feedback (press, Roblox's sheet, a toast if it can't).
4. A dial over each car (a SurfaceGui above its gate, phone-readable from the door): the
   group's photos or count while it's open; "Floor N" while a group it took climbs on this
   server. Floors climbed on other servers need MessagingService: if that won't fit, the dial
   says "Climbing" and the floor goes to ROADMAP as its own ticket.
5. A player alone in the lobby (in no car) is pointed to the fullest open car that will take
   them (a soft marker on it), gone once they step in. Too big? Split in ROADMAP first.
**Acceptance:** checks green; Studio Play: the panel's Invite opens Roblox's invite (or says why
not in Studio), the dials show who's in each car and update as you step in and out, a lone
player's marker points at the fullest car; Output clean but 203785492, 120448020095820 and the
known rbxassethash lines.
**Read first:** ROADMAP L-08e3; GDD "The lobby"; DECISIONS D-121, D-123;
`src/client/CarPanel.luau`; `src/server/LobbyCars.luau` (`publish`).

## Queue (the evening run, owner Nov 12: lobby sessions until 8pm; ROADMAP Phase 1's order paragraph)
1. L-08e3 (next), then L-08e4 (GDD "The lobby", D-112) in green-ending sessions, art first.
2. Time left before 8pm: hone the lobby (ROADMAP polish); Seen fixes wait. No new keepers.
3. Seen (owner, Nov 12, "fix them later"): lobby car floors go splotchy as the camera moves
   inside; a sawn side or top flashes see-through as its panel drops (the swap to the holed
   model? `TopHole.saw`, `CrawlHole.saw`), must be seamless. Older: a lobby car's lamp burns at 0.14 of 1.2 in its bay on the client (ElevatorView's
   `lampAt`/`showLamp`; cause not found), so inside a car its walls read black round the results
   board; the elevator's gate cache (`posings`, Elevator/init.luau) is a weak table keyed by the
   car, so it rebuilds after each garbage pass; a ladder stood on a floor when it's cleared
   should go with it (untested); anyone still in the car 6 s after it opens is shut in
   (`OWNER.md`'s L-08a decision 2); watching a friend ride doesn't draw their shaft; DevCorridor's
   "Walk a floor" sign keeps the old number after "Again"; the ladder can't be knocked flat
   (D-107); tools of a player lost below the world land at
   the world's middle with no Pick up (`Slots.dropAll` with no root drops at `Vector3.zero`);
   FlashlightView's and HornView's screens once stayed on with the jump hidden (cause unknown,
   STUDIO.md); Output lines at Play, "rbxassethash://... Requester does not have permission for
   Asset" (cause unknown); turning round at a run's end the crawl stops a third of a second
   (D-110); the "Alt Cursor" chip shows at the lobby's spawn; a stray `DoorDent_M` model sits at
   the origin in Edit; in Studio
   (and a fallback lobby) everyone on the server counts in a climb's end, even someone who stayed
   in the lobby (Again now sends them to the front door); you hold the flashlight out in the
   lobby, over the results (put it away there?); the panel's host line is blank if the host's
   Player isn't found; the turned-away headline sits over the far wall, red on teal.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
