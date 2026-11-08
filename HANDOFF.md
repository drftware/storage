# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 25 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-04 is split** (ROADMAP): L-04a the moving boxes (done), L-04b the first finds, L-04c the
  director dealing each unit on open.
- **L-04a is done** (D-032): five boxes at real moving-box sizes (Small, Medium, Large, Wardrobe,
  Open with its flaps up), one MeshPart each on one 1024² Cardboard atlas at 97 texels a stud
  (opposite faces share texels). `art/boxes/` builds them (`scripts/art.sh boxes`: label sheet,
  bake, FBX, look sheets `art/sheets/boxes-*.png`); asset in `art/boxes/assets.json`. `Boxes`
  (`src/shared/Boxes`) has `prepare`, `clone` and the generated Specs. Templates are in the place
  at `ReplicatedStorage.Props.Boxes`, unsaved until the owner saves (`OWNER.md`).
- **Verified in Studio** (Galaxy A16 view, Play): ten boxes cloned into unit 101 with its door
  open stand on the floor and read as boxes from the doorway, but only in a stand-in torch
  (`docs/art/L-04a-unit-torch.jpg`): the hall light stops at the doorway, so under it and in the
  dark the inside is black. The owner decides how a unit is lit (`OWNER.md`, Decide); the default
  is a torch every player carries, needed before L-04c. Not checked: Level01 quality, up close.
- CollisionFidelity can't be set from the MCP; the owner sets it (`OWNER.md`).
- `rojo serve` runs on port 34872; Studio in Edit, Device Simulator off, Quality on Automatic.

## Next task: L-04b The first finds
The moment: the beam finds something on the floor of a dark unit and you want it. Finds are what
the director deals and what players sell, trade and display (GDD), so they must read on a phone.
1. Owner test results first (`OWNER.md`), and any answer on light inside a unit (its Decide).
2. Read the GDD's "Meta: finds" list (sets and the six rarities) and the mimic line under "What's
   behind the door" (a find with no dust may be a keeper). Only those.
3. Pick 4 to 6 finds from one set the GDD names (the 1980s bedroom: say a boombox, a cassette,
   a lava lamp, a rotary phone, a roller skate), each small enough to carry, under ~600
   triangles, and judged at phone size from a unit's doorway in a torch's beam.
4. Build them as `art/finds/`, the boxes' way: one spec, one build with stages, one shared
   texture atlas (copy `art/boxes/build.py`'s Faces, packer and bake; real shapes need more
   than boxes, so add the helpers you need from `art/unit/geo.py`), dust on what faces up, FBX,
   a generated Specs module, look sheets.
5. Upload, insert, `prepare` (a `Finds` module beside `Boxes`), templates at
   `ReplicatedStorage.Props.Finds`, and judge them on the floor of unit 101 on the Galaxy A16
   view (the torch stand-in: a client SpotLight at the camera, `docs/STUDIO.md`).
**Acceptance:** checks green; the finds in the place, judged in a unit at phone size; `OWNER.md`
says what to judge and the templates to save. Rarity's look only if the GDD names one.
**Read first:** `docs/ROADMAP.md` (L-04b, L-04c); the GDD's "Meta: finds"; `art/boxes/README.md`;
`art/boxes/build.py`; `docs/STUDIO.md` (Importing kit pieces); `scripts/art.sh`.

## Queue (the next run's order, from ROADMAP)
1. L-04c (needs light in a unit first), then L-05 to L-08, and L-10 (the map) after L-05. L-05
   adds "flash every light" to `MotionLights` and builds the lobby and elevator where
   `FloorBuilder`'s stand-in is; L-06's keepers hear doors on `Doors.acted` (each event's
   `reach`); L-08 lays the next floor during the ride.
2. **Before the ladder** (ROADMAP Phase 2): close a run's back (the 16-stud gap, no floor or deck)
   and its ends at a junction's hollow block; a wire top leaves 2.8 studs under the joists.
3. **Polish waiting** (ROADMAP): the boxes' second look and the wardrobe's bar; a door answering
   before the server's word; tool buttons per player; the cutters' snip; a lifted door's grace; a
   laid floor's draw cost on a phone; the L unit; the bolt and padlock moving; a shut door muffling
   sounds; a less-shake setting; a sound mix; a lit tube's hum; fading a far pool; the kit's
   texture copies; cheaper chain links; a red glow round a Seen eye; a haze edge; a client-side
   door collider; the padlock too small; the cursor hint once ever; the junctions' overlapping
   decks (and crossing lids) seen from the tops.
4. Studio traps (docs/STUDIO.md): a prompt triggers from the MCP only while the camera faces it;
   captures don't draw prompts or far, unstreamed areas; standing still lets the hall go dark
   in 7.5 s, so walk a step before a lit capture; CollisionFidelity won't set from the MCP.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
