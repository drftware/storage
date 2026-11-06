# Roadmap

One ticket = one session. A ticket names what to build, how we know it's done, and what to read
first. If a ticket grows past one session, split it here before starting. Later tickets are
one-liners; each gets its full spec when it becomes HANDOFF's Next task.

The order follows the owner's plan (2026-11-05): set up the project and bring the real assets in,
build the gameplay loop with those real assets and hone it until it's awesome, then flesh out
the rest of the floors and the game. It matches the GDD's build order (its "Build order" section).
Every system checks Brix first (`docs/FRAMEWORK.md`, D-008); each ticket below names its Brix piece.

## Phase 0: Foundations

Gate 0: two players walk a real corridor of units in Studio, and peeking, opening, slamming and
locking doors looks, sounds and blocks right for both of them, at phone size, with no hitch.

- [x] **P0-01 The storage unit and its roll-up door.** Done Nov 5 (passes checks, untested in
  Studio): the 10x10 unit built as code in Blender with baked PBR textures, an FBX for the 3D
  Importer, and the door rig (`RollUpDoor`, `Motion`, `Curtain`, `UnitKit`) with Lune specs
  (D-001 to D-007). Sizes S and L build but haven't been checked by eye.
- [x] **P0-02 The Roblox project, and the unit in Studio.** Done Nov 5: the full Rojo tree with
  the place's streaming and night lighting; Brix mounted at `4c21b5f` and a Host on each side; the
  unit uploaded through Open Cloud (D-010), inserted and prepared into `ReplicatedStorage.Units.M`;
  the dev corridor of nine units. Verified in Studio (one player): the corridor builds, Open runs
  2 s and the door draws open with its collider out of the way, a padlocked door and a lock on a
  moving door both refuse.
- [x] **P0-02b The corridor, played.** Done Nov 5, verified in Studio (one player, by key): Peek,
  Open, Close, Slam, Lock and Unlock at 101, and Lift from inside after a slam; "Padlocked" at 105
  and on a locked 101, "Shut it first" on an open door; bolt and padlock show; plates 101 to 108;
  the curtain coils cleanly; the slam lands in about 0.27 s and bounces. Go far streams the hall
  out, Come back brings every door back as left. Shots in `docs/art/P0-02b-*.jpg`. Found: the
  camera passes through every unit (P0-02c).
- [x] **P0-02c First person.** Done Nov 6, verified in Studio (one player): the camera locks at the
  head (D-011); from the eyes every key works at 101 with both refusals, Lift stays hidden behind a
  shut door (the invisible collider blocks its sight line) and shows from inside, and a slam from
  the doorway shuts you in or pushes you out, the slats never closer than half a stud in front of
  the eyes. Found and fixed: walking up to a door hid its prompts, because a prompt shows only
  while its point is on screen; the points now sit on the door at eye height. On a small Android
  the thumbstick walks and a drag looks. Shots in `docs/art/P0-02c-*.jpg`.
- [ ] **P0-02d The hall measured and lit.** Triangle and draw-call counts for the hall, phone-size
  screenshots (Device Simulator), and the hall's light level: it reads bright for after hours.
- [ ] **P0-03 The corridor kit (art).** Hall floor and ceiling, end walls and corners for the
  GDD's tile set (straight, corner, T, cross, dead end), and the motion-light fixture (the
  building's eyes), built the unit's way and judged at phone size.
- [ ] **P0-04 The door's sounds and feel.** The quiet scrape of a peek, the loud rattle of an
  open (keepers hear it), the bang and bounce of a slam with a little camera shake nearby, the
  latch's clack, the padlock; from Roblox's audio library, timed off `RollUpDoor.play`'s duration.

## Phase 1: The loop, with real assets

Gate 1 (the GDD's): friends ask for another run. The owner judges it in playtests.

- [ ] **L-01 The floor generator.** A floor laid from a seed on the GDD's tile grid: unit rows
  with shared walls dropped, numbers, paint per floor, the elevator lobby; built during the ride.
  Brix: Random (seeded), Schema for tile rows.
- [ ] **L-02 Doors as the GDD's state machine.** Closed, peeking, opening, open, slamming,
  locked; prompts for Peek, Open, Slam and Lift from inside; range, tool and rate checks. Brix: the
  door becomes a system on the Host's clock, with Signal for door events; Remotes once ENG-09 ships.
  Phone first: offer only the actions the door's state allows (Lift only when shut, no Open on an
  open door) and space them with `UIOffset`. The test hall's five prompts on one point draw as
  five 138×72 tap buttons on top of each other, so a phone can't pick one (P0-02c). Keep each
  prompt's point on the door at about eye height so it stays on screen up close.
- [ ] **L-03 Motion lights the building watches.** Fixtures wake for anything moving near them;
  the server owns their state; real lights near the camera, a glow farther out (GDD Lights).
  Brix: Zone for each fixture's watch area.
- [ ] **L-04 What's behind the door.** A first director deals each unit's contents on open: a
  find, a note, nothing, or a keeper (GDD "What's behind the door"). Needs find and box props.
- [ ] **L-05 Notes, the keypad and the elevator.** The floor's 4-digit code on sticky notes, the
  keypad, the gate that shuts 30 s after the last digit (Dandy's World). Needs the elevator,
  gate, keypad and note art first. Brix: Zone for "aboard", the Clock for the gate's timer.
- [ ] **L-06 The Mannequin.** The first keeper, at no more than player speed: a data row on
  Brix's Pursuit (floor pathing, a cone reach). Needs its model and animations first, and Brix's
  ENG-06 and ENG-07.
- [ ] **L-07 Getting kept and rescued.** Shrink-wrapped, stored in a random unit, banging to ping
  the team, cut free in a second, padlocked if left too long (GDD "Getting kept").
- [ ] **L-08 The ride and the next floor.** The elevator ride and a second floor, so the climb is
  a loop and not a single room. Brix: its round loop (ENG-13) if it has landed.
- [ ] **L-09 Hone.** Playtest with friends, tune Config, add juice, repeat until Gate 1. May
  repeat as several sessions; each one names what it changed and why. Brix: live config (ENG-11)
  and the presentation kit (ENG-15) as they land.

## Phase 2: The rest of the game (GDD build order step 2)

All ten floors with the ride, the stairwell set piece and both boss floors; the director; the
other keepers; tools (bolt cutters, saw with the crawl-hole wall, ladder onto the wire tops); the
hole trap with a dented-door variant; the light board; finds with rarity; your lobby unit; the
store; Captures. Player data, remotes, telemetry and UI from Brix (ENG-09 to ENG-16). Then soft
launch.

## Polish waiting for a slot

- The unit's sizes S and L: render and judge them; the large door's slat texture stretches 1.46x.
- A client-side door collider for the local player, if the server collider's ~0.1 s lag feels
  wrong in play (art/unit/README.md, "Not verified yet").
- The padlock is true to size (about 6 by 9 cm) and hard to spot from standing height
  (`docs/art/P0-02b-padlock.jpg`). A padlocked door should read from across the hall at phone
  size, since it's the bolt cutters' target: a bigger lock, a brighter body, or a hasp plate.
