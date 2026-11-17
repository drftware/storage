# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 225 (the home front and furnishings) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `c9f6667`.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03). The home look (S5-03a2b, D-263): b1 the
  room (D-264) and b2 the front and furnishings (D-266) are art only; b3 puts them in the game.
- b2 (D-266, `art/home/README.md`): `art/home/out/Home.fbx`, 25 parts, 10,664 triangles: the
  home front (the M's door rig in an oak-cased doorway, the sage wall across, HomeDoor kept
  new and tinted clay, a light switch with its own rocker, the unit's round lamp), a snake
  plant in a pot, an oak bench, a planter island with a seat round it, the starter rug,
  beanbag and floor lamp. `src/shared/Home/Specs.luau` (generated) has the switch, lamp,
  pieces, starter set and every part's box; `Lobby.Specs.Dressing` places 24 plants, 10
  benches and 2 planters. Sheets: `art/sheets/lobby-home.png`, `lobby-nook.png`, and the
  spawn, unit and inside sheets re-drawn. NOTHING uploaded: the place still holds the old
  lobby template (version 57) with the climb's M fronts, which keeps working.
- Find art (third find run): P1 and V1a done (D-265 to D-267): every kit find dealt from its
  art spec; noisy finds have a loudness and a noise cap; the squishies and duck squeeze with a
  sound each. Next: V1b, the squash in your hand (ROADMAP F-G1e1b; `art/finds/WAVES.md`).

## Next task: S5-03a2b3 The home look in the game
The moment: you load in and the ground floor is plainly a calm home, your unit a little house
with a clay door, a plant either side, its lamp on and a beanbag waiting (D-263).
1. Look at `art/sheets/lobby-spawn.png`, `lobby-home.png`, `lobby-nook.png` first (I ran out
   of room to judge them at phone size: fix anything that reads wrong before uploading).
2. Upload and import `art/lobby/out/Lobby.fbx` and `art/home/out/Home.fbx` in Studio (the
   unit's way, `docs/STUDIO.md`); keep the templates where `Lobby` finds its parts.
3. `Lobby.prepare`: paint the new parts (`Lobby.Paint`: walls, ceiling, the units' insides,
   the front's Facade sage and FacadeBack warm white, the door clay, pots cream, the beanbag
   mustard), Lamps Neon, the runner Fabric; the hall lights only over the cars.
4. The home front in each gap in place of the climb's M, on `RollUpDoor` with the HomeDoor
   slats, curtain and bar (no padlock, no number plate); each unit's Lamp for the bulb.
5. Place the starter set (`Home.Specs.Starter`) in each unit and `Lobby.Specs.Dressing` round
   the floor, with colliders and Seats on benches and planters; a PointLight in each floor lamp.
6. The switch: Switch (the lamps' verb), a click, the rocker rocks (`Home.Specs.Switch.Tilt`),
   the light warms up or down over about 0.2 s; dark with the door down and the light off.
Split if it won't fit (the import and paint, then the switch and furnishings).
**Acceptance:** check green; Play in Studio shows the home fronts, furnishings and the switch
working (Output clean); OWNER.md lists what to try on a phone.
**Read first:** D-266 (grep "^## D-266" docs/DECISIONS.md); ROADMAP S5-03a2b3;
`src/shared/Home/Specs.luau`; `art/home/README.md`; `src/shared/Lobby` (grep `prepare`);
`docs/STUDIO.md` (the FBX import recipe).

## Queue (next sessions, the owner's ticket order)
1. S5-03a2c the ground floor weighed for a phone, then S5-03a3 a unit each (a Brix plots
   system first, D-252), F-G1b4a the hard hat on your head, S5-03b the mirror test, then
   S5-03c to h.
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
