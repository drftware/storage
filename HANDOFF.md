# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 155 (afternoon run 3: S2-02d2) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **The Mannequin pulls the lever** (S2-02d2, D-166): at the breaker box its right hand goes up
  on the grip (its arm creaks), it holds 0.6 s (`Breaker.Grip`; a light holds it there, a sound
  or sight calls it off), then drags the lever down and stands 5 s holding it, head dropped.
  Two stop-motion keys (`Pose` Reach and Pull), each hand within 0.2 of the grip in the tests.
  Screens are told "Reaching"/"Pulling" (`Keeper.shown`), so the hall and the camera feed both
  show it. The thrower no longer hears its own clunk (it used to walk off at once).
- Run in Studio Play (floor 3): the feed showed the hand up for the beat before the throw; the
  server went Reaching, then Pulling 0.6 s later, the thrower stayed while the others came to
  the clunk. Studio drew no frames in the second run (STUDIO.md), so the pull moving on a
  screen and the phone-size look are unseen. Studio left in Edit.

## Next task: S2-05 The tap when you shut a door on a sleeper
ROADMAP S2-05. Pull a door down on a monster that's asleep, or hasn't seen you, and a bar with
a moving marker comes up by itself; hit it and the door settles quietly; miss or don't tap and
it bangs, and the monster wakes and pounds (OWNER.md's "small things": not tapping is a miss).
1. Read the GDD's section on shutting a door on a sleeper (docs tools, not WebFetch) and its
   precedent (the hit game it names); check `docs/FRAMEWORK.md` for anything Brix has for a
   timing bar or a hold-to-act; this game supplies the policy and the look.
2. Pure rules first (a new shared module, Lune spec first): when the bar shows (the door
   coming down on a unit whose keeper is asleep or hasn't seen the one pulling), how the marker
   moves, the hit window, what a miss or no tap does. Numbers in Config-style fields, each
   saying what it does to the player.
3. Server: the door's close (grep `Doors.luau` for "Close") asks the rules; a hit settles the
   door quietly; a miss bangs it and wakes the sleeper into the trapped keeper's pounding
   (`Keeper.trap`, as a waking sleeper does in S2-03b). Validate the tap remote (type, range,
   ownership, rate).
4. Client: the bar rises by itself as the door comes down (phone first: big, one tap anywhere),
   the marker sweeps, the hit's soft settle, the miss's bang and shake. No words on it.
5. Verify in Play: count `RenderStepped` first (STUDIO.md); shut a door on a sleeper, hit and
   miss, Output clean.
**Acceptance:** checks green; in Play a hit shuts the door quietly and a miss wakes it pounding;
the bar is readable at phone size; every outcome has its motion and sound.
**Read first:** ROADMAP S2-05; the GDD's sleeper-door section; `docs/FRAMEWORK.md` (grep
"timing\|bar\|hold"); `src/server/Doors.luau` (grep "Close"); `src/server/Keepers.luau` (grep
"sleepers", "trap"); `docs/STUDIO.md` (grep "draws no frames").

## Queue (next sessions per ROADMAP Phase 2)
1. S2-05 (next). S2-02d3 (judge the feed at phone size: framing, darkness, grain; a feed that
   starts mid-slide lands with the map) needs Studio drawing frames: do it when it is, or the
   owner judges it (`OWNER.md`). S2-06 and L-08e3c wait on `OWNER.md`. R-01 is for later.
2. Found S2-02d2: sounds call errand Mannequins off often; four came to the clunk.
3. Found S2-02d1: other monsters in the camera's view are copied once as statues (only the
   watched body moves); a second feed on the same floor replaces the first at once.
4. The machine's menu (S1-10d1 to d3): unseen with the menu really open are the wheel's slide,
   the dim tool bays with full slots, and the menu staying down after a buy (`OWNER.md`).
5. Found S2-04c: a player standing still at the keypad stays dark once the lights come back;
   S2-04b: monsters called to one spot all go to the same point (inferred).
6. Output at Play start: about 46 `rbxassethash ... Requester does not have permission` lines;
   S2-04a's `rbxassetid://89260803894903` ×27 as a dealt unit rolled up; `203785492` (wrong
   type). Causes unfound.
7. Found S2-03b: loose keepers go to look at a pounding door (a feature; watch it). S2-03a:
   waves can pass `Deal.awakeCap`. S2-02c: only a wandering Mannequin takes the errand; S2-02b:
   nobody can throw the breaker by hand (S2-06 may need it).
8. Small: S1-12 no saved cash total shows; S1-11 a friend's beam doesn't show the mark; S1-07b
   Take shows through a shut door; S1-09 a kept torch drains if left on; S1-07a 16 in 100
   units hold nothing; S1-10d2 a saw may poke 0.05 past the glass; unseen: S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
