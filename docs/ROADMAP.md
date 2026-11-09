# Roadmap

One ticket = one session. A ticket names what to build, how we know it's done, and what to read
first. If a ticket grows past one session, split it here before starting. Later tickets are
one-liners; each gets its full spec when it becomes HANDOFF's Next task.

The order follows the owner's plan (2026-11-05): set up the project and bring the real assets in,
build the gameplay loop with those real assets and hone it until it's awesome, then flesh out
the rest of the floors and the game. It matches the GDD's build order (its "Build order" section).
Every system checks Brix first (`docs/FRAMEWORK.md`, D-008); each ticket below names its Brix piece.
The keepers' brain is the one exception: it is built in this game (D-064).

## Phase 0: Foundations

Gate 0: two players walk a real corridor of units in Studio, and peeking, opening, slamming and
locking doors looks, sounds and blocks right for both of them, at phone size, with no hitch.

- [x] **P0-01 The storage unit and its roll-up door.** Done Nov 5 (passes checks, untested in
  Studio): the 10x10 unit built as code in Blender with baked PBR textures, an FBX for the 3D
  Importer, and the door rig (`RollUpDoor`, `Motion`, `Curtain`, `UnitKit`) with Lune specs
  (D-001 to D-007). Size S joined in L-01b; L builds but hasn't been checked by eye.
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
- [x] **P0-03b The motion-light fixture** (D-021). A steel strip light on two jack chains from
  the deck, midway between two joists, its lens exactly the tuned tube (12.1 high, 3.8 long), and
  a motion sensor on one end whose red dome is the building's eye: Watching, Seen or Blind
  (`HallLight.eye`). `CorridorKit.hang` puts one up; the test hall has three (weak, lit, dead).
  About 2,000 triangles each (half of it chain), three draw calls shared by all fixtures; from the
  spawn the hall is now 71,400 triangles in 21 opaque draws (`docs/art/P0-03b-phone.jpg`).
- [x] **P0-03c The plain wall and the dead end** (D-022). A unit's front without the door: the
  plain wall takes a unit's 12-stud place on the door faces' line, the dead end closes the hall's
  end and the deck over the whole span; both are the units' painted corridor wall to 10 with an
  R-panel above to the deck. `CorridorKit.wall` puts one up, painted like the floor's units. The
  test hall has four plain walls and two dead ends; the exit sign hangs on the far one, its glow
  moved off the wall so the wall reads as a wall. From the spawn: 73,800 triangles in 28 opaque
  draws (`docs/art/P0-03c-*.jpg`).
- [x] **P0-03d The corner, T and cross.** Done Nov 7 (D-023): three 24-stud junction squares on
  the straights' grid and a short plain wall (an S unit's 8); the junction's deck continues its X
  arms and a joist girder carries it across each Z arm's mouth; a steel column at every corner of
  wall. `CorridorKit.junction` lays one with its walls. The test hall ends in a T, a dead end down
  one arm, a corner up the other into a dark hall. Walking it and the render cost: `OWNER.md`.
- [x] **L-03 Motion lights the building watches.** Done Nov 7 (D-024): every hall fixture is a
  motion light the server owns (`MotionLights`, its rules in the pure `MotionLight`): anything
  moving in its Brix box zone wakes it, and it falls dark 5 s after the last movement it saw, so
  freezing under it puts you in the dark. Only state changes cross the wire; each screen draws
  them (`HallLights`): the eye's flare, the relay's click and the tube's flicker as it trips, a
  softer click and the eye sinking as it falls dark, silent death when the breaker cuts it. Real
  light for the three lit fixtures nearest the camera, a glow beyond. The test hall's five
  fixtures are motion lights, with a breaker post in the T for the north arm. Then, from the
  owner's play (D-025): your screen predicts your own lights, the reach is 40 studs, the hold
  7.5 s, the flicker a tenth of a second, and every stretch of the turn has its fixture. Feel and
  two players: `OWNER.md`.
- [x] **P0-04 The door's sounds and feel.** Done Nov 7 (D-026), verified in Studio (one player,
  by server calls): every door action answers with its sound at the door. While a door moves, a
  real roll-up door's rattle (a truck's rear door) follows its speed: quiet and low for a peek,
  loud for an open or a lift from inside (whose three heaves surge), high and short for a slam's
  fall. One-shots land on the frame the door hits something (`Motion.strikes`): the slam's bang
  with a thump under it, then its bounce's clatter; a close settling; the stop bolts at the top;
  the latch as a lift starts; the bolt and padlock when locking. A slam jolts the camera of anyone
  within 6 studs, fading out by 30 (`CameraShake`, about 0.6 degrees beside it). All Pro Sound
  Effects, each stretch found by measuring its loudness in Studio. The owner judges the sounds
  (`OWNER.md`).

## Phase 1: The loop, with real assets

Gate 1 (the GDD's): friends ask for another run. The owner judges it in playtests.

The loop comes first (owner, 2026-11-08): being chased, searching for the code and the tools,
trapping keepers, slipping between units from inside. So every tool that works on any keeper is
built here (the GDD's build order moved them into its first step the same day), and what only
dresses a unit (where the finds and boxes stand, more finds, their polish) waits for Phase 2. The
order puts a keeper on the floor as early as it can: L-06a built the Mannequin's art and poses
(Nov 8), and L-06b, the keepers' brain, is this game's own to build (D-064, Nov 9), so it waits
on nothing in Brix.

- [x] **L-01 The floor generator**, in three sessions. **L-01a done Nov 7** (D-027): the floor
  as pure data from a seed (`src/shared/Floor.luau`): halls grown from the lobby on a grid of
  junction points 48 studs apart, so a straight always stands between two junctions; loops
  joining near halls; each hall side a row of two M or three S slots, the kit's slots at the
  junctions, every slot a unit or a plain wall (never an M unit in a back corner); units numbered
  from the lobby as you walk out; one door colour per floor; a motion light over every hall piece,
  each in a power zone. Lune-checked over 400 floors (`tests/floor.spec.luau`);
  `lune run scripts/floor-map <seed> <floor>` prints one as a map. The owner judges the maps
  (`OWNER.md`). **L-01b done Nov 7** (D-028): the S unit exported, uploaded and kept at
  `ReplicatedStorage.Units.S`; its door wears the M's textures at the M's grain; the test hall's
  short hall past the corner is three S a side (109 to 114, 112 padlocked); every door action
  verified on an S in Studio; phone shots beside the M rows (`docs/art/L-01b-*.jpg`). **L-01c done Nov 7** (D-029): `FloorBuilder` lays a floor from its data on the server: each
  hall piece at its frame, a unit at every unit slot (painted, numbered, its shared side walls
  left out), the kit's plain or short wall at the rest, each junction's own wall left out where a
  unit stands (`CorridorKit.junction`'s `units`), the dead ends, a motion light over every piece
  in its floor's power zone, and a stand-in lobby lit by the elevator car's lamp. It works out
  from the lobby and never spends more than about 4 ms of a frame (65 ms in all for 67 units);
  each piece is parented once. The test hall lays floor 3 of seed 7 beside it ("Walk a floor"),
  checked slot by slot against the data on six floors in Studio; the door prompts moved to
  `DoorPrompts`. The ride's laying is L-08's. Brix: Random (seeded), Schema for the plans.
- [x] **L-02 Doors as the GDD's state machine.** Done Nov 7 (D-030), verified in Studio (one
  player): the pure `Door` (closed, peeking, opening, lifting, open, closing, slamming, locked;
  what each action does from each state and side, and what it refuses and why; 327 Lune checks)
  and the server's `Doors` system on the Host clock in place of the test prompts. A door shows only
  the buttons its state allows, side by side in fixed places (Peek left, Open middle, Slam right;
  Close toggles with Peek), Lift just inside while it's down; every press checked for reach, side,
  tools and rate. A padlocked door tried, from the hall or from inside, rattles: a few centimetres
  of give against the bolt and Pro Sound Effects "Door Shake 4", with "Padlocked" on the button;
  bolt cutters (held 1 s) take the padlock off. Door events on a Brix Signal with how far each is
  heard. The owner judges the buttons on a phone (`OWNER.md`).
- [x] **L-01d The floor laid for the saw and the ladder.** Done Nov 7 (D-031), on the owner's
  default: crawl holes only between side-by-side neighbours, tops run along a row. The pure
  `Floor` knows what stands past each slot's left, right and back walls (a unit, a plain wall or
  nothing; 4 studs of shared wall at least, `CrawlWidth`) and the floor's top runs (a row's slots
  side by side; every plain wall in a run with a unit gets a lid). Two rules, from measuring 400
  seeds: a plain wall picked at random never strands a unit with no neighbour to crawl to; on
  floors 1 and 2 the hall from the lobby to the first fork has no plain walls and a back-cornered
  side there is three small units, so 4 or more crawl pairs stand there (the GDD: they teach the
  hole trap). Every floor has 36 crawl pairs or more; none cut off on floors 1 and 2, at most 2
  above (the lobby's own hall); runs 24 to 216 studs. `FloorBuilder` lids a plain wall in a run
  with the unit's own wire top and floor, verified in Studio (9 lids on floor 3, flush with their
  neighbours' tops). `scripts/floor-map` marks a cut-off unit x and draws the tops;
  `scripts/floor-survey` measures over many seeds.
- [ ] **L-04 What's behind the door.** A first director deals each unit's contents on open: a
  find, a tool, nothing, or a keeper (GDD "What's behind the door"). Split Nov 7, reshaped Nov 8:
  - [x] **L-04a The moving boxes.** Done Nov 7 (D-032), verified in Studio on the Galaxy A16 view:
    five boxes at real moving-box sizes (Small, Medium, Large, Wardrobe, and an Open one with its
    flaps up), one MeshPart each on one Cardboard atlas: kraft board, packing tape lapping the
    ends, hand holes, the maker's print, marker words, a crushed corner, a water mark, dust.
    `art/boxes/` (label sheet, bake, FBX, look sheets), `Boxes` (`prepare`, `clone`) and its
    generated Specs; templates at `ReplicatedStorage.Props.Boxes`. Stacked in unit 101 they read
    as boxes from the doorway, but only in a torch's beam: the hall light doesn't reach past the
    doorway, so they're unseen under it and in the dark (`docs/STUDIO.md`).
  - [x] **L-04b The unit's own light.** Done Nov 7 (D-034), verified in Studio on the Galaxy
    A16 view at Level01 and 21: a caged bulb on a short cord under every unit's wire top (S and M,
    the test hall's 15 and a laid floor's 77), a piece of the corridor kit (`Bulb`, 518
    triangles). Wired to the door like a fridge's light: it clicks and stutters on as the door
    starts up (a peek lets a warm band out under the door) and is out the frame the door lands, a
    slam's bang included. Dim and warm (0.6, reach 11): the boxes at the back plain from the
    doorway, the back corners dark. The 3 nearest lit bulbs throw light and hum; the rest glow.
    `UnitLight`, `UnitLights`, `ShutIn.bulb`, `CorridorKit.hangBulb`; shots `docs/art/L-04b-*.jpg`.
  - [x] **L-04c The first finds' art.** Done Nov 7 (D-035), in Blender only: the 1980s bedroom
    set's first four (a boombox, a portable TV, a mended teddy, a pair of roller skates), one
    MeshPart each on one Bedroom atlas (colour, normal, roughness, metalness; 99 texels a stud),
    dusty on whatever faces up, 1,004 to 2,248 triangles. `art/finds/` (README, sheets
    `finds-*.png`), `Finds` (`prepare`, `clone`) and its generated Specs. The GDD names no look
    for rarity, so none. Split from the import on Nov 7: the unwrap and bake traps took the
    session (`docs/STUDIO.md`).
  - [x] **L-04c2 The finds into Studio.** Done Nov 7 (D-036): uploaded, inserted and prepared into
    `ReplicatedStorage.Props.Finds`; judged among 101's boxes from the doorway on the Galaxy A16
    view at Level01 and 21 (`docs/art/L-04c-finds.jpg`). All four read once they stand behind
    the unit's bulb; the skates re-posed so the fallen one lies in front, wheels to the door.
  - [x] **L-04d The deal.** Done Nov 8 (D-038), reshaped that day for the loop: the rules alone,
    pure and Lune-tested (`Deal`, 326,000 checks over 600 floors). When a floor is laid: its code,
    the notes that carry it (two on floors 1 and 2, four above), one to each wing in turn and 48
    studs apart, a note behind a padlock from floor 6; and the padlocked doors (6 in 100 units on
    floors 1 and 2, 12 above), none in the lobby's hall. When a door first lifts: a tool out of a
    shuffled bag (Tetris; the saw first on floors 1 and 2), nothing, a find, or a keeper asleep or
    awake, the odds set by the director's mood, worse behind a padlock, never more awake than the
    floor's cap and no keeper in the lobby's hall on floors 1 and 2. `lune run scripts/floor-deal`
    prints a floor's deal. Where the boxes and the find stand moved to Phase 2 with the finds.
- [x] **L-06a The Mannequin's art.** Done Nov 8 (D-039): `art/mannequin/` builds it the unit's
  way, 6.3 studs, faceless fibreglass, chipped, a seam and a ball at every joint, fifteen rigid
  R15 parts (8,356 triangles, one 1024² set); `Mannequin.prepare` rigs the import with R15's
  RigAttachments and Motor6Ds; `Mannequin/Pose.luau` (pure) holds its shop pose and a stop-motion
  walk of four keys a light freezes it on, checked by 26,222 Lune checks (limits, standing,
  nothing through anything, stride, mirroring). Verified in Studio: the Motor6Ds pose it exactly
  as the pure maths says; it reads 30 studs down the hall (`docs/art/L-06a-hall.jpg`).
- [x] **L-05a1 The elevator's art in Blender** (Nov 8, D-040). `art/elevator/`: the car (12.5 x 11
  x 9.6 inside), its collapsible lattice gate (13 pickets, 72 straps, posed by the pure
  `Elevator/Gate.luau`, Lune-checked), the landing's frame and sill, the keypad with ten engraved
  keys, and the sticky note (its digits written by the game in Kalam). 9,966 triangles; FBX,
  generated Specs and five look sheets. Split from L-05a when the Studio half wouldn't fit.
- [x] **L-05a2 The elevator in Studio** (Nov 8, D-041). Uploaded (asset 89467597147215) and
  prepared by `Elevator.prepare` into `ReplicatedStorage.Props.Elevator` and `Props.Note`; the
  gate's 85 parts posed by `setGate`; `clone`, `note` and `write`. FloorBuilder lays it in the
  lobby's back wall in place of the stand-in's car and lamp. Verified in Studio: the gate at 0,
  0.5 and 1, a note reading `_ 7 _ _` on a box, and on the Galaxy A16 from the hall's mouth, at
  the gate and aboard (`docs/art/L-05a2-*.jpg`).
- [x] **L-05b1a The keypad's rules and the server** (Nov 8, D-042). `Elevator/Keypad.luau` (one
  digit at a time, the check on the fourth, the readout's text, the replicated state) and the
  gate's motion in `Gate.luau` (it gathers speed into its slam, recoils, settles; one replicated
  value); `Elevators` on the server: armed with the floor's code, the `Keypad` remote checked
  (types, range, rate, state), the wrong code's alarm (every light on the floor via
  `MotionLights.flash`, the keypad dead 3.5 s), the right code's gate with its collider; the gate
  laid shut. The test floor deals its code and prints it. Verified in Studio from the client.
- [x] **L-05b1c The keypad and gate on every screen** (Nov 8, D-043). `ElevatorView` folds the
  gate from its motion (only moving gates stepped), jolts anyone beside it as it slams, sinks
  each pressed key, and draws the readout as four seven-segment LEDs (`LedReadout`, the shared
  pure `Elevator/Readout.luau`): dim dashes, red digits, the wrong code blinking with the status
  light, green on the right one, the glow green too. `Elevator/Sounds.luau` (pure) times the
  beep, buzzer, alarm bell, double-ding, latch and fold so the slam lands as the gate hits;
  `SoundPrimer` plays each recording once silently, since a first play starts a third of a second
  late. `KeypadPad` is the on-screen keypad every device types on, opened by the keypad's "Use"
  prompt; mouse, touch, keyboard and gamepad. Verified in Studio on the Galaxy A16 and desktop:
  0000's alarm, a clear, 5062 folding the gate open; shots `docs/art/L-05b1c-*.jpg`.
- [x] **L-05b1b The notes in their units** (Nov 8, D-044). FloorBuilder takes the floor's deal and
  sticks each note on its unit's back wall as it lays the unit: facing the door at eye height, on
  a rib, a little off the middle and crooked, 1.6 times the art's size (`Elevator/NoteSpot.luau`,
  pure, 75,928 Lune checks: on the wall, seen whole through the doorway, its digit about 2 mm on
  the phone from 5 studs). `NoteView` loads Kalam as a client starts and redraws early notes.
  Verified in Studio on the Galaxy A16: floor 3's four notes spell its code (5062); a note is a
  plain square from a big unit's doorway and its "5" reads from 6 studs
  (`docs/art/L-05b1b-*.jpg`). From the doorway itself the digit is a speck: `OWNER.md`.
- [x] **L-05b1d Read a note** (Nov 8, D-045). Two steps into a note's unit a "Read" button shows
  under the note; a tap lifts the note into the middle of the screen with a paper flap, crooked as
  it hangs: its real paper mesh in a ViewportFrame, its four slots in Kalam over its writing area,
  the digit 7.7 mm tall on the Galaxy A16 (on the wall, 2 mm from 5 studs). A tap on it, Read again
  (E, gamepad X), B, a click, walking out to the doorway or dying drops it, after a 0.3 s grace.
  `Elevator/NoteCard.luau` (pure: reach, layout, slots; 395 Lune checks over eight screens) and
  `NoteView`. Verified in Studio on the Galaxy A16 (Unit 313's `_ 0 _ _`): the card, and every
  way to drop it but the mouse; shot `docs/art/L-05b1d-card.jpg`. A real tap on Read, the click
  and the motion are the owner's (`OWNER.md`).
- [x] **L-05b2 The gate's timer** (Nov 8, D-046). Once the right code's gate has slammed open,
  a 30 s clock runs for everyone on the floor (within 240 studs), then the gate folds shut on its
  own, as Dandy's World's elevator does; nobody can send it early. The clock is the elevator's own
  LED digits in the middle of Roblox's top bar, popping in with the PA's chime, green, then red
  from 10 s, jumping each second; from 10 s the car's lamp blinks ever faster and a heartbeat
  swells and quickens under everything; the elevator's bell rings each of the last five seconds,
  a little higher each time. The instant the shut gate hits its post a Brix Zone over the car says
  who rode: "Going up" for them, a lurch, and (the stand-in ride) a fade to black while the dev
  floor moves them back to the spawn and re-arms the elevator; "Left behind" for the rest, as
  the car's light draws away and leaves them in the dark. `Elevator/Departure.luau` (pure, 6,188
  Lune checks), `GateClock` (client), `Elevators` keeps the clock, `ElevatorView` the lamp,
  `LedReadout.row`. Verified in Studio on the Galaxy A16: the whole countdown and its sounds, the
  lamp, a run through the closing gate (crossed 28% shut, a 6.4-stud gap) counted aboard and
  ridden back, and left behind; shots `docs/art/L-05b2-*.jpg`. Two players: `OWNER.md`.
- [ ] **L-11 Tools in hand.** You carry two tools plus whatever is in your hands (GDD), as Lethal
  Company's slots: pick a tool up off a unit's floor, switch, drop, hand one to a friend, each
  with a phone button. The flashlight everyone carries (signals friends; keepers with eyes see
  it; freezing the Mannequin lands with L-06b). The bolt cutters and the padlock move off the
  test post onto it (`Door.Tools`). Each tool's art first. Brix has no inventory (checked Nov 8,
  `4c21b5f`). Split (Nov 8) so each fits a session:
  - [x] **L-11a The flashlight** (Nov 8, D-047). Everyone carries an old two-battery plastic
    torch (`art/flashlight/`, built by script, baked, sheets), held low on the right of your
    first-person view: it sways with your stride, trails a hard turn, breathes when you stand and
    dips as you click it. A right click, a gamepad's R1 or a round phone button above the jump
    button switches it at once on your screen with a plastic click (heard 22 studs off); the server
    owns on and off and the aim (`Flashlights`: a desired-state remote, checked for type, a living
    hand and a burst-then-gap rate). Its beam is a shadowed SpotLight (54 degrees, 42 studs) with
    a soft spill ring; friends see your torch in your hand, its lens lit, your arm raised to where
    you look, and the nearest three friends' beams cast real light. No battery or flicker: the GDD
    gives it none. `Flashlight/Torch.luau` (pure, 44 Lune checks), `FlashlightView` (client).
    Verified in Studio: the torch in hand, right click and R1, the server's state and aim, the
    beam at Level 21 and Level 8 and on the Galaxy A16 (`docs/art/L-11a-*.jpg`). The phone tap,
    a friend's beam and arm, and six players' light: `OWNER.md`.
  - [x] **L-11b Two slots and your hands** (Nov 8, D-048). The bolt cutters built by script
    (`art/boltcutters/`: chipped red handles, black grips, bolted black plates, a forged jaw ground
    bright; baked, sheets) and imported to `ReplicatedStorage.Props.Tools.BoltCutters`. Lethal
    Company's slots: a tool lies on a floor with "Pick up" (E, X); it comes into your hand (the
    free slot if your hand is full) with a clank everyone near hears, and its name shows above the
    bar; "Hands full" when both slots are. The bar at the bottom middle shows each tool as a real
    3D picture, the one in hand raised: tap it, 1 and 2, or the d-pad. Drop (the round button, G,
    d-pad down) lets it fall crosswise ahead of you and clank on the concrete. A friend holding a
    tool sees "Give" on you within 10 studs; you hear the clank and read "Bolt cutters from Sam".
    Yours is drawn low on the left of your view with the torch's sway, swinging up as it arrives
    and down as it goes; friends see it in your left hand, jaw forward. Dying or leaving drops
    everything. `Tools.Carry` (pure, 48 Lune checks), `Tools.Catalog` (a row per tool), `Slots`
    (server), `ToolView` (client); two pairs lie in the test hall in place of the old post.
    Verified in Studio: pick up, switch, switch back, drop, the bar and the held tool, on a
    computer and on the Galaxy A16 (by gamepad keys; shots `docs/art/L-11b-*.jpg`). Handing over
    and the phone's taps: `OWNER.md`.
  - [x] **L-11c The padlock, and the cutters at work** (D-049). The padlock built by script
    (`art/padlock`, the doors' laminated padlock, open, twice their size); tools work only in your
    hand ("Hold the cutters"); Lock, held 0.5 s, shows only to a padlock in hand and spends it;
    Cut snaps the padlock off with a jolt, its copy tumbling out onto the hall floor, and its
    clatter; your view brings the tool out to the door as you hold. "One padlock per use" read
    as a cut padlock spent (`OWNER.md`).
- [ ] **L-06b The Mannequin hunts.** The first keeper, and with it the keepers' brain, which
  lives in this game (D-064): one system on the Host's clock, each keeper a data row, built on
  Brix's contracts and parts (Pathing, Reach, Zone, Signal, Random) so it can move to Brix later.
  It waits on nothing in Brix. Split Nov 9, a session each. Where the GDD doesn't give a number
  (how far a keeper sees, how long before it gives up), pick a default and list it in `OWNER.md`.
  Each keeper's row lists its abilities (D-068): the Mannequin has none, it only walks.
  - [x] **L-06b1 The halls as a map keepers walk.** Done Nov 9 (D-068): `KeeperMap` lays the
    floor as places (each hall piece, a junction's middle and arms, the lobby, each unit) joined by
    passages (the joints between hall pieces, each unit's doorway, shut while its door is down);
    the elevator car isn't on it. Shortest trips by A* over the passages, in Brix's Pathing
    contract (`length`, `advance`, `route`, a route planning again when a door changes or its
    target moves into another place). A passage may need an ability ("Climb", "Crawl"), and each
    keeper walks through a pathing made for its abilities; raised places (the tops) and passages
    (ladders, crawl holes) can be added while a floor runs. `tests/keepermap.spec.luau`: 62,000
    checks over 60 seeded floors of both plans (Brix's promises, no wall or shut door crossed,
    routes arrive, abilities, a raised place, no allocation once warm); a length across a full
    floor takes about 10 µs in Lune.
  - [ ] **L-06b2 The Mannequin goes to look.** Split Nov 9 into two sessions.
    - [ ] **L-06b2a It hears a door and walks to it.** The moment: you slam a door and, two halls
      off, something starts walking toward it. The brain as a system on the Host's clock, its
      first states (asleep, going to look, waiting there, going back) and its first row (speed
      from the GDD's share of player sprint, `abilities = {}`). Keepers hear a door (the GDD: an
      open, a slam, a lift from inside) as far as its sound carries: take each action's reach
      from `DoorSound.Actions`, so what players hear and what keepers hear stay one table. The
      map: one `KeeperMap.build` per floor laid, each door's state fed through
      `KeeperMap.letsThrough` into `setDoor` as it changes, and world positions turned into the
      floor's own (its lobby at the origin) going in and back coming out. Its body is L-06a's:
      clone it with `Mannequin.clone`, an anchored model moved along its route by its
      HumanoidRootPart on the server, with no Humanoid, stood in a hall by a dev command until
      L-06b2b deals them. It may judder on screen until L-06b4 smooths it.
    - [ ] **L-06b2b Dealt keepers join.** Dealt keepers (L-04e): stand one at `Deals.dealt`'s
      place as its door first lifts (asleep, in its shop pose; awake, up and looking), joining
      the brain at that moment, and hand `Deal.open` the keepers awake now in place of `Deals`'
      tally of those dealt awake.
  - [ ] **L-06b3 It hunts, freezes and catches.** At no more than player speed (the GDD's speed
    rule): it notices a player by its row's senses, hunts them by the map, and gives up when it
    has lost them. Frozen (`Pose.freeze(travelled)`) the moment a hall light or a torch's beam is
    on it, decided on the server. The catch is a Brix cone reach measured along the map, so never
    through a wall, and fires the event L-07 takes. Decide here whether `Brix.Pursuit` runs the
    chase and the catch: only if it fits with no new Brix work (D-064).
  - [ ] **L-06b4 What you see and hear of it.** On every screen its place is smoothed between
    the server's steps, and it is posed on the clients (`Pose.at(travelled)`, Motor6D
    `Transform`) rather than by replicating C0 every step. The freeze lands at once on your own
    screen when your torch finds it, predicted as `HallLights` predicts your own lights, with no
    slide past the stop. Its tell, heard in the dark while it moves: fibreglass knocking at its
    joints and a stiff, quick footfall per step, as Five Nights at Freddy's footsteps say an
    animatronic moved. Judged at phone size.
  - Later, with the first keeper that climbs or crawls (a new keeper is the owner's design,
    D-068): the tops join its map as raised places (from `Tops.Map`), a leaned ladder as a
    passage that needs Climb (shut when it's taken down), and a sawn wall's hole as one that
    needs Crawl (from `Saws`). Only those calls and the keeper's row; the map stays as it is.
- [x] **L-04e The deal on the floor.** Done Nov 9 (D-050): the deck's padlocks set as each unit
  is laid; `Deals` deals a unit on its first lift (a peek, an open, a lift from inside) and lays
  it: a tool to pick up, a find standing behind the bulb facing the doorway, a keeper's place
  handed to L-06b (`Deals.dealt`). Where is `DealSpot` (pure, 32,000 Lune checks): tools in the
  bulb's pool, nothing tall in the note's sight line. Tools without art (the saw and L-14's) are
  dealt but lie nowhere until their tickets. Judged on the Galaxy A16 (`docs/art/L-04e-*.jpg`).
- [ ] **L-12 The saw and the hole trap.** Saw a crawl hole into the unit beside you (`Floor`'s
  left and right, D-031); it's loud. Players crawl through, keepers can't. Lead a keeper into a
  unit, crawl out the hole, run round and slam it in: it dents the door and breaks out after
  about 90 s, unless the padlock tool locks it in for the floor; the team gets a bonus (GDD "The
  hole trap"). Split Nov 9, one session each (L-12b split again into b1, b2, b3):
  - [x] **L-12a The saw's art.** Done Nov 9 (D-051): a green cordless reciprocating saw
    (`art/saw/`, 6,168 triangles, one baked set), standing on its battery where it's laid;
    `Props.Tools.Saw` and a `Catalog` row (held low on your left turned in, blade to the middle;
    carried upright at a friend's side; a plastic knock picking it up, a plastic slam dropping
    it). Floor 1's first tool, unit 104 on seed 7, lies as a saw, picked up and dropped in Studio
    on the Galaxy A16 (`docs/art/L-12a-*.jpg`).
  - [x] **L-12b1 The crawl hole's art.** Done Nov 9 (D-052): `art/hole/` builds the holed side
    wall (each size, each side, in the unit's own wall texture), the bright cut edge with its
    tongues bent away from the saw and the panel fallen flat on the far side, both ways round;
    `Props.CrawlHole`; `CrawlHole.saw(from, into)` swaps the wall two units in a row share and
    opens its collision round the hole (`Boxes`, Lune-checked). The hole opens at the same place
    in every unit (`crawl_*` in the unit's spec: 3.75 to 6.75 along, 0.3 to 2.9 up). The test
    hall sawed 101 into 103 and 104 into 102 until L-12b3; judged from both units on the Galaxy A16
    (`docs/art/L-12b1-*.jpg`).
  - [x] **L-12b2 Sawing it.** Done Nov 9 (D-053): a Saw button each side of every wall two
    units in a row share (`Saws`), shown only to someone carrying a saw; hold it 4 s with the saw
    in hand ("Hold the saw" if it's in your other slot) and the hole goes through. The motor and
    blade are heard 200 studs off (`Saws.sawing` for keepers), a hot line crawls round the cut
    with sparks, your view buzzes; the panel tips over and clangs flat on the far side, jolting
    anyone near (`SawView`). Server-checked like Cut and again before it cuts. The deal keeps off
    the hole spots (`DealSpot`). A saw lies by the test hall's spawn. Cut 103 into 105, 106 into
    108 and the small 109 into 111 in Studio; a short hold stops clean.
  - [x] **L-12b3 Crawling through.** Done Nov 9 (D-054): a Crawl button (E, X on a pad) each side
    of every holed wall (`Crawls`, watching `CrawlHole.Tag`), shown only on your own side and not
    while you crawl. Press it and the game takes you through in about 1.4 s, as DOORS' and
    Pressure's vents: down onto your belly at the hole's mouth (a thud, a jolt), two pulls through
    (a drag each, the cut steel scraping your shoulders, your view low and rocking), up on your
    feet in the next unit (`Crawling`, pure, Lune-checked). Your screen moves your body (touching
    nothing on the way); every screen poses the crawler's arms reaching and hauling (`CrawlView`).
    One body in a hole at a time ("Wait for them"); `Crawls.crawled` for keepers (35 studs). The
    test hall no longer cuts holes as it's laid. Crawled 106 into 108 and back, and the small 109
    into 111, in Studio.
  - [ ] **L-12c The hole trap** (needs L-06b's keepers): slam a keeper in, the dented door, its
    break-out after about 90 s, a padlock keeping it in for the floor, the team's bonus.
- [x] **L-13 The ladder and the tops.** Split Nov 9:
  - [x] **L-13a The tops' closed edges** (D-055). Nothing on the tops drops you off the world: an
    S unit's wire top over every junction square a run reaches (its blocks of wall, a corner's
    outside square), so a run turns the corner, and the kit's plain-wall panel, from the cap up
    through the deck, at every other drop (rows' backs, the 4-stud step beside an 8-deep unit, a
    run's end at the lobby, a lid over an empty slot); over a pit with no wall of its own the
    panel shows its bare sheet down to the floor. `Floor`'s lids, panels and `Run.lids` (pure,
    Lune-checked over 400 floors that no edge is left open). In Studio on floor 1: 78 panels and
    13 lids laid, rays and sliding probes found no way off, the corners closed flush.
  - [x] **L-13b The ladder.** Split Nov 9:
    - [x] **L-13b1 The ladder's art, carried and dropped.** Done Nov 9 (D-056): an aluminium
      extension ladder built the unit's way (`art/ladder/`), two parts (the base, and the fly
      welded on it, 5 studs of travel for L-13b2), 6.8 long collapsed. Lies where the deal puts
      it (across a small unit, deeper in a big one) and by the test hall's spawn; picked up with a
      bang and dropped with a clatter on concrete. Friends see it on your left shoulder; it takes
      both hands (no switching slots or picking up, "Drop the ladder first"), and slows your walk
      to 12, as Lethal Company's two-handed items.
    - [x] **L-13b2 Up the ladder and along the tops.** Split Nov 9:
      - [x] **L-13b2a Lean it and climb.** Done Nov 9 (D-057). A Lean button (R) up on each unit's
        front, left of the door, for whoever holds the ladder: it swings up against the front at the
        4-to-1 rule, rails on the top edge, the fly runs out and locks with a bang, a rattle and a
        clack, every screen playing it (`Leaning`, `Leaned`, `Ladders`, `LadderView`). Climb (E) is
        a pressed move the game makes, as the crawl's: up rung over rung (Roblox's own climb
        animation on your body, so friends see it) and over the edge onto your belly in a spot of
        your own on the wire top (3 on a small unit, 4 on a big one); Climb down (E) ahead of you
        brings you back into the hall; Take (F) puts it back on your shoulder, refused while
        anyone's on it or up there. Roblox's truss climbing was tried first: on a leaned truss it
        flicks between climbing and falling. No crawling through a hole with it in hand. Keepers
        never get the buttons. Verified in Studio; phone and two players wait on `OWNER.md`.
      - [x] **L-13b2b The tops closed in steel.** Done Nov 9 (D-058, owner): with open wire a
        torch from up there showed every unit's code and keepers. Every unit's top and junction lid
        is now the walls' ribbed steel laid flat, two sheets lapped on the middle channel, the rib
        ends closed (`Top`, was `WireTop`; the same collider, so the ladder's spots didn't move);
        from up there you see only the halls. Landing on it is a body against thin steel, not a
        fence rattle. Both unit templates swapped in the open place; verified in Studio.
      - [x] **L-13b2c Along the tops and down.** Done Nov 9 (D-059). The stick steers your lying
        body over the steel, slow and low (4.5 a second, surging per pull, backward at half), held
        on the tops by the pure `Tops` map each floor publishes (its run slots, lids and a lip over
        each hall), your head only out over a front so you can look down; the server checks your
        place five times a second. Each pull booms softly on the steel for every screen, every other
        one a `climbed` "Crawl" for keepers (30). Climb down from wherever you are by a ladder; Drop
        down (F) off any unit's front: over, down, a crouch, a thud and a jolt, standing in the
        hall. Take no longer waits for those up top. Lune: 34,372 checks over 60 floors (every
        lying spot fits, random crawls never leave the steel, unit to unit, onto every lid, the
        peek, the drop). Verified in Studio: 102 to 104 along a run, the peek, the drop, onto a lid
        on floor 1, backward, Climb down from 4.4 studs off. Round a corner onto another run, two
        players and the phone wait on `OWNER.md`.
      - [x] **L-13b2c2 Hands out of walls.** Done Nov 9 (D-060; owner: the torch and tools went
        through the roof and doors). Your torch and the tool in your other hand are drawn at a
        third of their size a third as far from your eye (`Hands`), so they look the same but never
        poke through a wall, a door, the steel or the ceiling; when even that would touch (lying on
        the steel looking down) they pull back and duck out of view, as Ready or Not's and Escape
        from Tarkov's guns do. The beam still leaves where the full-size lens would be, but never
        from past a surface, yours or a friend's (`HandRoom`). Verified in Studio: nose to a wall,
        on a top looking down, the peek. A tool in hand, a friend's beam and the phone wait on
        `OWNER.md`.
      - [x] **L-13b2d Saw down into a unit** (owner, Nov 9). Up on the tops with the saw, hold Saw
        over a unit to cut its top (the saw's 4 s, heard floor-wide, waking what sleeps inside)
        and drop in blind, as Rainbow Six Siege's floor hatches; one-way, no ladder inside. Out:
        an unlocked door rolls up from inside; a padlocked one keeps you in until you saw out
        sideways or a friend cuts the lock. Your torch can look down the hole before you drop
        (owner, Nov 9: you paid for the look with the saw's noise). Split Nov 9, as the wall hole
        was (art, the cut, the way through):
        - [x] **L-13b2d1 The sawn top's art.** Done Nov 9 (D-061). A unit's steel top with a
          hole sawn in it (`art/tophole/`, the wall hole's code and recipe loaded as a library):
          2.8 across, 2.05 front to back, in the middle just behind the door's drum, across the
          first channel (sawn through, bright ends); tongues bent down; the panel on the floor
          below, tilted on the channel's stub, slid aside. `Top_S`, `Top_M`, `Edge`,
          `PanelEdge`, `Panel`; generated `TopHole/Specs`. Judged in eight look sheets, one at
          phone size; not yet uploaded.
        - [x] **L-13b2d2 Saw the top.** Split Nov 9 in three (the art in, the cut, the map):
          - [x] **L-13b2d2a The sawn top in the place.** Done Nov 9 (D-062). Uploaded,
            inserted and prepared into `Props.TopHole`; `TopHole.saw(unit, at?)` swaps the
            unit's top for the holed one, lays the edge and the fallen panel (one `TopPanel`
            model, tagged with its cut time), opens the top's collision round the hole;
            `TopHole.frame(unit)` reads the hole's frame off any unit. Verified in Studio: an M
            and an S cut, looked at from the tops, head over the hole and inside, at phone size.
          - [x] **L-13b2d2b The cut.** Done Nov 9 (D-063). A Saw button over every unit's hole
            spot, only for someone lying up on the tops with a saw: the wall's hold (R/R2, 4 s),
            sounds and checks in the same `Saws` system, plus up on this unit's top (Ladders) and
            not lying on the hole ("Move off it"). A thin orange-hot line crawls round the cut on
            the steel's face from the front edge, sparks rise off the blade, your view buzzes.
            Through, the panel hangs a beat, drops ten studs at the game's gravity (its pose in
            the hole from the art's own fall, `TopHole/Specs.Fall`), and lands with a heavy clang
            heard floor-wide and a jolt. Verified in Studio: a player's lie, hold, let go early,
            hold through, the line, the drop and the hole, on an M.
          - [x] **L-13b2d2c The map.** Done Nov 9 (D-065). A sawn top's hole is on the tops'
            map the moment it goes through (`Ladders:holed`): nobody crawls over it, your head
            goes out over its edge to look down into the unit, anyone lying across it (a friend,
            or the sawer's feet) glides off onto the steel with the steel's give and a jolt. The
            ladder offers only spots clear of the hole and not rolled across it: one on a sawn
            top of either size, the first, by the ladder (a small unit's moved a quarter stud
            out). Verified in Studio: sawed with my feet over the spot and glided off, crawled at
            the hole and stopped at its edge looking down, the bulb's light up through the hole
            at full graphics.
        - [x] **L-13b2d3 Drop in, and out again.** Split Nov 9 in two (the drop; what's below):
          - [x] **L-13b2d3a Drop in.** Done Nov 9 (D-066). Lying at a sawn hole's edge with your
            head out over it, a Drop in button (F, pad B) shows down the hole and the Drop down
            button hides. Pressed, you tip up, your legs slide down the hole's middle, you hang
            a beat with your head under the ceiling, drop feet first with your arms going up,
            and land in a crouch on the unit's floor facing its door: 0.96 s, the steel's ring
            as you push off, a thud and a jolt, heard 45 studs (`climbed` "In"). Verified in
            Studio as a player on the test hall's Unit 101: sawed, crawled to the edge, pressed
            F, landed under the hole's middle, head never above 13.66 under the 14-stud ceiling.
          - [x] **L-13b2d3b A clear floor, and out again.** Done Nov 9 (D-067): the deal lays
            nothing where you land under a top's hole (3 studs across, from the door's line to
            0.9 behind the hole's middle) nor where the top's cut-out panel falls, and a unit
            is now dealt when a saw's hole first opens it (its top or a wall), not only when
            its door lifts, so what it holds is there as you look down. Lift from inside a
            padlocked door rattles and says "Saw a wall". Verified in Studio on the walked
            floor's Unit 102: sawed its top (it held a boombox, at the back), dropped in onto
            bare floor, tried Lift padlocked, then unlocked, sawed through to Unit 104 (dealt
            a saw as the hole went through) and walked out under the lifted door. The owner
            judged it in Studio on Nov 9: looks good, the foot in the fallen panel left as is.
- [ ] **L-14 The other tools.** Bubble wrap across a hall (pops for anything that crosses, heard
  floor-wide), the air horn (lures keepers to a spot, wakes sleeping ones), the moving blanket
  (thrown over a keeper, blinds it a few seconds), glow sticks (light the building can't see,
  keepers with eyes can). Each a row on L-11's tools, its art first; may split a tool a session.
- [ ] **L-07 Getting kept and rescued.** Shrink-wrapped, stored in a random unit, banging to ping
  the team, cut free in a second, padlocked if left too long (GDD "Getting kept").
- [ ] **L-08 The ride and the next floor.** The elevator ride and a second floor, so the climb is
  a loop and not a single room. Brix: its round loop (ENG-13) if it has landed.
- [ ] **L-10 The map** (owner, Nov 7: players shouldn't get lost and give up). A floor map you
  open with a button, filling in only the halls you've walked, as R.E.P.O.'s map fills in rooms as
  you find them; the lobby and elevator always marked, so the sprint for the gate always knows the
  way; units you've opened ticked. Never keepers or lit fixtures: that stays the office light
  board's (GDD), so working the board is still worth a player. Drawn from the same `Floor` data
  as the building (GDD: one tile graph). Phone first: one tap to open, readable at phone size.
  Whether friends show on it waits on the owner (`OWNER.md`). Needs L-05's elevator.
- [ ] **L-09 Hone.** Playtest with friends, tune Config, add juice, repeat until Gate 1. May
  repeat as several sessions; each one names what it changed and why. Brix: live config (ENG-11)
  and the presentation kit (ENG-15) as they land.

## Phase 2: The rest of the game (GDD build order step 2)

All ten floors with the ride, the stairwell set piece and both boss floors; the director; the
other keepers and their own tools (mothballs, the box cutter); the dolly; the light board; finds
with rarity; your lobby unit; the store; Captures. Player data, remotes, telemetry and UI from Brix
(ENG-09 to ENG-16). Then soft launch.

- **Finds in a run** (moved from L-04d, Nov 8): where a unit's boxes and its find stand for the
  unit's size, the find deeper than the bulb and facing the door within a small turn (D-036);
  carrying finds out to the elevator; padlocked units' finds the best (rarity).
- **Fake notes** from floor 6, in the building's slightly different hand (GDD "Codes").

## Polish waiting for a slot

- **Your foot in the top's fallen panel** (L-13b2d3b): landed, the foot on the panel's side
  stands 0.6 studs into the panel's corner and 0.4 deep in it (the panel has no collision). A
  small unit has no room to lay the panel clear of your feet, so it wants a new resting pose in
  `art/tophole` (leaned on the side wall?) or a kick as you land. The owner passed it as it is
  (Nov 9), so it waits for a slot like the rest of this list.

- **A friend sliding off a sawn hole** (L-13b2d2c): only the slider hears the steel give; others
  see the glide and hear a pull's boom. The steel's ring and a scrape for everyone near.

- **A top's panel landing** (L-13b2d2b): a puff of dust off the concrete where it lands and a few
  flakes of rust and paint falling through the hole after it, so someone inside sees it land, not
  just hears it. And the line's glow lighting the hole's edge from below for anyone inside.

- **The steel bowing under a crawler** (L-13b2c): the sheet you lie on dipping a hair as you pass
  and the lap seam creaking where two sheets meet; and a recording of its own for the pull's
  boom (it's the landing's, pitched down).
- **A hint the first time you're up top** (L-13b2c): nothing on screen says you can crawl; a
  first-time nudge once the owner has played it.
- **A friend's arms on the ladder** (L-13b1): the ladder rides on their left shoulder, but their
  arms swing free; the left arm raised to steady its rail (as the torch's raise, `Torch.raise`)
  would sell its weight.
- **The ladder's rattle as you walk** (L-13b1): a soft aluminium rattle in step with your stride
  while it's on your shoulder, heard by friends close by, so the slow one is heard as well as
  seen.
- **The ladder leaned in a unit** (L-13b1): the deal lays it flat; leaned on a unit's side wall
  it would read from further off (L-13b2's lean, reused).
- **Taking the ladder down** (L-13b2a): Take puts it straight back on your shoulder with the
  pick-up's bang; the fly sliding in and the ladder swinging down off the front onto your
  shoulder (the raise played backwards) would answer the press as the lean does.
- **Your hands on the rungs** (L-13b2a): climbing, first person shows the rungs passing close but
  no hands; your hands taking each rung in turn would put you on the ladder.
- **The ladder bowing under a climber** (L-13b2a): a slight flex and creak as each climber
  steps on, so a full ladder sounds loaded.
- **Columns at the tops' corners** (L-13a): where two panels meet at a corner up on the tops,
  their sheets' cut ends meet bare; a steel corner column, as the junctions' walls have, would
  finish them. Unseen until the ladder takes players up there.

- **Filings under the hole** (L-12b1): a scatter of bright steel filings on the floor under the
  cut, both sides, and a little drywall-white dust on the saw's side; a few on the fallen panel.
- **The cut's corners overrun** (L-12b1): a hand-held saw overshoots where two cuts meet; short
  thin slits past each corner of the hole would say "sawn" up close.
- **The Hole set's atlas** (L-12b1): its strips are long and thin, so three quarters of its 512²
  is gutter. Laid out by hand (each strip a row) it could go to 256² at the same sharpness.
- **The saw's trigger blip** (L-12a): picking it up plays a plastic knock; a quick squeeze of
  its trigger (a quarter second of the motor's whine, quiet) would say "power tool" the moment
  it's in your hand, once L-12b has the motor's sound. Keep it quiet so nobody thinks a keeper
  heard it.
- **A friend's arm while they saw** (L-12b2): a friend sawing shows the line, the sparks and the
  sound, but they stand still with the saw at their side; their arm raised to the wall with the
  saw's blade in the cut (as the torch's raise, `Torch.raise`) would show who's making the noise.
- **The cut cooling into the edge** (L-12b2): the line fades over 0.6 s as the holed wall swaps
  in; a quick orange glow on the cut edge's bright strip, cooling to steel, would join them.
- **Saw dust on the sawer's side** (L-12b2): a little grey dust puffing off the blade with the
  sparks, settling under the cut (with the filings above).
- **A friend's legs while they crawl** (L-12b3): their arms reach and haul, but their legs trail
  straight; a knee drawn up in turn with each pull (hips and knees posed, as the shoulders are)
  would sell the drag.
- **Your hands through the hole** (L-12b3): crawling, first person shows only the tool in your
  hand floating ahead; your hands planting on the floor at each pull (with the saw's and the
  torch's hands) would put you on your belly.
- **Dust at the lip** (L-12b3): a puff of floor dust as you land on your belly at the hole, and a
  grey smear on the cut's lip after the first body has dragged over it.
- **Your hand on the saw** (L-12a): first person shows the saw alone, low on the left; a hand
  round its rear grip would sell the hold, with the cutters' and the torch's hands.

- **The bite at the shackle** (L-11c): the cutters in your view reach the door, not the latch by
  your feet; their jaw meeting the padlock (`Specs/BoltCutters.JawTip`) and closing as it snaps,
  a bright fleck off the cut, and the cut padlock's shackle shown cut (a second mesh) would land
  it. A friend sees nothing of your cut but the padlock flying off: their arm reaching down to
  the latch with the cutters as you hold Cut.
- **Your padlock flying to the door** (L-11c): on Lock it jerks and drops out of your view; it
  could travel from your hand to the latch and snap shut there.
- **Your hand on the cutters** (L-11b): first person shows the cutters alone, low on the left; a
  left hand closing round the grips would sell the hold (with the torch's hand, one rig).
- **A dropped tool's tumble** (L-11b): it falls straight and lands flat; a bounce and a skid on
  the concrete in time with the drop's clanks would land the moment.
- **The slots' bar wakes and sleeps** (L-11b): it shows always; it could fade to faint after a few
  seconds with nothing new and come back on any change, as Minecraft's hotbar stays but quiet.
- **Your hand on the torch** (L-11a): first person shows the torch alone, low on the right; a hand
  round its grip (the avatar's own colour) would sell it, as DOORS' and Pressure's held items do.
- **A hint for the torch's right click** (L-11a): mouse players learn Alt from FreeCursor's pill;
  the torch's right click wants the same pill once ("Right click  Flashlight").
- **The beam in the haze** (L-11a, atmosphere: after the loop): a faint visible cone in the hall's
  dust (a Beam or a few lit puffs), as Lethal Company's torches show theirs.
- **The torch into a wall** (L-11a): pressed face-first into a wall, the held torch's head sinks
  into it; pull it back towards you when a wall is that close.
- **A friend's arm, animated** (L-11a): their raised arm is a turned shoulder, stiff and straight;
  an aim pose with a bent elbow would read as holding a torch rather than pointing.
- **The view sheets' spill** (L-11a): rerender `art/sheets/flashlight-view*.png` with the game's
  spill light (`Torch.SpillOffset`) when the torch's art is next rebuilt.

- **The PA's voice** (L-05b2): the GDD has the PA count the 30 s down aloud. Today a chime starts
  the clock and the bell counts the last five; a voice ("Thirty seconds", "Ten", then the count)
  wants a recording or Roblox's text-to-speech (`AudioTextToSpeech`, verify it first).
- **The ride's motor** (L-05b2, for L-08): the lurch after the gate slams is felt but not heard;
  the car wants its motor's whine and the cables' creak as it starts up.
- **The thumbstick over the ride's fade** (L-05b2): Roblox's touch controls stay drawn over the
  black while the car rides; hide them for the fade, or let them show (most games do).
- **The held-up note's shadow** (L-05b1d): a soft shadow under the card as it lifts, so it reads
  as paper held off the world rather than pasted on the screen.
- **A note answers when it's found** (L-05b1b): the first time a note comes into your light, a
  soft paper flutter and a faint sting, once per note, so the find lands even before it's read.

- **Light that matches at every quality** (owner, Nov 8): at Quality Level 01 nothing casts
  shadows, so the car's lamp lights the lobby's back wall through it and the keypad's red glow
  doesn't show; at 21 the wall is dark but for the glow (`docs/art/L-05a2-keypad-*.jpg`). Pick
  one look and make both qualities give it.
- **A floor dial over the landing** (L-05a1): an arrow dial in the frame's header that swings
  floor to floor during the ride, read from across the lobby, as old elevators' indicators.
- **A trim sheet for the elevator's big trim** (L-05a1): the car's posts, fascia and boards and the
  landing's frame are at 41 texels a stud; if they read soft on a phone, map them onto tiling
  strips at 80 like the car's walls.
- **Tally marks in the car** (L-05a1): scratched into the paint by a back corner, someone counting
  nights; a patch of its own, since the walls tile.
- **The shaft** (L-05a1): rails, cables, the counterweight and the next landing passing during the
  ride, and what's left when the car goes up without you (L-08).

- **The Mannequin's head turned to you** (L-06a): each time it moves unseen, its Neck turns
  toward the nearest player, so the next look finds it watching you, as Five Nights at Freddy's
  animatronics stare into the camera. A line in L-06b's mover, inside the Neck's limits.
- **The Mannequin's inventory tag** (L-06a): a manila tag on a string round its wrist, a lot
  number in pen, that swings when it stops; read up close in a torch.
- **More of the Mannequin's keys** (L-06a): a lurch, a crouch round a corner, a head down at a
  door's gap, so a long hunt shows new freezes; each one checked by the spec's stands().
- **The Mannequin's feet** (L-06a): its root moves smoothly while its pose holds, so its feet
  slide during a hold; move it in steps with the snap if anyone ever sees it walk.
- **A doll-sized Mannequin for the Kept shelf** (GDD's Kept tier): the same model scaled, its head
  turning when you look away.
- **The Mannequin's walk without garbage** (L-06a): `Pose.at` builds a new table each call; reuse
  one when L-06b steps it every frame for several keepers.

- **The finds' printed words** (L-04c): the boombox's badge and "STEREO", the tuner's numbers,
  the TV's channel numbers, from a label sheet the boxes' way.
- **The bedroom set's other pieces** (L-04c): about four more and the display piece a finished set
  unlocks (GDD); the owner picks when finds come back in Phase 2. The default: an electric guitar,
  a lava lamp, a shoebox of mixtapes, a desk phone.
- **A mimic's clean finds** (L-04c, needed by the mimic): the Bedroom atlas baked again with
  `DUST = 0` (a mimic has no dust, GDD), uploaded as its own maps.
- **The teddy's fuzz and the atlas's room** (L-04c): a soft fur edge on its outline; 63% of the
  atlas is empty gutter round the teddy's small islands, so a tighter packer would raise 99
  texels a stud.

- **The boxes' second look** (L-04a): every box of a size looks alike (one atlas). A second label
  set, or a box turned so another face shows, before a unit holds three of one size side by side.
- **The wardrobe box's hanging bar** and a lid lifted on the Open box's floor (L-04a).
- **A unit's bulb swinging** on its cord after a slam or a bump, its pool rocking across the boxes
  (L-04b): a small spring on the bulb model, stepped only while it swings.
- **The guard's bars on the walls, softly** (L-04b): from a point light the six wires threw hard
  black bands across the whole unit (`docs/art/L-04b-guard-shadows.jpg`), so the guard casts no
  shadow. A faint striped texture on the walls near the bulb, or fewer, thinner wires, if the
  owner wants the caged look back.

- **What a laid floor costs to draw** (L-01c): the whole floor streams in at once, and from its
  lobby the main view drew 96,000 triangles (112,000 down an aisle) in 43 draw calls in Studio's
  window, most of them units hidden behind walls. If a low-end phone struggles (`OWNER.md`), try
  a lower `StreamingTargetRadius`, the units' MeshParts on `RenderFidelity` Automatic, or a
  cheaper unit far off.
- **The junctions' girder from a unit:** behind a junction's corner block the two halls' decks
  overlap in a 4-stud square, unseen from the halls; a unit's wire top could show it (the floor
  keeps M units out of those slots; an S row there stops short of it, D-027). Where both halls'
  slots there are M plain walls, their two lids cross in that square (L-01d): seen from the tops
  once the ladder lands.
- **L units on a floor:** a large unit (20 deep) doesn't fit under a hall's 32-stud span, so the
  floors place none. A dead end's far wall could hold one facing down the hall, under a deck of
  its own (GDD: three sizes).

Atmosphere effects wait until the loop is solid (owner, Nov 7); the haze stays as built.

- **The bolt and the padlock move** (P0-04): locking now snaps the latch bolt across and shows the
  padlock at once, with its sounds; a slide of the bolt (about 0.2 s) and the padlock swinging
  once on its hasp would let the eye follow the sound.
- **A shut door muffles the unit behind it** (P0-04): sounds from inside a shut unit, or the hall's
  heard from inside, play as clear as an open one. A low-pass (an `EqualizerSoundEffect`) on a
  door's sounds while BehindDoors says a shut door stands between would make a slam heard from
  inside the hall sound like it.
- **A "less camera shake" setting** with the settings menu (P0-04's `Shake`, scaled by it).
- **The sound mix:** a SoundGroup for effects (the door, the lights) under the settings' volume.

- The unit's size L: render and judge it. Its door is wider than the M's bake, so its slats,
  bottom bar and drum stretch the texture 1.46x (a narrower S crops it, D-028); tile it instead.
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
- The fixture's chains are half its 2,000 triangles. If a floor's triangle count bites on a
  low-end phone, cut each link to 6 points round (about 260 fewer a fixture); at phone size the
  links read as a beaded line either way.
- A faint red glow on the housing round a Seen eye (a tiny light) would sell the flare, but costs
  a light per tripped fixture; try it only if L-03's light budget has room.
- A lit tube's hum, faint and close, so a lit stretch sounds alive and a dark one dead (L-03;
  ambience, so after the loop).
- If a far fixture's pool shows popping on or off as the three nearest change (L-03's budget),
  fade its light over a quarter second instead.
- Each kit FBX brings its own copy of the unit's texture sets (Concrete, TrimSheet, and now Facade
  and Partition). If texture memory on a low-end phone shows the copies, `prepare` could point the
  kit's SurfaceAppearances at the unit template's maps (plugin security: the command bar can).
- A door answers only when the server's word comes back (a round trip, about 0.1 s on a good
  phone connection). If it feels late, start the motion on the presser's screen at once and let
  the server confirm, as the lights do (D-025) (L-02).
- The Cut button shows on every padlocked door, to players without bolt cutters too (it says "Need
  bolt cutters"). When the tools land, a client layer could show tool buttons only to who carries
  the tool, and the padlock tool its own Lock button (L-02, D-030).
- Bolt cutters cutting a padlock play the padlock's pop; a real cutter's snip and the lock
  dropping to the floor when the tools land (L-02).
- If a friend griefs by slamming a door again the moment a lift from inside reaches the top, give
  a lifted door a second's grace before it can be shut from the hall (L-02; nobody can shut it
  while it rises).

