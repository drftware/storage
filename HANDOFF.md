# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 224 (the ground floor re-done calm) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `c9f6667`.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03). The home look (S5-03a2b, D-263) is split
  three ways: b1 is done (D-264), b2 is the art below, b3 puts it all in the game.
- b1: the home's own baked sets (`art/home`: Plaster, Wood; `scripts/art.sh home`) and the
  ground floor re-drawn in them: oak planks, sage and cream plaster walls with a wood baseboard
  and rail, a white ceiling on wood beams with 28 round lamps, a red runner, plaster unit
  insides. The cars' 12-deep strip keeps the climb's concrete, deck, joists and hall lights.
  Sheets: `art/sheets/lobby-spawn.png`, `-unit`, `-inside`. FBX and `Lobby/Specs.luau`
  exported, NOT uploaded: the place still holds the old template (version 57), which keeps
  working; the new parts need b3's `Lobby.prepare` paint before they import.
- The fronts in the gaps are still the climb's M (D-262), and the bulbs the climb's.

## Next task: S5-03a2b2 The home's furnishings and front (art)
The moment: from the car you see a row of little homes, a plant by each door and a bench
between, and inside yours a rug, a beanbag and a lamp waiting (D-263; Animal Crossing's first
tent comes furnished).
1. Look at `art/sheets/lobby-unit.png` and `lobby-inside.png`; read D-263 and D-264.
2. In `art/home`: the home front, built from the unit kit's door rig (`art/unit/parts.py`,
   the M's numbers) so the door still rolls: a clean roll-up door (a no-wear DoorKit variant
   or new home set; the game tints it warm), a painted frame and facade with no diamond plate,
   and a light switch plate inside by the door. Its own FBX and Specs, the unit's way.
3. Furnishings, each its own part: a snake plant in a pot (a Leaf bake: dark green with
   lighter cross bands, yellow edges, a soil band), a wood bench, a rug, a beanbag, a floor
   lamp. Place plants and benches on the ground floor's walls between doors in `art/lobby`
   (spec rows the game can read) and a couple of islands in the open middle.
4. Sheets: the front shut and open, a furnished unit, the floor from the spawn. Judge each at
   phone size (about 640 wide): calm, cared for, plainly not the climb.
Split again if it won't fit (the front, then the furnishings).
**Acceptance:** check green; new sheets show the home front and a furnished unit, the climb's
units unchanged; triangle counts in the README; nothing uploaded yet (b3 does it).
**Read first:** D-264 (grep "^## D-264" docs/DECISIONS.md); `art/home/README.md`;
`art/unit/README.md` (Parts, How it's made); `art/unit/parts.py` (the door rig's parts);
`art/lobby/build.py` (`unit_shells`, `wood_box`, `unit_fronts`); `art/home/looks.py`.

## Queue (next sessions, the owner's ticket order)
1. S5-03a2b3 the home look in the game (ROADMAP has its steps: upload, prepare's paint and
   looks for the new parts, Neon lamps, hall lights only over the cars, the home front in
   each gap, the switch), then S5-03a2c the ground floor weighed for a phone, then S5-03a3 a
   unit each (a Brix plots system first, D-252), F-G1b4a the hard hat on your head, S5-03b
   the mirror test, then S5-03c to h.
2. F-G1b4b the hard hat spent and broken; F-G1b5 waits for its art.
3. Brix ticket: Driving's stick read needs `PlayerScripts.PlayerModule`; fall back to the camera-
   turned `Humanoid.MoveDirection` as `input` does (D-254). Built in `../engine`, then the pin.
4. S4-02 monsters by lowest floor (its plan is in ROADMAP), then S4-03 the choice on the
   elevator's buttons, S4-04 trapping pays (5 coins a trapped monster), S4-05 the big find.
5. The item catalog doc and the design doc's finds section need D-250, D-251 and D-259 when
   next opened (lamps and RC car "at home"; hard hat, skates, slippers).
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Spread late arrivals off the one arrival spot (`ClimbEnd.spot`); the driving torch's rules
   vs what's seen (D-257); Play logs assets 92259888500166 (box opens, 27 fails) and 203785492
   (type mismatch). Small polish: ROADMAP lists it. The front office's counter and shelves are
   still the climb's steel (a later home piece may re-do the shop).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
