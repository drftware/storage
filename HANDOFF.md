# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-12, session 112 (L-08e4a), evening run session 2 · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-08e4a done (D-125).** The platform cart, built the unit's way (`art/cart/`,
  `scripts/art.sh cart`): worn safety-orange steel, a rubber mat, a U handle with a foam grip,
  bumpers, 6-inch casters. Seven MeshParts on one 1024 set: the body, `CartForkL`/`R` (front
  swivel forks), four `CartWheel*`; `Cart.Specs` gives each caster's kingpin and axle. At
  `ReplicatedStorage.Props.Cart` (prepared); `Lobby.lay` parks one nose-in at each rack slot
  (`Cart.park`, `Lobby.Parked`), anchored, a `Deck` box to bump and step on.
- Verified in Studio Play from the spawn and up close (`docs/art/L-08e4a-*.jpg`); Output clean;
  Studio left in Edit.

## Next task: L-08e4b The ride
The moment: you kick a platform cart across the lobby while the count runs and roll up to the
gate as it shuts. On the carts L-08e4a parks. If it won't fit one session, split it in ROADMAP
first (say e4b1 ride, kick and coast; e4b2 bumps, hop off at a gate, the roll home).
1. Owner test results first, if pasted. Read ROADMAP L-08e4 and the GDD's "The lobby" (the cart
   ride), then `src/shared/Cart/init.luau` and its Specs.
2. A pure core with Lune specs (`src/shared/Cart/Ride.luau`?): the kick's rhythm while forward is
   held (each kick a push, no tapping), coasting to a stop, the speed cap, the turn, a bump's
   stop (never a launch). Feel numbers in Config, each commented.
3. Ride: a one-verb prompt on each parked cart ("Ride"); the server gives it to one rider and
   unanchors it to the rider's client, which moves it; the server caps its speed and takes it back
   on hop-off, leave or death. Jump hops off. Your back leg kicks in rhythm (an animation), the
   wheels spin by `WheelRadius`, the front forks swing to trail the way it rolls (`Casters`).
4. Feedback: the casters' rumble rising with speed, the kick's scuff, a bump's clank. At a gate
   you hop off; the cart rolls home to its slot (`CartSlots`, `Parked`), never through a player.
**Acceptance:** checks green; Lune specs for the core; Studio Play: ride a cart round the lobby,
kick, coast, turn, bump a wall and a cart (no launch), hop off, watch it roll home; Output clean
but 203785492, 120448020095820 and the known rbxassethash lines. Two riders: OWNER.md.
**Read first:** ROADMAP L-08e4; GDD "The lobby"; `src/shared/Cart/init.luau` and `Specs.luau`;
`src/shared/Lobby/init.luau` (`Parked`, the carts in `lay`); STUDIO.md "Camera and prompts".

## Queue (the evening run, owner Nov 12: lobby sessions until 8pm; ROADMAP Phase 1's order paragraph)
1. L-08e4b (next), in green-ending sessions. Then L-08e3b Share and follow.
2. Time left before 8pm: hone the lobby (ROADMAP polish, e.g. "The dials' finish"); Seen fixes
   wait. No new keepers.
3. Seen (owner, Nov 12, "fix them later"): lobby car floors go splotchy as the camera moves
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
   (put it away there?); the panel's host line is blank if the host's Player isn't found; the
   turned-away headline sits over the far wall, red on teal; screen captures right after Play
   show the lobby nearly black for several seconds (lighting); the rack sits behind you at the
   spawn (you face the cars), so the carts are seen only once you turn round.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
