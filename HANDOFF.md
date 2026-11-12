# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-11, session 102 (L-19b), night run session 3 of 15 · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-19b done (D-115).** Each door has four spots (`DoorMiddle`, `DoorLow`, `DoorLatch` on the
  padlock's side, `DoorInside`). Shut: Open on the middle, Peek low; open: Close and Slam side by
  side; padlocked: "Padlocked" once over Open, Cut on the latch. The middle row per state comes
  from the pure `Door.place` (130-point steps, double-tap safe) and slides as it re-spaces.
- New client `DoorSpotView` (rule in pure `DoorSpot`) keeps spots in view on your screen only:
  Peek rides up the door just above the slots (comes onto the handle as you look down), the row
  comes down with your eye as you kneel (KneelView's own lowering is gone), the latch's spot
  slides in toward your gaze, clear of a phone's torch and jump buttons.
- The server judges a door press's reach from the nearest place a screen may have moved the
  spot (`nearest` in Doors). A scripted "Pick up" press can miss silently: use E (STUDIO.md).
- Verified in Studio (computer and Galaxy A16): shots in `docs/art/L-19b-*.jpg`.
- Studio: left in Edit, Device Simulator off, nothing imported.

## Next task: L-20a The inventory wheel and three slots
The moment: one round button at the bottom middle; tap it and your slots fan out round it like
GTA V's weapon wheel, pick one and a small box beside the button shows it; tap the box to lift
the tool into your hand or lower it out of view (pocketed, still yours). Never slow.
1. Owner test results first, if pasted.
2. Read ROADMAP L-20 and OWNER.md's three-slots line (default: three). Find where two slots are
   fixed (grep `ToolSlot`, `Slot2`, `for i = 1, 2` in Slots, Tools, ToolView, HornView) and make
   the count one shared number.
3. "Lowered" means an empty hand: check how Slots holds the hand (`carried` gives the hand's
   index) and whether a hand of 0 already works for Lock, Cut, Saw and Give (they want "Hand").
4. Replace ToolView's bar (`makeBar`) with the button, the wheel (each slot the tool's 3D picture,
   `picture()`) and the box; keep 1/2/3, the pad's d-pad, G to drop (the D-108 rule: a door's
   Slam takes G while it shows), the soft clank, the tool's name for a moment, Give on friends.
5. Motion and sound: the wheel opens in a beat (about 0.12 s), a tick per slot, closes on a pick.
6. HornView's round button and the Drop button sit "beside the bar" (`Hand`): place them beside
   the new button. DoorSpot's Peek limit (`Below` 12 degrees) was tuned to the slots' top on the
   A16 (y 267): re-measure the new button's top and retune `DoorSpot.Below` and doorspot.spec's
   `TO_HAND` if it moved.
7. Judge on a computer and the Galaxy A16 (mirror trick and click mapping in docs/STUDIO.md).
**Acceptance:** checks green; three slots; the wheel opens and closes with its motion and sound;
pick, lift, lower and drop work by tap, keys and pad; a held padlock still shows Lock and cutters
still Cut; a door's buttons stay clear of the new button on the A16; Output clean but 203785492
and the known rbxassethash lines. Live phone and two players go to `OWNER.md`.
**Read first:** ROADMAP L-20; `src/client/ToolView.luau` (header, `makeBar`, slot taps and
keys); `src/server/Slots.luau` (header, `carried`, how the hand is set); `src/shared/Tools/
init.luau` (slot attributes); `src/client/HornView.luau` (its place by the bar); docs/STUDIO.md
"The Galaxy A16's screen, measured".

## Queue (tonight's run order, owner Nov 11 night; ROADMAP Phase 1's order paragraph)
1. L-20a (next), L-17 every button on a phone at once, L-16d the tops still jitter on a computer.
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
   Requester does not have permission for Asset" (21 hashes again; nothing visibly missing).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
