# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03k1 done (D-476) · **Checks:** green · **Git:** `main`, not pushed; Brix `0b8c775` (pinned, not pushed).

## State
- **The owner's priority (D-436):** recipes, egg, incubator and chick first, built so new items join
  by data alone. Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, Part 2 only).
  Order: S5-03k2 to k6 (ROADMAP grep `S5-03k`).
- **The game's recipes are data** (D-476): `Home/RecipeRows` holds the hatch (egg tag into the
  Incubator, Place, `warming` 2 h, `wobbling` 10 min, egg used up, Chick made beside), its looks,
  and `Coming` kinds (Incubator, Egg, Chick) till S5-03k3 builds them; `RecipeRows.book(Brix)`.
  Finds carry `tags` on their catalog row. `Home/RecipeMoney` caps cash an hour. Save v16 keeps
  `recipes[spotId] = { recipe, stage, began, done, seed, inside }`; a find inside has left `finds`.
- **The no-names check** is in `tests/reciperows.spec`: any `src` file named *Recipe* (RecipeRows
  only below `-- ===== Code:`) fails if it names a find, piece, coming kind, recipe or look.
- **Studio:** `rojo serve` in sync (port 34872), Edit, unsaved. **Brix:** clean at `0b8c775`.

## Next task: S5-03k2 The server's recipes
The moment: you hold an egg near your incubator, press Place, and the egg is in it, saved, warming;
leave, come back two hours later, and it has moved on exactly as if you'd stayed (Stardew's
incubator, Grow a Garden's timers). Server and pure core; the incubator isn't drawn till k3.
1. **Pure core first**, `src/shared/Home/RecipeRun.luau` (header; name keeps "Recipe"), Lune spec
   `tests/reciperun.spec.luau` before the server: `start(data, book, spot, rowId, held, now, seed)`
   checks and applies one start in one step (the held find off `finds` into `inside` when the row
   takes it, the record on `data.recipes[spot]`), `unstart` undoes it whole when the save's write
   fails (as `Furniture.unbuy`); `settle(data, book, spot, step)` applies a step's results in one
   step (`useUp` of in: `inside` cleared; `giveBack`: back into `finds`; `make`: finds added,
   `beside` answered for the server to set out, `stored` into the box; `become` of in: `inside`
   renamed); a finished record leaves `recipes`. Refusals as words (`busy`, `noRecipe`, `notHeld`).
   Never lose or double a find: spec it with a fake book row and a failed write.
2. **One due list per server** (pure, in RecipeRun or its own *Recipe* module): add, remove, next
   due, built from `book:due`; nothing ticks: one `task.delay` to the earliest, re-armed on change.
3. **Server system** `src/server/Recipes.luau`: on a home's load, catch up every record
   (`book:advance(record, now)`) and settle its steps before drawing; a press remote checked as
   Arranging and Takes do (type, then range, then the home's holder only, reach `Take.Reach` +
   `Take.Slack`, what's really in hand, rate limit), friends may only press a thing's own press
   (D-345); each recipe's stage on the drawn thing as attributes (recipe, stage, began, due) for
   every screen. Book built once at start; warn and skip any problem row.
4. **`RecipeTest`**, Studio-only (or the owner's UserId): skip a home's recipes forward by N
   seconds, so k5 can see a hatch without waiting.
5. Feedback this ticket owns: the press answered (the held find leaves the hand into the thing;
   a refused press does nothing visible, per "no obvious refusal text"). The looks are k4's.
**Acceptance:** check.sh green, the no-names check included; reciperun.spec proves a start and a
settle never lose or double a find, a failed write undoes a start, catch-up across a gap settles
once; a v15 save still loads; Studio Play: the server starts with no recipe problems in Output
(the hatch can't be pressed until k3 draws an incubator; say so).
**Read first:** ROADMAP grep `S5-03k2`; D-476; `src/shared/Home/RecipeRows.luau` (whole, ~170
lines); `vendor/brix/docs/modules/Recipes.md` "Records"; `src/server/Takes.luau` (83 lines) and
`src/shared/Home/Furniture.luau` lines 281-325 (`check`/`buy`/`unbuy`, the one-step pattern);
`src/server/Arranging.luau` lines 253-352 (`draw`, `apply`, where a drawn thing gets its press).

## Queue (next sessions, the owner's ticket order)
0. After S5-03k2: k3 to k6. `NeonSign` is both a kit find and a furniture piece: one name in the
   recipes' kinds (D-476). **The shelf's cubby finds stand off the shelf** (D-470). The held-find
   view hides the crates at phone size. Pallet and camp bed cards float back in Small (D-461).
   Hide the minimap's "You" sliver (D-447). Drop `ArrangeCamera.Room.slot`, `slotBox` (D-443);
   rename `BuildView.eyeBox` (D-444). Hand projections: use `lens` (D-446). `ToolView.luau` ~1293
   reads on-screen as "ahead" (D-451). A blocked let-go may be judged blocked again (D-456). One
   lamp drag tocked three times (D-457). Sit and Open hide a held find's kept spot; a cubby find
   can't be held to open Arrange (D-466). After S5-03k: S5-03g2b's "Polish:" lines, g3b, then the
   climb run on hold (S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06). Home and Brix
   leftovers: ROADMAP's polish "Home leftovers (from HANDOFF, Nov 19)".

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
