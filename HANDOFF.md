# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 277 (the furniture's paints, D-335; S5-03g4c1, the server sets
furniture out, D-336) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin`
drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only)
  is built a ROADMAP piece a session (S5-03). The counter's furniture now wears its sheet's paints
  (`Home.paint`, D-335; the place's template repainted in Edit; the tab re-captured,
  `docs/art/S5-03g4b-tab.jpg`). The server sets a bought floor piece out like a find (D-336):
  placed name "CampBed:Furniture#1" in `placed`, its footprint from its parts, drawn solid with
  `Home.piece`, crates in turn mustard, teal, terracotta; Put back returns it. Seen in Studio Play
  through `ServerStorage.ArrangeTest` (`docs/art/S5-03g4c-camp-bed.jpg`). No screen for it yet.
- Rojo is connected. A16 clicks and captures: STUDIO.md (gui click at x + 47; a black capture
  means the display is asleep: `caffeinate -u -t 8 &` first, sandbox off; aiming a shot, too).
- Test save: cash 268; owns 2 MilkCrate, 1 CampBed, all in the box (nothing set out); Unit1.
  Stage only your own paths (the find run's stay). `art.sh home export` restamps Home.fbx:
  checkout if unchanged.

## Next task: S5-03g4c2 The job box and Arrange on screen for bought furniture
The moment: home from the counter, you open your job box and the camp bed is there with your
finds; Set out, and Arrange opens holding it; you slide it by the wall, green where it fits, it
sets down with a knock and stays. The Sims' and Bloxburg's build mode; Animal Crossing's pockets.
1. Read ROADMAP S5-03g4c2 and D-336. The server side is done: Place with
   `what = Furniture.placed(id)`, Put away by the set-out id, the box's fourth value.
2. BoxPanelView: list each piece in the box (`ArrangeBox`'s fourth value, or ask `ArrangeTest`'s
   "rows" in Studio) below or beside the finds, its picture the painted art in a viewport as
   FurnitureTab's card draws it (`Home.template()` parts, framed from `Spots.pieceBox`), the
   verb Set out; no sale, no Hand. Wall and ceiling pieces listed without Set out (g4d).
3. Set out opens Arrange holding it, as a find from the tray is held: the lifted ghost is
   `Home.piece`'s model, green or red by the same judge (`Arrange.shapeOf` already knows it);
   Turn as finds turn; let down, the server answers and it lands with the knock.
4. In Arrange a piece set out lifts by a tap (it carries `Spots.Tag` and the id) and moves or
   goes back to the box with Put away, as a find does.
5. Studio Play on the A16: set out the camp bed from the box, rejoin, still there, put back;
   picture each step. Two clients: OWNER.md steps (the second sees it land).
**Acceptance:** check green; a bought piece listed in the box with its picture, set out through
Arrange, saved, back in the box on Put away; nothing snaps; reads at A16 size.
**Read first:** ROADMAP S5-03g4c2; D-336; `src/client/BoxPanelView.luau` (the verbs, by
ranges); `src/client/ArrangeView.luau` (how a find from the tray is lifted, by ranges);
`src/client/FurnitureTab.luau` (the card's viewport, 360 to 400); `src/server/Arranging.luau`
(`sendBox`, `place`).

## Queue (next sessions, the owner's ticket order)
1. S5-03g4d (the lit pieces on walls and ceilings, their lights near only; the server refuses
   them "notYet" until then); then S5-03g3c choosing a card's style, h; S5-03d4 across the trip;
   S5-03a2d the cars' hidden triangles; F-G1b4a2 the headlamp's beam; F-G1b4b the hat spent.
2. Furniture tops: a find standing on a pallet or a crate (`Specs.Tops`), sitting on a crate or
   the camp bed (Seats). The looks' polish (ROADMAP under g2b2, g2b3 and g3b).
3. The home's warm fill (D-290): faces turned from the bulb go near black. F-G1b5 waits for its
   art. Brix (in `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a
   PlayerSaves hook before a leaving save's last write. S4-02 to S4-05.
4. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-336.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. Late arrivals off
   `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error; the front office's
   steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the hat's first-Wear dark
   screen; the body after a respawn (D-282); a Gold's own textures.
6. One `CaughtSeized` string; S5-03d4's climb server restamps its lights (`Use.leave`). The HUD
   coin count reads 0 in Play (Nov 17, seven times now). Lobby sheets: no plates. Cash spent at
   the counter and sold from the job box aren't sent to analytics (Recording has coins only).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
