# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 153 (afternoon run 1: S1-10d3 and S2-04c) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **The halls go dark for a wrong code** (S2-04c, D-163), seen in Studio Play on seed 7, floor
  3: every hall light on the floor goes out for the keypad's dead span (`MotionLights:out`,
  shown "Out" on each fixture) and comes back dark; the car's lamp isn't a fixture, so it stays.
  Lit tubes and dark eyes stutter out under a power-down whine and stutter back under a
  fluorescent flicker. Seen: 23 fixtures out 3.5 s and back, a lit tube's stutter and grey eye,
  both sounds playing, the freed Mannequin walking through the dark; Output clean. Not heard.
- **The machine's menu stays down after a buy** (S1-10d3, D-164): a sale closes it; its Buy
  comes back once the vend is over. Passes checks, untested in Studio. Studio left in Edit.

## Next task: S2-02d The camera shows the Mannequin cut the power
ROADMAP S2-02d (the owner's words there): as a Mannequin on its errand reaches the breaker, every
player on that floor sees the corner map cut to a security camera's view of the box: grainy, a
cold tint, a camera number and a blinking red dot, the Mannequin's hand pulling the lever down,
the clunk, then static and the map back. As Five Nights at Freddy's cameras. The owner's "WTF
moment" for first-time players: make it land. Built as a feed any monster can use later.
1. Read ROADMAP S2-02d and D-155 (the errand); find where the errand reaches the box and throws
   it (`Keepers.luau`: grep "breaker", "errand"; `Breakers:throw`).
2. Server: a reusable feed (a small system or Keepers hook): which floor, where the camera hangs
   (high in a corner of the box's hall, looking at the box), what it watches, how long; tell
   that floor's players a beat before the throw so the feed shows the hand on the lever.
3. Client: the feed replaces the corner map (`MinimapView`) in the same frame. A ViewportFrame
   draws only what's inside it: clone the box and the hall around it once, follow the
   Mannequin's live pose each frame (check STUDIO.md on ViewportFrames first). Grain, tint, the
   camera number, a blinking dot; the hiss cutting in, the lever's clunk, static out.
4. If it won't fit, split in ROADMAP: the feed working with its look and sound first, extra
   polish second. Defaults (length, angle, whether the dev throw plays it) go in `OWNER.md`.
5. Verify in Play: send a Mannequin on its errand (D-155's dev path) or stage a throw; the map
   cuts to the feed, the lever goes down in it, static, the map comes back. Phone size matters.
**Acceptance:** checks green; the feed shows on that floor only, the throw seen in it, the map
back after; no text explaining it; Output clean.
**Read first:** ROADMAP S2-02d; DECISIONS D-155; `src/server/Breakers.luau` (header, `throw`);
`src/server/Keepers.luau` (grep "breaker"); `src/client/MinimapView.luau` (header);
`docs/STUDIO.md` (grep "ViewportFrame").

## Queue (next sessions per ROADMAP Phase 2)
1. S2-02d (next), then S2-05 (the tap when you shut a door on a sleeper). S2-06 and L-08e3c
   wait on `OWNER.md`. R-01 is for later.
2. The machine's menu (S1-10d1 to d3): unseen with the menu really open are the wheel's slide,
   the dim tool bays with full slots, and the menu staying down after a buy (`OWNER.md`).
3. Found S2-04c: a player standing still at the keypad stays dark once the lights come back
   (the motion lights' rule; a freed Mannequin caught me there). Watch it in the playtest.
4. Found S1-10d2: the narrower drop leaves a tumbling saw's box corner up to 0.05 past the glass
   as it tips (a box estimate; likely unseen). If the owner sees it, a gentler `TIP` fixes it.
5. Found S2-04b: monsters called to one spot (the keypad, a door) all go to the same point and
   nothing keeps them apart, so four may stand inside each other at the keypad (inferred from
   distances, not seen). Spreading them round the spot is a small brain change worth a ticket.
6. Found S2-04a: Output's `ContentId: rbxassetid://89260803894903 ... No asset content
   representation found` ×27 as a dealt unit rolled up; not in the repo, cause unfound.
7. Found S2-03b: loose keepers hear a pounding door and go to look (a feature; watch it); a
   woken unit's Studio line says "asleep". S2-03a: waves can pass `Deal.awakeCap` (six bound it).
8. Found S2-02c: only a wandering Mannequin takes the errand; one standing awake that has never
   been out (Watching) doesn't. S2-02b: nobody can throw the breaker by hand (S2-06 may need it).
9. Found S1-12: no saved cash total shows yet; a climb left mid-way makes no cash (D-151).
   S1-11: a friend's beam doesn't show the mark. Output's `203785492` (wrong type), unchecked.
10. Small: S1-07b coin piles and batteries show Take through a shut door; S1-09 a kept torch
   drains if left on; S1-07a 16 in 100 units hold nothing; unseen: S1-06, S1-05, S1-04b2.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
