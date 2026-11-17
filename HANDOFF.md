# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 252 (S5-03e3a1, the Arrange screen built, D-311) · **Checks:**
green in the shared checkout · **Git:** `main`, committed, not pushed (`origin` is
github.com/drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror, oak shelf with finds, job box, its panel, taking out, selling,
  Golds, cracked finds at half, taking finds up into a climb, and the server arranging (S5-03e2b).
- Arrange's screen is built, passes checks, untested in Studio (S5-03e3a1, D-311):
  `src/client/ArrangeView.luau` (button in your own home, camera up in the door's corner, floor
  grid, the box's tray, lift from tray or room, drag snapped, green or red, Turn, Place, Put
  away, ×, Done) on `src/shared/Home/Arrange.luau` (the room's set-up, now shared with
  `Arranging`; the `ArrangeBox` remote; drawn finds carry `PlacedOn`/`PlacedAt`).
- On a live server the climb is on its own server and the teleport carries nothing yet (S5-03d4).
- The test save: cash 476, 37 finds (no Blob lamp, no lava lamp, no sign), Gold Teddies; nothing
  set out. Watch it with a Server `GetAsync` on "Saves.studio" (STUDIO.md).
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `src/shared/Tools/Catalog.luau`, and may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03e3a2 Arrange, seen in Studio at phone size
The moment: at home you tap Arrange, the camera eases up, a faint grid; you slide a find up out of
the tray, it ticks from square to square, red in the shelf, green on the job box; Place, a knock
and a puff, there after a rejoin. Bloxburg's build mode is the bar.
1. Studio to the front, Play with a phone device (landscape). Walk into your home: the Arrange
   button pops in (only inside, only yours). Tap it: camera up (`Arrange.Feel` Below/In/Look
   frame the room?), grid, tray filled (ArrangeBox answered).
2. Drag a card up out of the tray: whoosh, white outline, ticks; over the shelf red, over the job
   box's top green; Turn; Place: knock, dust, the server's find replaces the ghost with no gap
   (`ArrangeTest:Invoke(player, "rows")` shows it). Tap it: lifts; drag; Place. Put away; ×.
   A find on the TV's top, then move the TV (the rider jumps with it). Done: camera back, the
   touch controls and keys back.
3. A true Stop and Play rejoin: the finds stand again and the screen judges round them.
4. Fix what's off (watch `ScreenPointToRay` vs the inset, `GuiService.TouchControlsEnabled`,
   the Highlight's AlwaysOnTop). Capture into `docs/art/S5-03e3a2-*.jpg` (STUDIO.md: the macOS
   window capture when `screen_capture` times out). `scripts/check.sh` green.
**Acceptance:** check green; each step seen in Studio Play at phone size, or its steps in OWNER.md.
**Read first:** D-311; `src/client/ArrangeView.luau`; `src/shared/Home/Arrange.luau`;
`src/server/Arranging.luau` (the ArrangeTest bindable); STUDIO.md "Arranging, seen in Play";
OWNER.md's home defaults item 12.

## Queue (next sessions, the owner's ticket order)
1. S5-03e3a2, e3b, then S5-03f-h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311.
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
