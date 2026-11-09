# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 45 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-12b3 is done** (D-054): crawling through. `Crawls` (server) puts a Crawl button (E / X)
  each side of every holed wall (`CrawlHole.Tag`); checks inside, reach, rate, not crawling, the
  hole free ("Wait for them"); tags the character `Crawling.Tag` with the start and the crawl's
  frame; puts you through itself if your screen never moved you. `CrawlView` (every screen):
  your screen moves your body along the path (PlatformStand, the `Crawling` collision group) and
  your view with your head, handed back where first person sits; everyone's shoulders posed
  reaching and hauling; a thud, two drags and a steel scrape at the hole. Each Crawl button shows
  only on your side of its wall. Rules, path and numbers: `CrawlHole/Crawling` (pure,
  `tests/crawling.spec.luau`). `Crawls.crawled` for keepers (35 studs). The test hall no longer
  cuts holes as it's laid (`DEV_HOLES` gone): the saw makes them.
- **Verified in Studio** (Play, a computer view, holes cut by `CrawlHole.saw` from the Server as
  the saw does): crawled 106 into 108 and back, and the small 109 into 111, standing up 3.6
  studs past the wall each time; refused from the hall and from a step away; 106's button hidden
  from inside 108 (the server refused it when it showed, before the fix); the view hands back
  with no jump; hands on the floor, arms inside the hole (tuck 35 measured held still; the crawls
  ran at 30); no errors. Screens: the hole's mouth, mid-hole, and an outside view of the body
  coming through. Not seen: a friend's screen, the phone, the sounds (nobody can listen).
  Studio left in Edit, Play stopped. No owner results came (the overnight run).

## Next task: L-13a The tops' closed edges
The moment (for L-13b): a keeper below, you up on the wire tops running a row; first the tops
must be a place you can't fall off the world from.
1. Owner test results first (`OWNER.md`).
2. Read D-031 (tops run along a row), D-023 (junctions) and how `FloorBuilder` lays a unit's
   wire top and the gap behind a row.
3. A panel from each row's back up to the joists (as a plain wall's above its cap), over the
   16-stud gap behind the row; a lid on each junction's hollow 8-by-8 block (an S wire top fits).
4. `Floor.runs`: each run's slots in order (pure, Lune-checked), for L-13b's ladder.
5. Real art only: reuse the unit's and corridor kit's pieces; any new piece is built the unit's
   way (`art/unit/README.md`).
**Acceptance:** checks green; in Studio on floor 1, stand on a run's tops (teleport) and find no
gap to fall through at a row's back or a junction; Lune checks for `Floor.runs`.
**Read first:** ROADMAP L-13a; DECISIONS D-031 and D-023; `src/server/FloorBuilder.luau` (the
wire top, grep "WireTop"); `src/shared/Floor.luau` (slots, junctions); `docs/CODEMAP.md` rows
for FloorBuilder and Floor.

## Queue (the next run's order, from ROADMAP)
1. L-13a, then L-13b (the ladder). L-06b the Mannequin hunts **waits on Brix**: ENG-07a/b (a
   chase in a place) aren't built, and this repo never edits Brix; a Brix session first. L-12c
   the hole trap needs L-06b's keepers. Then L-14; then L-07, L-08, L-10, L-09.
2. **Bug, small:** FlashlightView's `motor()` takes only `Motor6D`, but players' shoulders here
   are `AnimationConstraint`s (docs/STUDIO.md), so a friend's torch arm likely never raises.
   Take either, as CrawlView's `joint()`; check with two players.
3. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
4. **Check, small:** G is both a door's Slam and Drop (ToolView binds G since L-11b): with a tool
   in hand, does G at an open door slam, drop, or both? Give Drop its own key if it clashes.
5. L-06b's keepers stand at `Deals.dealt`'s place, hear doors on `Doors.acted`, the keypad on
   `Elevators.acted`, a dropped tool on `Slots.changed`, the saw on `Saws.sawing` (200 studs), a
   crawl on `Crawls.crawled` (35); keepers with eyes see a torch (`Flashlights.switched`); a
   keeper's path must treat a holed wall as solid (the hole is 2.6 tall).
6. **Check:** Output warns six times per Play, "rbxassetid://203785492 failed: Asset type does
   not match": not in our code; find what asks for it (the place, a plugin).
7. Studio traps (docs/STUDIO.md): the test hall and the walked floor share unit names (pick by
   Z); a Client `execute_luau` has its own `require` (edit, sync, Play again); prompts pressed by
   script need the camera on them, and the Assistant resets a Scriptable camera after each call.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
