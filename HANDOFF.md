# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 256 (S5-03f2a, the clothes rail's art, D-315) ·
**Checks:** green in the shared checkout · **Git:** `main`, committed, not pushed (`origin` is
github.com/drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror test, shelf, job box and its panel, taking out, selling, Golds,
  taking finds up, Arrange, the mirror's real frame, and now the clothes rail's art (S5-03f2a).
- The rail (D-315) stands past the mirror on its wall in all 12 homes: oak posts on castors, a
  hat shelf, three oak hangers on a graphite bar, a shoe rack. Nothing hangs on it yet. Seen in
  Play on the A16 (`docs/art/S5-03f2a-rail-a16.jpg`). `Home.rail(template, unit, face)`;
  `Specs.Rail` has its rows' heights (`Shelf`, `Bar`, `Rack`) and the hangers' places.
- The place's Home (asset 110439035194989) was updated in place and re-imported into
  Props.Home in Edit (worst 0.0006; clone all of `ReplicatedStorage.Shared` to import, README).
  In `home_spec.py`, `RAIL` is the wall's paint rail: the clothes rail's numbers are `GARMENT*`.
- On a live server the climb is on its own server and the teleport carries nothing yet (S5-03d4).
- The test save: cash 476 (Play showed 0 this time: not looked into); set out in Unit1. Studio's
  Device Simulator is left on the Galaxy A16, landscape; to tap a gui button there, click its
  centre plus (47, 0) (STUDIO.md).
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `tests/stuffdeal.spec.luau`, and may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03f2b Wearing from the rail
The moment: everything you own that you can wear hangs on your rail; you press the hard hat and
you're wearing it, with its knock and its lamp's click, and you see it on you in the mirror
(Lethal Company's suit rack). Press again to hang it back.
1. Read D-315 (the rail, its rows), D-277 and D-283 (the hat worn, its slot). Wearables today:
   the hard hat (hat shelf); the skates if they're worn (check the catalog, the rack); no
   slippers or clothes exist yet, so invent none. Split f2b in ROADMAP if it won't fit.
2. Wearables you own stand on their row (`Specs.Rail`) instead of the shelf, as the shelf's
   finds stand on its spots (`Shelves`, `Shelf`): server-placed, in every home.
3. Press one ("Wear"): the server checks it's yours, you're home and in reach, rate-limits, and
   puts it on your head through `Slots` (as `FindUses`' Wear does from your hand), the find's
   own press sound and motion; it's off the rail. Press again ("Hang up", on the rail) to hang
   it back. Worn into the elevator it's a find you take up (D-251).
4. `scripts/check.sh` green; see it in Play on the A16: wear the hat from the rail, see it in
   the mirror, hang it back; capture to `docs/art/`.
**Acceptance:** check green; wearing from the rail seen at phone size, or exact steps in OWNER.md.
**Read first:** D-315; D-277 and D-283; `src/server/Shelves.luau` (how kept finds stand);
`src/server/FindUses.luau` near `Head.Verb`; `src/server/Slots.luau` `toHead`; `Specs.Rail` in
`src/shared/Home/Specs.luau`.

## Queue (next sessions, the owner's ticket order)
1. S5-03f3, f4, then S5-03g, h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-315.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures and the Packrat wanting a Gold most; a crack drawn on a cracked card (ROADMAP polish).
8. `CaughtSeized` is set by CaughtLunge and ArrangeView and read by FlashlightView, each with its
   own string: share one constant (a "camera held" attribute) when next in those files.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
