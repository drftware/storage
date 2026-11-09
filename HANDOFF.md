# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 41 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-04e is done** (D-050): the deal on the floor. The deck's padlocks are set as each unit is
  laid (no sound; every screen gets it locked). The new `Deals` system deals a unit on its first
  lift (Peek, Open, LiftInside, from `Doors.acted`) and lays it at once: a tool by `Slots:lay`, a
  find (`Deal.Finds`, the bedroom set) standing behind the bulb facing the doorway, a keeper's
  place fired on `Deals.dealt` for L-06b. Where is `DealSpot` (pure, `tests/dealspot.spec.luau`):
  tools in the bulb's pool, finds and keepers behind it, a tall thing never in a note's sight
  line. Unbuilt tools (saw, ladder, L-14's) are dealt but lie nowhere; Studio's Output says what
  each unit held. L-12 is split into L-12a (the saw's art), L-12b (sawing a hole), L-12c (the trap).
- **Verified in Studio** (floor 3, seed 7, Galaxy A16 view): the nine dealt doors padlocked on
  both sides (Open and Cut only); peek and open deal; cutters in 301 picked up, 311's dealt
  padlock cut (1 s hold) then opened and dealt; the TV, boombox and cutters read from doorways;
  note unit 332's note in plain sight beside its boombox (`docs/art/L-04e-*.jpg`). Not seen: a
  keeper standing (no keeper system yet), a friend's view, real phone taps (`OWNER.md`). Studio
  left in Edit, Play stopped, simulator off.
- No owner test results came this session (the overnight run).

## Next task: L-12a The saw's art
The moment: the first tool out of the bag on floors 1 and 2 is a saw lying in a unit's light,
the loop's best move (the hole trap) in your hand. Today it's dealt and lies nowhere.
1. Owner test results first (`OWNER.md`).
2. Read the GDD's saw (its Tools row and "The hole trap") and how the bolt cutters were built.
3. Build it the cutters' way in `art/saw/`: a battery reciprocating saw at real size (scaled up
   as the cutters were if it won't read on a phone), its spec, parts UV-mapped to one baked set,
   FBX, generated `src/shared/Tools/Specs/Saw.luau`, look sheets; `scripts/art.sh saw`.
4. Import it to `ReplicatedStorage.Props.Tools.Saw` (`Tools.prepare`), a `Catalog` row (its hold
   in your left hand, a `use` pose for L-12b, pick up and drop sounds). Then floors 1 and 2 lay it.
5. Judge it on the floor, in hand and held out, from a doorway on the Galaxy A16.
**Acceptance:** checks green; `scripts/art.sh saw` rebuilds it; in Studio: floor 1 or 2's first
dealt tool lies as a saw, is picked up, sits in hand; phone shots; the owner's checks in OWNER.md.
**Read first:** ROADMAP L-12; the GDD's Tools row for the saw (docs tools, never WebFetch);
`art/boltcutters/README.md` and `spec.py`; `src/shared/Tools/Catalog.luau`; DECISIONS D-048.

## Queue (the next run's order, from ROADMAP)
1. L-12a, L-12b. L-06b the Mannequin hunts **waits on Brix**: ENG-07a/b (a chase in a place)
   aren't built, and this repo never edits Brix; a Brix session first. L-12c the hole trap needs
   L-06b's keepers. Then L-13, L-14; then L-07, L-08, L-10, L-09.
2. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
3. **Check, small:** G is both a door's Slam and Drop (ToolView binds G since L-11b): with a tool
   in hand, does G at an open door slam, drop, or both? Give Drop its own key if it clashes.
4. L-06b's keepers stand at `Deals.dealt`'s place, hear doors on `Doors.acted` (a Cut carries 40
   studs), the keypad on `Elevators.acted`, a dropped tool on `Slots.changed`; keepers with eyes
   see a torch (`Flashlights.switched`, GDD); hand `Deal.open` the keepers awake now.
5. **Check:** floor 3's laying peaked at 12.2 ms in a frame (session 37); 6.4 ms this session.
6. Studio traps (docs/STUDIO.md): hold a prompt with `InputHoldBegin` while it's on screen (set
   the camera Scriptable to aim); door buttons hide while their point is off screen; the command
   bar caches `require`; set the Device Simulator's device in Edit before Play; a capture after a
   teleport, or after standing still (the motion light went out), comes back black.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
