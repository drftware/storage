# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 279 (S5-03g4c3, a find on a piece's top, D-338) · **Checks:**
green · **Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix pinned at
`7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only)
  is built a ROADMAP piece a session (S5-03). Finds now stand on furniture (D-338): the crate,
  the pallet, the folding table and the steel shelf's top tier, at the art's own height
  (`Spots.pieceTop`, through `Arrange.frameOn` on both sides); a lifted piece carries copies of
  its riders in its ghost; Put away takes them back to the box. Seen in Studio Play on the A16:
  the moon lamp on the pallet, slid and placed by the screen, the firefly jar aimed green onto
  it, a re-lay, all put away; a jar on a crate (`docs/art/S5-03g4c3-*.jpg`). The camp bed and the
  floor cushion are sat on (Seats, later); wall and ceiling pieces are still refused "notYet".
- Rojo connected. A16: STUDIO.md (gui click at x + 47; a world point at (X + 47, Y - 58);
  prompts need Studio drawing, caffeinate; Arrange's camera stays where a ShotCam leaves it).
- Test save: cash 188; owns 2 MilkCrate, 1 Pallet, 1 CampBed, all in the box; set out Boombox,
  CampLantern, Capybara, MoonLamp (on the job box top; 4/25); Unit1. Stage only your own paths.

## Next task: S5-03g4d The lit pieces
The moment: home after a climb, you hang the string lights from your ceiling and the neon moon
on the wall by the bed; they glow warm and pink as you walk in, the room suddenly yours (Bloxburg's
and Adopt Me's string lights and neon signs; Animal Crossing's wall items).
1. Read ROADMAP S5-03g4d, D-324 (the two pieces' art), D-332 (the neon card's wall wash, near
   only) and D-271 (the ground floor's light budget). The server refuses them "notYet"
   (`Arranging.place`); `BoxPanel.settable` and the tray leave them out.
2. Spots: a wall piece hangs as a find on a wall does (`fits` Wall, its back to it), the string
   lights from the ceiling by their origin; footprints from `Spots.pieceBox` (across by up on a
   wall). Check `Arranged.box`/`pivot` hang the art right (the neon moon's back flat on the
   wall, the lights' cord at the ceiling). Lune spec first (tests/spots.spec).
3. Server (`Arranging.drawPiece`): `Specs.Glows` parts Neon in `Colour`, clear parts Glass
   (or SmoothPlastic 0.85 as D-335 found for the moon's backing), no light on the server.
4. Screen: each lit piece's one light made only while it's among the nearest you, faded in and
   out, as `HomeCards`' washes are; within D-271's budget (count lights in the unit). Lift the
   "notYet" refusal; the job box and the tray list them with Set out.
5. Studio Play on the A16: set out both, walk in, pictures (the glow at phone size); OWNER.md
   steps for two clients (the friend sees the glow too).
**Acceptance:** check green; both pieces hang right, set out, saved, moved and put away; their
light only near you; reads at A16 size; nothing snaps.
**Read first:** ROADMAP S5-03g4d; D-324, D-332; `src/shared/Home/Specs.luau` (`Glows`, 146 to
175); `src/client/HomeCards.luau` (the washes, 40 to 130); `src/server/Arranging.luau`
(`drawPiece`, `place`, by ranges); `src/shared/Home/Spots.luau` (`shape`, `pieceTop`, 150 to 230).

## Queue (next sessions, the owner's ticket order)
1. S5-03g3c a card's style, h; S5-03d4; S5-03a2d the cars' hidden triangles; F-G1b4a2 the
   headlamp's beam; F-G1b4b the hat spent.
2. Sitting on a crate, the cushion or the camp bed (Seats); the steel shelf's lower tiers. In
   Arrange the job box's "Open" shows over the room; the starter shelf hides a piece behind it
   from Arrange's corner camera (both seen Nov 17). The looks' polish (g2b2, g2b3, g3b).
3. The home's warm fill (D-290): faces turned from the bulb go near black. F-G1b5 waits for its
   art. Brix (in `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a
   PlayerSaves hook before a leaving save's last write. S4-02 to S4-05.
4. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-338.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. Late arrivals off
   `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error; the front office's
   steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the hat's first-Wear dark
   screen; the body after a respawn (D-282); a Gold's own textures.
6. One `CaughtSeized` string; S5-03d4's climb server restamps its lights (`Use.leave`). The HUD
   coin count reads 0 in Play (Nov 17, eight times now). Lobby sheets: no plates. Cash spent at
   the counter and sold from the job box aren't sent to analytics (Recording has coins only).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
