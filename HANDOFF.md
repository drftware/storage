# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 82 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-07 split in five** (ROADMAP): a the wrap and being stored, b the wrap you see and hear,
  c banging, d cut free, e the padlock. "Left behind" and "Whole team kept" moved to L-08.
- **L-07a done (D-095): getting kept.** Caught, what you carried drops where you stood, and in
  the black the building stores you in a shut unit away from you (never the nearest, an
  unopened one first, never one a keeper is in), held still facing its door, "Wait for a
  friend" on screen, every prompt refused. Its door all the way up lets you out (the stand-in
  until L-07d). The lobby stand-in is gone, and with it the repeat catch by the lobby.
- Pure `Kept` (Lune-tested), server `KeptPlayers`, `Caught.Wrap` (was `Out`); keepers skip
  anyone with the `Kept` attribute; `Prompts.wrapped`, `Slots:dropAll`, `Deals:hold`.
- **Verified in Studio** (seed 7, floor 1): stored in 153, 124, 112 facing the door; a horn
  dropped where I stood; the door opened let me out and I walked; one catch each; Output clean.

## Next task: L-07b The wrap you can see and hear
The moment: your friend lifts the door and there you are in the dark, shrink-wrapped head to
foot in clear stretch film, and as the keeper wraps you, you hear the film squeal in the black.
1. Owner test results first, if pasted.
2. Art first, the unit's way (`art/unit/README.md`): a new `art/` script in Blender 5.2 for a
   standing body's wrap: clear stretch film in overlapping bands, creased, a little cloudy,
   UV-mapped to a baked PBR set; FBX, a generated Specs module, look sheets. Size it to Roblox's
   default R15 body (the Mannequin's spec has the proportions) and scale it at runtime to the
   kept character's bounding box. Judge it at phone size in a dark unit.
3. Server: `KeptPlayers` puts the wrap on the kept character at the move (welded, massless, no
   collision; arms down at the sides if they poke through) and takes it off as they're let out.
   Hide it on the kept player's own screen.
4. The squeal: a stretch-film sound on the catch, for the caught one in the black and anyone
   near. Find a real asset (verify its id loads in Studio); list it in `docs/STUDIO.md`.
**Acceptance:** checks green; in Studio on seed 7, floor 1, caught by 157's Mannequin, the
kept body stands wrapped in its unit as seen from its open door (a capture with the ambient
raised, `docs/STUDIO.md`), nothing of the film in your own view, the squeal in Output's sounds
log or heard; Output clean.
**Read first:** ROADMAP L-07b; D-095; `art/unit/README.md`; `art/bubblewrap/README.md` (clear
film already made once); `art/mannequin/spec.py` (R15 proportions); `src/server/KeptPlayers.luau`.

## Queue (the next run's order, from ROADMAP)
1. L-07b, then L-07c (banging, the light under the door), L-07d (cut free), L-07e (the
   padlock). L-14b2d if the owner asks. Then L-08 (it takes Left behind), L-09.
2. **Small, own session:** cut `MovingBlanket`, `GlowSticks` from `Deal.Tools`/`Deal.Bag` (D-091);
   it reshuffles every seed, so recheck the units `OWNER.md`'s steps name (seed 7, floors 1, 3).
3. **Check, small:** caught crawling or on the ladder, `CrawlView`/`LadderView` may keep holding
   PlatformStand after you're let out. (Walking after a plain catch works: the old "couldn't
   move" was the MCP's `Humanoid:Move`, `docs/STUDIO.md`.)
4. **Check, small:** a press made the moment you arrive reaches the server while it still sees you
   a few studs back (D-085): Saws, Ladders and a door's Cut and Lock check where you stand; allow
   for it as `Crawling.counts` does if one drops. Server facing is 0.4 s late (D-084).
5. **Checks on the tops, small:** Climb or Drop down lying behind a sawn hole slides you across
   it; a friend's drop-in lands 0.2 under the floor; crawlers should be refused a door's buttons
   and the ladder (`Ladders:crawling`). A horn blown up there is heard from the unit under you.
6. **Bugs, small:** FlashlightView's `motor()` takes only `Motor6D` (shoulders are
   `AnimationConstraint`s), so a friend's torch arm never raises; DoorSounds' first slam lands up
   to 0.35 s late (`SoundPrimer.prime`). HornView now carries every verb tool's button: rename it
   (`UseButton`) when a third tool needs it.
7. **Check:** G is a door's Slam and a tool's Drop: which wins at an open door? A left click
   blows a horn (or lays wrap) even while clicking the slots' bar. Output's "rbxassetid://
   203785492 ... Asset type does not match" on Play: in none of our code, templates or services.
8. Keepers should hear the keypad, a dropped tool, the saw, a crawl, the ladder and a drop in
   (D-059, D-066) through `Keepers:hear` (D-092). **Small:** a trapped keeper's every blow prints;
   a crawler's feet as `Wraps` reads them must sit within `Wrap.Under` (3), or crawling won't pop.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
