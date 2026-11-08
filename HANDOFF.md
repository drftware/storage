# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-08, session 29 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **The loop comes first** (owner, D-037): the owner judged the finds and boxes good, and wants a
  keeper on the floor and the loop proved fun before more polish. Every tool that works on any
  keeper moved into Phase 1 (L-11 to L-14); the GDD's build order now says so too. Where a unit's
  boxes and find stand, and carrying finds out, moved to Phase 2.
- **L-04d is done** (D-038): `src/shared/Deal.luau` lays a floor's code, notes and padlocks from a
  seed and deals each unit on its first lift (a tool from a shuffled bag, nothing, a find, a keeper
  asleep or awake) by the director's mood; `tests/deal.spec.luau`; `lune run scripts/floor-deal`.
  Nothing in Studio uses it yet (L-04e).
- **Brix's chase isn't ready:** ENG-06a, ENG-06b and ENG-07 are open in `../engine`, with pursuit
  work landing there. The Mannequin's chase (L-06b) waits on them; its art doesn't.
- **The place is unsaved** until the owner saves it (`OWNER.md`, first item): the kit, boxes and
  finds templates live only in it. Studio wasn't opened this session.

## Next task: L-06a The Mannequin's art
The moment: a shop mannequin standing in a unit's dark, and the next time your light finds it,
it's a step closer. This ticket builds it, real art, ready for L-06b to make it hunt.
1. Owner test results first (`OWNER.md`): the deal's defaults, then anything older.
2. Check `../engine/docs/ROADMAP.md`: if ENG-06 and ENG-07 have landed, say so in HANDOFF and
   ROADMAP (L-06b moves up). Don't edit Brix.
3. Read the Mannequin's row in the GDD's Keepers table, "The speed rule" and the flashlight's row
   in Tools (docs tools, those blocks only). Name each trait's hit-game precedent.
4. Verify on create.roblox.com: R15's part names, Motor6D joints and attachments, and whether a
   custom-mesh R15 model plays Roblox animations; write it in `docs/STUDIO.md`.
5. `art/mannequin/` the unit's way (spec, parts UV-mapped to one texture set, PBR bake, FBX,
   generated Specs, look sheets): faceless fibreglass, chipped paint, a seam at every joint, each
   rigid part one R15 body part, so Motor6Ds move it with no skinning.
6. Into Studio (`ReplicatedStorage.Keepers.Mannequin`), standing in a unit and in the hall; judged
   on the Galaxy A16 view by a unit's bulb and in the dark.
7. Its poses: still, mid-step frozen, a walk no faster than a player. Decide uploaded animations
   or poses set by code (a pure module, Lune-tested); default to code if uploading is a snag.
If it won't fit, split it in ROADMAP first: the model and rig, then the poses. **Acceptance:** checks green; the Mannequin in Studio, jointed and posed, reads as a mannequin
from a doorway and 30 studs down a dark hall at phone size; shots in `docs/art/`; `OWNER.md` has
what to judge.
**Read first:** the GDD's Keepers row and Tools row (above); `docs/ROADMAP.md` (L-06a, L-06b);
`art/unit/README.md`; `docs/STUDIO.md` (Blender and FBX); `docs/FRAMEWORK.md` (the Pursuit row);
`art/finds/README.md` (the last asset's pipeline).

## Queue (the next run's order, from ROADMAP)
1. L-05 notes, keypad and elevator (notes where `Deal` puts them); L-11 tools in hand (two slots
   and hands, the flashlight, bolt cutters and padlock off the test post); L-06b the Mannequin
   hunts (Brix ENG-06, ENG-07); L-04e the deal on the floor; L-12 the saw and the hole trap; L-13
   the tops' edges and the ladder; L-14 the other tools; then L-07, L-08, L-10, L-09.
2. L-05 adds "flash every light" to `MotionLights`; L-06b's keepers hear doors on `Doors.acted` at
   `DoorSound.Actions`' reach; L-04e calls `Deal.open` on a door's first lift, peek or open, and
   tracks keepers awake for the cap; L-08 lays the next floor during the ride, each floor its own
   seed (the same seed gives floors 3 and 6 the same layout).
3. **Polish waiting** (ROADMAP): the finds' words, the set's other pieces, a mimic's clean finds;
   a unit's bulb swinging; the guard's bars; a door answering before the server's word; tool
   buttons per player; the cutters' snip; a lifted door's grace; a floor's draw cost on a phone;
   the L unit; the bolt and padlock moving; a shut door muffling; a less-shake setting; a sound
   mix; a lit tube's hum; fading a far pool; the kit's texture copies; cheaper chain links; a red
   glow round a Seen eye; a haze edge; a client-side door collider; the padlock too small; the
   cursor hint once ever; the junctions' overlapping decks.
4. Studio traps (docs/STUDIO.md): a prompt triggers from the MCP only while the camera faces it;
   captures don't draw prompts or far, unstreamed areas; standing still lets the hall go dark
   in 7.5 s; CollisionFidelity reads back Default in the call that sets it; set the Device
   Simulator's device before its orientation; a find in front of a unit's bulb reads dark.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
