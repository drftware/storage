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
- [x] **P0-02e A shut door hides whoever is behind it** (owner's test, Nov 6). Measured: the run
  animation swings a hand 1.25 studs through the old 0.4-deep collider and 0.8 through a 1.2-deep
  one (docs/STUDIO.md). The collider is now 1.2 deep (`RollUpDoor.ColliderDepth`, fitted at
  placement), the prompt points sit just outside it, and each client stops drawing anyone a shut
  door stands between it and (`BehindDoors`, D-013). P0-02c's probes pass. The owner's
  two-player test passed (Nov 6): nothing through the door, no invisible-wall feel. One miss: the
  hidden player's name tag still floats through the door, now in P0-02f.
- [x] **P0-02f The hidden friend's name tag, and the cursor key** (owner's tests, Nov 6). Done
  Nov 6. A friend `BehindDoors` hides now loses their name tag too: this client's copy of their
  Humanoid's `DisplayDistanceType` goes to None and the old value comes back on show and stop
  (a client's write stays on that client, checked in Play; name occlusion can't do it, since an
  invisible collider never occludes). Left Alt frees the mouse and takes it back for mouse players
  (`FreeCursor`, D-014), with a hint, "Alt Cursor", that fades in 3 s after you spawn and out 6 s
  later, or as soon as you press it (`docs/art/P0-02f-cursor-hint.jpg`). The mouse is either the
  view or a cursor (owner, Nov 6): no cursor is drawn while it turns the view, including the right
  button held while free. Verified in Studio: Alt toggles both ways and the cursor shows only when
  free; with the cursor free E, F, Q and R opened, closed, peeked and locked 102; Alt does nothing
  while Roblox's menu is open; the hint shows once and cleans up. Not seen here: the mouse actually
  going free and the view holding still (Studio doesn't lock the mouse while its window is out of
  focus), the menu's cursor, and the name tag with two players. All wait on `OWNER.md`.
- [x] **P0-02d The hall lit like the look sheets** (D-012, D-015). Fixtures every 24 studs, 2
  above the wire tops, a 130° cone (`HallLight`); the exit sign's red at the far end; a slight
  desaturation. Matches the sheets at full graphics quality (`docs/art/P0-02d-*.jpg`). The flat
  white look was Studio's Automatic quality falling back to coarse lighting.
- [x] **P0-02g A shut unit stays dark on every phone.** Below graphics quality about 10, the
  hall's lights cast no shadows at all, so walls of any thickness let them in. Now the client
  dims the hall's lights for whoever is shut in, draws the line under the door as a glowing
  strip, and lets the light flood back as the door lifts (D-016; `docs/art/P0-02g-inside.jpg`,
  `-peek.jpg`).
- [x] **P0-02h The hall's light at every quality.** Automatic graphics quality switches levels
  mid-play, and low graphics lit upright walls 2 to 3 times brighter than full quality (floors
  matched), so open units flipped between lit and black. Each fixture is now a short shadowed
  tube for the pool on the floor plus a shadowless fill at door height (D-017): low graphics is
  about 1.7x full quality (was 1.9x in the hall, 2.35x in an open unit), and an open unit's
  walls read dimly at both (`docs/art/P0-02h-hall.jpg`, `-open-101.jpg`; the shut-in dark holds,
  `-inside-105.jpg`).
- [x] **P0-02i The hall's haze.** Under each lit tube a few slow puffs of dust glow grey, as in
  the look sheets: Roblox's smoke texture, about six in the air per lit fixture, partly lit by
  the hall so low graphics and full quality stay close (D-018; `docs/art/P0-02i-haze.jpg`). A dead
  fixture's dust vanishes at once; a fixture coming on throws a burst so the air is already dusty.
  The shut-in dark holds (`P0-02i-inside-105.jpg`).
- [x] **P0-02j The hall's cost and phone shots.** The hall costs about 61,000 triangles and 25
  draw calls from the spawn (43,000 from under a tube); the haze adds 24 triangles and 3 draw calls
  at both qualities, so its puffs stay (docs/STUDIO.md, "The hall's render cost"). Found: Roblox
  thinned the haze to under one puff per tube at low graphics, so each player's screen now emits
  the puffs itself and they hold at every level (D-019). Phone shots on a Galaxy A16 at Level01,
  Level08 and Level21 (`docs/art/P0-02j-phone.jpg`). If the owner wants the two looks closer
  still, the lever is the fill's share (more fill, less tube).
- [x] **P0-03a The straight hall piece** (D-020). 24 studs of hall: the concrete floor between
  the doors and a corrugated steel deck on open-web joists over the hall and its units, on the
  unit's own textures, two meshes that instance. The test hall now stands on three, with plain
  walls past its last units; its end walls moved out to 36. Joists stop at 12.8, clear of the
  haze (a Lune spec holds it). From the spawn: 65,000 triangles in 18 opaque draw calls
  (`docs/art/P0-03a-phone.jpg`, Galaxy A16 at Level01 and Level21; `art/corridor/README.md`).
- [ ] **P0-03b The motion-light fixture.** The building's eyes: a housing and diffuser on two
  chains from the deck between two joists, the tube where `HallLight.Height` hangs it, and a small
  sensor eye that shows it's watching (for example the red pip a real occupancy sensor blinks
  when it trips; the owner judges). Built the unit's way, a TrimSheet or small new texture set, judged at phone size.
  L-03 lights it.
- [ ] **P0-03c The junctions.** Corner, T, cross and dead end for the GDD's tile set, on the
  straight piece's grid (8-wide hall, ceiling over a 12-deep unit row each side), and the plain
  wall a hall has where no unit stands (the test hall's end bays and end walls are plain blocks
  until then). The dead end is one you back out of: its end wall at the hall's end, nothing to
  hide behind.
- [ ] **L-03 Motion lights the building watches.** Moved up from Phase 1 by the owner (Nov 7):
  the hall should light as you walk it, like a real storage building, and mostly-dark fixtures
  give the hall its pools of light and dark between. Fixtures wake for anything moving near them
  and fall dark a while after it leaves; the server owns their state; real lights near the
  camera, a glow farther out (GDD Lights). Built on the kit's fixture (P0-03b), so
  L-01 later places fixtures through the same system. Set every light through `HallLight` so it
  keeps the tag and lit brightness that `BehindDoors` scales for a player shut in a unit.
  Brix: Zone for each fixture's watch area. Budget: three lit fixtures awake near a player
  (each is two lights, D-017); the owner thinks that's enough and judges it once built (Nov 7).
- [ ] **P0-04 The door's sounds and feel.** The quiet scrape of a peek, the loud rattle of an
  open (keepers hear it), the bang and bounce of a slam with a little camera shake nearby, the
  latch's clack, the padlock; from Roblox's audio library, timed off `RollUpDoor.play`'s duration.

## Phase 1: The loop, with real assets

Gate 1 (the GDD's): friends ask for another run. The owner judges it in playtests.

- [ ] **L-01 The floor generator.** A floor laid from a seed on the GDD's tile grid: unit rows
  with shared walls dropped, numbers, paint per floor, the elevator lobby, the motion lights
  placed through L-03's system; built during the ride.
  Brix: Random (seeded), Schema for tile rows.
- [ ] **L-02 Doors as the GDD's state machine.** Closed, peeking, opening, open, slamming,
  locked; prompts for Peek, Open, Slam and Lift from inside; range, tool and rate checks. Brix: the
  door becomes a system on the Host's clock, with Signal for door events; Remotes once ENG-09 ships.
  Phone first: offer only the actions the door's state allows (Lift only when shut, no Open on an
  open door) and space them with `UIOffset`. The test hall's five prompts on one point draw as
  five 138×72 tap buttons on top of each other, so a phone can't pick one (P0-02c). Keep each
  prompt's point on the door at about eye height so it stays on screen up close.
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

Atmosphere effects wait until the loop is solid (owner, Nov 7); the haze stays as built.

- The unit's sizes S and L: render and judge them; the large door's slat texture stretches 1.46x.
- A client-side door collider for the local player, if the server collider's ~0.1 s lag feels
  wrong in play (art/unit/README.md, "Not verified yet").
- The padlock is true to size (about 6 by 9 cm) and hard to spot from standing height
  (`docs/art/P0-02b-padlock.jpg`). A padlocked door should read from across the hall at phone
  size, since it's the bolt cutters' target: a bigger lock, a brighter body, or a hasp plate.
- The cursor hint shows once per session; once ever needs the saved profile (Phase 1's player
  data). On a Mac the key cap could read "Option" instead of "Alt".
- At low graphics a haze puff cuts a faint straight edge where it meets the ceiling's corner
  (`docs/art/P0-02i-haze.jpg`, bottom left); full quality softens it. The corridor kit's ceiling
  height may move it.
