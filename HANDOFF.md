# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 122 (S1-01 Saving) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-01 saving is built** (D-134). Brix moved to `e8397ff` (its saves; Brix must be pushed
  before the game, `OWNER.md`). `src/shared/Save.luau` is the save's shape, version 1 (cash,
  finds kept plain and sealed, the book's stamps, best floor); `src/server/Saving.luau` holds
  each player's save: claimed on join, written every 30 s, let go on leave and shutdown, in the
  DataStore `Saves` (Studio: `Saves.studio`). Later systems read `data(player)` or `loaded`,
  change it in place and call `save(player)`; nothing writes yet. **Verified in Studio Play**
  (Nov 14): a new save made on join, autosaved 30.7 s later, let go on Stop, claimed in under a
  second on the next Play; the stored record read back with its version, lease and UserId. No new
  errors in Output. A live server hop is the owner's (`OWNER.md`).
- Studio syncs (Rojo connected). A Brix session may run in `../engine` with a second Studio open:
  target only "Storage (placeId: 113250085204323)" by its `studio_id`. Left in Edit.
- The GDD (D-127, D-128) is the newer word; ROADMAP Phase 2 is its build order. The GDD says
  "monsters"; the code says keepers.

## Next task: S1-04b1 Things to look at: the art
The moment: a door goes up on a unit with no coins and it's still somebody's stuff in there, a
mattress on its side, boxes stacked to the bulb, a rolled carpet, so every door is worth opening
and the units feel lived in. This piece builds the things; S1-04b2 deals them into units.
1. Read ROADMAP S1-04b. Check what `art/boxes/` and `src/shared/Boxes` already hold (they may
   be stacked boxes built for something else); reuse what fits. Confirm or reshape the split.
2. Build each thing the unit's way (`art/unit/README.md`; `art/coin/` is the newest example):
   one spec, shared texture sets, procedural materials baked to PBR, an FBX, a generated
   `Specs` module, look sheets; `scripts/art.sh`. Sized to sit in an S or M unit under the bulb.
3. Import each into the place under `ReplicatedStorage.Props` (STUDIO.md's FBX recipe; the
   coin's import is the latest), anchored scenery like a find.
4. Judge each at phone size in Studio: one small capture in a unit under its bulb.
**Acceptance:** checks green; each thing built by script and in the place; seen in a unit in
Studio (say exactly what was seen); STUDIO.md has any new Blender or import trap.
**Read first:** ROADMAP S1-04b; GDD "Doors" (docs tools, search "Fewer units" and "bare");
`art/unit/README.md`; `art/coin/` (its README and build script); `art/boxes/`; STUDIO.md
"Importing kit pieces".

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-04b1 (next), then S1-04b2 Dealt into units, then S1-05 Finds you carry. S1-02 Recording
   waits on Brix ENG-12 (a Brix session is building it). S2-06 and L-08e3c wait on `OWNER.md`.
   Lobby polish ("The ride's finish", "The dials' finish") waits.
2. Found S1-01: arriving on another server (a lobby car's trip), the claim may wait up to 5 s if
   the lobby's let-go lands after you (Brix retries a held claim every 5 s). Harmless while
   nothing reads saves; the first screen that shows saved cash shows it as `loaded` fires. If 5 s
   is too slow then, a Brix ticket in neutral terms: retry sooner after a hold being let go.
3. Found S1-03: Deal's padlock count is a share of the units, so floors now get about half as
   many padlocks. S1-07 ("What a door holds") sets padlocks afresh, and whether a padlocked door
   pays more coins; leave both till then.
4. Found L-08e3b: a lobby car's `far` (the group it sent) isn't cleared when that group's trip
   fails and they're back in the car; it just ages out after `Trip.WordStale`. Harmless.
5. Found L-08e4b1: no PlayerModule in PlayerScripts in Play (STUDIO.md), so WatchView's
   `controls` lookup fails quietly (controls may stay on while you watch; untested).
6. Seen (owner, Nov 12, "fix them later"): lobby car floors go splotchy inside; a sawn side or
   top flashes see-through as its panel drops (`TopHole.saw`, `CrawlHole.saw`). The lobby car's
   lamp burns very dim. Older, see git log of HANDOFF (session 116): the gate cache, ladder and
   tool edge cases, the rbxassethash lines at Play, the flashlight out in the lobby and riding.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
