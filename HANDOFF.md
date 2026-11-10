# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 72 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-06b4b2 done (D-083):** each screen hears the walk it shows. A stiff clack of its foot as
  each step of its stop-motion walk lands and a hollow knock of its joints as each pass lands
  (`Pose.tell`: each key once, from KeeperView's own pose, nothing new on the network), from
  the body, footfalls to 70 studs, knocks to 40; and one deeper knock as a lift first clears the
  feet of one standing in a unit, asleep or watching (`KeeperTell`, `KeeperSounds`; numbers on
  the row's `tell`; 168 Lune checks). Verified in Studio on seed 7, floor 1: every footfall on a
  step pose, alternating feet 5.4 studs apart; knocks on passes; the reveal at 157 and 154 within
  a frame of the curtain clearing their feet; no sound errors. By ear and phone: `OWNER.md`.

## Next task: L-06b4b3 The freeze on your screen
The moment: you swing your torch onto it mid-stride and it stops dead that instant, on your
screen, never a step on and back; as SCP-173 and FNAF's animatronics hold the moment you look.
1. Owner test results first, if pasted.
2. Today the freeze reaches your screen a round trip late (the brain decides it, D-076; a Stop
   record goes out at once) and shows 0.1 s behind the server (D-075), so it walks on, then
   eases back about 0.07 studs. Measure that first in Studio (log the beam landing, the screen's
   stop, the record).
3. Predict it on the torch holder's screen, as `HallLights` predicts your own lights: when your
   own torch's beam (Torch's cone, the brain's test: a point up its middle within 42 studs and
   27 degrees, a clear line) finds a body your screen shows walking, hold its pose on the key
   `Pose.freeze` gives, at once; when the server's Stop arrives, settle onto it without a slide;
   if no Stop comes within a round trip or two (a wall the screen missed), let it walk on.
4. Make the beam test one pure rule both sides use (the brain's and the screen's), Lune-tested;
   the screen's clear line is a raycast, the brain's `KeeperMap.clear`: note any disagreement.
5. Every action answers: the stop is the feedback; nothing new on screen. Too big? Split first.
**Acceptance:** checks green; in Studio on seed 7, floor 1, a torch swung onto the roaming
Mannequin stops it on your screen the frame the beam lands (log it against the server's
record), never past and back; a beam through a shut door doesn't stop it; Output clean.
**Read first:** ROADMAP L-06b4b3; D-076 and D-075; `src/client/HallLights.luau` (its
prediction); `src/client/KeeperView.luau`; `src/shared/KeeperMotion.luau` (`follow`,
`receive`, `update`); `docs/STUDIO.md` "Testing the light freeze from the MCP".

## Queue (the next run's order, from ROADMAP)
1. L-06b4b3; D-064, D-068 to D-083. L-12c needs L-06b3d (done). Then L-14; L-07 (takes
   `Keepers.caught`) to L-10.
2. **Check, small:** caught crawling a hole or on the ladder, the stand-in's move may leave
   `CrawlView`/`LadderView` holding PlatformStand; if a keeper can reach you there, end it.
3. **Checks on the tops, small:** Climb or Drop down lying behind a sawn hole slides you across
   it; a friend's drop-in lunges toward the door and lands 0.2 under the floor; a door's own
   buttons in reach while lying at its front, or the ladder to your shoulder while lying, should
   be refused for crawlers (`Ladders:crawling`). **GDD:** its ladder line says open mesh (D-058/9).
4. **Bugs, small:** FlashlightView's `motor()` takes only `Motor6D` (shoulders are
   `AnimationConstraint`s; KneelView's `joint()` takes both), so a friend's torch arm never
   raises; DoorSounds' first slam lands up to 0.35 s late (`SoundPrimer.prime`), the trap's too.
5. **Check:** G is a door's Slam and a tool's Drop: at an open door, tool in hand, which?
6. **Check:** Output's "rbxassetid://203785492 ... Asset type does not match" (six per Play)
   and "rbxassetid://139561946838090 ... content representation is being generated"; neither
   id is in our code, templates or the place's services.
7. Keepers hear doors and a trapped one's blows (done), and should hear the keypad, a dropped
   tool, the saw, a crawl, the ladder and a drop in (D-059, D-066). **Later:** they can't see
   into the elevator car, nor between the tops and the halls (OWNER.md asks).
8. **Small:** Output prints every blow of a trapped keeper (about 28 lines a trap); trim to the
   first, every tenth, the dent's steps and the last if it gets in the way.
9. **Check, small:** the walk holds an arm out level; a keeper stopped against any other wall or
   door may put its hand through it (L-06b3d2 fixed only the trapped stand).
10. **Check, small:** after a Peek from the MCP, that door's other buttons ignore presses until
    you step out of reach and back (docs/STUDIO.md); does a player's real press do the same?

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
