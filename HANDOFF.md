# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-12, session 103 (L-20a), night run session 4 of 15 · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-20a done (D-116).** Three slots (`Carry.Slots`). ToolView's bar is gone: a round button at
  the bottom middle (a dot per slot), a wheel of slots fanning out over it with a tick each
  (tap, click, or Q on a computer, which frees the mouse), a box beside it showing the slot your
  hand is on (tap: put the tool away or bring it up), Drop after the box, HornView's Blow (on a
  computer) on the button's left. 1/2/3 pick, a second press puts away; d-pad steps, up puts
  away, down drops. Pure shape and rules: `src/shared/Tools/Wheel.luau` (Lune-checked).
- "Put away" is the server's: `Carry.pocketed`, attribute `ToolPocketed`, remote `ToolPocket`;
  `Slots.carried` gives the hand as 0 while pocketed, so Lock, Cut, Saw, Lean, Give see an empty
  hand. The ladder can't be put away.
- The button's top on the A16 (270) is no higher than the old slots' (267): `DoorSpot.Below`
  unchanged; Peek measured at 233 to 235.
- Verified in Studio (computer and Galaxy A16): shots in `docs/art/L-20a-*.jpg`.
- Studio: left in Edit, Device Simulator off, nothing imported.

## Next task: L-17 Every button on a phone at once
The moment: on a phone in the worst crowd (kept and banging, or at a door with a horn up, the
wheel open), every button is where your thumb expects it and nothing hides another.
1. Owner test results first, if pasted.
2. Read ROADMAP L-17 and the polish note "The held tool behind a door's low buttons (L-19b)".
3. In Studio on the Galaxy A16 (device calls and click mapping in docs/STUDIO.md), set up and
   capture each crowd: (a) kept with the Bang button up (`ServerStorage.CatchTest`, STUDIO.md
   "Testing a catch anywhere"); (b) a horn up at a shut and an open door, torch and jump showing,
   the map in its corner; (c) the wheel open by a door. Captures skip BillboardGuis: use the
   mirror trick (STUDIO.md "Seeing a BillboardGui in a capture").
4. Fix what overlaps or doesn't read. Known: the kept player's wheel button and box under the
   Bang button (CaughtView `placeButton`); hide the wheel while kept if it clutters (WatchView's
   `HUD` list hides "Slots" only once your legs give up).
5. Rename HornView's round button, which carries every verb tool's press, to `UseButton` (its
   ScreenGui and the button's Name; CODEMAP and comments follow).
6. Judge the held torch behind Cut on a phone (the L-19b note); lower the hand a touch while a
   door's buttons show only if it hides a chip.
**Acceptance:** checks green; captures of each crowd on the A16 with nothing overlapping;
`UseButton` renamed; Output clean but 203785492 and the known rbxassethash lines. Live phone
and two players go to `OWNER.md`.
**Read first:** ROADMAP L-17; `src/client/CaughtView.luau` (header, `placeButton`);
`src/client/HornView.luau` (`placeButton`, `makeButton`); `src/client/ToolView.luau` (`layout`);
docs/STUDIO.md "The Galaxy A16's screen, measured" and "The wheel on the A16".

## Queue (tonight's run order, owner Nov 11 night; ROADMAP Phase 1's order paragraph)
1. L-17 (next), L-16d the tops still jitter on a computer.
2. The lobby, L-08e1 to L-08e4 (GDD "The lobby", D-112), no longer waiting on L-09a: split
   L-08e1 and L-08e4 into sessions that each end green (the room's art script first, then the
   cars, the joining and the count, then the trip to a server of the group's own).
3. With sessions left: the Seen fixes below, L-18, then honing tonight's work (ROADMAP polish).
   Never new keepers, no store or paid items, proven mechanics only, never edit Brix.
4. Seen: the elevator's gate cache (`posings`, Elevator/init.luau) is a weak table keyed by the
   car, so it rebuilds after each garbage pass (allocates; works); a ladder stood on a floor
   when it's cleared should go with it (untested); anyone still in the car 6 s after it opens is
   shut in (`OWNER.md`'s L-08a decision 2); watching a friend ride doesn't draw their shaft;
   DevCorridor's "Walk a floor" sign keeps the old floor's number after "Again" (Studio only);
   the ladder can't be knocked flat yet (D-107); tools of a player lost below the world land at
   the world's middle with no Pick up (`Slots.dropAll` with no root drops at `Vector3.zero` and
   the prompt never comes back; Studio test teleports found it); Output lines at Play,
   "rbxassethash://... Requester does not have permission for Asset" (cause unknown).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
