# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 184 (B-01a, D-208) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- B-01a done: the marked box is built in `art/boxes` (eight parts in `Boxes.fbx`, the shared
  Cardboard atlas rebaked at 90 texels a stud), its Open motion, cue and hinges in
  `Boxes/Specs.luau` (`Specs.Marked`), its sounds in `Boxes.Sounds`, sheets
  `art/sheets/boxes-marked-*.png` judged at phone size. Nothing uploaded or put in the place.
- The place's box templates (`ReplicatedStorage.Props.Boxes`) are still the old upload with the
  old atlas baked in, so they look as before. The repo's `Boxes.fbx` is the new one.
- S3-02's `Purchasing` and `Live` are in; nothing is on sale. Studio shows two copies each of
  `Live`, `Purchasing`, `Feeds`, `Taps` (a Rojo sync glitch; reconnect Rojo if an edit won't run).

## Next task: B-01b The box, in Studio
ROADMAP B-01b (D-208). The moment is B-01a's: a plain box with something in it. This piece puts
it in the place, so B-02 can open it.
1. `lune run scripts/upload_art Boxes` (updates asset 89264624666926 in place; `art/boxes/assets.json`).
   Insert it with the MCP's `insert_asset`; remove the `Assistant:` tag it adds.
2. Replace the five templates in `ReplicatedStorage.Props.Boxes` with the new ones the README's
   way (`Boxes.prepare`, PivotTo the origin; set CollisionFidelity per STUDIO.md if it won't take).
   Check first that no live code holds the old instances (they're cloned by name).
3. Write `Boxes.prepareMarked(model)` and `Boxes.cloneMarked(pivot, parent)` in
   `src/shared/Boxes/init.luau`: anchored, CanTouch off, only `Marked_Body` collides (Box
   fidelity); each part's PivotOffset put on its `Specs.Marked.Parts` hinge (Pivot is from the
   body's pivot, the middle of its bottom); the seam `Material = Neon`, `Color` the cue's,
   `Transparency = 1`, CastShadow off. Group the eight inserted `Marked_*` parts into a Model
   `Marked` (PrimaryPart the body) in `ReplicatedStorage.Props.Boxes`.
4. In Edit, clone one into a unit and play `Specs.Marked.Motions.Open` by hand with
   `Finds/Art.luau`'s `Art.sample` (turn = degrees about Axis through Pivot, scale = times size):
   capture it mid-open and settled; compare with `boxes-marked-open-strip.png`.
5. Light the cue (seam Transparency to `Cue.Transparency`) and capture from a unit's doorway at
   QualityLevel 1 and 21 (wait several seconds after switching): it must read faint but clear
   and not smear (STUDIO.md "Neon blooms into blobs"). Play the three `Boxes.Sounds` once.
6. Say in OWNER.md's "Judge the marked box" where the templates live.
**Acceptance:** checks green; the six templates in the place; the marked box opens in Edit as the
filmstrip shows; the cue reads at phone size in both graphics levels; HANDOFF and OWNER.md say
where the templates live.
**Read first:** ROADMAP B-01b; D-208; `art/boxes/README.md` ("Into Studio", "The marked box");
`src/shared/Boxes/init.luau`; the `Marked` block of `src/shared/Boxes/Specs.luau`; STUDIO.md
"Importing kit pieces" (line ~861).

## Queue (next sessions, the owner's ten-ticket order)
0. **B-02 to B-05** (ROADMAP, D-205): B-02 plays `Specs.Marked.Motions.Open` (0.95 s) inside its
   reveal, with `Boxes.Sounds` (Tear at the snap, 0.1 s; Flaps at the burst, about 0.3 s). Then
   S3-03 Cut Free (it owns Studio's "CutFree" let-in; rows in `Products`, prompted with
   `Purchasing:prompt`), then S3-04 the counter's shop.
1. **S4-01 Floors made by rules.** Split first: S4-01a the rules table and the top gone, S4-01b
   what changes floor to floor. Read the GDD's "Floor rules", D-106, D-128, `Climb.luau`,
   `Deal.luau`; grep `Climb.Top`, `Climb.Building`, `topped`. The escape ("Made it") has no trigger
   once the top goes: keep its code, note it. The climb goes past floor 3 in Studio (DevFloorNumber 3).
2. **F-G1b Using a find plays what it does** (ROADMAP F-G1); then S4-02 to S4-05 (5 coins a trapped
   monster, D-188). Any ticket that adds finds starts from the catalog doc the GDD's finds section links.
3. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
4. L-08e3c, L-14b2d wait on `OWNER.md`; R-01 later. A GDD section costs ~15k context: `view`
   with `outline: true` and `from` the heading's id, then `search` with `blocks` on just the part needed.
5. Small, from earlier (ROADMAP and `git log` hold the detail): Rojo's duplicate modules (above);
   a dropped find bumps a walking player (D-182); a take could show the arm first (KeeperView Kit);
   rbxassethash warnings in Play; the Packrat's dead Slots entry and S2-06b1's way home; move the
   Mannequin's pose onto `Rig.luau` (D-176); the watch bar's empty panel; S3-01b's wipe after the
   bring unseen; S1-07a, S2-02b to d4, S2-03b, S2-05a, S2-07a1 to b2 leftovers; unseen S1-10d1 to
   d3, S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
