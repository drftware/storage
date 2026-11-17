# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 265 (S5-03g1c1, the counter's furniture, part one) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix
pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03), up to g1c1: the looks' art (D-321), the name
  card's styles (D-322) and the first four pieces of furniture (D-323).
- g1c1: an upturned milk crate (seat 1.65), a two-pallet coffee table (1.2), a folding table
  (2.8), a sage steel shelf in `furnish.py`; `Pine` in `looks.py`; `Home.Specs.Tops` (tested).
  Home.fbx 21,820 triangles, 53 parts. Sheet `art/sheets/home-furniture.png` (`build.py --stage
  furniture`, 10 s), judged at phone size. Not uploaded: g4.
- An export rewrites Home.fbx byte-different with the same parts: `git checkout` it unless parts
  changed; bake one set with `--stage textures --sets Name` (the maps are tracked).
- Studio (Rojo unconnected) holds HEAD's code to S5-03f4b3, patched by hand, not saved; the test
  save: a HardHat on the rail, cash 478, Green worn; Device Simulator: Galaxy A16.
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `tests/stuffdeal.spec.luau`, may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03g1c2 The counter's furniture, part two (art)
The moment: a unit you'd stay in: a moving blanket over a crate, a camp bed, string lights, neon.
1. Read `furnish.py`'s furniture section (`grid`, `loft`, `place` in `build.py`) and `cards.py`'s
   `rounded`, `neon_path` (the name card's tube).
2. In `furnish.py`, the unit's way: a moving blanket (quilted, Fabric tinted or a new quilted
   set; draped, a throw you set on a crate or the floor), a camp bed (a canvas sling on a folding
   frame, lie on it), string lights (a cable in swags with warm bulbs; a hanging find, idea 14:
   clips to the wire ceiling), a neon sign (a tube shape on a clear backing, the game makes it
   Neon). Numbers in `home_spec.py`, each a piece in `PIECES`, parts in `TEXSET`, tops in
   `furniture_tops` where a find or you can go.
3. `scripts/art.sh home` (or `--stage export`); add them to `stage_furniture`'s sheet, judge at
   phone size; README table; ROADMAP. Then g2.
**Acceptance:** check green; the four in Home.fbx (not uploaded until g4), the sheet judged,
`Home.Specs.Pieces` naming them, under 20,000 triangles a part.
**Read first:** ROADMAP S5-03g1c; `art/home/README.md` (furniture); `art/home/furnish.py` (from
"the counter's furniture"); `build.py` (`stage_furniture`); `cards.py` (`rounded`, `neon_path`);
`home_spec.py` (`CRATE` to `furniture_tops`).

## Queue (next sessions, the owner's ticket order)
1. Then g2 (paint and floors on Arrange; the panels first), g3 (doors and name cards:
   ROADMAP says how the plates replace the lobby's), g4 (furniture at the counter), h; S5-03d4
   across the trip (unblocked); S5-03a2d the cars' hidden triangles; F-G1b4a2 the headlamp's
   beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-322.
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
12. Twelve neon cards are twelve lights on the floor (g3): check the light budget on the A16.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
