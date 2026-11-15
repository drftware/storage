# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 185 (B-01b, D-208) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- B-01b done: `Boxes.fbx` re-uploaded (asset 89264624666926, new ColorMap 82034486652211) and all six
  templates replaced in the place at `ReplicatedStorage.Props.Boxes`: the five scenery boxes
  (MeshParts) and `Marked`, a Model of eight parts, PrimaryPart `Marked_Body`, Atomic streaming,
  only the body solid, every part's pivot on its hinge turned square with the box, the seam Neon
  at Transparency 1. `Boxes.prepareMarked` and `Boxes.cloneMarked` wrote it. In the place, unsaved.
- Verified in Studio: the Open motion played by hand in Edit matches the filmstrip; the lit cue
  reads as two thin clean lines at Level01 and Level21 in Play (`docs/art/B-01b-cue-level01-21.jpg`);
  the three `Boxes.Sounds` load and play. No unit has a marked box yet (B-03 deals them).
- Studio shows two copies each of `Live`, `Purchasing`, `Feeds`, `Taps` (Rojo glitch; reconnect).

## Next task: B-02a The box opens
ROADMAP B-02a (B-02 split, D-205, D-208). The moment: you press Open and the tape rips, the flaps
burst; everyone near hears and sees it. B-02b adds the grade's light and the find coming out.
1. Server: a marked box answers one "Open" prompt, the way `Coins.lay`'s take does (`Prompts.make`,
   tap, line of sight off; checked alive, not wrapped, `Reach`, not through a shut door by
   `RollUpDoor.keepsApart`; rate-limited; once only). It stamps the model, e.g. attribute
   `OpenedAt` = `workspace:GetServerTimeNow()`, `OpenedBy` = UserId; the server never moves the
   flaps. Tag the box (e.g. `MarkedBox`) so screens find it. Feel numbers in Config.
2. Studio-only stand-in until B-03: a Workspace attribute (as `DevCoins` is) stands one marked
   box in the first unit that opens (`Boxes.cloneMarked(pivot, unit's hall piece)`), cue lit.
3. Client view (as `BatteryView` plays a take): for each tagged box, while shut, the seam lit
   (`Specs.Marked.Cue.Transparency`) and the Hum looped with a short roll-off; on `OpenedAt`, play
   `Specs.Marked.Motions.Open` (0.95 s) stepped only while it moves, from the server time so late
   screens catch up; one streamed in already open shows the settled pose. Tear at the snap (0.1 s),
   Flaps at the burst (about 0.3 s), Hum stops at the tear. Recipe proven in Edit this session:
   turn: `part:PivotTo(box:GetPivot() * CFrame.new(spec.Pivot) * CFrame.fromAxisAngle(spec.Axis,
   math.rad(Art.sample(track.Keys, t))))`; the seam's scale: `Size = base * v` (each axis at least
   0.001), `PivotOffset` position times v, then `PivotTo(box pivot * CFrame.new(spec.Pivot))`
   (base Size and PivotOffset read from the template). It hides by 0.14 s.
4. Pure parts (the open's rules, the clock from `OpenedAt`) get Lune specs first.
5. Prove in Play: open one from the Client with `user_keyboard_input` (STUDIO.md "Staging a buy");
   capture mid-burst and settled at Level01 and 21 in Play; Output clean; a second open refused.
**Acceptance:** checks green; Open plays the motion and both sounds in Play; a refused or repeated
open does nothing; OWNER.md has numbered two-player steps for friends seeing it.
**Read first:** ROADMAP B-02 and B-02a; D-205 and D-208; `src/shared/Boxes/init.luau`;
`src/server/Coins.luau` (`lay` and its take); `src/client/BatteryView.luau` (a take on every
screen); STUDIO.md "Staging a buy".

## Queue (next sessions, the owner's ten-ticket order)
0. **B-02b to B-05** (ROADMAP, D-205): B-02b the find comes out (the grade's coloured light
   through the flaps and its sound, F-G1c's idea moved to the box; the find lifts, turns once, is
   yours; friends see it, a Legendary further off). Then S3-03 Cut Free (it owns Studio's "CutFree"
   let-in; rows in `Products`, `Purchasing:prompt`), then S3-04 the shop.
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
   bring unseen; S1-07a, S2-02b to d4, S2-03b, S2-05a, S2-07a1 to b2 leftovers; unseen S1-10d1-3.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
