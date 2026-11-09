# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-08, session 40 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-11c is done** (D-049): the padlock and the cutters at work. The padlock you carry is built
  by script (`art/padlock/`: the doors' laminated padlock, open, twice their size; baked, sheets),
  uploaded and prepared at `ReplicatedStorage.Props.Tools.Padlock`; one lies across the spawn from
  the cutters (`DevCorridor`'s `TOOLS`). Tools work only in your hand ("Hold the cutters"). Lock
  (R, R2; held 0.5 s) shows on shut doors only to a padlock in hand and spends it (`Slots:spend`);
  Cut (now R2 on a pad, R1 is the torch's) snaps the padlock off: a loud snap and a jolt, a copy
  thrown 1.5 studs out onto the hall floor on every screen (`DoorView`), its clatter. Your view
  brings the tool out to the door while you hold (`Catalog` rows' `use`). `CarriesBoltCutters`
  is gone.
- **Verified in Studio:** pick up the padlock, Lock hidden without it and shown with it, lock a
  door (padlock leaves the bar), pick up the cutters, cut it, the copy landing on the hall floor;
  the padlock's look on the floor, in hand and held at the door. Not seen in light: the cutters'
  pose at the door (the torch key didn't land); handing over, phone taps, a friend's view are the
  owner's (`OWNER.md`). Studio left in Edit, Play stopped, simulator off.
- No owner test results came this session (the overnight run).

## Next task: L-04e The deal on the floor
The moment: you lift a door on a strange floor and what the deal put there is waiting in the bulb's
light: a pair of bolt cutters, a padlock, a find; and the doors the deal padlocked won't budge.
1. Owner test results first (`OWNER.md`).
2. Read ROADMAP L-04e, D-044 (a note's sight line) and how `Deal` names a unit's contents.
3. When a floor is laid, padlock the doors the deal says (`Doors:lock(unit, true)`, no player).
4. On a unit's first lift (a Peek or an Open: `Doors.acted`), lay what it holds: a tool with
   `Slots:lay` (keys are `Deal.Tool`'s, which are the catalog's), a find, a keeper's place
   (L-06b fills it). Where in the unit: a pure rule with Lune specs (on the floor, clear of the
   walls and boxes, never between the doorway and a note).
5. If laying everything won't fit one session, split L-04e in ROADMAP (tools and padlocks first).
**Acceptance:** checks green; Lune specs for where things are laid; in Studio: walk floor 3 from
seed 7, peek and open a few units, see their tools and finds, a dealt padlock that needs the
cutters (Galaxy A16 shots from doorways); the owner's checks in OWNER.md.
**Read first:** ROADMAP L-04e; DECISIONS D-044; `src/shared/Deal.luau` (its types); 
`src/server/FloorBuilder.luau` (grep `deck`, `lay`); `src/server/Slots.luau` (`lay`);
`src/server/Doors.luau` (`acted`, `lock`).

## Queue (the next run's order, from ROADMAP)
1. L-04e; L-06b the Mannequin hunts **waits on Brix**: ENG-07a/b (a chase in a place) aren't
   built, and this repo never edits Brix; a Brix session first. Then L-12, L-13, L-14; then
   L-07, L-08, L-10, L-09.
2. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
3. **Check, small:** G is both a door's Slam and Drop (ToolView binds G since L-11b): with a tool
   in hand, does G at an open door slam, drop, or both? Give Drop its own key if it clashes.
4. L-06b's keepers hear doors on `Doors.acted` (a Cut carries 40 studs), the keypad on
   `Elevators.acted`, a dropped tool on `Slots.changed`; keepers with eyes see a torch
   (`Flashlights.switched`, GDD).
5. **Check:** floor 3's laying peaked at 12.2 ms in a frame (session 37; 8.3 ms this session).
6. Studio traps (docs/STUDIO.md): the MCP's keys only tap, so hold a prompt with
   `InputHoldBegin`; door buttons hide while their eye-height point is off screen; the command
   bar caches `require` (require a clone); set the Device Simulator's device in Edit before Play;
   a capture right after a teleport comes back black, take it again.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
