# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 66 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-06b3c done (D-077):** a hunting keeper catches the one it hunts within its row's grasp
  (`reach` 3.5, `reachAngle` 45), Brix's cone along its map, a clear line, within its height;
  never lit, asleep or anyone else (`Keeper.catches`, `k.caught`). The server jolts and blacks
  out the caught player's screen (`Remotes.Caught`, `CaughtView`, timings in `Caught`), fires
  `Keepers.caught` (body, player, floor) and spares them 2 s; DevCorridor's stand-in puts them
  in the lobby in the black (until L-07). Verified in Studio on seed 7, floor 1, torch half too.
- **The brain:** pure `src/shared/Keeper.luau`, rows in `KeeperRows.luau`, run by
  `src/server/Keepers.luau`; 63,436 keeper checks. MCP chase and catch recipes: `docs/STUDIO.md`.

## Next task: L-06b3d1 Trapped, it bangs and breaks out
The moment: you led it into a unit and slammed the door on it. It bangs; the door jumps on its
rail with each blow; you have about a minute and a half before it bursts out, loud, and comes
for whatever it last heard. A padlock keeps it in for the floor. (Amnesia's battered doors; the
GDD's hole trap.) The dent art is L-06b3d2's, not this ticket's.
1. Owner test results first, if pasted.
2. The brain: a keeper is trapped when its doorway was open (door all the way up) and the door
   came down on it awake inside, by a slam or a close; a peek lowered over it isn't a trap, it
   just waits (`Keepers` `onChanged` sees door changes; `KeeperMap.placeAt` says whose unit).
   Trapped, it bangs every few seconds (a row number) and at about 90 s (a row number) the door
   bursts up and it goes after the last thing it heard, or roams. Lift it yourself and it's
   just out. A padlock on the door (`Door` state `Locked`) holds it for the floor.
3. Each bang is a sound keepers hear (D-069; give the bang a reach) and players get its feedback
   in this ticket: the door jolts on its rail and booms (DoorView, DoorSounds: a slam's boom,
   quieter, is a sensible default) and CameraShake for anyone near. The burst is a loud lift.
4. The cap: while trapped or padlocked in, it doesn't count in `awakeOn` (the deal's
   `Deal.awakeCap`); out again, it counts.
5. Output: "the Mannequin is trapped in Unit 126", "bangs", "bursts out". Lune: trapped only by
   a slam or close on an awake one inside after its doorway was open; bangs on its clock; bursts
   out on time after the last sound; never padlocked; the cap; warm, it allocates nothing.
**Acceptance:** checks green; in Studio on seed 7, floor 1, open 126 and slam it the moment it's
up, before the Mannequin is out (once out, keepers never go home, D-071; a hunt can lead one in):
it bangs and bursts out at about 90 s; again with a padlock on 126: it never does.
**Read first:** ROADMAP L-06b3d, L-06b3d1; the GDD's "Tools and traps" hole-trap bullets only;
`src/shared/Keeper.luau` (states, `hear`, `lookOut`); `src/server/Keepers.luau` (`onActed`,
`onChanged`, `awakeOn`); `src/shared/StorageUnit/Door.luau` (states, `Locked`);
`src/client/DoorSounds.luau` (the slam's boom and kick).

## Queue (the next run's order, from ROADMAP)
1. L-06b3d1, L-06b3d2 (the dent), L-06b5 (the guarded note), L-06b4b (its sounds, the sting on
   sight, the freeze predicted on your screen); D-064, D-068 to D-077. L-12c needs L-06b3d.
   Then L-14; L-07 (takes `Keepers.caught`) to L-10.
2. **Check, small:** caught crawling a hole or on the ladder, the stand-in's move may leave
   `CrawlView`/`LadderView` holding PlatformStand; if a keeper can reach you there, end it.
3. **Checks on the tops, small:** Climb or Drop down lying behind a sawn hole slides you across
   it; a friend's drop-in lunges toward the door and lands 0.2 under the floor; a door's own
   buttons in reach while lying at its front, or the ladder to your shoulder while lying, should
   be refused for crawlers (`Ladders:crawling`). **GDD:** its ladder line says open mesh (D-058/9).
4. **Bugs, small:** FlashlightView's `motor()` takes only `Motor6D`, but shoulders are
   `AnimationConstraint`s, so a friend's torch arm never raises; DoorSounds' first slam lands up
   to 0.35 s late (swap `preload` for `SoundPrimer.prime`).
5. **Check:** G is a door's Slam and a tool's Drop: at an open door, tool in hand, which?
6. **Check:** Output's "rbxassetid://203785492 ... Asset type does not match" (five per Play)
   and "rbxassetid://139561946838090 ... content representation is being generated"; neither
   id is in our code, templates or the place's services.
7. Keepers hear doors (done), and should hear the keypad, a dropped tool, the saw, a crawl, the
   ladder and a drop in (D-059, D-066). **Later:** they can't see into the elevator car, nor
   between the tops and the halls, so a torch from the tops never freezes one (OWNER.md asks).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
