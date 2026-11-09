# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 52 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-13b2d split in three** (art, the cut, the drop in and out). **L-13b2d1 is done** (D-061):
  the sawn top's art, `art/tophole/` (`scripts/art.sh tophole`, about 90 s). A hole 2.8 across and 2.05 front to back in the middle of a unit's top, just
  behind the door's drum, across the first channel (sawn through, bright ends); five tongues bent
  down; the panel on the floor below, tilted on the channel's stub, slid aside. The wall hole's
  build is loaded as a library with the top's spec (`hole_kit()`), so one code draws both.
  Pieces: `Top_S`, `Top_M` (units' frames), `Edge`, `PanelEdge`, `Panel` (the hole's frame:
  add `Specs.Channel[size]` along the unit). Generated `StorageUnit/TopHole/Specs.luau` (no game
  module yet); its upload entry is in `scripts/upload_art.luau`.
- **Judged** in eight look sheets (`art/sheets/tophole-*`), one at phone size. **Not done:**
  uploaded, inserted, prepared, seen in Studio. From along the tops the cut is only a glint.

## Next task: L-13b2d2 Saw the top
The moment: lying on a unit's top with the saw, you hold Saw, the whole floor hears it, the line
crawls round the cut, the panel drops and clangs below, and you look down the hole with your torch.
1. Owner test results first (`OWNER.md`'s L-13b2d1, L-13b2c2, L-13b2c, L-13b2a sections).
2. Split in ROADMAP before starting if it won't fit (likely: the art in the place and `saw` one
   session, the button and the map the next).
3. Art in: `lune run scripts/upload_art TopHole`; insert with the MCP, drop its `Assistant:` tag;
   a `TopHole` module (`init.luau` beside `Specs`) with `prepare` as `CrawlHole.prepare` (square
   to the kit by `Top_M`, the unit's wall look from `Units.M.WallLeft` on `Top_*` and `Panel`)
   and `saw(unit, at?)`: the unit's `Top` swapped for `Top_<size>`, `Edge` laid, `Panel` and
   `PanelEdge` dropped (tagged for screens, as `CrawlPanel`). Into `Props.TopHole`. Judge in
   Studio at phone size from the tops and inside; the owner's "Save the place" line grows.
4. The cut: a Saw button over the hole spot for a crawler lying by it with the saw (D-053's
   hold, keys, sounds and server checks; on that top per `Tops` and `Ladders`' crawler record),
   the line round the cut (`Sawing.line`'s way), sparks up top; through, the panel's fall and
   clang, heard floor-wide, `Saws.sawing` for keepers.
5. The map: the hole off `Tops` (no crawling over it) with a lip so your head can go out over it
   and the torch look down (`Tops.Lip`'s way); the ladder's lying spots that touch it out.
**Acceptance:** checks green; Lune checks for the map's hole; in Studio saw a top, see the panel
fall, look down with the torch; phone-size judged.
**Read first:** ROADMAP L-13b2d2; DECISIONS D-061 and D-053; `art/tophole/README.md`;
`src/shared/StorageUnit/CrawlHole/init.luau` (`saw`, `prepare`); `src/server/Saws.luau` (Grep
`sawing`); `src/shared/Tops.luau`.

## Queue (the next run's order, from ROADMAP)
1. L-13b2d2, then L-13b2d3 (the drop in; the deal keeps the floor under each hole clear; out by
   the door or sawing sideways). L-06b the Mannequin hunts **waits on Brix** (ENG-07a/b); a Brix
   session first. None of the escapes has been tried against a keeper yet. L-12c needs L-06b.
   Then L-14; L-07, L-08, L-10, L-09.
2. **GDD, small:** its ladder line still says open mesh tops you run across (D-058/D-059 closed
   them, the crawl steered); update it (a Claude Doc: the docs tools).
3. **Check, small:** lying at a unit's front, are that door's own buttons (Open, Slam) in reach
   from the tops? If so, refuse them for crawlers (`Ladders` knows who's up).
4. **Check, small:** up top, switching to a two-handed tool in your other slot (the ladder) would
   put it on your shoulder while you lie; refuse it for crawlers ("Not up here").
5. **Bug, small:** FlashlightView's `motor()` takes only `Motor6D`, but players' shoulders here
   are `AnimationConstraint`s (docs/STUDIO.md), so a friend's torch arm likely never raises.
6. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
7. **Check, small:** G is both a door's Slam and Drop: with a tool in hand, does G at an open
   door slam, drop, or both? Give Drop its own key if it clashes.
8. **Look, small:** your torch's head is a flat black disc from behind; a faint rim? Owner's call.
9. L-06b's keepers hear doors, the keypad, a dropped tool, the saw, a crawl and the ladder (see
   D-059's signals); see a torch; treat a holed wall as solid; can't reach the tops.
10. **Check:** Output warns six times per Play, "rbxassetid://203785492 failed: Asset type does
   not match": not our code; find what asks for it.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
