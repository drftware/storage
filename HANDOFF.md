# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 70 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-06b5b done (D-081):** tap Peek and your view eases down over 0.35 s to an eye 1.0 off the
  floor, so you see under the door: the guard's legs mid-stride in 157, the sleeper's square feet
  in 154 (`docs/art/L-06b5b-peek-*.jpg`). The door's buttons come down with you on your screen.
  A step, a jump, your Open, Close or Slam, or any other move of the door stands you back up.
  Friends see you kneel, chest to the floor (`-friend-kneels.jpg`): the server tags you
  (`Kneels`), every screen poses your joints (`KneelView`). A cloth rustle as you go down and up.
  Pure rule in `Kneel`, 94 Lune checks. Verified in Studio on seed 7, floor 1, one screen; two
  screens, the phone view and the rustle by ear wait on `OWNER.md`.
- **L-06b4b split** in ROADMAP into b1 (the sting and the chase bed), b2 (its tell: footfalls and
  joint knocks) and b3 (the freeze predicted on your screen), a session each.

## Next task: L-06b4b1 The sting and the chase bed
The moment: a keeper turns its head your way, and a sting cuts in the instant it sees you, as
Granny's chase music does; a low bed runs under the chase and fades as it loses you.
1. Owner test results first, if pasted.
2. Find how your screen can tell a keeper hunts *you*: the body's `KeeperState` attribute says
   Hunting, but whom? (`Keeper.luau` keeps `k.target`; `Keepers.luau` sends the catch over
   `Remotes.Caught`). If no screen knows, have the server tell the hunted player's screen when
   the hunt starts and ends, validated and cheap (one message per change, not per step).
3. Pick the sting and the bed from Roblox's sound library (the game uses Pro Sound Effects';
   `search_asset`, then check each loads and where its sound sits, as `docs/STUDIO.md` "Testing
   the peek's kneel" did). Only on the hunted player's screen; friends hear the keeper, not your
   music. Feel numbers (volumes, the bed's fade in and out, a short gap before a second sting)
   in shared Config with what each does to the player.
4. The rule for when the sting plays and the bed runs (a fresh sighting, not every glance back
   after it lost you for a moment) is pure and Lune-tested.
5. Every action answers; nothing new on screen. Too big? Split in ROADMAP first.
**Acceptance:** checks green; in Studio on seed 7, floor 1, opening 157 in front of the guard
plays the sting the moment it turns on you and runs the bed under the chase; losing it fades the
bed; Output shows no sound errors. Judge by ear what you can; the rest goes to OWNER.md.
**Read first:** ROADMAP L-06b4b1; D-074; `src/shared/Keeper.luau` (lines 310 to 365);
`src/server/Keepers.luau` (its catch remote and `KeeperState`); `src/client/CaughtView.luau`
(a screen answering a keeper); `docs/STUDIO.md` "Testing the catch from the MCP".

## Queue (the next run's order, from ROADMAP)
1. L-06b4b1, L-06b4b2, L-06b4b3; D-064, D-068 to D-081. L-12c needs L-06b3d (done). Then L-14;
   L-07 (takes `Keepers.caught`) to L-10.
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
