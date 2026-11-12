# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-12, session 111 (L-08e3), evening run session 1 · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-08e3 done (D-124).** A dial over each lobby car's gate (`CarDial`, client): the bay's
  number, three seats either side (photos in warm rings, sockets for room), one line ("Friends
  only", "Full", "Going up", "Floor N" from LobbyCars' `ClimbFloor` while its group climbs here).
  A player in the front office in no car is pointed to the fullest car that takes them
  (`Boarding.fullest`): its rim and your seat breathe warm, a chevron bobs in its doorway.
  Invite beside Go on the car's panel for anyone aboard (Roblox's sheet; launch data marks the
  joiner `InvitedBy`, whose pointer prefers that car); hidden on a group's own server.
- Split out: **L-08e3b Share and follow** (share link, invites from a group's own server, the
  dial's floor from other servers). L-08e4 split into **e4a** (the cart's art) and **e4b** (ride).
- Verified in Studio, one player, other cars faked; Output clean. Studio in Edit, play stopped.

## Next task: L-08e4a The cart, built the unit's way
The moment (for e4b): you kick a platform cart across the lobby while the count runs. This
session builds the cart itself, parked in the rack by the door, so it reads as a real storage
office's platform cart from the spawn on a phone.
1. Owner test results first, if pasted. Read ROADMAP L-08e4 and the GDD's "The lobby" (the
   cart ride), then `art/unit/README.md` (the recipe) and a small script to copy (`art/ladder/`).
2. `art/cart/`: `spec.py` (a 2.2 by 4.3 stud deck as the rack was sized for, `art/lobby/spec.py`
   `RACK_*`; a push handle at the back; four casters, the front pair swivelling, wheels as
   their own parts for e4b to spin), `build.py`, baked PBR maps on shared sets, the FBX, a
   generated `src/shared/Cart/Specs.luau`, look sheets (hero, in the rack, phone-size from the
   door). Build with `scripts/art.sh`.
3. Import it as `ReplicatedStorage.Props.Cart` (STUDIO.md's FBX recipe and Blender traps); the
   front office parks one nose-in at each `Lobby.Specs.CartSlots` (in `Lobby.lay`).
4. Judge it in Studio Play at phone size from the spawn and up close; fix and rebuild.
**Acceptance:** checks green; the art builds headless; Studio Play shows a cart in every rack
slot, at the rack's scale, textured, nothing floating or clipping; Output clean but
203785492, 120448020095820 and the known rbxassethash lines. Upload help needed? OWNER.md.
**Read first:** ROADMAP L-08e4; GDD "The lobby"; `art/unit/README.md`; `art/ladder/build.py`
(a small script to copy); `art/lobby/spec.py` (the rack); STUDIO.md "Getting assets into Roblox".

## Queue (the evening run, owner Nov 12: lobby sessions until 8pm; ROADMAP Phase 1's order paragraph)
1. L-08e4a (next), then L-08e4b (the ride), in green-ending sessions. Then L-08e3b.
2. Time left before 8pm: hone the lobby (ROADMAP polish, e.g. "The dials' finish"); Seen fixes
   wait. No new keepers.
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
   Player isn't found; the turned-away headline sits over the far wall, red on teal; screen
   captures right after Play show the lobby nearly black for several seconds (lighting).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
