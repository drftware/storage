# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 241 (taking a find out of the job box, seen in Studio, D-295) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage);
Brix pinned at `482368f`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror, oak shelf with finds, job box, its panel, and taking a find out
  of it into your hands or onto the shelf, now seen in Studio Play (D-293, D-295).
- Seen at 1380x761 with real clicks: the pick, Take into a hand (the count ticks down, the last
  card leaves), Shelf into a free cubby, hands full asking nothing, the find in your hand after
  Close; bad asks refused with nothing changed; a rejoin finds the box whole. Fixed: a hand drew
  its find before the picture landed. Captures `docs/art/S5-03c2b2-pick.jpg`, `-flight.jpg`,
  `-shelf.jpg`. Sounds and phone size are the owner's (OWNER.md).
- Studio: `ServerStorage.ShelfTest:Invoke(player, "", i)` empties cubby `i` into the box, so
  Shelf can be tried on a full shelf. Buttons are clicked with `user_mouse_input`'s
  `instance_path` (STUDIO.md).

## Next task: S5-03c3a Selling from the panel
The moment: you pick a common you've got five of, press Sell, the picture drops into a cash
pile with a cash-register ring, your cash ticks up beside the panel, and the x5 goes to x4.
1. Read the home doc's idea 9 (selling) and its "What you decided (Nov 16)" by heading, with the
   docs tools; D-251's panel lines. Precedents: Pet Simulator's sell, Animal Crossing's Nook box.
2. Server: a third way on `JobBoxTake` (or its own remote, the same checks and rate limit): Sell
   one `name` from the box (`Save.boxed` must hold one), price `Grades.Worth` of its grade (as
   the haul counts it, `CashOut`), strike one from `finds`, `Save.earn` the cash, write the save
   at once (CashOut's way), answer the holder with the new cash. Never one on the shelf or out.
3. Pure core first: the sell rule and its price in `Home/BoxPanel` or `Save` with Lune specs
   (one past what's in the box refused; ten asks sell at most what's there).
4. Client: a Sell verb on the picked card beside Take and Shelf (three won't fit a 114-point
   card side by side: two rows, or Sell under them; judge at phone size), the picture dropping
   with a ring, the cash shown counting up (CarResults' count), the count ticking down.
5. Studio Play: sell a few, watch the cash and count, rejoin (the sale kept); capture
   `docs/art/S5-03c3a-*.jpg`. Hand anything left to S5-03c3b (Gold) in ROADMAP.
**Acceptance:** check green; a sale is the server's (price, save) and refuses what isn't in the
box; the panel answers with motion, sound and the count; seen in Studio Play, Output clean.
**Read first:** ROADMAP S5-03c3a; the home doc's idea 9; D-251 and D-293; `src/server/JobBoxes.luau`
(`takeAsked`); `src/client/BoxPanelView.luau` (`takeOut`, `took`, the verbs in `start`);
`src/server/CashOut.luau` with `Grades.Worth`.

## Queue (next sessions, the owner's ticket order)
1. S5-03c3b four make a Gold; S5-03d-h; S5-03a2d the cars' hidden triangles; F-G1b4a2 the
   headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent (its minute starts when a hat worn at
   home leaves the ground floor). S5-03d builds on D-293: a box find is never kept at a gate yet.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259 and D-277.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
