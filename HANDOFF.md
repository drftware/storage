# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 154 (afternoon run 2: S2-02d1) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **A security camera shows the Mannequin cut the power** (S2-02d1, D-165), run in Studio Play
  on seed 7, floor 3: as a Mannequin walks its last steps to the breaker, every screen on that
  floor turns its corner map to snow and grows it into a grainy, cold, choppy camera picture of
  the box's hall ("CAM 07", a blinking dot); the clunk comes through it thin, it dims, static,
  map back. Run: in 2.5 s before the throw, 46 hall parts and the body and box copied in, dimmed
  at the throw, gone 2.2 s after; the window on the map's own corner. Seen: the grain, number
  and a hall's panels; never a clean shot of the Mannequin at the box. Not heard. Studio in Edit.
- Reusable: `Feeds:show/close/hang/ready` (server), `FeedView` (client), `Feed` (rules, tested).

## Next task: S2-02d2 The hand on the lever, judged at phone size
ROADMAP S2-02d2 (the owner's idea in S2-02d above it). The feed works; what it shows doesn't
yet land: the Mannequin stands at the box in its still pose as the lever slams down by itself.
1. Read ROADMAP S2-02d2 and D-165. Read `Mannequin/Pose.luau`'s header and its `Poses` table
   (grep "Lunge = {" for a reach), and how KeeperView picks a pose (grep "Pose.frame", "Still").
2. Two stop-motion keys: "Reach" (the arm nearest the grip up on it) and "Pull" (the arm down,
   the body leaning into it), inside `LIMITS`, checked in `tests/mannequin.spec.luau` as the
   other poses are (feet on the floor, nothing through anything).
3. The brain: at the box it stands a beat with its hand on the grip (a `Keeper` hold, about 0.6
   s, a number in `Breaker`), then throws: `threw` set after the beat, not on arrival; a light
   on it in the beat holds it there; tests in `tests/errand.spec.luau` first.
4. Screens: KeeperView shows Reach for the beat and Pull as the box goes (the state or a body
   attribute the server sets), on every screen, so the hall shows it too and the feed copies it.
5. Judge in Play with Device Simulator at phone size: run the STUDIO.md "Testing the camera
   feed in Play" recipe and capture as the hand reaches. Tune `Feed.Fov`, `Feed.AimUp`, the
   light, `Feed.GrainSee` until the Mannequin and the lever read in a 160-point window.
6. A feed starting while the map slides in should land where the map lands (FeedView
   `mapWindow`); and a far player's picture needs the hall streamed (it is, at errand start).
**Acceptance:** checks green; in Play the feed shows the hand go up and pull the lever down,
the clunk on the pull; seen at phone size; Output clean.
**Read first:** ROADMAP S2-02d2; DECISIONS D-165; `src/shared/Mannequin/Pose.luau` (header,
`Poses`); `src/shared/Keeper.luau` (grep "errand"); `src/client/KeeperView.luau` (grep "Pose.");
`docs/STUDIO.md` (grep "camera feed").

## Queue (next sessions per ROADMAP Phase 2)
1. S2-02d2 (next), then S2-05 (the tap when you shut a door on a sleeper). S2-06 and L-08e3c
   wait on `OWNER.md`. R-01 is for later.
2. Found S2-02d1: other monsters in the camera's view are copied once as statues (only the
   watched body moves); a second feed on the same floor replaces the first at once.
3. The machine's menu (S1-10d1 to d3): unseen with the menu really open are the wheel's slide,
   the dim tool bays with full slots, and the menu staying down after a buy (`OWNER.md`).
4. Found S2-04c: a player standing still at the keypad stays dark once the lights come back
   (the motion lights' rule). Watch it in the playtest.
5. Found S1-10d2: a tumbling saw's box corner may poke 0.05 past the glass (likely unseen).
6. Found S2-04b: monsters called to one spot all go to the same point; four may stand inside
   each other at the keypad (inferred, not seen). Spreading them is a small brain change.
7. Found S2-04a: Output's `ContentId: rbxassetid://89260803894903 ... No asset content
   representation found` ×27 as a dealt unit rolled up; cause unfound. Also seen this session:
   about 46 `rbxassethash ... Requester does not have permission` lines at Play start.
8. Found S2-03b: loose keepers hear a pounding door and go to look (a feature; watch it); a
   woken unit's Studio line says "asleep". S2-03a: waves can pass `Deal.awakeCap`.
9. Found S2-02c: only a wandering Mannequin takes the errand. S2-02b: nobody can throw the
   breaker by hand (S2-06 may need it).
10. Found S1-12: no saved cash total shows yet; a climb left mid-way makes no cash (D-151).
   S1-11: a friend's beam doesn't show the mark. Output's `203785492` (wrong type), unchecked.
11. Small: S1-07b coin piles and batteries show Take through a shut door; S1-09 a kept torch
   drains if left on; S1-07a 16 in 100 units hold nothing; unseen: S1-06, S1-05, S1-04b2.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
