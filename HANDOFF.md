# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-08, session 30 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-06a is done** (D-039): the Mannequin, 6.3 studs of faceless, chipped fibreglass in fifteen
  rigid R15 parts (`art/mannequin/`, 8,356 triangles, one 1024² set). `Mannequin.prepare` rigs the
  import with R15's RigAttachments and Motor6Ds; `Mannequin/Pose.luau` (pure, 26,222 Lune checks)
  holds its shop pose and a stop-motion walk a light freezes on a key. In Studio, Motor6Ds pose it
  exactly as the pure maths says, and it reads 30 studs down the hall (`docs/art/L-06a-hall.jpg`).
- **The place is saved** (owner, Nov 8): every template so far, the Mannequin's at
  `ReplicatedStorage.Keepers.Mannequin`, lives in it (D-009). A new template needs saving again.
- **Brix's chase isn't ready:** ENG-06a, ENG-06b and ENG-07 are open in `../engine`. L-06b (the
  Mannequin hunts) waits on them; its brief in ROADMAP now says how to drive the body.
- **L-05 is split** (ROADMAP): L-05a the elevator's art, L-05b the notes, keypad and gate.

## Next task: L-05a The elevator's art
The moment: the last friend sprinting for the lit car as its gate starts to fold shut. This
ticket builds what that happens in: the freight elevator car, its folding gate, the keypad, a
sticky note, real art the unit's way, ready for L-05b to make them work.
1. Owner test results first (`OWNER.md`): the Mannequin's sheets, then anything older.
2. Check `../engine/docs/ROADMAP.md`: if ENG-06 and ENG-07 have landed, say so in HANDOFF and
   ROADMAP and do L-06b instead. Don't edit Brix.
3. Read the GDD's blocks on the elevator, the keypad and the notes (docs tools, search
   "elevator", "keypad", "gate", "sticky"). Name each one's precedent (the gate's timer is
   Dandy's World's).
4. Read `FloorBuilder`'s stand-in lobby: where the car stands and how big the opening is. Size the
   car for four players and the Mannequin (6.3 studs) to fit through its gate.
5. `art/elevator/` the Mannequin's way (`art/mannequin/README.md`): spec, lofted or boxed parts,
   one texture set, the finds' bake, FBX, generated Specs, look sheets. The car: steel walls
   scuffed by years of dollies, a caged lamp, a floor of diamond plate; the gate: slats on
   scissor links, built so its fold can be animated by code (slats as separate parts or one part
   per stage); the keypad: ten keys and a dim readout; the note: yellow, curling, two or four
   digits in pen (a label sheet, as the boxes' labels).
6. Into Studio beside the lobby; judged on the Galaxy A16 view from the hall's far end and aboard.
If it won't fit, split it in ROADMAP first: the car and gate, then the keypad and note.
**Acceptance:** checks green; the car, gate, keypad and note in Studio, read at phone size from
across the lobby; shots in `docs/art/`; `OWNER.md` has what to judge.
**Read first:** the GDD's elevator, keypad and note blocks; `docs/ROADMAP.md` (L-05a, L-05b);
`art/mannequin/README.md`; `docs/STUDIO.md` (Getting assets in, Importing kit pieces);
`src/server/FloorBuilder.luau` (the lobby stand-in, by grep); `art/boxes/build.py` (labels, grep).

## Queue (the next run's order, from ROADMAP)
1. L-05a the elevator's art; L-05b notes, keypad and gate (notes where `Deal` puts them); L-11
   tools in hand (two slots and hands, the flashlight, bolt cutters and padlock off the test post);
   L-06b the Mannequin hunts (Brix ENG-06, ENG-07); L-04e the deal on the floor; L-12 the saw and
   the hole trap; L-13 the tops' edges and the ladder; L-14 the other tools; then L-07, L-08,
   L-10, L-09.
2. L-05b adds "flash every light" to `MotionLights`; L-06b's keepers hear doors on `Doors.acted`
   at `DoorSound.Actions`' reach, walk on `Pose.at`, freeze on `Pose.freeze`, posed on clients;
   L-04e calls `Deal.open` on a door's first lift and clones a sleeping Mannequin in `Still`;
   L-08 lays the next floor during the ride, each floor its own seed.
3. **Polish waiting** (ROADMAP, "Polish waiting for a slot"): the Mannequin's head turned to
   you, its tag, more keys and a garbage-free walk lead the list; the rest stand as before.
4. Studio traps (docs/STUDIO.md): an imported part's pivot carries the FBX's Z-up turn (take the
   part's own rotation); a prompt triggers from the MCP only while the camera faces it; captures
   can time out mid-Play (take the shots that matter first); standing still lets the hall go dark
   in 7.5 s; CollisionFidelity reads back Default in the call that sets it; set the Device
   Simulator's device before its orientation.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
