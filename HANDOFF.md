# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 67 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-06b3d1 done (D-078):** a door down from all the way up on an awake keeper inside traps it
  (`Keeper.trap`, state `Trapped`); it stands against the door and bangs, the first blow at 1.2 s,
  then 5 s closing to 2 s. Each blow and its burst at 90 s are door motions (`Bang`, `Burst`) the
  server plays with `Doors.move`, so every screen jolts, booms and shakes from the door's one
  motion attribute, and keepers hear them. A padlock holds it (one last blow, then quiet);
  trapped, it isn't counted in the cap (`Keeper.loose`). 144 checks in `tests/trapped.spec.luau`.
  Verified in Studio on seed 7, floor 1: 28 blows, out at 90.25 s; padlocked, still in at 103 s.
- **The brain:** pure `src/shared/Keeper.luau`, rows in `KeeperRows.luau`, run by
  `src/server/Keepers.luau`. MCP recipes for the chase, catch and trap: `docs/STUDIO.md`.

## Next task: L-06b3d2 The dent
The moment: the door you slammed on it starts to bow out toward you, a little more with each
blow, so you can see from the hall how close it is to coming through (Amnesia's battered doors).
1. Owner test results first, if pasted.
2. The art, the unit's way (`art/unit/README.md`; the curtain is `art/unit/curtain.py`): the
   door's slats bowing out into the hall around chest height, a few baked steps (say 3: dented,
   bowed, buckling) or a shape key, whichever Studio's importer keeps; rebuild with
   `scripts/art.sh`, never hand-edit the generated FBX or Specs. Judge it at phone size.
3. How screens know: the server counts each blow on the door (a door attribute, say `DoorDent`,
   0 to 1 by the share of `breakOut` gone, set in `Keepers`' `onBlow` with each `Doors.move`
   "Bang"); `RollUpDoor`'s rig (`Rig.pose`) or `DoorView` shows the matching step, the change
   landing on the blow itself (the jolt already plays from the `Bang` motion). A door lifted all
   the way up or burst keeps its dent for the floor (a sensible default; list it in OWNER.md).
4. The dent never changes the collider or what keepers see through (`KeeperMap` stays as it is).
5. Lune: the dent's step from the blows so far is pure (in `Door` or a small module): never
   back, full at the burst. Studio: the trap recipe, peek at the door from the hall each 30 s.
**Acceptance:** checks green; in Studio on seed 7, floor 1, slam 126 on its Mannequin (recipe in
`docs/STUDIO.md`, "Testing the trap"): the door visibly bows more at 30, 60 and 85 s, at phone
size; shots in `docs/art/`.
**Read first:** ROADMAP L-06b3d2; `art/unit/README.md`; `art/unit/curtain.py`;
`src/shared/StorageUnit/RollUpDoor.luau` (`Rig.pose`, the slat chain); `src/server/Keepers.luau`
(`onBlow`); D-078.

## Queue (the next run's order, from ROADMAP)
1. L-06b3d2 (the dent), L-06b5 (the guarded note), L-06b4b (its sounds, the sting on sight, the
   freeze predicted on your screen); D-064, D-068 to D-078. L-12c needs L-06b3d. Then L-14;
   L-07 (takes `Keepers.caught`) to L-10.
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
   first, every tenth and the last if it gets in the way.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
