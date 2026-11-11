# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-11, session 95 (overnight run, 10 of up to 15) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-15 done (D-107): keepers hear the rest.** The keypad (`Elevators.acted`), a dropped tool
  landing (`Slots.landed`, `Carry.DropHeard` 40), the saw (`Saws.sawing`), a crawl through a hole
  (`Crawls.crawled`) and the ladder, the tops and drops (`Ladders.climbed`) all reach keepers as
  far as players hear them, through `Keepers`' one `hearAt` and `Keeper.heardAt`. A sound up on a
  unit's top is heard from that unit's door front; one behind a shut door gets out at half its
  reach (`Keeper.Muffled`) and the keeper stands outside the door (`Keeper.heardFrom`,
  `KeeperMap.doorFront`). A new sound stops a keeper for its row's `startle` (0.8 s), turned to
  it; the server stamps `KeeperHeard` and every screen plays the Mannequin's Heard beat
  (`KeeperSounds`). Output says only news; a trapped keeper prints once, not every blow. A
  crawler's feet read on what they lie on (`Wrap.feetBelow`). Lune: `tests/hearing.spec.luau`.
- Verified in Studio: keypad beep unheard at 60, the alarm heard at 69; a tool unheard past 40,
  heard at 26; the ladder heard at 29; the Heard beat on screen (full at 30, the thunk alone at 67).
  The saw, crawls and drops passed Lune only: `OWNER.md`.
- Studio: nothing imported; left in Edit. The climb was "Again"ed in Play, which doesn't touch
  the place. `caffeinate` runs ~45 min from 10:55 and ends on its own.

## Next task: L-16a In hand and caught
The moment: the bugs a friend would hit in their first run with you, fixed before they play.
1. Owner test results first, if pasted.
2. Read ROADMAP L-16a. Then each item, smallest first:
   - A friend's torch arm never raises: `FlashlightView`'s `motor()` takes only `Motor6D`, and the
     R15 shoulders here are `AnimationConstraint`s (see how `Mannequin`/`HornView` pose arms).
   - Caught crawling or on the ladder may leave you stuck once let out: `CrawlView` and
     `LadderView` hold `PlatformStand`; release it when you're kept (`Kept.Attribute`).
   - The first slam's bang lands up to 0.35 s late (`SoundPrimer.prime`).
   - G is both a door's Slam and a tool's Drop: pick which wins at an open door (Slam, the door is
     the moment) and say it in DECISIONS.
   - A left click on the slots' bar blows a horn or lays wrap: a click on GUI isn't a use.
   - Output's stray lines at Play ("Asset type does not match" for 203785492; "KeeperView: can't
     move ... Mannequin") traced or silenced. Also seen tonight: 120448020095820 "content
     representation is being generated" (in the place, not the repo).
3. Each fix ships with its feedback; nothing new on screen without a sound and motion.
**Acceptance:** checks green; Lune for any pure change; in Studio each fixed item checked (the
arm via a second client or a stand-in, the stuck-after-catch by being caught on the ladder);
Output clean but known asset lines. Two players and a phone go to `OWNER.md`.
**Read first:** ROADMAP L-16a; `src/client/FlashlightView.luau` (`motor`);
`src/client/CrawlView.luau` and `src/client/LadderView.luau` (PlatformStand);
`src/client/SoundPrimer.luau`; `src/client/HornView.luau` (the click).

## Queue (the next run's order, from ROADMAP)
1. L-08e (the start, in the lobby) waits for the owner's lobby plan (Nov 11).
2. L-16b the tops and arriving (a horn on the tops is fixed by D-107); L-16c the roof crawl.
3. L-17 every button on a phone at once; L-18 the art saved with the code (optional).
4. L-09a the first run with friends, floors 1 to 3. L-14b2d only if the owner asks.
5. Seen: a ladder stood on a floor when it's cleared should go with it (untested); anyone still
   in the car 6 s after it opens is shut in (`OWNER.md`'s L-08a decision 2); watching a friend
   ride doesn't draw their shaft (ROADMAP polish); DevCorridor's "Walk a floor" sign keeps the
   old floor's number after "Again" (Studio only); the ladder can't be knocked flat yet, so that
   noise waits for whatever knocks it (D-107).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
