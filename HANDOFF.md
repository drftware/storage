# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-11, session 101 (L-19a), night run session 2 of 15 · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-19a done (D-114).** Every button in the world is `Style` Custom and drawn by the new client
  system `ButtonView` in the pure `WorldButton` look: a round key chip (key, pad picture, or a
  dot on a phone at 48 points), the verb beside it, the name only where it's news and once per
  row; swells in, blinks out, a hold ring, a press pop. A refusal now goes to the presser alone
  (`Prompts.refuser(p)` gives `(text, player)`, `Remotes.Refused`) and shakes the button red
  with its words and a dull tick. `ButtonReach` is folded in as `ButtonView.hide`.
- Names dropped where plain to see: doors (but "Padlocked" while locked), the ladder, Lean, Drop
  down. Kept: Drop in, Crawl, Saw, Pick up, Cut free, Give, test posts.
- Verified in Studio (computer and Galaxy A16): shots in `docs/art/L-19a-*.jpg`. Captures skip
  BillboardGuis; docs/STUDIO.md has the mirror trick and the A16 click mapping.
- Studio: left in Edit, Device Simulator off, nothing imported.

## Next task: L-19b A door's buttons where your hand would go
The moment: at a shut door your thumb finds Open on the door's middle and Peek low by the
ground, like reaching for the handle; at an open door Close and Slam sit side by side in the
middle; the padlock's Lock and the cutters' Cut sit on the latch where the hand goes.
1. Owner test results first, if pasted.
2. Read ROADMAP L-19b and D-114. Doors today: three buttons on one `DoorButtons` attachment,
   spaced by `UIOffset` (`Door.Slots` times `SLOT_PIXELS` 150, sized for Roblox's old box).
3. Give each button its own point on the door (an Attachment per place: middle, low, latch,
   inside), set in `Doors.add` from `RollUpDoor.frame` and the spec's latch; keep `Door.Slots`'
   promise that a tapped spot is empty after the tap (no double tap firing another button).
4. In first person a point more than 35° below your gaze is off screen and hides its button
   (docs/STUDIO.md "Camera and prompts"): check Peek low still shows from where you stand to use
   it, on a phone too; raise it as little as needed.
5. KneelView brings the door's buttons down with your peek: move whichever points need it.
   ToolView (`works()`) and LadderView read door buttons too; grep `DoorButtons`, `DoorAction`
   and `ButtonTag` before moving anything.
6. Judge on a computer and the Galaxy A16 (mirror shots); ButtonView's chip sits 30 points left
   of each point (`WorldButton.Shift`).
**Acceptance:** checks green; shut door: Open middle, Peek low; open: Close and Slam side by side;
padlocked: Cut on the latch, Lock on the latch with a padlock in hand; a long refusal never runs
over the next chip; Peek still crouches you; Output clean but 203785492 and the known
rbxassethash lines. Live phone and two players go to `OWNER.md`.
**Read first:** ROADMAP L-19b; `src/server/Doors.luau` (`HALL_BUTTONS`, `add`, `make`);
`src/shared/StorageUnit/Door.luau` (`Slots`, `offers`); `src/client/KneelView.luau` (its
`DoorButtons` move); `src/client/ButtonView.luau` (`place`); docs/STUDIO.md "Camera and prompts".

## Queue (tonight's run order, owner Nov 11 night; ROADMAP Phase 1's order paragraph)
1. L-19b (next), L-20a the inventory wheel and three slots, L-17 every button on a phone at
   once, L-16d the tops still jitter on a computer.
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
   the ladder can't be knocked flat yet (D-107); Output lines at Play, "rbxassethash://...
   Requester does not have permission for Asset" (up to 21 hashes this session, nothing visibly
   missing; no mesh or texture in the game points at them).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
