# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 242 (selling from the job box, seen in Studio, D-297) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage);
Brix pinned at `482368f`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror, oak shelf with finds, job box, its panel, taking a find out, and
  now selling one: a gold "Sell $22" on the picked card, the picture flying into your cash over
  the panel's corner, which chinks and counts up (D-297).
- Seen in Studio Play with real clicks: a sale ($234 to $256, x5 to x4), a run of four emptying
  the card, a rejoin keeping cash and counts, bad asks refused, the save written 6 s after a run.
  Found and fixed: a mashed Sell picked the card that slid into the gone one's place (a tap guard,
  `BoxPanel.Guard`). Captures `docs/art/S5-03c3a-sell.jpg`, `-flight`, `-run`, `-count`.
- Studio: `ServerStorage.ShelfTest:Invoke(player, key)` keeps a find; the box opens from a Client
  `prompt:InputHoldBegin()` on `Unit1`'s `JobBoxButton` with the camera on it. Buttons are
  clicked with `user_mouse_input`'s `instance_path`; its clicks land slower than asked (STUDIO.md).
- The find run committed its fragile lamps mid-session (D-296, save version 7 `chipped`): a sale
  doesn't read `chipped` yet, so selling the last of a cracked name leaves `chipped` above
  `finds` (S5-03c3a2 fixes it, now unblocked). Stage only your own paths: the find run shares this
  checkout.
- Find art: V5e fragile lamps built (D-296: dropped hard, the glass cracks, worth half, save v7
  `chipped`), seen cracking in Play; next V5e2 (the crack drawn, banked), then S1 (`art/finds/WAVES.md`).

## Next task: S5-03c3b Four make a Gold
The moment: you've four Teddies in the box; tap the card and a Gold button glows beside Sell;
press it and the four pictures pull together into one, a flash and a rising chime, and a gold
Teddy card deals onto the panel (Pet Simulator's golden machine).
1. Read D-188's Gold lines and D-251's ("with four of one kind, the panel offers to make it
   Gold"); the item catalog doc's Gold rule by heading, with the docs tools.
2. Decide how a Gold is kept, with the fewest save changes: a name of its own in `finds` (say
   `Teddy.Gold`, which the catalog, the shelf and ToolPicture must read) or a new map. A new save
   version builds on version 7 (`chipped`, D-296).
3. Pure core first in `Home/BoxPanel` with Lune specs: four in the box make one Gold (three
   refused, eight make two in two asks, never one on the shelf or out); Gold's price for Sell.
4. Server: a fourth way on `JobBoxTake` (same checks and limit), the four struck and the Gold
   added in one step, written as a sale is (`SellSave`), answered on `JobBoxTook`.
5. Client: a Gold verb while four or more are in the box; the animation; the new card dealt.
6. Studio Play with real clicks; capture `docs/art/S5-03c3b-*.jpg`. Hand anything left to a
   c3b2 in ROADMAP.
**Acceptance:** check green; a Gold is the server's and needs four in the box; the panel answers
with motion, sound and the new card; seen in Studio Play, Output clean.
**Read first:** ROADMAP S5-03c3b; D-188 and D-251 (Gold); D-297; `src/shared/Home/BoxPanel.luau`
(`sell`, `Ways`); `src/server/JobBoxes.luau` (`takeAsked`); `src/client/BoxPanelView.luau`
(`takeOut`, `took`, `countTo`, the verbs in `start`).

## Queue (next sessions, the owner's ticket order)
1. S5-03c3a2 a cracked find sells first at half, one off `chipped` (small; F-G1e5e is in); S5-03d-h;
   S5-03a2d the cars' hidden triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4);
   F-G1b4b the hat spent. S5-03d builds on D-293: a box find is never kept at a gate yet.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
