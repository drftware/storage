# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 251 (S5-03e2b, the server arranges, D-309) · **Checks:** green in a
clean worktree; the shared checkout's `carry.spec` is red from the find run's uncommitted mega goo
ball · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned
at `7f25310`, NOT on Brix's `origin` yet (nor 482368f and 6574e0c before it).

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror, oak shelf with finds, job box, its panel, taking out, selling,
  Golds, cracked finds at half, and taking finds up into a climb, seen in Studio (S5-03d3).
- Arrange (S5-03e): the save holds `placed` (D-308); the server judges, saves and draws every
  move (`src/server/Arranging.luau`, D-309): remotes ArrangePlace(what, on, x, y, turn) and
  ArrangePutAway(id), answered on Arranged(what, id, refusal). Seen in Studio Play through
  `ServerStorage.ArrangeTest` and the remotes (STUDIO.md "Arranging, seen in Play"); a true Stop
  and Play rejoin not watched (another Play was running). No screen yet: nobody can arrange by hand.
- On a live server the climb is on its own server and the teleport carries nothing yet (S5-03d4).
- The test save: cash 476, 37 finds (no Blob lamp, no lava lamp, no sign), Gold Teddies; nothing
  set out. Watch it with a Server `GetAsync` on "Saves.studio" (STUDIO.md).
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `src/shared/Tools/Catalog.luau`, and may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03e3a Lift, drag and set down
The moment: at home you tap Arrange, lift your lava lamp out of the box list, slide it over the
room with your thumb, see it green on the job box and red in the shelf, let go and it lands with a
soft knock, there for every friend. Bloxburg's build mode, on a phone.
1. `src/client/ArrangeView.luau`: an Arrange button only in your own home (HomeCards' pattern),
   the box list (BoxPanelView's) and the finds set out (tagged `Spots.Tag`, yours by
   `Spots.OwnerAttribute`), tappable to lift.
2. The client's own judge: build the same `Brix.Placements` as `Arranging.lay` (move that set-up
   into a shared function both call, e.g. `Arranged.home(unit, slot, pivot)` returning areas,
   frames and blocks) and load the finds set out, so `check` paints the ghost green or red.
3. Dragging: a ray from the finger onto the room's areas and finds' tops (`Arranged` frames),
   `Brix.PlacementSnap.grid({ step = 0.5, turn = 90 })`, a turn button; let go → Place; a
   Put away button; on the answer the ghost settles or slides back. Sounds: lift, knock, slide.
4. Studio Play at phone size: place, refused, put away; then a true Stop and Play rejoin (the
   finds stand again). `scripts/check.sh` green.
**Acceptance:** check green; seen in Studio Play at phone size, or the steps in OWNER.md.
**Read first:** D-308, D-309; `src/server/Arranging.luau` (`lay`, the remotes); `src/shared/Home/Arranged.luau`;
`src/shared/Home/Spots.luau`; `src/client/BoxPanelView.luau`; `../engine/docs/modules/Placements.md`.

## Queue (next sessions, the owner's ticket order)
1. S5-03e3a, e3b, then S5-03f-h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures and the Packrat wanting a Gold most; a crack drawn on a cracked card (ROADMAP polish).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
