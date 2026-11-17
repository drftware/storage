# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 262 (S5-03f4b3, the counter's mirror in line, seen; S5-03g1
split) · **Checks:** green in the shared checkout · **Git:** `main`, committed, not pushed
(`origin` is github.com/drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03), up to f4b3: the counter's mirror, all seen.
- Seen in Play on the A16 (D-320, `docs/art/S5-03f4b3-*.jpg`): from the counter facing it, Pink's
  Try on swings you to the mirror, centred in the glass, wound in pink; no slab through the peel;
  three studs aside, no Try on pills. A mirror's very first look in a session can show its room
  dark behind you for about a quarter second: ROADMAP's polish section has it.
- S5-03g1 is split in ROADMAP into g1a (floors, papers, paints, door colours), g1b (the name
  card's four styles) and g1c (the counter's furniture), with the plan doc's lists in it: no need
  to read the doc again for g1.
- Studio (Rojo still unconnected) holds all of HEAD's code, patched by hand; Shop and TryOn are
  fresh ModuleScripts (TryOn comment-stripped). Not saved by me. In the A16 simulator a
  `user_mouse_input` tap lands 47 points left of its aim (STUDIO.md): the Shop button is (310, -29).
- The test save: one HardHat (on the rail), cash 478, Green worn. Device Simulator: Galaxy A16.
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `tests/stuffdeal.spec.luau`, and may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03g1a Floors, papers, paints and door colours (art)
The moment: on the Arrange screen (g2) you pick a floor and a wall, and your unit turns from a
bare box into somewhere you'd hang out; your door's colour is what the hall sees.
1. See what a home's floor and partitions are now: `art/lobby/spec.py`'s unit shells,
   `Lobby.Paint` (`src/shared/Lobby/init.luau`), `art/sheets/lobby-inside.png`.
2. In `art/home/looks.py`, the unit's way: floor sets for carpet, checkerboard tiles and rubber
   matting (boards are the Wood set), and two or three wallpapers; calm and warm (D-263), each
   registered with its size in `build.py`. Keep each set as small as reads at phone size.
3. In `home_spec.py`: the paints (six to eight, the units' warm white `#E8DFCF` first) and the
   door colours (six to eight) as palettes, written to `Home.Specs` by `write_luau`.
4. `scripts/art.sh home`; a look sheet of one unit in each floor and paper
   (`art/sheets/home-floors.png`), judged at phone size. Update `art/home/README.md`'s tables.
5. Then g1b (ROADMAP), if context allows.
**Acceptance:** check green; the sets baked, the sheet judged, the palettes in `Home.Specs`.
**Read first:** ROADMAP S5-03g1; `art/home/README.md`; `art/home/looks.py` (`plaster`, `wood`,
`fabric`); `art/home/home_spec.py` (`write_luau`); `art/unit/README.md`; D-263.

## Queue (next sessions, the owner's ticket order)
1. S5-03g1b, g1c, then g2 (paint and floors on Arrange), g3 (doors and name cards), g4
   (furniture at the counter), h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-320.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures and the Packrat wanting a Gold most; a crack drawn on a cracked card (ROADMAP polish).
8. `CaughtSeized` is set by CaughtLunge and ArrangeView and read by FlashlightView, each with its
   own string: share one constant (a "camera held" attribute) when next in those files.
9. S5-03d4's climb server must restamp the lights it receives (`Use.leave`), as Climbs does.
10. The catch's film now comes from `Film.make`: watch a catch in Play once Rojo is connected.
11. The HUD coin count read 0 in Play again (S5-03f4b3) with the save's cash at 478: find why.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
