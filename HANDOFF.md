# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-11, session 100 (L-16b2), night run session 1 of 15 · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-16b done (D-111, D-113).** A press made the moment you arrive counts: new pure `Arrival`
  (shared) judges a press where the server sees you and at moments out to 0.4 s on at the speed
  it sees you moving. Used by `Crawling.counts`, every reach in `Ladders` (crawlers by the crawl
  check's own speed, `Ladders:moving`), its hole check and Drop in, `Saws` (the press and every
  frame of a cut) and `Doors` (reach, and the side for Lock and Cut).
- **`ButtonReach` fixed:** its weak tables lost buttons, so every door button stayed hidden after
  climbing down off the tops. Plain tables now (never key a weak table by an Instance:
  docs/STUDIO.md).
- Verified in Studio: Climb, Saw (hole through) and Lean on arrival at a full run, where Climb
  and Saw were dropped before; L-16b1's door buttons hidden up top (padlock in hand too) and back
  once down; Climb down and Drop down ignored behind a hole, a clear Drop down going.
- Studio: left in Edit, nothing imported.

## Next task: L-19a One look for every button
The moment: a button in the world is a small, sharp key chip with one verb beside it, there the
instant you're near, gone without a trace; on a phone it's a clean thumb target that never
covers the hall. The owner's "prompt updates" ("takes up too much space on mobile... look modern
and world-class").
1. Owner test results first, if pasted.
2. Read ROADMAP L-19a and the prompt notes in docs/STUDIO.md ("Camera and prompts"). List every
   prompt the game makes (`Prompts` on the server; KeypadPad, ToolView and NoteView make their
   own on the client); each is one verb.
3. One client system draws every prompt (`ProximityPrompt.Style` Custom, set where they're
   made): the round key chip (keyboard key, gamepad button, or nothing but the chip on touch,
   at least 44 px), the verb beside it, the object's name only where it's news; fades and
   scales in and out; the ring fills over a hold; a refusal shakes it red with its few words
   (today's refusal flashes in `ObjectText`, `Prompts`); a tap on the chip triggers it on touch.
4. Fold `ButtonReach` in (hidden buttons draw nothing), keeping its plain tables.
5. Use the roblox-ui skill. Judge at phone size (Galaxy A16) and on a computer in Studio, with
   shots; nothing from our planning on screen.
**Acceptance:** checks green; every prompt in the test hall draws the new chip; holds fill;
a refusal (Open on Unit 112, padlocked) shakes red with "Padlocked"; touch taps work; Output clean
but 203785492. Live phone and two players go to `OWNER.md`.
**Read first:** ROADMAP L-19a; docs/STUDIO.md "Camera and prompts"; `src/server/Prompts.luau`;
`src/client/ButtonReach.luau`; `src/client/ToolView.luau` (its `ButtonReach.hide` calls).

## Queue (tonight's run order, owner Nov 11 night; ROADMAP Phase 1's order paragraph)
1. L-19a (next), L-19b a door's buttons where your hand goes, L-20a the inventory wheel and
   three slots, L-17 every button on a phone at once, L-16d the tops still jitter on a computer.
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
   the ladder can't be knocked flat yet (D-107); new Output lines at Play, "rbxassethash://...
   Requester does not have permission for Asset" (14 hashes, nothing visibly missing; no mesh or
   texture in the game points at them).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
