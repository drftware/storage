# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 76 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-14a2 done (D-087): blowing the air horn.** Blow (left click, L2, a round button left of a
  phone's jump button or beside the slots' bar) while it's in your hand. Any tool whose `Catalog`
  row has a `verb` now has a press of its own: `ToolUse`, checked by `Slots` and fired as
  `Slots.used`. `Horns` (server) keeps one blow per 2.5 s, stamps the horn `Blown` and calls
  `Keepers:hearHorn`: keepers on that floor within 130 studs along the halls come to where you
  blew it, sleepers in an open unit wake (`Horn`, pure, `tests/horn.spec.luau`). `HornView` plays
  the blast, raises the horn (`ToolView`'s new `Hand`) and kicks your view; friends hear it at
  your horn and see your left arm go up. Verified in Studio on seed 7 (a sleeper woke 100 studs
  off and came; a roamer came from 44); Output clean. Reach, phone, friend, sound: `OWNER.md`.

## Next task: L-14b1 Bubble wrap's art
The moment (L-14b2 builds it): you lay a sheet across the hall behind you, and seconds later,
round the corner, it pops: something is coming, and every keeper on the floor heard it too.
1. Owner test results first, if pasted.
2. Name the hit game whose noise trap this is (Granny's creaking floor and things that fall?).
   With no real precedent it's an untested bet: `OWNER.md`, and ask before building.
3. Read `art/airhorn/` (newest, smallest) and `art/unit/README.md` for the recipe: one spec, parts
   UV-mapped to a shared set, baked PBR, an FBX, a generated `Specs/BubbleWrap` (the sheet's
   size, the roll's grip), look sheets. Two looks: a roll in your hand, a flat sheet on the
   floor (the sheet as a second part, or its own template; say which in DECISIONS).
4. The `Catalog` row: name "Bubble wrap", hold, use (held out to unroll), a friend's hand,
   icon, pick-up and drop sounds (Pro Sound Effects, measured by AudioAnalyzer), `verb = "Lay"`.
   Import into `Props.Tools` (`Tools.prepare`) and lay one in the test hall beside the horn.
**Acceptance:** checks green; `scripts/art.sh` rebuilds it; in Studio at desktop size, picked
up, held and dropped, the slot's picture reads at phone size; Output clean.
**Read first:** ROADMAP L-14b; D-086 (the horn's art, the pattern); `art/airhorn/` (its spec and
build); `art/unit/README.md`; `src/shared/Tools/Catalog.luau`; `docs/FRAMEWORK.md`.

## Queue (the next run's order, from ROADMAP)
1. L-14b1, L-14b2 (bubble wrap); D-064, D-068 to D-087. Then L-14c, L-14d; L-07 (takes
   `Keepers.caught`) to L-10.
2. **Check, small:** caught (moved to the lobby), the MCP's Client couldn't move the character
   54 s on (CFrame or `MoveTo`); a Server pivot could. Can a real player walk after a catch?
   Caught crawling or on the ladder, `CrawlView`/`LadderView` may keep holding PlatformStand.
   And a keeper that chased you to the lobby catches you there again every 2 s (L-07's to fix).
3. **Check, small:** a press made the moment you arrive reaches the server while it still sees you
   a few studs back (D-085). Saws, Ladders (Lean, Climb, Drop down) and a door's Cut and Lock
   check where you stand: allow for it as `Crawling.counts` does if one drops. And any server
   check of where a player faces sees the turn 0.4 s late (D-084).
4. **Checks on the tops, small:** Climb or Drop down lying behind a sawn hole slides you across
   it; a friend's drop-in lunges toward the door and lands 0.2 under the floor; a door's own
   buttons in reach while lying at its front, or the ladder to your shoulder while lying, should
   be refused for crawlers (`Ladders:crawling`). **GDD:** its ladder line says open mesh (D-058/9).
   A horn blown on the tops is heard from the unit under you (D-087).
5. **Bugs, small:** FlashlightView's `motor()` takes only `Motor6D` (shoulders are
   `AnimationConstraint`s; KneelView's `joint()` and HornView's take both), so a friend's torch
   arm never raises; DoorSounds' first slam lands up to 0.35 s late (`SoundPrimer.prime`).
6. **Check:** G is a door's Slam and a tool's Drop: at an open door, tool in hand, which? And a
   left click blows a horn in hand even while clicking the slots' bar with a free cursor.
7. **Check:** Output's "rbxassetid://203785492 ... Asset type does not match" (six per Play), and
   139561946838090's "being generated"; neither id is in our code, templates or services.
8. Keepers should hear the keypad, a dropped tool, the saw, a crawl, the ladder and a drop in
   (D-059, D-066): L-14b2's general sound on `Keepers` is the place. **Later:** they can't see
   into the car, nor between tops and halls (OWNER.md).
9. **Small:** a trapped keeper's every blow prints (about 28 a trap); a keeper stopped against a
   wall may put its reaching hand through it; after an MCP Peek a door ignores presses until you
   step out of reach and back (docs/STUDIO.md): does a real press?

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
