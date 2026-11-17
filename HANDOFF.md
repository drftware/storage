# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 246 (a cracked find sells at half, D-301; taking finds up, the
save's rules, D-302) · **Checks:** green in a throwaway worktree with this session's files; the
shared checkout is red only at the find run's uncommitted colour goo ball (`findpose`: "Order
names a built find") · **Git:** `main`, committed, not pushed (`origin` is
github.com/drftware/storage); Brix pinned at `482368f`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror, oak shelf with finds, job box, its panel, taking out, selling,
  Golds, and now a cracked find selling first at half (S5-03c3a2) and the rules for taking finds
  up (S5-03d1, pure, not wired).
- Selling cracked (D-301): `BoxPanel.sell` sells a cracked one first at half, one off `chipped`;
  the box's list carries how many are cracked (`BoxPanel.cracked`) and Sell shows the next one's
  price. Seen in Studio Play: a cracked Blob lamp sold for 9 (cash 467 to 476), then "Sell $18".
  Captures `docs/art/S5-03c3a2-{cracked,whole}.jpg`.
- Taking up (D-302): no save field; what's out stays live (D-293). `Home.Taken.settle` says how a
  taken-up find's end changes saves: Aboard (yours: nothing; a friend's: kept into theirs, struck
  off yours), Lost (`Save.lose`), Back (its crack comes home). A crash settles nothing.
- Studio: the Edit DataModel can't reach DataStores from the MCP. To crack one in the test save,
  in Play: `ServerStorage.StudioCrack:Invoke(player, "BlobLamp")` (Studio-only, JobBoxes), then
  shut and reopen the job box. The test save: cash 476, one Blob lamp (whole), Gold Teddies.
- Stage only your own paths; the find run commits its own `art/finds/` and `src/shared/Finds/`.
- Find art: S2a built the colour-change goo ball's art and colour trick (D-303), not yet seen
  in Play; next S2b (`art/finds/WAVES.md`'s Next line).

## Next task: S5-03d2 Taking finds up, wired on the server
The moment: you bring your lamp up, get caught on floor 3, and your friend grabs it and sprints
for the gate: it's theirs now. Nobody does, the gate shuts, and it's gone from your box for good.
1. Read the find run's latest commits to `src/server/Slots.luau` first; keep edits to the home's
   lines (`t.home`, `keep`, `recall`, `fromBox`). Any new pure rule gets a failing spec first in
   `tests/taken.spec.luau`.
2. Slots `keep(player)`: a taken-up find carried by someone not its owner (`t.home ~= rider`) is
   kept as theirs and returned apart (key, owner's UserId, cracked); its `home` mark cleared. The
   owner's own stays in their slots (as today).
3. A taken-up find's other ends reach one place (a Slots signal): destroyed with a floor the
   climb leaves behind, or when the climb is over, is Lost; `recall` (its owner left at home) is
   Back; nothing on a server shutting down (BindToClose).
4. Its owner leaving mid-climb: each of theirs on the climb is Lost in their final save and its
   `home` mark cleared, so a friend carrying it aboard keeps it.
5. GatePay (or a small new system) calls `Taken.settle` with each save (Saving's `data`) and
   writes every touched save at once. A taken-up find can crack on the climb now (D-296).
**Acceptance:** check green; the friend's keep and the owner's strike in one server step; a
crash path settles nothing; passes checks (Studio Play is S5-03d3).
**Read first:** ROADMAP S5-03d2; D-302, D-293; `src/shared/Home/Taken.luau`; `src/server/Slots.luau`
(`keep`, `recall`, `unbox`/`fromBox`, where finds go with a floor); `src/server/GatePay.luau`
(the keep at the gate); `src/server/Saving.luau` (`data`, `save`).

## Queue (next sessions, the owner's ticket order)
1. S5-03d3 (seen), then S5-03e-h; S5-03a2d the cars' hidden triangles; F-G1b4a2 the headlamp's
   beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302.
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
