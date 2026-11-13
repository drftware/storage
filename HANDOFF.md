# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-12, session 113 (L-08e4b1), evening run session 3 · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-08e4b1 done (D-126).** Tap Ride: you stand on the deck facing the handle; it heads where
  you look, your back leg kicking in rhythm (pure `Cart.Ride`, Lune specs). Server `Carts` rigs
  each cart, hands it to the rider's screen, watches its pace and place; `CartRide` rolls it
  (swept box: clank, scrape) and hops you off at a car's stripes; `CartView` spins the wheels,
  swings the casters, rattles with speed, stands the rider. Jump hops off; the cart coasts and
  parks where it stopped (not home yet). Verified in Studio Play (one player, a computer): out of
  the rack, kicks to 21 a second, a clank at a wall, a turn off it, Jump, the coast and park, the
  stripes. Output clean but 203785492. Studio left in Edit.

## Next task: L-08e4b2 Home again
The moment: you hop off at a car's stripes as the gate's about to shut, and behind you the cart
rolls itself back to the rack. If it won't fit one session, split it in ROADMAP first.
1. Owner test results first, if pasted. Read the Read-first list.
2. A pure core with Lune specs (in `Cart.Ride` or a new `Cart.Home`): the way home from where a
   cart stands to a free slot (`Lobby.Specs.CartSlots`), rolling handle first then easing in nose
   first as parked (`Lobby.Parked`); its pace (slower than a ride), a pause while anyone stands
   in its way, a give-up (put it in its slot) if it can't get there.
3. Server: a cart left at the stripes, or standing unridden a while anywhere (a sensible wait;
   OWNER.md), starts home: the server publishes the way and its start time on the cart, every
   screen draws it along that (CartView, no per-frame replication); the server anchors it in its
   slot at the end, its button back. No Ride while it's going home (a default).
4. Feedback: the rattle along the way, a soft clunk as it noses into the rack.
**Acceptance:** checks green; Lune specs for the way home; Studio Play: hop off at a car's
stripes and watch the cart roll home and park; one left mid-room goes home after the wait; stand
in its way and it waits; Output clean but 203785492 and the known rbxassethash lines.
**Read first:** ROADMAP L-08e4b2; DECISIONS D-126; `src/server/Carts.luau`;
`src/client/CartView.luau`; `src/shared/Lobby/init.luau` (`Parked`, the carts in `lay`);
STUDIO.md "Testing a cart ride from the MCP".

## Queue (the evening run, owner Nov 12: lobby sessions until 8pm; ROADMAP Phase 1's order paragraph)
1. L-08e4b2 (next), in green-ending sessions. Then L-08e3b Share and follow.
2. Time left: hone the lobby (ROADMAP polish: "The ride's finish", "The dials' finish"). No keepers.
3. Found L-08e4b1: no PlayerModule in PlayerScripts in Play (STUDIO.md), so WatchView's
   `controls` lookup fails quietly (controls may stay on while you watch; untested).
4. Seen (owner, Nov 12, "fix them later"): lobby car floors go splotchy as the camera moves
   inside; a sawn side or top flashes see-through as its panel drops (the swap to the holed
   model? `TopHole.saw`, `CrawlHole.saw`), must be seamless. Older: a lobby car's lamp burns at
   0.14 of 1.2 in its bay on the client (ElevatorView's `lampAt`/`showLamp`; cause not found), so
   inside a car its walls read black round the results board; the elevator's gate cache
   (`posings`, Elevator/init.luau) is a weak table keyed by the car, so it rebuilds after each
   garbage pass; a ladder stood on a floor when it's cleared should go with it (untested); anyone
   still in the car 6 s after it opens is shut in (`OWNER.md`'s L-08a decision 2); watching a
   friend ride doesn't draw their shaft; DevCorridor's "Walk a floor" sign keeps the old number
   after "Again"; the ladder can't be knocked flat (D-107); tools of a player lost below the
   world land at the world's middle with no Pick up (`Slots.dropAll` with no root drops at
   `Vector3.zero`); FlashlightView's and HornView's screens once stayed on with the jump hidden;
   Output lines at Play, "rbxassethash://... Requester does not have permission for Asset" (cause
   unknown); turning round at a run's end the crawl stops a third of a second (D-110); the "Alt
   Cursor" chip shows at the lobby's spawn; a stray `DoorDent_M` model sits at the origin in
   Edit; in Studio (and a fallback lobby) everyone on the server counts in a climb's end, even
   someone who stayed in the lobby; you hold the flashlight out in the lobby, over the results
   and while riding a cart (put it away there?); the panel's host line is blank if the host's
   Player isn't found; the turned-away headline sits over the far wall, red on teal; screen
   captures right after Play show the lobby nearly black for several seconds (lighting); the
   rack sits behind you at the spawn (you face the cars), so the carts are seen only once you
   turn round.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
