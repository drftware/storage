# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 255 (S5-03f1, the mirror's real frame, D-314) ·
**Checks:** green in the shared checkout · **Git:** `main`, committed, not pushed (`origin` is
github.com/drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror test, shelf, job box and its panel, taking out, selling, Golds,
  taking finds up, Arrange, and now the mirror's real frame (S5-03f1).
- The mirror wears a moulded oak frame, a bevelled glass edge and felt pads (D-314), from the
  place's Home (asset 110439035194989, updated in place and re-imported into Props.Home). Seen in
  Play on the A16: you in it, the room behind (`docs/art/S5-03f1-*`). Where it stands is now the
  art's (`Specs.Mirror`); `Home.mirror(template, unit, face)`.
- Importing Home in Edit: clone all of `ReplicatedStorage.Shared`, not Home alone (README).
- On a live server the climb is on its own server and the teleport carries nothing yet (S5-03d4).
- The test save: cash 476; set out in Unit1: MoonLamp#1 on the job box, Boombox#1, CampLantern#1
  and Capybara#1. Studio's Device Simulator is left on the Galaxy A16, landscape; to tap a gui
  button there, click its centre plus (47, 0) (STUDIO.md).
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `tests/stuffdeal.spec.luau`, and may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03f2 The clothes rail
The moment: beside your mirror stands a rolling garment rail with everything you can wear
hanging on it; you press the hard hat and you're wearing it, with its knock and its lamp's click,
and you see it on you in the mirror (Lethal Company's suit rack). Press again to hang it back.
1. Read the home doc's idea 23 (docs tools, search "clothes rail") and D-277, D-283 (the hat
   worn, its slot). Split f2 in ROADMAP if it won't fit (f2a the rail's art, f2b pressing).
2. Model the rail in `art/home/furnish.py` (oak and soft graphite steel, D-263's calm look; a
   hanger per wearable kind), the mirror's way: spec numbers in `home_spec.py`, a `Rail` piece,
   bake, FBX, `scripts/art.sh home export`, `lune run scripts/upload_art Home`, re-import.
3. Stand it beside the mirror in every home (`Home.piece`; keep Arrange's fixed footprints and
   `Spots.blocks` right) and show what you own that's wearable hanging on it.
4. Press to wear and to hang back: server-owned (validate, rate-limit), the find's own sound.
5. `scripts/check.sh` green; see it in Play on the A16 (wear the hat from the rail, see it in the
   mirror) and capture to `docs/art/`.
**Acceptance:** check green; the rail seen at phone size, wearing from it seen or in OWNER.md.
**Read first:** the home doc's idea 23; D-277 and D-283; ROADMAP S5-03f2; `art/home/furnish.py`
(`mirror_frame`, the shelf); `src/shared/Home/init.luau` (`piece`, `mirror`); how the hat is worn
now (`Grep "Wear"` in `src/server`).

## Queue (next sessions, the owner's ticket order)
1. S5-03f3, f4, then S5-03g, h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-314.
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
