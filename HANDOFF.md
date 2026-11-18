# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 280 (S5-03g4d, the lit pieces, D-339) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix pinned at `7f25310`,
NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only)
  is built a ROADMAP piece a session (S5-03). All eight pieces of the counter's furniture now set
  out (D-339): the string lights hang from the ceiling (aimed over the floor under them, as The
  Sims hangs ceiling lights), the neon moon on a wall; their bulbs and tube glow everywhere and
  the three lit pieces nearest you throw real light (`HomeGlows`, `Home.LitPiece`). Seen in Studio
  Play on the A16: both set out, laid from the save after a restart, moved, lamp on and off
  (`docs/art/S5-03g4d-*.jpg`); the moon's wall glow is faint with the door up (`OWNER.md`).
- Every home today is the XL box: home 1's partitions 19.7 apart, its back wall 30 in; the room's
  areas (`Spots.room`) come from the slot's XL `Inside`. `Spots.Sizes` holds only the limits.
- Rojo connected. A16: STUDIO.md (macOS window capture in Play, never `screen_capture`; gui
  click at x + 47; a world point at (X + 47, Y - 58); `ArrangeTest` "own" for a piece).
- Test save: cash 188; owns 2 MilkCrate, 1 Pallet, 1 CampBed in the box; set out the string
  lights (ceiling, back half) and the neon moon (back wall, high), Boombox, CampLantern,
  Capybara, MoonLamp; Unit1. Stage only your own paths.

## Next task: S5-03h The four sizes and the walls that move
The moment: back from a good climb you pay to grow your home; the partitions grind back, the door
widens, and everything you'd set out stays exactly where it was, with room for more (Bloxburg's
house expansions, Adopt Me's bigger homes, Animal Crossing's house upgrades; ideas 30 and 31).
1. Read ROADMAP S5-03h and the home doc's ideas 30, 31 and "What you decided (Nov 16)" (docs
   tools, by heading). It won't fit one session: split it in ROADMAP first, e.g. h1 the sizes
   (each size's inside box per slot, the save's size, Small for everyone, the room's areas and
   limit from it, a Lune spec first), h2 the small home's walls drawn (partitions and the back
   wall where the size ends, the panels and lamp following), h3 buying Medium with cash at the
   counter and the walls grinding back with sound, h4 what's set out kept through a resize
   (nothing ever lost: anything outside the new box goes back to the job box). Large and XL for
   Robux stay S5-07.
2. Do h1 this session: pure first (`Spots`), then `Arrange.room` and `Arranging`, then a look in
   Studio Play at the room's areas for Small.
**Acceptance:** check green; the split written in ROADMAP; a Small home's areas and limit come
from its size and saved rows outside it go back to the box (spec); seen in Studio.
**Read first:** ROADMAP S5-03h; the home doc's ideas 30 and 31; D-259, D-325 (the panels);
`src/shared/Home/Spots.luau` (`Sizes`, `room`, `limit`); `src/shared/Home/Arrange.luau` (`room`,
215 to 260); `src/shared/Lobby/Specs.luau` (`Slots`, 264 to 290).

## Queue (next sessions, the owner's ticket order)
1. S5-03g3c a card's style, h; S5-03d4; S5-03a2d the cars' hidden triangles; F-G1b4a2 the
   headlamp's beam; F-G1b4b the hat spent.
2. Sitting on a crate, the cushion or the camp bed (Seats); the steel shelf's lower tiers. In
   Arrange the job box's "Open" shows over the room; the starter shelf hides a piece behind it
   from Arrange's corner camera and from the doorway (the moon on the back wall). A lifted lit
   piece's light stays where it was until it's set down. The looks' polish (g2b2, g2b3, g3b).
3. The home's warm fill (D-290): faces turned from the bulb go near black. F-G1b5 waits for its
   art. Brix (in `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a
   PlayerSaves hook before a leaving save's last write. S4-02 to S4-05.
4. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-339.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. Late arrivals off
   `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error; the front office's
   steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the hat's first-Wear dark
   screen; the body after a respawn (D-282); a Gold's own textures.
6. One `CaughtSeized` string; S5-03d4's climb server restamps its lights (`Use.leave`). The HUD
   coin count reads 0 in Play (Nov 17, nine times now). Lobby sheets: no plates. Cash spent at
   the counter and sold from the job box aren't sent to analytics (Recording has coins only).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
