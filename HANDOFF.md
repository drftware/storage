# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 254 (S5-03e3b, the limit bar, the lid and friends, D-313) ·
**Checks:** green in the shared checkout · **Git:** `main`, committed, not pushed (`origin` is
github.com/drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror test, oak shelf, job box and its panel, taking out, selling,
  Golds, taking finds up into a climb, and Arrange (S5-03e), now done.
- Arrange's limit bar is seen on the A16 (3/25 to 4/25 as a capybara was placed); the job box's
  lid carries what's on it and stops propped at 60 with the moon lamp (D-313,
  `docs/art/S5-03e3b-*`). A friend's find settling in and a full room are not seen (OWNER.md).
- On a live server the climb is on its own server and the teleport carries nothing yet (S5-03d4).
- The test save: cash 476; set out in Unit1: MoonLamp#1 on the job box, Boombox#1 and
  CampLantern#1 on the floor, and now Capybara#1 in the room's middle (put it away or keep it).
  Watch it with a Server `GetAsync` on "Saves.studio" or `ServerStorage.ArrangeTest` "rows".
- Studio's Device Simulator is left on the Galaxy A16, landscape. To tap a gui button there,
  click its centre plus (47, 0) (STUDIO.md, S5-03e3b).
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `tests/stuffdeal.spec.luau`, and may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03f1 The mirror in every home, its real frame
The moment: walk into your home and the long mirror leaning by the wall is a real piece of
furniture (a warm wooden frame, the glass a little bevelled), the first thing you check your hat
in. The mirror test's frame is plain parts (D-280); this builds it the unit's way. Split S5-03f
in ROADMAP first: f1 the mirror's frame, f2 the clothes rail (press to wear, the find's own
sound; Animal Crossing's wardrobe), f3 nothing worn or switched on runs down at home, f4 wrap
colours tried on with a mirror by the counter.
1. Read D-280 and the home doc's ideas 21 to 24 (docs tools, by heading). If the owner's mirror
   verdict in OWNER.md is still open, go on (my default: it convinces) and say so there.
2. Model the frame in `art/home` (a new part set beside the furniture, `furnish.py` style): oak
   to match the shelf, a leaning stand, bevel on the glass edge; bake, FBX, look sheets.
3. Import it, swap MirrorView's frame for it, keeping the glass's size and the reflection maths
   untouched (`src/shared/Mirror.luau`); the room's own pieces in `Spots.blocks` (Arrange) must
   still block it.
4. `scripts/check.sh` green; see it in Studio Play on the A16 (you in the mirror, the frame at
   phone size) and capture to `docs/art/`.
**Acceptance:** check green; the frame seen in Play at phone size, or steps in OWNER.md.
**Read first:** D-280; `art/home/README.md`; `art/home/furnish.py` (the shelf, for the oak);
`src/client/MirrorView.luau` (where the frame comes from); ROADMAP S5-03f; the home doc's
"The mirror" section.

## Queue (next sessions, the owner's ticket order)
1. S5-03f2-f4, then S5-03g, h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-313.
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
