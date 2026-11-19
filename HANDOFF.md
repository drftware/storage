# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j8a1 done (D-477) · **Checks:** green · **Git:** `main`, not pushed; Brix `9408d63` (pinned, not pushed).

## State
- **The owner's new ticket goes first:** S5-03j8 "Shelves are surfaces like anything else" (ROADMAP
  grep `S5-03j8`), split a1, a2, b, c, d. S5-03k2 waits until j8d is done, then is Next task again
  exactly as before: copy its section from `git show 61a6588:HANDOFF.md`.
- **Brix's Placements takes several tops** (D-477): a shape's `tops` list and `height`; an area's or
  top's `height` (the room above); a pose's and a saved row's `top` (which top, the first when left
  out); refusal "tooTall". The game moved to the list, every piece still offering its one top.
- The save's current placed rows take an optional `top`; the server's and pure pose copies keep it.
  The client's copies don't yet (j8b's list in ROADMAP).
- **Studio:** `rojo serve` in sync (port 34872), Edit, unsaved. Untested in Studio this session.

## Next task: S5-03j8a2 Every piece's surfaces as data
The moment this serves (in j8b): you drag a lamp at the steel shelf's middle tier and it goes there.
1. `art/home/home_spec.py` (`furniture_tops`, ~194; the shelf's `SHELF`, `SHELF_ROOM`,
   `shelf_spots` ~62-110) and its Specs writer (~541): one `Surfaces` table for every piece with
   any: each surface's middle in the piece's frame, its size across and deep, and the room above it
   (the gap under the next tier; left out when open). The steel shelf's four tiers (room = next
   tier's top minus its lip minus this top); the oak shelf's six cubbies (room `SHELF` h) and its
   own top; the job box's lid; crate, pallet, table. Keep `Tops` for seats (`Home/Sit`, homesit
   spec) unless they read `Surfaces` cleanly. Rebuild with `scripts/art.sh home`; never hand-edit.
2. One pure lookup in `Spots` (say `Spots.surfaces(kind)`: each surface's Area with `height`, and
   its offset from the middle of the piece's box foot) replacing `pieceTop`, `PieceTops` and
   `StarterTops`; `Spots.shape` gives a piece all its surfaces as `tops` and every find its
   `height` (its box's tall). The rug stays a floor; seats stay seats.
3. `Arrange.frameOn` takes the top's number (a pose's `top`) for a piece's surface offset; the
   other callers (`Lobby/init` ~369, `JobBoxView`) read the lookup.
4. Lune specs: the steel shelf four surfaces, its tiers' rooms, its top open; the oak shelf seven;
   a find too tall for a cubby refused "tooTall" on Brix's judge, a short one fine; no piece or
   find named in the lookup's code (data only).
**Acceptance:** check.sh green; aiming still picks each piece's highest surface as today (j8b
changes aim); a v16 save loads unchanged.
**Read first:** ROADMAP grep `S5-03j8`; D-477; `src/shared/Home/Spots.luau` lines 40-60 and
160-250; `art/home/home_spec.py` lines 60-110 and 190-210; `src/shared/Home/Arrange.luau` lines
445-473; `vendor/brix/docs/modules/Placements.md` lines 1-35.

## Queue (next sessions, the owner's ticket order)
0. S5-03j8a2, b, c, d; then S5-03k2 to k6. `NeonSign` is both a kit find and a furniture piece:
   one name in the recipes' kinds (D-476). The held-find view hides the crates at phone size.
   Pallet and camp bed cards float back in Small (D-461). Hide the minimap's "You" sliver (D-447).
   Drop `ArrangeCamera.Room.slot`, `slotBox` (D-443); rename `BuildView.eyeBox` (D-444). Hand
   projections: use `lens` (D-446). `ToolView.luau` ~1293 reads on-screen as "ahead" (D-451). A
   blocked let-go may be judged blocked again (D-456). One lamp drag tocked three times (D-457).
   After S5-03k: S5-03g2b's "Polish:" lines, g3b, then the climb run on hold (S5-01d's torch,
   S5-02b2c2, S4-06, S4-07, S5-04, S5-06). Home and Brix leftovers: ROADMAP's polish "Home
   leftovers (from HANDOFF, Nov 19)".

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
