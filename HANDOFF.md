# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 276 (S5-03g4b, the furniture on the counter's screen) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix
pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only)
  is built a ROADMAP piece a session (S5-03). The counter's shop now has a Furniture tab (D-334,
  `client/FurnitureTab.luau`, hosted by ShopView): this week's five pieces turning in cards, your
  cash pill, owned badges (from the new `FurnitureShelf`), Buy held until `FurnitureBought`, then
  the cash ticks down, the piece drops with the lid's clunk, "In your box". Seen in Studio Play
  on the A16 (`docs/art/S5-03g4b-*.jpg`). Bought pieces are only counts in the save so far.
- Rojo is connected. A16 clicks and captures: STUDIO.md (gui click at x + 47; a black capture
  means the display is asleep: `caffeinate -u -t 8 &` first, sandbox off).
- Test save: cash 268; owns 2 MilkCrate, 1 CampBed; Unit1 (frame at 60, 0, 478). Stock Nov 16 to
  22: MilkCrate, Pallet, SteelShelf, CampBed, NeonSign. Stage only your own paths (the find run's
  stay). `art.sh home export` restamps Home.fbx: checkout if unchanged.

## Next task: S5-03g4c Bought furniture in the job box, set out with Arrange
The moment: home from the counter, you open your job box and the camp bed is there with your
finds; Set out, and Arrange opens holding it; you slide it by the wall, it sets down with a knock
and stays, there for friends who visit. The Sims' and Bloxburg's build mode; Animal Crossing's
furniture from your pockets.
1. Read ROADMAP S5-03g4c, D-333, D-334, and how a find is set out today (D-3xx in Arrange's
   header). Too big for one session? Split: g4c1 the box lists owned pieces not set out and Set
   out opens Arrange holding one; g4c2 the server places it (`placed`, checked like a find's
   spot) and lays it for everyone, Put back returns it.
2. The box's panel (BoxPanelView) lists each owned piece not yet set out (owned minus placed),
   its picture from the art, a Set out verb; no sale for furniture (bought, not found).
3. Set out opens Arrange holding the piece: floor pieces stand on the floor clear of the walls,
   the starter set and each other (Spots' blocks from `Specs.Pieces`' boxes); Turn as finds do.
4. The server checks and saves the spot in `placed` (a new kind beside finds; save v13 if the
   shape changes: copy v12's fields-clone pattern) and lays the piece in the home with
   `Home.piece`, for everyone; Put back takes it off and it's in the box again.
5. Wall and ceiling pieces (the neon moon, string lights) wait for g4d: listed, no Set out.
6. Studio Play on the A16: set out the camp bed, rejoin, it's still there; picture it.
**Acceptance:** check green; a bought piece is in the box, set out, saved, seen by a second
client (OWNER.md), back in the box on Put back; nothing snaps; reads at A16 size.
**Read first:** ROADMAP S5-03g4c; D-334; `src/shared/Home/Arrange.luau` (header and `placed`);
`src/server/Arranging.luau` (by ranges); `src/client/BoxPanelView.luau` (the verbs, by ranges);
`src/shared/Home/Spots.luau`.

## Queue (next sessions, the owner's ticket order)
1. S5-03g4d (the lit pieces, their lights near only); then S5-03g3c choosing a card's style (the counter sells the Cash ones by then), h; S5-03d4
   across the trip (unblocked); S5-03a2d the cars' hidden triangles; F-G1b4a2 the headlamp's
   beam; F-G1b4b the hat spent.
2. The looks' polish (ROADMAP under g2b2, g2b3 and g3b): the sheet a shade darker than the panel
   at the hand-over; the mirror keeping the room's old look (re-copy on `LookWorn`); the floor's
   wipe half under the looks tray; a new card style swapping in plays rather than snaps.
3. The home's warm fill (D-290): faces turned from the bulb go near black. F-G1b5 waits for its
   art. Brix (in `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a
   PlayerSaves hook before a leaving save's last write. S4-02 to S4-05.
4. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-334.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. Late arrivals off
   `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error; the front office's
   steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the hat's first-Wear dark
   screen; the body after a respawn (D-282); a Gold's own textures.
6. One `CaughtSeized` string; S5-03d4's climb server restamps its lights (`Use.leave`). The HUD
   coin count reads 0 in Play (Nov 17, six times now). Lobby sheets: no plates. Cash spent at the
   counter and sold from the job box aren't sent to analytics (Recording has coins only).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
