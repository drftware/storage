# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 69 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-06b5a done (D-080):** every floor has a guarded note. `Deal.new` picks it last from the
  notes' units (behind an unlocked door where it can), `Deal.odds` deals it a keeper awake in any
  mood and past the cap, and every other door counts its place until it's dealt, so on floors 1
  and 2 other keepers deal asleep until the guard is trapped. `tests/guard.spec.luau`, 379,934
  checks. Verified in Studio on seed 7, floor 1: Unit 157 guarded; 126 and 154 dealt asleep;
  opening 157 its guard caught me.
- **Seed 7, floor 1's awake Mannequin is now 157's guard,** not 126's (`docs/STUDIO.md` has 157's
  spots; OWNER.md warns the owner's older tests).
- **Found:** the built peek has no crouch. A standing eye sees a stud or two under the gap, so no
  keeper's feet show, the guard's tell included (`docs/art/L-06b5-guard-standing.jpg` vs
  `-guard-low.jpg`). The GDD's peek: "Lift the door a foot and crouch". That's the next ticket.

## Next task: L-06b5b The peek's crouch
The moment: you tap Peek, drop low as the door lifts a foot, and see a keeper's feet standing
mid-stride in the bulb's light, or a sleeper's slack ones, before you make a sound.
1. Owner test results first, if pasted.
2. Read how your screen presses a door's buttons (`DoorView`) and how `LadderView` lowers your
   view (`Humanoid.CameraOffset`); find any crouch pose already built (the drop-in's landing).
3. Your own Peek drops your view to the gap's height (eye about 1.3 up), eased over about 0.35 s,
   and holds while the door stays peeked and you stay where you knelt. Moving off, Open, Close,
   Slam or the door moving stands you back up with the same ease. Feel numbers in shared Config,
   each with what it does to the player. The rule for when it holds is pure and Lune-tested.
4. A friend sees you kneel (reuse a built pose if one fits; otherwise the simplest that reads).
5. Every action answers: the motion is the feedback; a soft cloth sound if one exists. Nothing new
   on screen. Phone first: the buttons still sit right while low. Too big? Split in ROADMAP first.
**Acceptance:** checks green; in Studio on seed 7, floor 1, peeking 157 the Client's first-person
view shows the guard's stride under the door; peeking 154, a sleeper's slack stance; walking off
stands you up. Judge at phone size (Galaxy A16 view).
**Read first:** ROADMAP L-06b5b; D-080's last bullet; `src/client/DoorView.luau`;
`src/client/LadderView.luau` (lines 40 to 60, 410 to 465); `src/shared/StorageUnit/Door.luau`
(Peeking); `docs/STUDIO.md` "The awake Mannequin moved to Unit 157".

## Queue (the next run's order, from ROADMAP)
1. L-06b5b (the peek's crouch), L-06b4b (its sounds, the sting on sight, the freeze predicted on
   your screen); D-064, D-068 to D-080. L-12c needs L-06b3d (done). Then L-14; L-07 (takes
   `Keepers.caught`) to L-10.
2. **Check, small:** caught crawling a hole or on the ladder, the stand-in's move may leave
   `CrawlView`/`LadderView` holding PlatformStand; if a keeper can reach you there, end it.
3. **Checks on the tops, small:** Climb or Drop down lying behind a sawn hole slides you across
   it; a friend's drop-in lunges toward the door and lands 0.2 under the floor; a door's own
   buttons in reach while lying at its front, or the ladder to your shoulder while lying, should
   be refused for crawlers (`Ladders:crawling`). **GDD:** its ladder line says open mesh (D-058/9).
4. **Bugs, small:** FlashlightView's `motor()` takes only `Motor6D`, but shoulders are
   `AnimationConstraint`s, so a friend's torch arm never raises; DoorSounds' first slam lands up
   to 0.35 s late (swap `preload` for `SoundPrimer.prime`), and the trap's first blow may too.
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
