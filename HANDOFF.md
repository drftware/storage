# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-12, session 104 (L-17), night run session 5 of 15 · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-17 done (D-117).** Judged on the Galaxy A16: kept, horn at shut and open doors, the wheel
  open by a door. While the wheel is open every button in the world fades aside and takes no taps
  (`ButtonView.aside`, `WorldButton.Aside` 0.1 s), back as it folds. Kept in a unit the empty
  wheel slides off the bottom (ToolView's `alive` is false while kept) and the torch's switch and
  the Use button go (FlashlightView, HornView watch `Kept`), leaving Bang, the map and the stick.
- On a computer Q at a shut door now peeks only (Peek's key; ToolView's `keyTaken`, as G/Slam).
- HornView's round button and its ScreenGui are both named `UseButton`.
- Seen once: the jump-following screens missed the jump's hide at a catch (STUDIO.md).
- Verified in Studio (Galaxy A16 and computer): shots `docs/art/L-17-*.jpg`.
- Studio: left in Edit, Device Simulator off, nothing imported.

## Next task: L-16d The tops still jitter on a computer
The moment: lying on the unit tops at a computer's full frame rate, crawling and turning glide as
smoothly as walking the hall; no repeat-then-jump frames.
1. Owner test results first, if pasted.
2. Read ROADMAP L-16d and D-110 (what L-16c measured and changed).
3. In Studio with the Device Simulator off and Studio focused, get on the tops (STUDIO.md
   "Placing a crawler exactly", the Lean/Climb order above it) and record every frame per
   STUDIO.md "Measuring the crawl's view frame by frame": eye position and frame time, crawling
   straight and turning. Look for frames where the eye holds then jumps.
4. Leads: LadderView steers the body in PreSimulation (`bodyStep`) while the camera draws in
   PreRender, so above the physics rate frames repeat a place, then jump. Fix at the cause (e.g.
   draw the eye from an interpolated place, or steer per render frame) without breaking the
   server's crawl check or a phone's 60.
5. Check the crawl check's put-backs on the server's log while crawling fast.
**Acceptance:** checks green; a frame-by-frame record before and after on a computer showing no
hold-then-jump; the phone path unchanged (a short A16 run); Output clean but 203785492 and the
known rbxassethash lines. A live server and a 120/144 Hz screen go to `OWNER.md`.
**Read first:** ROADMAP L-16d; DECISIONS D-110; `src/client/LadderView.luau` (`bodyStep`, the
camera hookup); `src/shared/Tops.luau` (header); docs/STUDIO.md "Measuring the crawl's view frame
by frame" and "Placing a crawler exactly from the MCP".

## Queue (tonight's run order, owner Nov 11 night; ROADMAP Phase 1's order paragraph)
1. L-16d (next).
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
   the prompt never comes back); FlashlightView's and HornView's screens once stayed on with the
   jump hidden (cause unknown, STUDIO.md); Output lines at Play, "rbxassethash://... Requester
   does not have permission for Asset" (cause unknown).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
