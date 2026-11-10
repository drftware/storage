# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 71 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-06b4b1 done (D-082):** the instant a keeper sees you, a hit cuts in on your screen alone
  (APM's "Rising Fear Hit 1") and a low drone swells under the chase ("Tension Repeat Drones
  39"), fading over 4 s once no keeper hunts you. A glance back within 4 s of a loss doesn't hit
  again, nor a second keeper within 8 s; a catch cuts both dead. The server tells each player
  how many keepers hunt them only when that changes (`Remotes.Hunted`, from `Keepers`); the rule
  is pure (`Chase`, 46 Lune checks), played by `ChaseMusic`. Verified in Studio on seed 7, floor
  1: the hit on the sighting's frame, the rise, the fade after an escape, the catch's cut, no
  sound errors. Sounds were chosen by measurement (the bed for a phone's speaker); judging them
  by ear, on a phone and on two screens waits on `OWNER.md`.

## Next task: L-06b4b2 Its tell
The moment: in the dark you hear it before you see it: a stiff, quick footfall each step and
fibreglass knocking at its joints, as Five Nights at Freddy's footsteps say an animatronic moved;
and one knock of its joints as a lifted door first shows one standing in a unit.
1. Owner test results first, if pasted.
2. Find where each screen's `KeeperView` knows a foot plants (it poses the body from the records'
   walked distance, `Pose.frame`): footfalls come from each screen's own pose, so nothing new
   crosses the network. Friends hear it too: it's a sound in the hall, from the body, heard to a
   set distance (as doors are, `DoorSounds`).
3. Pick the footfall and the joint knock from Roblox's library (Pro Sound Effects; `search_asset`,
   then load and measure each as `docs/STUDIO.md` "Sounds measured for the chase" did). Feel
   numbers on the keeper's row (`KeeperRows`: keepers are data rows), each with what it does to
   the player. Cap sounds per keeper; only a keeper streamed to you plays (phone first).
4. The knock as a door first lifts on a keeper standing in its unit: once, on each screen near.
5. Whatever is pure (when a foot plants from the walked distance, the knock's once-only rule) is
   Lune-tested. Every action answers; nothing new on screen. Too big? Split in ROADMAP first.
**Acceptance:** checks green; in Studio on seed 7, floor 1, the guard walking out of 157 plays one
footfall per planted foot (log each play against the pose's stride) and a peek at 157 or 154
knocks once; Output shows no sound errors. Judge by ear what you can; the rest goes to OWNER.md.
**Read first:** ROADMAP L-06b4b2; D-075; `src/client/KeeperView.luau`;
`src/shared/Mannequin/Pose.luau` (the stride's frames); `src/shared/KeeperRows.luau`;
`docs/STUDIO.md` "Testing the chase music from the MCP".

## Queue (the next run's order, from ROADMAP)
1. L-06b4b2, L-06b4b3; D-064, D-068 to D-082. L-12c needs L-06b3d (done). Then L-14; L-07
   (takes `Keepers.caught`) to L-10.
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

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
