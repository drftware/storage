# Roadmap

One ticket = one session. A ticket names what to build, how we know it's done, and what to read
first. If a ticket grows past one session, split it here before starting. Later tickets are
one-liners; each gets its full spec when it becomes HANDOFF's Next task.

The order follows the owner's plan (2026-11-05): set up the project and bring the real assets in,
build the gameplay loop with those real assets and hone it until it's awesome, then flesh out
the rest of the floors and the game. Phase 2 follows the GDD's "Build order" section, Steps 1 to 6
(the owner's answers to the proposal, Nov 13, D-128).
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

**The order from here** (owner, Nov 10), one session each: L-14e (the cut tools out of the
deal), L-07d, L-07e, L-06c1, L-06c2, L-08a to L-08d (the climb), L-15, L-16a, L-16b, L-16c, L-17,
then L-09a, the first run with friends. L-14b2d only if the owner asks.
**The overnight run (owner, Nov 10 night):** up to 15 sessions back to back, each capped at about
300k tokens of context, still one ticket each. Hard limits: **no lobby** (L-08e waits: the owner
brings the full lobby plan on Nov 11) and **no new keepers** (the owner approves each one); the
Mannequin can get as much scarier as it likes. Progress first (floor 2 and the climb), polish
throughout. Owner, verbatim on the Mannequin: "right now it sounds like fucking pinnoccio walking
around and getting caught doesn't seem like a big deal" (L-06c1, L-06c2). The roof crawl is
"super glitchy and the camera shakes a ton. It needs to be smooth, and feel perfect" (L-16c).
L-18 moves after L-16c, optional. A spare session at the end hones floor 2.
**The owner's Nov 11 play** reordered the end: L-16c first (the tops, "really bad... it needs
fixed"), then L-16b, then L-19 (the buttons in the world, small and modern) and L-20a (the
inventory wheel) before L-17 judges every button on a phone at once, then L-09a. That night the
tops still jittered on a computer: L-16d, "not now", but before friends play (L-09a).
**The overnight run (owner, Nov 11 night):** "Run 15 sessions, capping each at 300k context...
Make the fixes I recently described, the prompt updates, build the lobby, and beyond... this game
needs to be perfect." Up to 15 sessions back to back, about 300k tokens of context each, still one
ticket each, every session ending green and committed. Order: L-16b2 (done), L-19a (done: one
look for every button, the owner's "prompt updates"), L-19b (done: a door's buttons where the
hand goes), L-20a (done: the inventory wheel, three slots), L-17 (done: every button on a
phone at once), L-16d (done: your body placed each drawn frame), L-08e1a (done: the front
office built), L-08e1b1 (done: step in and the count), L-08e1b2 (done: the host's panel),
L-08e1c (done: a server of the group's own), L-08e2 (done: back in your car), then the rest of
the lobby, L-08e3 and L-08e4 (GDD "The lobby", D-112), which no longer waits on L-09a (only the owner can run that): split L-08e4
into sessions that each end green (the cart's art script first, then the ride). With sessions left: HANDOFF's "Seen" fixes, L-18, then honing what was built
tonight (the polish list). Hard limits: no new keepers, no paid items or store (Phase 2 waits on
Brix's purchases and profiles), proven mechanics only, never edit Brix.
**The evening run (owner, Nov 12):** "keep working on the lobby. Run 300k max context sessions
until 8pm... it needs to be absolutely world-class if we want to monetize this properly."
Sessions back to back until 8pm, about 300k tokens of context each, still one ticket each, every
session ending green and committed: L-08e3, then L-08e4 in green-ending pieces, then honing the
lobby (the polish list). The owner looks at the lobby at 8pm. The two things the owner saw that
day (the car floors' splotches, the flash through a sawn panel; HANDOFF's Seen) wait: "we can
fix them later." The overnight run's hard limits hold.

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
- [x] **L-06b The Mannequin hunts.** The first keeper, and with it the keepers' brain, which
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
  - [x] **L-06b2 The Mannequin goes to look.** Split Nov 9 into two sessions.
    - [x] **L-06b2a It hears a door and walks to it.** Done Nov 9 (D-069): you open or slam a
      door and, two halls off, the Mannequin walks the halls to stand square in front of it,
      facing it, for five seconds, then walks back and goes still, Granny's way with a noise. The
      brain is the pure `Keeper` (asleep, going to look, waiting, going back) reading a row from
      `KeeperRows` (the Mannequin: top speed 0.9 of your run, looking at half that, hears as far
      as you do, lingers 5 s, no abilities), run by the server's `Keepers` system on the Host's
      clock with one map per laid floor kept in step with its doors (`Doors.changed`). It hears an
      open, a slam or a lift from inside within DoorSound's reach measured along the halls, so
      never through a wall or a shut door; a newer sound takes it there. Its body is an anchored
      `Mannequin.clone` moved by its root, posed on the server at most 20 times a second, holding
      its stride when it stops. A "Stand one" post in the walked floor's lobby stands one 60 studs
      down the halls. `tests/keeper.spec.luau`: 20,000 checks over 30 seeded floors. Verified in
      Studio: an open 40 studs off and one 79 studs round a corner brought it the shortest way,
      every sample on the halls; one 86 studs off in a straight line but 116 along the halls left
      it still.
    - [x] **L-06b2b Dealt keepers join.** Done Nov 9 (D-070): a keeper the deal puts behind a
      door stands where it was laid as the door first lifts, so a peek shows its feet. Asleep, it
      stands slack in its shop pose, still, until the first loud sound that reaches it through its
      open doorway wakes it (Left 4 Dead's Witch), and it goes to look; its own door's open
      doesn't wake it, so a peek and a quiet close still save you. Awake, it holds a stride square
      to the doorway and steps out to look the moment its door is all the way up. The brain gains
      Asleep (dealt asleep) and Watching (awake, standing) and `Keeper.lookOut`; the deal's cap
      counts the brain's keepers awake now (`Keepers:awakeOn`). 20,572 Lune checks. Verified in
      Studio on seed 7, floor 1: Unit 112's sleeper stayed still through its own open and woke to
      Unit 113's; Unit 126's awake one, dealt first, walked out once its door was up; dealt after
      the sleeper woke, the cap turned it asleep. Judged by the owner Nov 9: not bad, but the
      walk reads jerky (L-06b4a), and slamming an awake one in, or letting it walk home and
      shutting it there, was too easy (D-071).
  - [x] **L-06b3 It roams, hunts, freezes, catches and breaks out.** Split Nov 9, a session each,
    at no more than player speed (the GDD's speed rule) throughout. Reshaped with the owner Nov 9
    (D-071): as built, a keeper went home after looking, so you could let it walk back in and
    shut it there, and a slam ended an awake one for good. Run order: L-06b3a1, L-06b3a2, L-06b4a,
    L-06b3b, L-06b3c, L-06b3d, then L-06b5a, L-06b5b and L-06b4b (b1, b2, b3).
    - [x] **L-06b3a1 Once out, it roams.** Done Nov 9 (D-073). After looking at a noise, or out
      of its own doorway, a keeper roams the halls between noises, as Granny walks the house room
      to room: to a hall piece's middle 40 to 120 studs off along the halls that isn't one of its
      last four stops, at its looking pace, stopping 3 s, picked by a fresh Brix Random from the
      floor's seed (`Keepers:add` takes it). Never into a unit, so its door shut behind it changes
      nothing; a door down across its way makes it pick again, and one shut in its unit before it
      got out watches until the door is up. Roaming replaces Returning. 23,420 Lune checks.
      Verified in Studio on seed 7, floor 1: Unit 126's awake one walked out, looked, roamed 75 s
      without going back in (126 slammed behind it), never stood still over 3 s, and came to Unit
      139's open 33 studs off. Waits on `OWNER.md` for feel and the defaults.
    - [x] **L-06b3a2 It sees you and hunts.** Done Nov 9 (D-074). Pursuit doesn't run it (a
      placed hunter is never moved by Pursuit again). Awake in any state, a keeper sees a player
      within its row's `sight` (48) and `sightAngle` (60 degrees each side) along a straight line
      `KeeperMap.clear` passes (no wall, shut door or door post; not up on the tops), turns and
      hunts the nearest at its top speed to arm's length (`Keeper.Close`, 2.5); no sound pulls it
      off. Lost, it rushes to where it last saw them, stands its linger, then roams. Asleep it sees
      nothing. The server feeds players' feet each step. 46,500 keeper and 73,126 map checks.
      Verified in Studio on seed 7, floor 1: opening 126 in front of it, it came out at once;
      chased 90 studs down the hall and round the junction 5 studs behind; lost, it searched,
      stood 5 s and roamed; roaming, it turned on a player 18 studs ahead. Waits on `OWNER.md`.
    - [x] **L-06b3b Light freezes it.** Done Nov 9 (D-076). A row that freezes in light (the
      Mannequin) holds where it stands, as it stands, while it's in a hall under a lit hall
      light's pool (13 studs round the fixture) or a torch's beam reaches it (42 studs, 27 degrees
      off the beam's middle, along a line the map clears, so never through a wall, a shut door or
      round a corner). Its walk to look, its roam, its hunt and its clocks all stop; it still sees
      and hears, so it can start hunting you while frozen, but never turns; it walks on the moment
      no light is on it, exactly as if no time had passed. A freeze reaches screens at once as a
      stop record. 51,410 keeper checks (twins, one held, end up identical; beams against a fine
      reference; a shut door). Verified in Studio on seed 7, floor 1: out of 126 and chasing me in
      the dark, it froze 13.5 studs off the moment I turned my torch on it, held 3 s (drawn within
      0.05 studs), and walked on to arm's length when I turned away; running under the lights, it
      froze in the light 24 studs back, and when I stood still the lights went out after 7.5 s and
      it closed in. Waits on `OWNER.md` for feel.
    - [x] **L-06b3c The catch.** Done Nov 10 (D-077). Hunting, its hand closes on the one it
      hunts within its row's grasp (`reach` 3.5 studs, a stud past arm's length, and `reachAngle`
      45 degrees either side), Brix's cone reach measured along its map, along a line the map
      clears (never through a wall or a shut door, never from the tops) and no higher than its
      head; never while a light holds it, never asleep, never anyone else. Caught, it stands over
      the spot its linger, then roams. The caught player's view jerks, the screen drops half dark
      and closes to black with "Caught", and they're held still 2 s (`Caught`, `CaughtView`); the
      server fires `Keepers.caught` and keepers leave them alone 2 s. Stand-in until L-07: in the
      black, DevCorridor puts them back in the floor's lobby. 63,436 keeper checks (exact against
      Brix's cone on eight floors). Verified in Studio on seed 7, floor 1: out of 126 it caught me
      at arm's length; with my torch on it, it hunted frozen 12 s and never came. Waits on
      `OWNER.md` for feel.
    - [x] **L-06b3d It breaks out** (moved from L-12c, D-071). Split Nov 10: L-06b3d1 is the
      brain, the bangs' feedback and the cap; L-06b3d2 is the dent, the door's own art. Trapped means its doorway was open
      (its door all the way up) and the door came down on it awake inside, by a slam or a close; a
      peek lowered over an awake one isn't a trap, it just waits. A trapped keeper bangs at its
      door every few seconds, heard as keepers hear (D-069), dents it more with each bang, and at
      about 90 s bursts it up, loud, and goes after the last thing it heard, the way Amnesia's
      monsters batter down a door you shut. A padlock on the door keeps it in for the floor. While
      trapped or padlocked it takes no place in the floor's cap of awake keepers (`awakeOn`), so
      the next door can hold a fresh one; out again, it counts again. The dent is the door's own
      art, built the unit's way. Lune checks on the clock and the cap; in Studio, slam 126 on its
      awake one and time the break-out.
      - [x] **L-06b3d1 Trapped, it bangs and breaks out.** Done Nov 10 (D-078). A door down from
        all the way up on an awake keeper inside traps it (`Keeper.trap`); it stands against the
        door and bangs, the first blow 1.2 s after, then every 5 s closing to 2 s; each blow is a
        door motion (`Bang`, `Doors.move`): the door jumps on its rail, the slam's boom quieter,
        a jolt for anyone near, heard by keepers to 70 studs. At 90 s it bursts the door up
        (`Burst`, 0.6 s, loud) and goes after the last thing it heard through its door, or steps
        out to look. Lift it yourself and it's out. A padlock holds it: one last blow at 90 s,
        then quiet; cut, it bursts out. Trapped, it takes no place in the cap (`Keeper.loose`).
        144 trap checks. Verified in Studio on seed 7, floor 1: slammed as 126 got up, 28 blows,
        out 90.25 s later; padlocked, quiet after 90 s and still in at 103 s. Waits on
        `OWNER.md` for feel.
      - [x] **L-06b3d2 The dent.** Done Nov 10 (D-079). Each blow bows the door out toward the
        hall: the server keeps the share of the keeper's time gone on the unit (`DoorDent`, never
        back) and every screen shows one of three baked steps, a fist-sized pocket from the first
        blow (0.34 out), bowed with a fold from 36 s (0.66), buckling 1 stud out, proud of the
        wall, from 68 s. The steps are bowed copies of the ribs they reach (`art/unit/dent.py`,
        `Props.DoorDent_M`/`_S`), swapped into the chain by `RollUpDoor`; a rib goes flat as it
        rolls up behind the header. A trapped keeper now stands 3.4 in, so its reaching arm no
        longer pokes through the door into the hall. 1,540 dent checks. Verified in Studio on
        seed 7, floor 1: steps landed at the first blow, 38.5 s and 68 s, flat-out at the burst;
        the bow reads at Level21 under the hall light (`docs/art/L-06b3d2-*.jpg`). Waits on
        `OWNER.md` for phone size and low graphics.
  - [x] **L-06b4 What you see and hear of it.** Split Nov 9 (owner: the walk reads jerky, which
    makes it less scary).
    - [x] **L-06b4a It moves smoothly on every screen.** Done Nov 9 (D-075). The server sends
      each keeper's motion as a short record on its body's `KeeperMotion` attribute (its feet, the
      way it faces and walks, its pace, how far it walks before it stops, how far it has walked,
      its state, the server's time), only when that changes (`KeeperMotion.due`), at most 12.5 a
      second in one state. Each screen's `KeeperView` carries it on 0.1 s behind the server, so
      turns and stops land exactly, eases late corrections and turns, never walks it past a stop,
      and poses it through Motor6D `Transform` in one of 33 fixed frames (`Pose.frame`); the
      server leaves its joints at rest and moves its root only with a record or every 8 studs.
      253 motion checks (late, jittered, 30 fps). Verified in Studio on seed 7, floor 1: the chase
      drew at its pace (median 14.4, p99 15.4 studs a second, no stalls) and a roam at 7.2; every
      part within 0.0001 studs of `Pose.solve`; 50 records and 50 root moves over the chase and no
      joint writes, where the old body sent 60 root moves and up to 300 joint writes a second.
      Waits on `OWNER.md` for a phone and a second screen.
    - [x] **L-06b4b Its sounds, and the freeze on your screen.** Split Nov 10 into three, a
      session each, in this order:
      - [x] **L-06b4b1 The sting and the chase bed.** Done Nov 10 (D-082). The server tells
        each player's screen how many keepers hunt them, only when that changes
        (`Remotes.Hunted`); their screen alone plays APM's "Rising Fear Hit 1" on a fresh sighting
        (not a glance back within 4 s of a loss, not within 8 s of the last sting) and runs
        "Tension Repeat Drones 39" under the chase, up over 0.8 s, fading over 4 s once none
        hunts you; a catch cuts both (`Chase`, pure, 46 Lune checks; `ChaseMusic`). Verified in
        Studio on seed 7, floor 1 (the sting on the sighting's frame, the rise, the fade, the
        catch's cut, no sound errors). Waits on `OWNER.md` to be judged by ear and on a phone.
      - [x] **L-06b4b2 Its tell.** Done Nov 10 (D-083). Each screen hears the walk it shows: a
        stiff clack of its foot as each step key lands and a hollow knock of its joints as each
        pass lands or it jerks out of its slack pose (`Pose.tell`, each key once), from the body,
        footfalls to 70 studs and knocks to 40; and one deeper knock as a lift (Peek, Open, Lift)
        first takes a door's curtain 0.4 up past the feet of one standing in its unit, asleep or
        watching (`KeeperTell`, `KeeperSounds`; numbers on the row's `tell`). Pro Sound Effects'
        "Wood Drop Light" 4 and 2 and "Knock Slap Plastic" 9 and 7, chosen by measurement. 168
        Lune checks. Verified in Studio on seed 7, floor 1: every footfall on a step pose,
        alternating feet 5.4 studs apart; knocks on the passes; the reveal at 157 and 154 within
        a frame of the curtain clearing their feet; no sound errors. Waits on `OWNER.md` by ear.
      - [x] **L-06b4b3 The freeze on your screen.** Done Nov 10 (D-084). Measured first: the
        server saw your turn up to 0.4 s late (Roblox eases a player's character in), so a hunter
        walked on under your torch and caught you. Now your torch sends its heading with its pitch
        (at once on a big swing or as your screen sees the beam land) and keepers test your beam
        along it; one beam test serves the brain and your screen (`Torch.lights`,
        `Keeper.beamPoint`; your screen's line a raycast). The frame your beam lands on a body
        your screen shows walking, it stops dead there on the key a light freezes it on
        (`KeeperMotion.hold`), never sliding while held; once the server lets it go it makes the
        gap up as it walks, never stepping back; a walk going on from a mid-snap stop holds its
        key (`Pose.along`). 280 motion and 69 torch checks. Verified in Studio on seed 7, floor 1:
        held the frame the beam landed, the server's freeze 0.03 s later and 1.66 studs on; a
        beam through 157's shut door held and froze nothing. Waits on `OWNER.md` (a real network).
  - **L-06b5 The guarded note** (D-072; needs L-06b3d). One note on every floor sits in a
    guarded unit that always holds an awake keeper, so no floor is cleared without a chase, as
    DOORS puts the library's code hints in the room Figure walks (the GDD's floor 5 already does
    it with Dale). The peek is how you find it: a keeper's feet, and whether it stands awake.
    Split Nov 10, one session each:
    - [x] **L-06b5a The guard on the deal.** Done Nov 10 (D-080). `Deal.new` picks the guarded
      unit last from the notes' units (behind an unlocked door wherever a note is, so the peek
      can find it), seeded, so nothing else a seed deals changed; `Deal.odds` deals it a keeper
      awake in every mood and past the cap, standing clear of the note's sight line as every
      keeper does (`DealSpot`), and every other door counts its place among those awake until
      it's dealt. So on floors 1 and 2 every other keeper is dealt asleep until the guard is
      trapped. 379,934 Lune checks over 400 seeds on all ten floors (`tests/guard.spec.luau`).
      Verified in Studio on seed 7, floor 1: Output names Unit 157 guarded; 126 peeked first held
      its Mannequin asleep, 157 awake, guarding its note, 154 after it asleep; opening 157 the
      guard saw me 11 studs off and caught me. A peek doesn't show its feet to a standing eye
      (`docs/art/L-06b5-guard-standing.jpg`), only from low (`-guard-low.jpg`): L-06b5b.
    - [x] **L-06b5b The peek's crouch.** Done Nov 10 (D-081). Tap Peek and your view drops
      over 0.35 s to an eye 1.0 off the floor, just under the foot of gap (Rainbow Six Siege's
      drop to look under a door), so you see the floor under the door to the back wall: a
      keeper's feet and shins. The door's buttons come down with you on your screen to sit 16
      degrees over a level gaze. You stay down while the door holds its peek and you stay within
      a stud of where you knelt; a step, a jump, your Open, Close or Slam, any other move of the
      door, or a climb, crawl or catch taking your body stands you back up with the same ease. A
      friend sees you kneel (the server tags you once it lifts the door; every screen poses your
      joints): on both knees, chest to the floor, forearms out toward the door, head up. A soft
      cloth rustle as you drop and stand, heard close by only. The rule is pure (`Kneel`, 94 Lune
      checks). Verified in Studio on seed 7, floor 1: peeking 157 the guard's legs stand
      mid-stride under the door (`docs/art/L-06b5b-peek-guard.jpg`), peeking 154 the sleeper's
      stand square and slack (`-peek-sleeper.jpg`); a stud's walk, Close, and the door closed by
      the server each stood me up; a copy of my kneeling body knelt as a friend's would
      (`-friend-kneels.jpg`, ambient raised to see it). Waits on `OWNER.md` for two screens and a
      phone.
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
- [x] **L-12 The saw and the hole trap.** Saw a crawl hole into the unit beside you (`Floor`'s
  left and right, D-031); it's loud. Players crawl through, keepers can't. Lead a keeper into a
  unit, crawl out the hole, run round and slam it in: it breaks out after about 90 s unless
  the padlock tool locks it in for the floor (L-06b3d; GDD "The hole trap"). Split Nov 9, one session each (L-12b split again into b1, b2, b3):
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
  - [x] **L-12c The hole trap, end to end.** Done Nov 10 (D-085). Played first: two things broke
    it. Units two along a row passed as neighbours (`CrawlHole.between`), so 155's Saw and Crawl
    buttons for its wall with 153 went to 157 and a crawl from 155 was refused; now each door face
    must stand half its own unit's width from the wall. And the server sees your run late, so a
    Crawl pressed as you reached the hole was silently dropped (it still saw you in the doorway);
    now a press counts where it sees you or where you'll be 0.4 s on (`Crawling.counts`, `Lag`).
    Lost in a unit, the keeper stopped on the wall's own line, half through the hole; now it
    stops 3.4 studs off a unit's walls and turns to where it lost you (`KeeperMap.offWalls`).
    `tests/holetrap.spec.luau` plays the trap through. Verified in Studio on seed 7, floor 1:
    lured the guard from the junction, crawled 155 into 153 (pressed on arrival), it stood in
    155 staring at the hole, and the slam 0.9 s after the crawl trapped it. The first trap of
    each keeper type going in the Catalog waits for the Catalog (Phase 2). Waits on `OWNER.md`.
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
- [ ] **L-14 The other tools.** The GDD's tool table: each a row on L-11's tools (`Tools.Catalog`),
  its art first, built the unit's way. Split Nov 10, one tool a session (split again into art and
  use if it won't fit, as L-12a and L-12b were); each names its hit-game precedent first, and one
  with none goes to `OWNER.md` as an untested bet, never built quietly. The moving blanket and
  glow sticks are cut (owner, Nov 10; the minimap does glow sticks' job), so the bubble wrap is
  the last:
  - [x] **L-14a The air horn.** Lures keepers to a spot, wakes dormant things nearby (GDD). Blown
    where you stand, heard as keepers hear (`Keeper.hear`), so it pulls a keeper to you or sets
    up a trap (with the bubble wrap, or into a unit's mouth for the hole trap). Split Nov 10:
    - [x] **L-14a1 The air horn's art.** Done Nov 10 (D-086): a marine air horn (`art/airhorn/`,
      6,000 triangles, one baked set), a white can with a black band and an orange sound-wave
      mark, an orange trumpet standing up out of a black collar; `Props.Tools.AirHorn` and a
      `Catalog` row (held low on your left, trumpet up; in a friend's fist, mark out; a steel
      slap picking it up, a can's clatter dropping it). Laid in the test hall by the spawn;
      picked up, held and dropped in Studio (desktop size; the phone look waits on `OWNER.md`).
    - [x] **L-14a2 Blowing it.** Done Nov 10 (D-087): Blow (a click, L2, or a round button left
      of a phone's jump button, beside the slots' bar elsewhere) while it's in your hand; a press
      of its own (`ToolUse`, any tool with a `verb`), checked and rate-limited by `Slots`, then
      one blow every 2.5 s (`Horns`). Keepers hear it 130 studs along the halls (`Horn`,
      `Keepers:hearHorn`): the awake come to where you blew it, sleepers in reach wake. Your
      screen plays a stadium horn's blast at once, brings the horn up and kicks your view;
      friends hear it at your horn and see your arm go up. Verified in Studio on seed 7: a
      sleeper in 154 woke 100 studs off and came; a roaming one came 44 studs off, looked, left.
  - [ ] **L-14b Bubble wrap.** Laid across a hall, it pops when anything crosses, heard
    floor-wide (and on the light board, Phase 2); friends pop it too. Split Nov 10, as the horn:
    - [x] **L-14b1 Bubble wrap's art.** Done Nov 10 (D-088). Its precedent is Minecraft's
      tripwire, set off by any mob or player that walks through it. A roll of large-bubble wrap
      on a cardboard core, its loose end taped down, and the sheet it unrolls, curled at its ends
      (`art/bubblewrap/`, one baked set; 1,840 and 768 triangles). The roll is
      `Props.Tools.BubbleWrap` with its `Catalog` row (held low on your left, the taped end up; in
      a friend's fist by its middle along the forearm; a crinkle picking it up, a crackle dropping
      it); the sheet is its own template, `Props.BubbleSheet`. Laid in the test hall beyond the
      horn; picked up, held and dropped in Studio at desktop size (the phone look waits on
      `OWNER.md`). No `verb` yet, so no Lay button does nothing until L-14b2 gives it one. The
      owner judged it Nov 10: looks good, the bubbles a little softer: each now goes gently
      milky toward its edge with a soft glint, no white ring (re-uploaded, the templates' looks
      swapped in Studio).
    - [x] **L-14b2a Laying it.** Done Nov 10 (D-090): `verb = "Lay"` on the row; the press goes
      through HornView's round button (a click, L2, or the phone's button), which now takes
      any tool with a verb (`presses`). The server (`Wraps`) finds the hall you stand in
      (`Wrap.place` over `Wrap.halls` of a floor, or the test hall's own list), spends the roll
      and lays one `Props.BubbleSheet` square across the hall, its near edge at your toes the
      way you face (under your feet at a dead end), tagged and stamped `Laid`. In a unit, on the
      tops, in the lobby or the car your screen says "Lay it in a hall". Every screen
      (`WrapView`) unrolls it from the layer's left in 0.55 s, a roll rolling over the floor
      and thinning to its core, then sinking away, with a crinkle at the sheet; your view
      brings the roll out and down. Verified in Studio: placement on the server, the unroll
      sampled mid-way, Output clean; the press itself untested (the MCP couldn't pick the roll
      up this session, docs/STUDIO.md).
    - [x] **L-14b2b The pops.** Done Nov 10 (D-092): `Wrap.crosses` (Lune-tested) says a foot
      stepping onto a laid sheet, or clean over it in one step, crosses it; stepping off,
      shuffling on it, walking beside it, jumping over it or being moved across the floor
      doesn't. `Wraps` keeps each sheet and, while any lies unpopped, checks every living
      player's feet and every keeper's (`Keepers:feet`) each step; a crossing pops it once,
      stamped `Popped`, and keepers hear it as far as an opened door (`Keepers:hear`, 110
      studs; the horn's `hearHorn` now runs through it, and `Keeper.heardAt` is the pure
      rule). Every screen (`WrapView`) plays a measured burst of pops at the sheet, heard as
      far, squashes its bubbles and dulls its film; under you, your view jolts. Verified in
      Studio with L-14b2c.
    - [x] **L-14b2c Three pops, and every screen hears them.** Done Nov 10 (D-093), from the
      owner's test: the pops were silent on screen because `WrapView` gave up on a sheet that
      reached it before its part; now laid sheets stream `Atomic` and `WrapView` waits for a
      late part. A sheet pops three times (`Wrap.ready`, `Wrap.worn`, Lune-tested), never twice
      within 0.8 s, each pop at its own pitch and a step flatter, greyer and clearer, then lies
      spent. Verified in Studio: lay, four walks across, "1 of 3" to "3 of 3", three sounds
      playing, the sheet worn to 0.3 of its height, 0.35 clear and grey.
    - [ ] **L-14b2d The spent sheet's own look** (waits on `OWNER.md`'s judgement of the
      spent look): a second texture set baked by `art/bubblewrap` (the same atlas, the sheet's
      strip painted as burst bubbles: flat, creased film), swapped onto the sheet's part at its
      third pop. Small; one session.
  - [x] **L-14e The blanket and glow sticks out of the deal** (D-091; owner, Nov 10: "can go").
    They're cut, but `Deal.Tools` and its bag still deal them, and `Deals` lays nothing for a
    tool not built yet, so a door dealt one opens on an empty unit. Take both out of `Deal`'s
    type, list and bag; fix the specs and `scripts/floor-deal` that count on them. It reshuffles
    every seed: the owner said not to worry about old test steps naming units, but L-07d's
    Studio check needs a seed with an awake Mannequin on floor 1 found again. Small; one session.
    Done Nov 10 (D-098): the bag is six built tools, nine to a bag; `tests/carry.spec` now fails
    if the deal ever hands out a tool without its catalog row and Specs. `scripts/floor-deal`
    deals as Studio's floor does (it seeded its own Random before, so it never matched Play) and
    names the guarded note. The guard is now drawn before the bag, so tuning the bag never moves
    it. Seeds keep their layouts, codes, notes, padlocks and every unit's kind; the bag's order
    moved, and the guard on some floors (seed 7: floors 3 to 5; floor 1's stays Unit 157, so
    the owner's steps and the Studio recipes naming it still hold). Verified in Studio on seed
    7, floor 1: 26 units opened (101 to 125, then 157) dealt door for door what the script
    prints, eight tools all laid, no "no art yet"; 157's guard caught me; Output clean (Studio's
    own 203785492 lines aside). Sixty floors (six seeds, floors 1 to 10) deal no blanket or glow
    sticks.
- [x] **L-10 The minimap** (owner, Nov 7: players shouldn't get lost and give up; Nov 10: a small
  corner map, always on, for now, which the owner may later make a map you stop to open, exposed
  while you read it). It fills in only the halls you've walked, as R.E.P.O.'s map fills in rooms
  as you find them; the lobby and elevator always marked, so the sprint for the gate always knows
  the way; units you've opened ticked. Never keepers or lit fixtures: that stays the office light
  board's (GDD), so working the board is still worth a player. Drawn from the same `Floor` data
  as the building (GDD: one tile graph), the drawing kept apart from its frame so a full map
  behind a button is a small change. Phone first: small enough to leave the buttons and the hall
  clear, readable at phone size. Friends show as dots (owner, Nov 10, as Lethal Company's ship
  radar shows the crew), behind one Config switch so they can come off in a line. Moved up to
  straight after the bubble wrap (owner, Nov 10).
  Done Nov 10 (D-094): `Minimap` (pure, Lune-tested), `Minimaps` (the server sends the layout as
  shapes, never the seed, and the opened list), `MinimapView` and `MinimapDrawing` (the window and
  the drawing apart). Verified in Studio at Galaxy A16 size on seed 7, floor 1: the lobby and car
  from the start, two walked halls filled in, unit 103 opened went green and ticked, the gate's
  mark on the edge, clear of the torch and jump buttons; Output clean.
- [ ] **L-07 Getting kept and rescued** (GDD "Getting kept"). Split Nov 10 into four, each its
  own session. Precedents: Dead by Daylight's hook (a teammate frees you, worse the longer you
  wait, everyone sees where you hang) and Flee the Facility's freeze pods (captured, stored, a
  friend lets you out). Stored in a random unit, never the nearest, is the GDD's own twist on the
  hook (`OWNER.md`).
  - [x] **L-07a The wrap and being stored.** The keeper's hands close: a 2-second wrap in the
    dark, what you carried drops where you stood, and you wake in a shut unit away from where you
    were caught (never one a keeper is in), held still, facing the door. Keepers leave you alone
    while you're kept. Until L-07d, the stand-in way out: your unit's door going all the way up.
    Done Nov 10 (D-095): `Kept` (pure, Lune-tested: which unit), `KeptPlayers` (the server:
    drop, hold, store, let out), `Caught.Wrap` (was `Out`), `CaughtView` (the wake inside, "Wait
    for a friend", prompts hidden, the body not turning), every world prompt and Slots' pick-up
    and hand-over refusing a kept player, `Deals:hold`. Replaced DevCorridor's move to the lobby,
    which also ends the keeper by the lobby catching you every 2 s. Verified in Studio on seed 7,
    floor 1: three catches stored me in 153, 124 and 112 facing the door; a carried horn dropped
    where I stood; the door all the way up let me out and I walked out; one catch each, Output
    clean.
  - [x] **L-07b The wrap you can see and hear.** The shrink-wrapped body friends find when they
    open your unit, built in Blender the unit's way (art first, owner Nov 10): clear stretch film
    in bands round a standing body, scaled to the kept character, hidden on its own screen. The
    film's squeal as the wrap goes on, heard by you in the black and by anyone near.
    Done Nov 10 (D-096): `art/keptwrap` (a cocoon round the default R15 body, a spiral of
    overlapping bands, edge cords, the twist on top, alpha in its colour map; 4,440 triangles),
    `Props.KeptWrap`, pure `Kept.fit` (Lune-tested: any body held whole, clamped), `KeptPlayers`
    fits and welds it at the move and takes it off as you're let out, `CaughtView` never draws
    your own, `KeptSqueal` (a tape's screeching peel on every screen from the `Kept` attribute).
    Verified in Studio on seed 7, floor 1: caught by 157's Mannequin twice (kept in 145, then
    109); the film on, 4.13 x 5.52 x 1.81, welded, no collision or shadow; a capture from 109's
    open door with the ambient raised shows a cloudy cocoon, the body blurred inside; your own
    view clear; the squeal on the catch's frame; opening 109 let me out in 2.04 s with the film
    gone. Output clean but for Roblox still processing the fresh upload.
  - [x] **L-07c Banging.** A Bang button inside: each bang thuds on your door for everyone near,
    shows your unit on friends' screens and the corner map, and keepers hear it
    (`Keepers:hear`). The hall light under the door. Decide whether being wrapped puts your
    torch out (it still works and lights the unit, L-07a).
    Done Nov 10 (D-097): pure `Kept.ready`, `mark`, `encodeBangs`/`decodeBangs` (Lune-tested);
    `Remotes.Bang` in `KeptPlayers` (kept and inside, then the rate) bangs through
    `Doors:move`, so keepers hear it as a trapped keeper's blow, and marks the floor's model;
    `CaughtView`'s Bang button in place of "Wait for a friend"; `BangMarks` (a blue mark with
    the name over the door, through walls); `MinimapView` (a banging unit's dot, kept friends'
    dots hidden); `UnderDoor` (the hall light's warm line under the door). The torch stays on
    (`OWNER.md` asks). Verified in Studio on seed 7, floor 1: kept in 120 and 118; Space bangs
    no faster than 0.6 s with one press held; 362 remote presses in 3 s landed 8; the Mannequin
    heard a bang 54 studs off along the halls and came to the door; the line under the door lit
    with the hall light and went with it; let out, the mark cleared. Studio's captures draw no
    billboards, so the mark over the door is untested by eye.
  - [x] **L-07d Cut free.** A friend at your open door holds Cut free one second and you stand
    up; it replaces L-07a's stand-in way out.
    Done Nov 10 (D-099): pure `Kept.cut` (who may cut: not yourself, not kept, alive, you inside
    with your door all the way up, a full hold on the server's clock, between the unit's walls
    from a stride into the hall, within reach; Lune-tested), `Kept.tearPose` (the film's slump
    over a beat) and `Kept.pull`, `Kept.widen`; `KeptPlayers`' Cut free button on the film in
    front of the chest, shown only with the door up, its hold strained onto the wrap and its
    trigger judged, a cut tearing the wrap off where you stood; `CutFreeView` (the strain, the
    rip, strips of film flung at the cutter, the slump to a heap round the ankles, its crunch,
    the kicks and the freed player's view widening); `CaughtView`'s Bang button fades out. The
    door going up no longer lets you out. Verified in Studio on seed 7, floor 1, alone, with a
    stand-in friend (`ServerStorage.CutFreeTest`, docs/STUDIO.md): kept four times; the button
    off with the door down, on with it up; my own trigger refused (Self), the stand-in refused
    too short, down, across the hall, through the side and back walls and from the tops; from
    the doorway its cut tore the film off: rip, shreds, heap by 0.6 s, gone by 2.2 s, my view
    widened to 77 degrees and back, Bang faded, walk back; Output clean. At Galaxy A16 size Cut
    free and the door's Close and Slam never overlap (197 px apart at the closest). A real
    friend's hold and the sounds by ear are the owner's (`OWNER.md`).
  - [x] **L-07e The padlock.** Left a few minutes, the building padlocks your unit; only bolt
    cutters let you out. A warning comes first (the padlock's sound on your door, a short line
    for you and for friends) so everyone feels the clock run out.
    Done Nov 10 (D-100): pure `Kept.clock`, `counts`, `lockable`, `tick`, `seconds` and
    `handlings` (Lune-tested): 150 s of your door being down (shut, open a crack or coming down;
    never going up or up), the warning its last 20 s; run out, the padlock goes on once the door
    is down and still. `KeptPlayers` steps each keep's clock, sets `Kept.WarnAttribute` (when it
    goes on) on the kept player through the warning, then `Doors:lock(unit, true)` and
    `Kept.PadlockedAttribute`, cleared as the padlock's cut off; one padlock a keep; a padlock on
    stays on the empty unit; Workspace's `DevPadlockSeconds` gives Studio a short clock.
    `PadlockView` (new): Pro Sound Effects' "Keys In Padlock" worked at the hall side of the
    door five times, closer and louder to the end, then every 3 s while the door's held up a
    crack; "Padlock in 20" high on the kept screen beating each second, red for the last five;
    "Sam: padlock in 12" under the top bar on friends' screens; at the click a jolt, APM's "Evil
    Mind 9" (quieter for friends, wherever they are) and "Padlocked" slamming in. Verified in
    Studio on seed 7, floor 1, alone, with a 30 s clock (keeps in 123, 111 and 119): the
    countdown, the pause with the door up (4.72 s left both ways), the padlock on the second and
    the door's Padlocked, Cut free off until the padlock was cut and the door up, a stand-in's
    cut; the five handlings and two more while the door stayed up a crack past 0, padlocked 0.25 s
    after it closed; the padlock left on after dying; a cut before the warning ended the clock.
    Friends' lines with a real second player and the sounds by ear are the owner's (`OWNER.md`).
- [x] **L-06c Scarier keepers** (owner, Nov 10: make the walk and the catch scarier, "nothing
  gorey but leaning more toward jump scare"). Done Nov 11 in two sessions: the walk limps and
  sounds heavy (L-06c1); the catch is a jump scare (L-06c2), no longer a jerk of the view, the
  screen going black and "Caught" (L-06b3c).
  - [x] **L-06c1 A walk that frightens. Done Nov 10 (D-101).** The light wooden clack and the
    plastic knocks are gone. It limps now: a stiff left leg it drags round on its toe, its steps
    uneven (a short heavy plant, a long slow drag, a short stiff heel, a silent swing through), the
    plant held long and then a jerk, and its head lolling hard to one side and landing a beat after
    its body (Silent Hill's mannequins, Doors' Figure). Each beat is layered recordings, measured
    for a phone's speaker: a hollow fibreglass thunk that carries 70 studs, and under it a body's
    weight that only comes in as it nears (full within 10 studs, a tenth by 40, and higher pitched
    far off), so the steps get heavier as it comes (Five Nights at Freddy's); a rock-on-concrete
    scrape for the drag (SCP-173); a rubber creak when it turns 40 degrees or jerks out of its shop
    pose; a deep thunk and a creak as a lifted door shows its feet. Standing still or held in light
    it's silent. Verified in Studio on seed 7, floor 1: 157's guard walked out and roamed while I
    watched from above, every beat logged at the body with its distance (the weight 0.88 at 12.6
    studs, 0.61 at 22, 0.36 at 29, 0.09 at 46, none past 50; the thunk heard to 63), the limp's
    rhythm 0.27, 0.47 and 0.73 s, silence through its 5 s looks, a creak on a corner; the poses
    captured on lit copies (`docs/art/L-06c1-gait-front.jpg`, `-side.jpg`). By ear and on a phone
    is the owner's (`OWNER.md`). Not built: the dead-still-then-rush (a change to the server's
    motion; polish list below).
  - [x] **L-06c2 The catch as a jump scare.** The moment: its blank face fills your screen with a
    hit of sound, then the black (Piggy's and Five Nights at Freddy's catches: the face rushes
    the camera with a scream, no blood; overrides the GDD's "no screamer" line, owner Nov 10).
    Done Nov 11 (D-102): the hall goes silent and the HUD goes, your view is wrenched to its face
    and holds there (0.48 s), its head twitches back and rushes your eye as the view crash-zooms,
    a scream, "Razormorph K" and a whoosh on the rush's first frame with its own groan and scrape,
    its hollow thunk and the hardest kick and a knock as it lands taller than your screen, pressed
    in, cut to black at 0.96 s; "Caught" in the black over your own film's squeal; a slow wake
    (eyes crack open, drop shut, open; blurred and grey; the hall's sound back). Friends see the
    film wind up you as you turn once round (`Kept.wind`, KeptWrapOn; the server wraps you at the
    catch now). `CaughtLunge`, `Caught`'s curves (712 Lune checks), `Pose.Poses.Lunge`, the row's
    Lunge and Catch beats. Verified in Studio on seed 7, floor 1, caught by 157's guard three
    times: frames held with `DevCatchHold` and captured (the dread, the rush, the landing, the
    press, the black, the wake), the sting's layers measured playing on the caught screen as the
    rush starts and the thunk as it lands, a real-time run logged frame by frame, a stand-in
    friend's wind captured mid-turn and settling; Output clean. A second client's view and the
    sound by ear on a phone wait on `OWNER.md`.
- [ ] **L-08 The ride and the next floor.** The elevator ride and a second floor, so the climb is
  a loop and not a single room. Brix: its round loop (ENG-13) if it has landed (not yet, checked
  Nov 10). Takes the GDD's "Left behind" (the gate shuts with you still kept or outside: you
  spectate, or Cut Free to the next floor) and "Whole team kept" (the climb ends, the Missing
  board), moved from L-07. Split Nov 10 into five, each its own session:
  - [x] **L-08a The ride. Done Nov 11** (D-103). The gate shuts, the car climbs one floor and
    its gate opens on the next hall, as Dandy's World's elevator carries the team between
    floors: on the server's clock (`Ride.Attribute`, `arrived`), 9.6 s to level, the gate
    folding at 10.3 s. The car never moves: riders' screens slide a sleeve of shaft down past the
    gate (the hall going black as the brakes let go, a header, lamp-lit concrete with the next
    floor's number painted on it, the next landing's sill, its black mouth lifting off the hall),
    the sway held on the camera (lurch, weight, two clanks, the bob as it levels; Lune-held to
    0.012 studs and 0.05° a frame), the lamp dipping, an amber floor readout over the gate inside
    and the clock's plate both ticking over as the brakes bite, and the brakes, the clanky motor,
    the clanks, a relay's click, the winding-down and the bell, measured. The stand-in fade and
    teleport are gone: the car arrives back at the same lobby one floor higher and is armed again
    6 s after its gate opens. Verified in Studio on seed 7, floor 1: punched 1097 and rode 1 to 2
    and 2 to 3; a real-time ride logged frame by frame (the shaft sliding 16 studs, the lamp at
    0.33 as the brakes let go, every sound on its cue, volumes following the speed); frames held
    with `DevRideHold` and captured (`docs/art/L-08a-*.jpg`: the readout at rest, the hall gone
    dark, the shaft mid-climb, the painted 2, the tick to 2, the dark lifting at the top, the
    gate open on 3); left in the lobby, no shaft or ride sound played there; Output clean. By
    ear, on a phone and with friends: `OWNER.md`.
  - [x] **L-08b The next floor. Done Nov 11** (D-104). The gate opens on a floor nobody has
    seen and the one below is gone, as each of Dandy's World's elevator stops opens on a new
    floor. `Climbs` (server; pure numbers in `Climb`) runs the climb: each floor dealt from its
    own seed (one seed for all laid floor 2 as floor 1 again) with `Deal`'s harder odds, laid
    1000 studs on from the last so a phone never streams two, put in every floor system and
    armed; the next floor laid as the right code opens the gate. Mid-ride the new car takes the
    ride over (`Elevators:takeOver`), riders' screens lay a second shaft outside it, and on the
    cable's second knock (6.1 s) every rider is moved to the same spot in it and the floor below
    is cleared in that frame, its lying tools with it (`Slots:clear`, after a stood ladder has
    fallen flat as its unit goes; the ladder untested);
    whoever's left there goes to the spawn. An empty car comes back and re-arms. FloorBuilder now
    adds each unit to its placed hall piece as it's dressed (a floor laid during play had held
    the server 160 ms in one frame; now 5 to 9 ms). Verified in Studio on seeds 7 and 23: floor 1
    to 2 to 3 three times, floor 2 played (its notes found in 237 and 249, its guard woken in 224
    and caught by it, its code punched), floor 1 gone (server instances 13,355 to 7,385), a frame
    log across the hand-off (the view moved 0.006 to 0.008 studs and didn't turn on the switch
    frame; no frame without a shaft), frames held either side of the move and captured
    (`docs/art/L-08b-*.jpg`), the empty car re-armed and the waiting floor 3 used next time, a
    dealt saw cleared with floor 1; Output clean but the known asset line. A phone's frame at the
    move and two players: `OWNER.md`.
  - [x] **L-08c Left behind. Done Nov 11** (D-105). Whoever the gate shuts on, kept or still
    outside, watches their friends go on, as Lethal Company's dead crew watch the living. As the
    car leaves with someone aboard, everyone else on the floor is out of the climb (`Watching`,
    `Left`): "Left behind" slams up in cold red with the gate's clang, the screen's top and
    bottom darken over the HUD, the lamp draws away up the shaft while the motor groans and fades
    above, muffled; as the light goes a low hit lands and your legs give up; the black comes down
    before the floor is cleared under you; the bell rings far above in the dark, and the black
    lifts on a friend's shoulder as their car levels and the gate opens without you. Your
    character goes (nothing can hurt or see you) and the server streams the world round your
    friend; the camera follows over their shoulder, smoothed, pulled in off walls, swung by a
    drag; a bar says who, "Back in when they finish", and switches friend with a tick and a dip
    (Q/E, the arrows, the bumpers). Cut Free (the GDD's revive) lets you back in on your friends'
    floor in front of the car, with the rip and "Back in": Studio only until the product exists
    (`OWNER.md`); nobody left to watch lets everyone back in (L-08d's to replace). GateClock's
    "Left behind" headline moved here. Verified in Studio on seed 7 with two stand-in friends in
    the car: three rides, the sting held and in real time (its log on its timeline), the camera
    0.003 studs a frame at most, switching, Cut Free, a friend removed and both removed; Output
    clean but the known asset line (`docs/art/L-08c-*.jpg`). Two players and a phone:
    `OWNER.md`. Untested: left behind while kept in a unit (the same path), and watching a friend
    as they ride again.
  - [x] **L-08d The climb ends. Done Nov 11** (D-106). Nobody left climbing (all kept or
    watching) ends it as a loss, the car leaving the top with friends aboard as an escape (the
    top a stand-in, floor 3, `OWNER.md`); one screen on everyone's, then "Again", as DOORS' Play
    Again (`ClimbEnd`, `ClimbEnds`, `EndView`). A wipe: the black over the last catch, the world
    gone quiet, two doors far off in the building, "Kept" slamming down with a low hit and a
    jolt, the photos dropping in greyed and askew with the floor each was lost on (the Missing
    board in small), "Floor 2 · 6:42", the warm button. The top: the ride untouched to the
    cable's second knock, then the light floods in, the motor gone, the bell clear in the white,
    "Made it" in the lamp's light. The climb is cleared under the screen (floors, lying tools,
    watchers, every character). "Again": "Waiting", each friend's photo warming with a tick,
    "Going up in 10" from the first press, the chime, a fresh floor 1 with everyone side by side
    in its lobby, the black lifting with the bell and "Floor 1" (`ClimbEnds.go`, for the owner's
    lobby to replace). Watching's "Alone" let-in is gone. Verified in Studio on seed 7: a real
    catch, the top ridden alone, left behind with stand-ins then removed; Again by mouse and
    Enter; a clean new character each time; Output clean but the known asset lines
    (`docs/art/L-08d-*.jpg`). Two players and a phone: `OWNER.md`.
  - [ ] **L-08e The lobby** (the owner's plan, Nov 11, D-112; GDD "The lobby"). Everkeep's
    front office at night, whose one job is getting friends into an elevator fast, as DOORS'
    lobby elevators do. Until it lands the test hall is the way in on live servers too (D-109);
    the lobby replaces it there, and the test hall goes back to Studio only, before the game goes
    public. Your own lobby unit, the daily door and the store are Phase 2.
    - [ ] **L-08e1 The front office and the elevators.** The moment: you spawn facing six
      freight cars, step through a gate with your friends, and the gate slams on the count. The
      room built the unit's way (`art/`): front door, cart rack, the counter (dressing for now),
      six cars that reuse the climb's car and gate. Step in to join; the first in hosts (Open or
      Friends only, 1 to 6, the difficulty); 20 s from the first step in, 5 s once full, Go at
      any time; at zero the climb's own gate slam. The car takes its group to a server of their
      own: ENG-13, or the stand-in `docs/FRAMEWORK.md` plans while it's unbuilt. A new player is
      in a car within 15 s. No longer waits on L-09a (owner, Nov 11 night). Three sessions, each
      ending green:
      - [x] **L-08e1a The front office, built. Done Nov 12** (D-119): `art/lobby/` (spec, build,
        README, six look sheets) builds the room wearing the unit's baked sets and the corridor's
        deck, joists and walls: 120 by 48, six bays for the climb's own landing along the back
        wall, the glass front and double door, the counter and shelves, the empty cart rack, a
        striped zone before each car. Asset 80376262399856, template `Props.Lobby` (saved);
        `src/shared/Lobby` lays it (paint, numbers, boxes on the shelves, glowing hall lights,
        two fills, a porch light, the climb's car in each bay, untagged) and the server's
        `FrontOffice` lays it at `Lobby.Origin` (0, 0, 600). The test hall's "Go to the lobby"
        post (R) and "Come back" by the lobby's door. Verified in Studio on a computer and the
        Galaxy A16 (`docs/art/L-08e1a-*.jpg`); a real phone's lights are the owner's.
        **For L-08e1b1:** the cars' keypads still stand beside them (use or hide them); a teleport
        keeps the camera's old look, so on load turn the camera to the cars.
      - [x] **L-08e1b1 Step in and the count. Done Nov 12** (D-120): the lobby's cars are the
        climb's elevators, tagged and marked with their bay; `LobbyCars` gives each a Brix zone
        (step in to join, out for 0.35 s to leave), runs the count on the climb's gate clock (20 s,
        5 once six are aboard, never back up; `Boarding`, 42 Lune checks), lays floor 1 out of
        play as a count starts (`Climbs:ready`), and at zero the climb's slam and ride carry the
        group up: floor 1's car takes the ride mid-cruise (`Climbs:board`, the hand-off shared
        with every floor) and opens on a fresh building. The count shows on screen only to the
        group (chime as you step in) and on the car's keypad readout for the room (dashes at rest,
        green, red from the warning); the keypad's prompt is gone; the car's floor readout and
        the ride's counter say L. The car is back in its bay 12 s after it left. One climb a
        server: other cars' counts wait while it runs. You load in at `LobbySpawn` facing the
        cars and the camera turns to them (`LobbyView`); the test hall is Studio only. Verified in
        Studio on a computer, one player (`docs/art/L-08e1b1-*.jpg`); friends and a phone are the
        owner's. **For L-08e1b2:** the keypad stays as the car's panel; its prompt is the place
        for the host's choices (KeypadPad skips lobby cars today). Go at any time can be
        `Elevators:count(car, now)`.
      - [x] **L-08e1b2 The host's panel. Done Nov 12** (D-121): the first one in hosts, as DOORS'
        lobby elevators: a "Host" button inside the car on the keypad's side (the keypad faces the
        room), reaching the whole car, opens `CarPanel`, right of centre: Open / Friends, the
        player count between - and + over six seats (aboard, room, none), the difficulty (Normal,
        the only one), Go. Others aboard get "View" and the same panel greyed. One remote
        (`Remotes.CarPanel`), checked types, range (the host), rate, then `Boarding`'s rules
        (never fewer players than aboard; not once shutting); the choices replicate on the car
        (`FriendsOnly`, `Players`); Go runs the count out now; filling the host's count cuts it
        to 5. A stranger the choices close the car to (full, or not the host's friend:
        `IsFriendsWith` asked once as they step in, kept) is set down outside with "Car full" or
        "Friends only". The host steps out: the next one hosts, choices kept; empty: Open and 6.
        Lune: 83 checks. Verified in Studio on a computer, one player (`docs/art/L-08e1b2-*.jpg`);
        two players and a phone are the owner's. **For L-08e1c:** the difficulty goes with the
        group (`Boarding.Difficulties`, one today); a held count ends with servers of their own.
      - [x] **L-08e1c A server of the group's own. Done Nov 12 (D-122).** Brix has nothing for
        it (ENG-13 unbuilt), so a stand-in, `Trips`: at the post the riders' screens fade to black
        ("Going up") as the car gathers speed, and 2.2 s in they're sent in one `TeleportAsync`
        to a new reserved server (`TeleportOptions.ReservedServerId`, a fresh GUID; the old
        `ReserveServer` is deprecated), the group and difficulty as its data (`Trip`, checked on
        arrival: it passes through each device). Failures worth it are tried again to the same
        server (3 tries); a rider still here 15 s on has failed. A failed trip puts them back in
        their car, host first, choices as they were, "Teleport failed" and the count again; two
        failed trips in a row and that lobby rides its groups up on its own server (as before).
        The group's server (`PrivateServerId` set, no owner) lays floor 1 at once, waits for the
        group (or 10 s after the first), streams floor 1's car to them and stands them in it 3.4 s
        into its ride (`Elevators:ride`, `Climbs:arrive`): the black lifts on the shaft sliding
        past, the car levels and opens on floor 1. Late or respawned: stood in front of the car.
        No lobby cars there. Studio rides on its own server as before; `DevTrip` on Workspace
        tries the rest: "Arrive", "Send" (Studio's test teleports, which open the place as last
        saved) and "Fail". Verified in Studio, one player: the ride here; the arrival; the whole
        trip through a test teleport; two failed trips, then the ride here. Lune: 73 checks.
        Live servers, friends and a phone are the owner's. A new player stands facing the cars a
        few steps from them as they load in (L-08e1a), so in a car within 15 s; L-08e3 points a
        lone player to the fullest. **For L-08e2:** the climb's end on a group's own server is
        still ClimbEnds' "Again" into a fresh floor 1 there: "back in your car" happens on that
        server (its front office is laid, its cars not opened: open the group's car, or send them
        back to a lobby; the GDD says the same car with the same friends).
    - [x] **L-08e2 Back in your car. Done Nov 12 (D-123).** The moment: the climb ends and you're
      standing in the same car with the same friends, results on the wall, the count running for
      another go. Again (the end's one button, D-106) now leads there: the climb's group gets
      characters in the car they left from, in their old order with the host's choices, facing
      its back wall (`Boarding.back`, `backSpot`), the car streamed in first; the results board
      goes up (CarResults: "Kept"/"Made it", floor and time, each friend's photo and floor) and
      the full 20 s count runs; the black lifts with the count's chime, the camera turned to
      where the server stood you. Anyone can step out and back in; the board goes as the car
      leaves. On a group's own server the trip's data (`Trip.Version` 2) names the car, its cars
      open only once the group is home (`Trips:home`), and their next climb rides up on that
      server. The test hall's climb still goes to a fresh floor 1. Verified in Studio, one
      player, on Studio's own server and a group's own ("Arrive"); place saved as version 35.
      Lune: trip 91, boarding 124, climbend 2944 checks. Friends, live servers and a phone are
      the owner's (`OWNER.md`).
    - [x] **L-08e3 Invite and the dials. Done Nov 12 (D-124).** The moment: a friend's not here,
      so you tap Invite on the car's panel and Roblox's sheet of your friends comes up ("Ride up
      with us"); from the door every car tells you who's in it, and a player in no car is pointed
      to the fullest that will take them. Invite sits beside Go for anyone aboard (Roblox's
      `PromptGameInvite`, its launch data naming you; hidden where Roblox says you can't invite
      and on a group's own server, which a friend can't follow you to yet). A friend who joins by
      it is marked with who invited them (LobbyCars) and pointed to that car first. A dial over
      each gate (CarDial) keeps the bay's number with three round seats either side: photos in
      warm rings as people step in (they pop in), dark sockets for room, faint past the host's
      count; one line under the number: "Friends only", "Full", "Going up", or "Floor N" in the
      readout's green while the group it took climbs on this server (`Boarding.FloorAttribute`).
      The pointer (`Boarding.fullest`): the dial's rim glows warm and breathes, the seat you'd
      take with it, and a chevron bobs in its doorway; gone once you step in. Verified in Studio,
      one player (others faked on the cars from the client): the dials from the door and close,
      a seat filling, "Floor 1" over car 3 while its climb ran, the pointer onto the fullest car
      and off as you step in, the panel's Invite opening Roblox's invite sheet (none sent), the
      key gone on a group's own server. Lune: boarding 137 checks. Live invites, friends and a
      phone are the owner's (`OWNER.md`).
    - [x] **L-08e3b Share and follow. Built Nov 13 (D-130); the panel verified in Studio Play**
      (Invite, Share and Go across its bottom; Share reaches the server, which asks Roblox for the
      link and Studio answers HTTP 403, as it does off a live server; the rest is `OWNER.md`'s). Three pieces the invite still lacked. (1) A share link
      (`SocialService:PromptLinkSharingAsync`, server only: an expiring link to the experience
      with launch data, Roblox's share sheet or the clipboard): Audience Expansion pays 35% of
      a new or returning player's first $100 when they come by the experience's share link, and
      an invite to a friend already on Roblox isn't that; where it sits waits on the owner
      (`OWNER.md`). (2) Invite from a group's own server: the launch data names that server
      (`Trip` data carries its id), and the public lobby a friend lands in sends them on to it
      (`TeleportAsync` with the same `ReservedServerId`), standing them at the front office
      there. (3) The dial's floor for a climb on another server: the group's server tells its
      lobby (MessagingService, the lobby's JobId in the trip's data) and the car's dial says
      "Floor N" until they're back.
    - [ ] **L-08e3c Invite before you leave, and joining mid-climb** (found building L-08e3b;
      waits on `OWNER.md`). Invite is on the car's panel, so a friend can only be sent on to a
      group's own server once the group's home. (1) An invite from a car on a public lobby names
      the server that car will send its group to (made as the group forms); a friend who lands
      where their inviter isn't is sent on to it. (2) Arriving mid-climb, they're stood beside
      the group on its floor (Trips' late-arrival path, built). Whether a friend may join a climb
      under way is the owner's call: DOORS doesn't let you join a run under way.
    - [ ] **L-08e4 The cart ride** (owner: "definitely"). The moment: you kick a platform cart
      across the lobby while the count runs and roll up to the gate as it shuts. Its own model,
      built the unit's way. Tap Ride; hold forward and your back leg kicks on its own in rhythm
      (no tapping); let go to coast; Jump to hop off. Carts bump and stop, never launch anyone;
      at a gate you hop off and the cart rolls back to its rack; one rider each; the rider's
      client moves it and the server caps its speed. As R.E.P.O.'s rideable vehicles and
      Roblox's classic skateboard. Cart cosmetics wait for the store. In three sessions (split Nov
      12, each ends green):
      - [x] **L-08e4a The cart, built the unit's way. Done Nov 12 (D-125).** `art/cart/`: a
        safety-orange steel platform cart (a 2.2 by 4.3 deck, a ribbed rubber mat, a U handle
        with a foam grip, rubber bumpers, 6-inch casters), seven parts so the ride can move them
        (the body, two swivel forks, four wheels), baked on one 1024 set, the FBX, `Cart.Specs`,
        five look sheets. In the place at `ReplicatedStorage.Props.Cart`; `Lobby.lay` parks one
        nose-in at each of the six slots, each a little off square, its front casters turned
        every which way. Verified in Studio Play from the spawn and up close
        (`docs/art/L-08e4a-*.jpg`); Output clean.
      - [ ] **L-08e4b The ride**, the GDD's cart ride on the carts L-08e4a parks, in two
        sessions (split Nov 12):
        - [x] **L-08e4b1 Ride, kick and coast. Done Nov 12 (D-126).** Tap Ride and you stand on
          the deck facing the handle, your view swinging round; push and it heads where you
          look, your back leg kicking in rhythm (`Cart.Ride`, Lune specs); let go to coast, push
          back to drag your foot; it turns about its fixed casters. Head on into a wall, a cart
          or a friend: a clank and a dead stop, at a slant a scrape and slide, never a launch.
          Jump hops you off (the cart rolls on, then the server parks it where it stopped); ride
          onto a car's stripes and you hop off there. Your screen rolls it (`CartRide`), the
          server watches its pace and keeps it in the room (`Carts`); every screen spins the
          wheels, swings the casters, rattles with speed and stands the rider (`CartView`).
          Verified in Studio Play: out of the rack, a curve, five kicks to 21 a second, a clank
          at the wall, a turn off it, Jump, the coast and the park, the band's hop-off.
        - [x] **L-08e4b2 Home again. Done Nov 13 (D-129); verified in Studio Play Nov 13**
          (session 119, one player; below). A cart you hop off at a car's stripes rolls
          home by itself 1.2 s after it parks, one left anywhere else after 20 s: nose first to
          the nearest free slot, a curve to line up and the last 6 studs straight in between the
          hoops, swinging round on the spot first if it faces away (`Cart.Home`, Lune specs). The
          server sends the way and a run stamped with its clock once; every screen rolls the
          cart (CartView), rattling, its casters flipping to trail, a soft clunk into the rack.
          Anyone or any cart just ahead: it brakes, waits, rolls on; held 12 s, or no way clear
          of walls and parked carts, it's put in its slot. No Ride on the way home. Two riders
          at once (`OWNER.md`). Verified in Studio Play from the server's and the screen's logs:
          four rides onto the stripes, each cart off about 1.2 s after its rider was put off and
          nosed into its slot about 7 s later, easing in; one left mid-room went home 20 s after
          it parked (a 57-stud way); stood 7 studs ahead of it, it braked to a stop about 2.4
          studs short and rolled on 0.75 s after you stepped aside; no "no way home" line. Fixed
          there: the look ahead for anyone in the way covered the cart's own deck, so a rider
          put off at the stripes who stood still held it 12 s, then it popped into its slot
          (`Carts`: only the strip its nose rolls into counts now). Not seen: the swing on the
          spot (no cart was left facing away), its sounds, two riders (`OWNER.md`).
- [x] **L-15 Keepers hear the rest. Done Nov 11 (D-107).** The keypad, a dropped tool, the saw, a
  crawl, the ladder and a drop off or into a unit each reach a keeper as far as players hear them,
  as Lethal Company's Eyeless Dogs come to any noise. A sound on a unit's top carries out over its
  front; one behind a shut door gets out muffled (half), and the keeper comes to stand outside it.
  A new sound stops it dead for 0.8 s, turned to it, with a Heard beat on every screen (a deep
  thunk far off, the groan up close). Output says only news; a trapped keeper prints once; a
  crawler's feet read on what they lie on. Verified in Studio: the keypad (a beep unheard at 60, the
  alarm heard at 69), a tool dropped (unheard past 40, heard at 26), the ladder going up (heard at
  29), the Heard beat on screen. The saw, a crawl and a drop-in passed Lune only (`OWNER.md`).
- [ ] **L-16 The fix pass before friends play.** The bugs friends would meet first, in two
  sessions:
  - [x] **L-16a In hand and caught. Done Nov 11 (D-108).** A friend's torch arm rises: one
    client `Joints` module finds and turns either kind of avatar joint for every view that poses
    a body. Caught crawling or on the ladder, the climb or crawl ends on the server and your
    screen lets go of your body at once; the catch hands back your own camera. G at an open door
    slams and keeps your tool; a click on a button on screen is never a use. Every recording is
    primed (the doors, the lights, the peek). KeeperView waits for a body still arriving; the
    server builds a keeper whole before it goes in. 203785492 traced to Studio (not the game).
    Verified in Studio: your own arm raised through `Joints`; caught on the ladder and mid-crawl
    (Studio-only `CatchTest`), kept, cut free, walking; Slam over Drop; a slot click blowing
    nothing. A friend's arm and the first slam's timing go to `OWNER.md`.
  - [x] **L-16b The tops and arriving. Done Nov 11**, in two sessions (split Nov 11: each item
    needs its own Studio check):
    - [x] **L-16b1 The tops. Done Nov 11 (D-111).** Lying behind a sawn hole, Climb down and
      Drop down are ignored: their slide to the edge would take your body over it (no words: the
      hole is in plain sight, owner). A landing's crouch bends your knees so your feet stay on the
      floor (`Tops.crouch`), off a front and in through a hole; they sank 0.63 into it. Lying at a
      front's edge you're 7 studs from the door's buttons below: they're hidden on your screen
      (`ButtonReach`) and the server ignores them. The ladder's foot is 12 studs off and the
      server already ignored a climber's Climb, Take and Lean. Verified in Studio: the crouch on
      the default avatar; in L-16b2, the door's buttons hidden up top (a padlock in hand too) and
      back once down, and Climb down and Drop down ignored behind a hole while the same press from
      a clear spot went. A friend's landing goes to `OWNER.md`.
    - [x] **L-16b2 A press on arrival counts. Done Nov 11 (D-113).** Sprint at the ladder and
      press Climb, or into a unit and press Saw at its wall, and it works first time. Measured in
      Studio first: the server saw a full run 3.5 to 4.3 studs late, so Climb (pressed 5.8 from the
      foot, seen 9.2 off) and Saw (pressed just inside, seen out in the hall) were dropped without
      a word; Lean only just landed on its slack. Now one pure helper, `Arrival` (Lune first),
      judges a press where the server sees you and at moments out to 0.4 s on at the speed it
      sees you moving, for every reach in `Ladders` (crawlers by the crawl check's own speed), the
      hole check and Drop in, `Saws` (every frame of a cut too, so it isn't dropped as the server
      catches up) and a door's reach and side (sprint out under a closing door and Lock it).
      `Crawling.counts` uses it. Found and fixed on the way: `ButtonReach` kept its buttons in
      weak tables, which Roblox empties while the buttons still exist, so every door button
      stayed hidden after climbing down off the tops. Verified in Studio: Climb, Saw (the hole
      went through, the server having seen you in the hall at the press) and Lean on arrival.
      Live servers and two players go to `OWNER.md`.
  - [x] **L-16c Crawling the tops feels right. Done Nov 11 (D-110).** Owner, Nov 10 night: "super
    glitchy and the camera shakes a ton"; Nov 11: "the view jerks all around repeatedly... It
    should be just as smooth as moving on the normal floor." Causes found by recording every
    frame in Studio: your view sits 1.5 studs up your body, so the body turning after your mouse
    (200° a second) swung it sideways at up to 5 studs a second; you all but stopped until the
    body faced the way you pushed; each pull surged your speed ±55%. Now your body turns about
    your eye (`Tops.Eye`), you move where you push at once as a walk does, the surge is ±10% and
    the head's dip and sway halved; the server allows for the hips' swing. Not causes: the map
    and hole checks (hundredths of a millisecond), physics (the body is one assembly), the
    server's put-backs (none in Studio). Verified in Studio: a quarter turn mid-crawl moved the
    eye 0.4 studs sideways in all (the sway), eye speed 4 to 5 studs a second. A live server and
    a phone go to `OWNER.md`.
  - [x] **L-16d The tops still jitter on a computer.** Done Nov 12 (D-118). Owner, Nov 11 night:
    "still janky on my computer... it still jitters a lot". Measured: physics steps 60 times a
    second whatever the screen draws, and your body moved only with it, so a screen at 120 or 144
    held a place two or three frames, then jumped. Now LadderView places your body each drawn
    frame just before the camera ("LadderViewPlace"), up the ladder, along the tops and down,
    holding it still through physics; the crawl over a frame is `Tops.advance` (steps of at most
    a sixtieth, a hitch capped at a quarter second; Lune-checked at 15 to 240 frames a second).
    Verified in Studio at 15 frames a second (it can't be focused from a script): every frame
    moves its share, the eye holds one height lying still, no server put-backs flat out with no
    lag, simulated 4G or bad 3G; the Galaxy A16 the same. The full rate and a live server:
    `OWNER.md`.
- [x] **L-19 The buttons in the world, small and modern** (owner, Nov 11: "It takes up too much
  space on mobile... all prompts in the game need to be revamped to take up less space and look
  modern and world-class"). Every button in the world is Roblox's default prompt today (the dark
  box with the key, the name over the verb). Two sessions:
  - [x] **L-19a One look for every button.** Done Nov 11 (D-114), verified in Studio on a
    computer and the Galaxy A16 (`docs/art/L-19a-*.jpg`): every prompt is `Style` Custom and
    drawn by the client's `ButtonView` in `WorldButton`'s look: a round key chip (the key, the
    pad's picture, or a dot on a phone at 48 points with a wider target), the verb beside it, the
    name only where it's news and once per row; it swells in and blinks out, a hold fills a ring,
    a press pops it, and a refusal (now sent to the presser alone, `Remotes.Refused`) shakes it
    red with its words and a dull tick. `ButtonReach` folded in as `ButtonView.hide`.
  - [x] **L-19b A door's buttons where your hand would go.** Done Nov 11 (D-115), verified in
    Studio on a computer and the Galaxy A16 (`docs/art/L-19b-*.jpg`): each door has four spots
    (`DoorMiddle`, `DoorLow`, `DoorLatch` on the padlock's side, `DoorInside`); a shut door shows
    Open on the middle and Peek low, an open one Close and Slam side by side, a padlocked one
    "Padlocked" once over Open and Cut on the latch. The middle row is laid out per state by the
    pure `Door.place` (130-point steps, double-tap safe, Lune-checked) and slides when it
    re-spaces. Each screen keeps the spots in view (`DoorSpotView`, the rule in `DoorSpot`):
    Peek rides up the door just above the slots and comes down onto the handle as you look down;
    the row comes down with your eye as you kneel (KneelView's own lowering is gone); the latch's
    spot slides in toward your gaze so a phone's torch and jump buttons stay clear.
- [ ] **L-20 The inventory wheel** (owner, Nov 11): one round button at the bottom middle in place
  of the slots' bar. Tap it and a wheel of your slots fans out from it; pick one and a small box
  beside the button shows it. Tap that box to lift the tool into your hand or lower it out of
  view (pocketed, still yours); to switch, open the wheel again. Stylish, out of the way, never
  slow: the wheel opens in a beat, and a keyboard's number keys still pick a slot. As GTA V's and
  Red Dead Redemption 2's weapon wheels. Three slots to start (the GDD's two plus one: `OWNER.md`),
  six with a purchase.
  - [x] **L-20a The wheel and three slots** (done Nov 12, D-116). Three slots (`Carry.Slots`,
    the one number every screen and the server read). The round button at the bottom middle
    carries three dots (lit where a tool is, grown for the one in your hand); a tap fans the
    slots out over it on an arc in a beat, each a 3D picture with a soft tick, slot 1 on the
    left; a tap on one brings it up, folds the wheel and flies the slot into the box beside the
    button. The box shows the slot your hand is on: a tap pockets its tool (out of your hand and
    view, still yours: Lock, Cut, Lean and Give see an empty hand) or brings it back up, as Rust's
    holster. A computer's Q opens the wheel and frees the mouse; 1, 2, 3 pick, a second press
    pockets; the pad's d-pad steps left and right and up pockets; G, d-pad down and Drop drop.
    A tap in the world or 4 s untouched folds it. The pure shape and rules are `Tools.Wheel`
    (Lune-checked); the server keeps `ToolPocketed` and a `ToolPocket` remote. The button's top
    stayed where the slots' was, so a door's Peek needed no retune. Verified in Studio on a
    computer and the Galaxy A16 (shots `docs/art/L-20a-*.jpg`).
  - [ ] **L-20b Six slots, bought** once the store and saved player data exist (Phase 2's S4-07:
    Brix's purchases and profiles); granted only after the profile saves.
- [x] **L-17 Every button on a phone at once.** Done Nov 12 (D-117). Judged on the Galaxy A16:
  kept with the Bang button up; the horn up at a shut and an open door with the torch, jump, map
  and Blow; the wheel open by a door. The open wheel's slots landed on a door's chips, so every
  button in the world now fades aside while the wheel is open (`ButtonView.aside`) and comes back
  as it folds. Kept, the Bang button ran into the torch's switch and the wheel sat on empty, so
  the wheel slides off the bottom while you're kept (its presses ignored) and the torch's switch
  and the Use button go with the jump button and while kept. On a computer Q at a shut door now
  peeks only (Peek's key; the wheel stays shut, as G is Slam's). The held torch behind Cut reads
  and stays. `HornView`'s round button is `UseButton`. Shots `docs/art/L-17-*.jpg`.
- [ ] **L-18 The art saved with the code** (optional; the owner saves the place every session,
  Nov 10). Each imported template under `ReplicatedStorage.Props` and `Units` kept as a model
  file in the repository that Rojo puts in place, so a fresh place builds the whole game.
- [ ] **L-09 Hone.** Playtest with friends, tune Config, add juice, repeat until Gate 1. May
  repeat as several sessions; each one names what it changed and why. Brix: live config (ENG-11)
  and the presentation kit (ENG-15) as they land.
  - [ ] **L-09a The first run with friends.** A private published place; the owner and friends
    climb floors 1 to 3; the next session tunes from what they report.

## Phase 2: The loop that pays (GDD "Build order", Steps 1 to 6; D-128)

The owner's answers to the proposal (Nov 13, D-127 and D-128) replaced the old Phase 2 (ten
floors, two boss floors, a roster of nine keepers, the light board). The GDD holds the design;
each ticket names its GDD section. These are one-liners: a ticket gets its full spec, and is
split to fit a session, when it becomes HANDOFF's Next task. The order inside a step is the
build order. Saved player data, purchases, remotes, recording and UI come from Brix (ENG-09 to
ENG-16); a ticket that needs a Brix piece that isn't there yet puts it in Brix's ROADMAP and
waits. The GDD says monsters; the code and the tickets above this line say keepers.

**Step 0** is L-09a, the first run with friends (Waits on `OWNER.md`). It doesn't hold Step 1.

### Step 1: Doors that pay, and things to carry (nothing sold)

- [x] **S1-01 Saving. Done Nov 14 (D-134); verified in Studio Play.** Brix moved to `e8397ff`.
  `Save` (shared) is the save's shape, version 1: cash, the finds you keep plain and sealed, the
  collection book's stamps (finds, sealed finds, keepers trapped, each with when) and your best
  floor; a new player starts at nothing. `Saving` (server) holds each player's save through
  Brix's Saves and PlayerSaves in the DataStore `Saves` (Studio: `Saves.studio`, or in memory
  when Studio can't reach DataStores): claimed on join, written every 30 s, let go on leave and
  at shutdown; `data(player)`, `loaded`, `save(player)` for later tickets; nothing writes yet.
  Studio prints a line per write. Lune: save.spec (round trip, refusals, version 1's sample,
  two servers over Brix's loopback, Brix's SaveFormat suite). A live server hop: `OWNER.md`.
- [x] **S1-02 Recording. Done Nov 14 (D-139); verified in Studio Play.** Brix moved to
  `6717740` for its Analytics. `Record` (shared, pure) is the plan and a book of the game's
  moments; `Recording` (server) sends them to Roblox's AnalyticsService: coins earned (pile,
  gate) with the floor and the count after; each unit opened and what it gave; the wait to the
  first door and to a lobby car leaving; catches, cut free (floors carried up), finds kept; each
  player's climb end (floor, fate, team) and Again; the `climb` path (floors started, completed,
  failed) and a `climb` funnel once a climb (began, door, coins, rode, kept). Lune: record.spec.
  Seen in Play: a lobby car, a unit, a pile, a ride, the end and Again. Not yet: purchases
  (none exist; S1-10's machine adds `spent`), an onboarding funnel (needs a "first visit" mark
  in the save; dedupe of Roblox's onboarding steps is unclear), and the trip carrying the lobby
  join time so the join-to-first-door wait is one number.
- [x] **S1-03 Half the units. Done Nov 13 (D-131); passes checks, untested in Studio.** About
  30 on floors 1 and 2 and about 40 above, with blank wall where units were and the halls as long
  as they are (GDD "Doors": "Fewer units"). `Floor`'s step 5b walls whole hall sides (a piece's
  two M or three S facing one way) in the order you meet them, at an even pace with chance in
  it (`Plan.units`, 30 and 40); every wing keeps a side picked at random; on floors 1 and 2 the
  first 8 doors past the lobby stay (`Floor.TeachDoors`); a side never goes if it leaves a
  neighbour with nothing to crawl to; more than 4 hall pieces in a row with no door get a side
  back in their middle (`Floor.BareMost`); the units left are numbered again. Over 400 seeds:
  26 to 37 units on floors 1 and 2, 36 to 48 above; crawl links at least 16. Lune: floor.spec
  (counts per band, a door in every wing, the teaching doors, bare stretches). Studio and a
  phone: `OWNER.md`.
- [ ] **S1-04 Coins in most units.** About seven units in ten have one to three coins on the
  floor; tap to pick them up and a small count goes up. Yours alone, for this climb only. The
  other units are bare or hold things to look at (stacked boxes, a mattress, a rolled carpet:
  art first, the unit's way). In two sessions (split Nov 13):
  - [x] **S1-04a1 Coins: the coin, the deal and the server** (D-132). `art/coin/` builds the coin
    the unit's way (a worn gold coin, a keyhole stamped through it; piles of one to three laid
    out by the spec); `Deal` gives about seven units in ten one to three coins, drawn last so no
    seed's other draws moved; `DealSpot` lays a pile in the bulb's pool, clear of the unit's
    tool, find or keeper; the server's `Coins` lays each pile with a glint and a "Take" button,
    checks every take and keeps each player's count for the climb (`Climbs.began` zeroes it).
    Passes checks; the take verified in Studio Play with S1-04a2.
  - [x] **S1-04a2 Coins: on screen. Done Nov 14 (D-133); the take verified in Studio Play.**
    The coin in the place (`Props.Coin`, asset 88101556754832); the client's `CoinView`: each
    coin of a taken pile jumps, stands on its edge spinning and shrinks away, a beat after the
    one before, the glint throws off sparks and goes out, the chink (and a jingle for two or
    three) at the pile; on the taker's screen each coin flies on from the top of its jump to the
    count at the right end of Roblox's top bar, which ticks up one, higher each time, with a
    swell and a spin of its coin. The count slides in as a climb begins.
  - [ ] **Polish: the coins' gold.** Under the warm bulb a pile reads coppery; a warmer gold in
    the coin's texture or a brighter glint if the owner finds piles hard to spot on a phone.
  - [x] **S1-04b Things to look at.** Stacked boxes, a mattress, a rolled carpet, built the
    unit's way, in some of the units without coins, so an open door is never just a bare box.
    Likely two sessions, as S1-04a was (split Nov 14; the session that starts it confirms):
    - [x] **S1-04b1 The things' art** (Nov 14, D-135). A mattress and a rolled carpet, each stood
      against a wall, and four stacks of the existing boxes (`art/stuff/`, `Props.Stuff`,
      `Stuff.lay`); judged in an S and an M unit in Studio under the real bulb.
    - [x] **S1-04b2 Dealt into units** (Nov 14, D-136). Half the units with nothing to take (no
      coins, tool, find, keeper or note) hold one thing, read from the unit's unused pick so no
      seed's other draws move; it stands back to a wall in a corner, clear of the door's line,
      both crawl hole spots, the landing and the fallen panel (`DealSpot.stuff`); `Deals` stands
      it as the door first lifts. A small unit fits only the rolled rug. Seen in Studio Play.
- [x] **S1-05 Finds you carry.** (Built Nov 14, D-137; take, drop and catch seen in Play.) One tap puts a find in one of your three slots, beside your
  tools. Slots full: drop something or leave it. Caught: your finds drop with your tools.
  Takes in the old "Finds in a run" (where a unit's find stands, D-036).
- [x] **S1-06 Pay and keeping at the gate.** (Built Nov 14, D-138; passes checks; the screen's
  pour and the finds rising seen in Play, fired from the server; a real ride's pay seen in Play
  in S1-02, with no find kept.) As the
  gate shuts everyone aboard is paid the same coins, a little more each floor (10, then 2 more a
  floor); the finds in your slots become yours and the slots empty, into your save; a wrapped
  player gets nothing (GDD "When the gate shuts"). Polish left: a "New" mark on a find kept for
  the first time (S5-04's book stamps it already); a kept find's glint for friends is a server
  burst, unseen in Play.
- [ ] **S1-07 What a door holds.** A padlocked door always has something good, with the best
  chance of something great and of a monster. A tool in about one unit in twelve (one in five
  today). A battery in about one unit in ten. Split Nov 14: no battery art exists, and a battery
  means nothing until the flashlight runs down.
  - [x] **S1-07a Padlocked doors and rarer tools.** (Built Nov 14, D-140; a padlock cut and its
    unit opened in Studio Play.) A padlocked unit always holds a find (7 in 10) or a tool, and
    about 3 in 10 have a monster standing in there with it, asleep or awake; tools in about one
    unit in twelve (6 in 100 behind an ordinary door). No seed lays anything differently.
  - [x] **S1-07b Batteries in units.** The battery's art (the unit's way, `art/`), dealt into
    about one unit in ten; built with S1-09, right after it. Built Nov 14 (D-143): a chunky
    D-cell (`art/battery/`, black and amber, a plus and a bolt) lying on its side in the bulb's
    pool clear of the coins, a glint on its button; a Take button only once your ring has lost a
    tick; the take hops it end over end into the taker's torch with a clack-click, the ring
    sweeping full. Seen in Play Nov 14 (S1-10a's session): laid in seed 7's unit 309, taken
    with a 27 s torch, the ring full again; the flight itself not watched (OWNER.md).
    Polish: record the pickup (`Record`, a `batteryTaken` event) with S1-10's machine buys; a
    brief flare of the beam as the battery snaps in; its own snap recording if the clicks feel
    thin.
- [x] **S1-08 Tools wear out.** Bolt cutters 3 padlocks, the saw 2 holes, the air horn 3
  blasts, the padlock 1 door; a mark on the slot shows the uses left (GDD "Tools wear out").
  Built Nov 14 (D-141): notches on the box and the wheel's slots, the last one red; the break
  (snap, bits, tumble, clank, fade; your view kicks, the box cracks); the horn's last blast dies.
  Seen in Play: the notches built and the ToolBroke remote up; a break itself unseen (OWNER.md).
  Polish: broken-piece art (the cutters in two halves, the saw's snapped blade) instead of the
  whole tool tumbling; a strained creak on the use that leaves one.
- [x] **S1-09 The flashlight runs down.** Only while it's on; a meter on its button, a flicker
  for the last half minute, then out; a battery fills it at once and takes no slot (GDD "The
  flashlight runs down"; the numbers are defaults in `OWNER.md`). Built Nov 14 (D-142): five
  minutes of light, full as each climb begins; a ring of 12 ticks round the button (bottom right
  on a keyboard), red for the last half minute; the flicker (a long stutter, then closer, darker
  ones, the light sagging and browning, a bulb's buzz in each stutter), out with a dull click by
  itself; a dead button clicks softly and wobbles. Seen in Play with a 40-second torch: the
  flicker, the ring, going out and the refusal. Battery pickup is S1-07b (`Flashlights:fill`).
  Polish: a friend's dying torch seen from their side (untested with two players); shaking the
  torch to wake it (Outlast-style) if the owner wants a use for the dead button.
- [ ] **S1-10 The machine on the ride.** The ride grows to about 20 seconds. From the second
  ride on, the vending machine in the car sells three or four tools for coins, stock changing
  each ride, batteries always (GDD "The ride"). Split Nov 14 into three sessions:
  - [x] **S1-10a The ride grows to about 20 seconds. Done Nov 14 (D-144); the loops seen in
    Play.** The car grinds up at about a stud a second: the brakes let go at 0.8 s, full speed
    by 3.2, three cable clanks (4.6, 8.9, 13.4), level at 18.8, the gate folding at 19.5. The
    motor and the rumble loop on their steady stretches (`Recording.Loop`, `Ride.position`).
    Riders move to the next car on the last clank; a lobby trip's riders arrive 6.2 s before
    the car levels, as before, so the first ride's extra length is the trip's black; a lobby car
    is back in its bay 2 s after the ride opens; a left-behind player stands in the dark lobby
    until 3 s before the hand-off, then the black. Unseen: a whole ride to a next floor (the dev
    floor's ride ends the climb).
  - [ ] **S1-10b The machine: art, in every car, waking on the ride.** Split Nov 14 in two
    (b1 the art, b2 the machine in the car). Art first, the unit's
    way (`art/machine/`, built like `art/battery/` on the finds' kit, several MeshParts sharing
    one Machine set at 1024²). The plan (Nov 14): a self-storage supply machine, the kind real
    storage buildings sell padlocks from: oxblood enamel cabinet, chipped to primer and steel,
    4.6 wide, 2.4 deep, 6.6 tall (eyes are at 4.6), in the car's back-right corner against the
    back wall, facing the gate, clear of the bumper boards (its middle about Blender x 3.5,
    y 10.6 in `art/elevator/spec.py`'s frame). Front, bottom up: plinth; a bin behind a push
    flap with the coin plate at its right (a keyhole slot for the building's coin, a return
    cup); then three rows behind one glass pane, each with a steel rail under it carrying, per
    bay, a lit price window and a chunky push button (old cigarette machines' one-knob-a-column
    look): two battery bays (row 1.0 tall), then two rows of two tool bays (1.25 tall, about
    1.9 wide); a lit sign at the top. Inside: white liner, steel shelves stopping short of the
    glass (the drop chute), a divider per row, a motor box at the back of each bay. Parts:
    `Machine` (the body), `MachineCoil` (one chrome helix along the depth, cloned per bay so it
    can turn), `MachineButton` (cloned per bay, sinks when pressed), `MachineFlap`, and
    untextured `MachineGlass`, `MachineTubes` (a fluorescent tube at the top of each row),
    `MachinePrices` (the six windows, one SurfaceGui for b's digits) and `MachineSign` (Neon,
    a keyhole-coin emblem drawn by a SurfaceGui). Dark on the first ride (GDD); on later rides
    it wakes as the gate slams (the tubes' starter flicker, the sign buzzing on, a hum, one
    SurfaceLight into the bays and one spilling into the car) and dies as the gate folds open.
    Sounds to find and measure: a fluorescent starter tink and a hum.
    - [x] **S1-10b1 The machine's art. Done Nov 14 (D-145).** `art/machine/` (README), built as
      planned: eight MeshParts, the Machine set at 1024 (about 49 texels a stud), look sheets in
      the elevator's own car (`machine-car`, `-dark`, `-near`, `-studio`); the tubes sit just
      behind the glass under each rail. `src/shared/Machine/Specs.luau` generated. Not yet in the
      place.
    - [x] **S1-10b2 The machine in every car, waking on the ride. Done Nov 14 (D-146).**
      Uploaded and prepared into `Props.Machine` (`Machine.prepare`); FloorBuilder stands one in
      each floor's car (`Machine.place`), not the lobby cars (their back wall holds the results).
      `Machine.Wake` (pure, `tests/machine.spec.luau`) and `MachineView`: the rows' tubes tink,
      flash and catch bottom up from 1.2 s, the sign buzzes on at 3.75 s, LED dashes, a hum,
      dips with the lamp, dead 0.35 s after the gate starts to fold; dark from the lobby. One
      SurfaceLight (into the car); a second into the bays blacked out the car. Seen in Play.
  - [ ] **S1-10c Buying.** Split Nov 14 in two (c1 the stock shown, c2 the buy).
    - [x] **S1-10c1 The stock shown. Done Nov 14 (D-147); seen staged in Play.** `Machine.Stock`
      (pure, `tests/stock.spec.luau`) deals each waking ride two batteries in each bottom coil
      and three or four of the five bay-sized tools in random tool bays (prices: battery 3,
      bubble wrap 5, padlock 6, air horn 7, saw 8, bolt cutters 10); the server's `Machines`
      keeps it by the ride's value and writes it on every machine whose car carries that ride
      (`Stock` attribute), so the taking-over car matches. `MachineStock` stands each thing in
      the front loop of its coil, face to the glass (`Specs.CoilFront`, `CoilPitch`, now
      exported); `MachineView` shows a row at its tube's first flash, its LEDs test 88 as it
      catches, then the prices (dashes for an empty coil); gone at the cut. Unseen: a real
      keypad ride and the takeover in Play (checked with a stand-in car).
    - [x] **S1-10c2a The buy and the machine's answer** (D-148). Each bay's button is a "Buy"
      named for its thing, live while its row is lit and stocked (`Machine.Buy.open`); the
      server validates (bay, reach, aboard that car on that ride, row open, stocked, can pay,
      rate) and in one step gives the thing (a tool in a free slot via `Slots:give`, or a
      battery via `Flashlights:fill`, refused silently when full or no room), then takes the
      coins (`Coins:spend`), lowers the count, stamps `Bought` and rewrites the stock. Every
      screen reads the sale off the stock (`Buy.sold`) and plays the vend (MachineVend): the
      button sinks with a click, the coil turns one loop with a whine, the thing tips off into
      the bin with its clunk, the flap knocks out and back; a press without the coins clicks,
      buzzes and blinks the price. Records `spent` (machine, item) and `batteryTaken`.
    - [x] **S1-10c2b The buy's flights** (D-149). The server tells the buyer's screen first
      (`Buy.Remote`); up to eight coins leave the count one by one, ticking it down, and curve
      into the coin slot, each clinking there; a beat after the thing lands in the bin it arcs
      out through the flap to the buyer's left hand or into their torch on every screen, with
      its pick-up sound (the battery's clack-click). Until it lands, screens hold the change
      back (`InFlight`): your drawn tool, a friend's tool in their hand, the torch's fill. A
      battery's Buy is hidden from a full torch. Seen in Play, both buys.
  - [ ] **S1-10d Pick from a menu, at a shallower machine** (owner, Nov 14 morning, verbatim:
    "it's difficult to see what's available because you have to literally look at the buttons,
    so stuff below is hard to tell. Plus an elevator full of people will make it hard to use. I
    think we shrink the depth of the vending machine a bit, and when you walk up you click a
    prompt that opens an overlay where you can make your selection. Then you can still see it
    animate and drop out of the vending machine as-is."). As Dandy's World's shop opens a panel
    in its elevator between floors. Two sessions:
    - [x] **S1-10d1 The menu. Done Nov 14 (D-161); the server's path verified in Play, the panel
      unseen (Studio drew no frames).** One "Buy" on the middle of the glass, reaching from the
      car's back half through friends (no line of sight), opens MachineMenu: the machine's front
      rising from the screen's foot with a latch's clunk, its oxblood cabinet, sign and keyhole
      coin, three rows of two bays in its order (picture, paper label, LED price, chrome button),
      its tubes stuttering on with tinks, LEDs testing 88, every row lit in step with the real
      tube. A pick sinks the real button; one you can pay goes up `Buy.Pick`, and the panel drops
      away for the vend and rises after; too few coins buzz, blink and shake. Closes on walking
      off, the buying's end, leaving, being caught, dying, its chrome knob, E or B.
      Originally: the per-bay Buy buttons give way to one button on the machine
      (one verb). Pressing it opens a panel over the screen, built phone first: every bay at
      once in the machine's own order, each with its thing's picture (rendered, like the coin
      count's coin), name, price, and whether its row is lit yet, it's sold out, or you're short
      of coins (shown, not explained). Tapping one sends the same buy the bay button sent today
      (the server's checks unchanged); the panel gets out of the way so you watch the coins fly,
      the coil turn and the thing drop and fly to your hand, as now. It closes itself when you
      walk off, the ride ends or you're caught; friends each open their own. Every press answers
      (motion and sound); a buy you can't afford answers the way the machine does today.
    - [ ] **S1-10d2 A shallower machine.** `art/machine/` spec made shallower (about a third
      less deep: the owner's "a bit"), rebuilt with `scripts/art.sh`, re-uploaded and prepared;
      the coil, bin, flap and the vend still read; a full car of friends fits round it. Judged
      at phone size in the car.
- [x] **S1-11 The one faint mark. Done Nov 14 (D-150); sampled in Play.** A hasty chalk ring
  with a dot (art/mark/, made from code) on the left jamb of one note's door: `Deal.markFrom`
  (pure, `tests/mark.spec.luau`) marks a note that isn't the guarded one on every floor 1 and 2
  and 6 floors in 10 above; FloorBuilder sticks it there hidden and tagged; FaintMarkView shows
  it only in your own beam's middle from within about three steps (`FaintMark.seen`), blooming
  in, lingering out, flickering with a dying torch. As Phasmophobia's fingerprints show only
  under the light you hold. The corner map shows nothing of notes. Polish later: a friend's
  beam showing it too (their aim is coarse).
- [x] **S1-12 Cash on the results. Done Nov 14 (D-151); verified in Play.** As the climb ends,
  each player's coins freeze and turn into cash one for one (`Cash.from`, `tests/cash.spec.luau`),
  straight into their save and written (CashOut); the car's results board shows each friend's
  cash under their photo, yours counting up with rising ticks and landing with a swell and a
  jingle. As Dandy's World's Ichor (from memory). Polish later: your saved total shown somewhere
  in the lobby once cash buys something (Step 4's starting tool); a coin flying off your count
  into the figure as it counts.

- [ ] **R-01 Remotes from Brix (later, not during the overnight run).** Move the game's
  hand-declared remotes (`Remotes.*`, each system's own RemoteEvent) onto Brix's typed Remotes
  (ENG-09a-d, Brix `5df692e`), pinning `vendor/brix` there; every check (type, range, owner,
  rate) kept as it is.

### Step 2: Monsters that mess with the floor (nothing sold)

Done when a team that has lost its lights goes looking for the breaker without being told to.

- [x] **S2-01 Sleeping monsters are placed when the floor is made. Done Nov 14 (D-152); seen in
  Play.** The floor's deal places its sleepers last (`Deal.new`, `deck.sleepers`: 10 in 100
  units, 20 behind a padlock, none in the guard's unit or the first hall on floors 1 and 2), and
  a door hands its sleeper back as it lifts; the director now deals only finds, tools, nothing
  and awake keepers. The keepers' brain knows each floor's sleepers behind doors never lifted
  (`Keepers.sleepers`), listed in Output as a floor is laid. As Left 4 Dead's Witch sits waiting
  before the team arrives (from memory). The bodies still stand only as a door first lifts:
  S2-03 decides how one woken behind a door never lifted stands and pounds.
- [ ] **S2-02 The breaker.** A breaker box on every floor, somewhere different each climb.
  Thrown: one heavy clunk and every hall light out, and moving under them does nothing. A
  one-second hold switches it back on. The elevator keeps its own light. A loose Mannequin with
  no light on it sometimes heads for the breaker and throws it, more often on higher floors
  (GDD "The breaker", "The Mannequin cuts the power"). Split (S2-01's session), one per session:
  - [x] **S2-02a The breaker box's art.** (S2-02a, Nov 14, D-153) A heavy-duty safety switch on
    a plywood board (`art/breaker/`): the lever on its right side, up for on, down for off, a
    safety-red grip; a pilot lamp the game lights; a lightning-bolt sticker; a conduit to the
    cap. `ReplicatedStorage.Props.Breaker`, `Breaker/Specs.luau`; judged on a hall wall in
    Studio Edit under a stand-in torch, from across and down the hall.
  - [x] **S2-02b Throw it and switch it back.** (S2-02b, Nov 14, D-154) One box per floor on a
    plain wall or a dead end, never in the lobby's hall, drawn last in the deal (`Breaker`,
    `Breakers`, `BreakerView`). Thrown: the clunk across the floor, every hall light blind, the
    red lamp pulsing with a short red glow; a one-second hold judged on the server brings the
    lights back on all at once, the lever snapping up, a click, the hum, the lamp green. Seen
    in Studio Play on the dev floor with the dev command (`ThrowBreakers`).
  - [x] **S2-02c The Mannequin throws it.** (S2-02c, Nov 14, D-155) A loose Mannequin picking
    where to wander next sometimes heads for the box instead (`Breaker.errand`: 8 in 100 picks
    on floor 1, 2 more a floor up to 30; none while thrown or for 45 seconds after the power comes
    on), walks there held by any light as ever, and throws it; keepers within a slam's reach of
    the box hear the clunk and come to look (`Keeper.offer`, `Keepers`). Seen in Studio Play: a
    Mannequin walked 110 studs to the box in 21 seconds and threw it, all 23 lights blind.
- [x] **S2-03 Sleeping monsters wake.** After four minutes on floors 1 and 2 (six above), three
  sleepers wake and pound on their doors, heard across the floor; three more every two minutes;
  sooner and more higher up. One pounding breaks out after 90 seconds unless its door is
  padlocked. No clock, no announcement. Split (the last overnight session), one per session:
  - [x] **S2-03a When they wake and which.** (Nov 14, D-156) Pure rules (`Waking`): the first
    wave at four minutes on floors 1 and 2, 15 seconds sooner a floor above, never under two and
    a half minutes; three at a time on floors 1 to 3, one more every three floors up to five;
    two minutes between waves on floors 1 and 2, 10 seconds closer a floor, never under 75; a
    step wakes what's owed, no more than are left asleep, never past six keepers stepping on the
    floor at once (loose or pounding), the held-back ones waking once there's room; which doors
    is a fair random pick. `tests/waking.spec.luau`. Nothing in the game calls it yet.
  - [x] **S2-03b They stand and pound.** (Nov 14, D-157; seen in Studio Play: two waves, three
    bursts at 90 s, a padlocked door holding) The keepers' brain keeps each floor's seconds since the
    team arrived and asks `Waking.now` each step; `Waking.pick` chooses among
    `Keepers.sleepers`. A picked sleeper's body stands in its unit then (the deal's place and
    facing, as a door lifting stands it), awake and shut in, and goes straight into the trapped
    keeper's clock (`Keeper.trap`, `bangGap`, `blow`: Mannequin `breakOut` 90 s), its blows heard
    across the floor by players and keepers (`Keepers:hear`), a padlock holding it. Its unit
    leaves `sleepers`. A Studio dev path that skips the minutes; verify in Play on the dev floor
    that one wakes, pounds and bursts an unpadlocked door after its time, Output clean.
- [x] **Owner's fixes, Nov 14 (D-158).** Players still in a car as its gate shuts on a floor are
  stood out on the landing; the trip's black waits until the car is seen climbing, and the
  group's server waits for each screen to load before standing them in the ride; a floor's first
  power cut comes soon once a Mannequin is loose; the coin count's coin is a sharp picture; the
  lobby's floor slab no longer runs under the cars. Verified in Studio Play with DevTrip
  "Arrive"; the phone trip is the owner's (`OWNER.md`).
- [ ] **S2-04 A wrong code lets monsters out.** One unit with a monster in it rolls up by
  itself on the first wrong code, three on the second, five after; the hall lights go out for
  the alarm; every loose monster heads for the keypad; the keypad locks 3.5, 7, then 14 seconds.
  Split (Nov 14), one per session:
  - [x] **S2-04a Doors roll up by themselves, and the keypad locks longer.** (Nov 14, D-159;
    seen in Studio Play: one door, then three, the third wrong code holding at a padlock, the
    keypad dead 3.49, 7.01, 14.02 s) Pure rules (`WrongCode`): 1, 3, then 5 units per wrong
    code on a floor, sleepers first, then monsters awake behind shut doors, never a padlocked
    door, sleepers only while the floor has room on its feet (`Waking.AwakeMost`); the doors
    roll one after another from 1.2 s, 0.7 s apart, each the slow, loud open. The keypad counts
    wrong codes per floor and stays dead `Keypad.dead` (3.5, 7, 14 s); the bell strikes again
    every 3.5 s while it's dead. A picked sleeper stands awake behind its door first, so it
    hears the alarm and comes for the keypad once out. `tests/wrongcode.spec.luau`.
  - [x] **S2-04b Every loose monster heads for the keypad. Done Nov 14 (D-160); seen in Play.**
    A wrong code's alarm calls every monster awake on its floor however far (`Keeper.alarm`), as
    Left 4 Dead's car alarm calls the horde; one shut in comes once out; one chasing you keeps
    on you. Freed ones stand quiet behind their rolling doors (`Keeper.hush`) and the doors'
    opens don't pull anyone off the alarm. In Play on seed 7: one 142 studs off and three just
    freed all walked to the keypad and looked round there.
  - [ ] **S2-04c The hall lights go out for the alarm.** Today a wrong code turns every light
    on (`MotionLights.flash`), freezing the Mannequins, so a team is safer for guessing (seen
    in Play: every Mannequin let out froze in the light). The GDD: the hall lights go out for
    the length of the alarm instead (the elevator keeps its own light). Its own sound and the
    lights' flicker as they cut and come back.
- [ ] **S2-05 The tap when you shut a door on a sleeper.** Pull the door down on a monster
  that is asleep or hasn't seen you and a bar with a moving marker comes up by itself. Hit it:
  the door settles quietly. Miss, or don't tap: it bangs, and the monster wakes and pounds.
- [ ] **S2-06 The second monster.** Waits on `OWNER.md` (its look, name and reason to be
  alive). Silent; moves only while it stands in light; a hall light it walks under sticks on
  until someone switches the breaker off and on. Its art first, then its row on the keepers'
  brain (GDD "The second monster").

### Step 3: Getting caught (the first products)

Done when nobody quits a climb because they were caught.

- [ ] **S3-01 Stay wrapped, carried up.** Nobody is out of the climb any more. Wrapped or late
  when the gate shuts, you watch the ride and turn up wrapped in a unit on the next floor, with
  empty hands, floor after floor until a friend cuts you free. Wrapped, you can bang on the
  door or watch a friend, and nothing else. The climb ends only when everyone is wrapped at the
  same moment (GDD "Getting caught"; changes L-08c's and L-08d's rules).
- [ ] **S3-02 Purchases that are never lost.** Brix's purchases on the saved profile: granted
  only after the profile saves. Before anything is sold live: a real phone purchase survives a
  forced save failure and a server hop; every purchase and shop view is recorded; any offer can
  be switched off without an update; prices are read from Roblox.
- [ ] **S3-03 Cut Free, Free a Friend, Free Everyone.** Offered only on the screen you see
  while caught, and Free Everyone before the results when the whole team is wrapped. Cut Free
  while you're being carried up stands you in the car at the next floor. (Cut Free is built and
  free in Studio, L-07d and L-08c.)
- [ ] **S3-04 The counter's shop, and wrap colours.** Walk up to the counter and the shop
  opens; a Shop button in the lobby and Roblox's own. Its first shelf: wrap colours, with gift
  versions (GDD "Monetization", D-112).

### Step 4: The climb with no top

Done when two climbs in a row feel different and players talk about their best floor.

- [ ] **S4-01 Floors made by rules, to floor 100.** One table says for any floor number what
  it holds and how hard it is (GDD "Floor rules"); the climb no longer ends at floor 3 (D-106).
  Room left for floors that play differently.
- [ ] **S4-02 Monsters by lowest floor.** Each monster's row carries the lowest floor it can
  appear on; above it the game mixes it in at random.
- [ ] **S4-03 The choice on the elevator's buttons.** Three buttons light up on the car's
  panel, each a version of the next floor and what it pays; most presses wins, a tie at random;
  it lasts that one floor (GDD "The team's choice").
- [ ] **S4-04 Trapping pays.** Each monster shut in a unit as the gate shuts adds a quarter to
  everyone's pay. A trapped monster now counts toward the floor's limit on awake monsters
  (today `Keepers.awakeOn` leaves it out).
- [ ] **S4-05 The big find.** From floor 2, one a floor, shown only once the code is in: a unit
  rolls up by itself and its place shows on the corner map. Carried in both hands, slower than
  any monster, no tools; it counts only if it's in the car as the gate shuts. Its art first.
- [ ] **S4-06 The marker.** Sold in the machine. Face a door and tap Mark: a bright mark the
  team sees down the hall and on the corner map. Five marks. Its art first.
- [ ] **S4-07 On sale.** A starting tool for cash during the car's countdown, flashlight beam
  colours, and a fourth, fifth and sixth slot (this is L-20b).

### Step 5: After the climb

Done when players watch the results to the end and change their perks between climbs.

- [ ] **S5-01 Finds valued one at a time** on the results: picture, name, how rare, what it's
  worth, the cash counting up; then a line for each player.
- [ ] **S5-02 Rarity, and finds still sealed.** Rarer finds on higher floors; about one in
  twenty still in its packaging, worth three times as much. A padlocked unit's find draws a
  grade better (GDD: "the best chance of something great"; S1-07a left it a plain find).
- [ ] **S5-03 Selling and keeping without a menu.** Copies and common finds sell on the spot;
  a rare one you don't own is kept.
- [ ] **S5-04 The collection book.** A page for every kind of find, stamped "New" the first
  time; each kind of monster trapped; sets.
- [ ] **S5-05 The shelf in the elevator.** The host's three best finds, shown in the car.
- [ ] **S5-06 Perks.** Unlocked by a first floor reached or a set finished, bought with cash,
  two picked before a climb.
- [ ] **S5-07 On sale.** Double cash, cash packs, the starter pack (after your first climb) and
  decor. Then the friend's matching beam colour for joining on your link, and cart cosmetics
  (D-112).

### Step 6: Coming back

Done when players come back the next day without a friend asking them to.

- [ ] **S6-01 Best floor.** On a plaque and on the dial over your car; badges at floors 10, 25,
  50 and 100, for each kind of monster trapped and each set finished.
- [ ] **S6-02 The Missing board.** A wiped team's photos and the floor they were caught on.
- [ ] **S6-03 The free door once a day** in the lobby, a better find on the seventh day running.
- [ ] **S6-04 Private servers and clips.** Private servers free or nearly; Roblox saves a short
  clip at the GDD's ten moments.
- [ ] **S6-05 The weekly shelf.** Three cosmetics at the counter, changed each week.

Then the soft launch (GDD "Build order").

### In no step

Each waits on the owner (`OWNER.md`) or comes after launch: the monster you hide from; the
monster that takes your head; the stair chase and other floors that play differently; the hall
of units; trading; a season pass; fake notes, finds that are monsters in disguise, the monster
that moves walls, and the dolly.

## Polish waiting for a slot

- **The coin picture (D-158):** the flying coins (the pour, a buy) are still 3D in
  ViewportFrames, fine in motion; if they read soft beside the count's new picture, give them
  the picture too (a 2D flip as they fly).
- **The buy (S1-10c1, S1-10c2b):** the stock vanishes at the cut rather than standing dark in
  the coils; a battery's label may face away (unchecked); the flap could knock a second time as
  the thing pushes out through it; the tool's name over the slots shows as the server gives it,
  a second before it reaches your hand; a friend sees no coins go into the slot (only the
  buyer's screen flies them).
- **The machine (S1-10b2):** a dark machine in the lobby cars too, so the car you board matches
  the one you arrive in (the results board on their back wall must move first); the bays' own
  light (a second SurfaceLight shone into the cabinet blacked out the car: try a small
  PointLight inside each row instead); the tube ends' orange glow while a starter tries.
- **Finds (S1-05):** a find you take flies from where it stood into its slot box, as coins fly to
  their count; a friend's arm sags under a heavy find (only your own view feels its weight now);
  a find standing in a unit can be walked through (it's inert, as a lying tool is); a glass
  rattle in the TV's drop.

- **More stuff in units (S1-04b1):** the GDD names three things; with a mattress, a carpet and
  four stacks, units repeat soon. Candidates the unit's way: a dust sheet over a chair, a bike on
  its side, a standing lamp with no shade, a stack of plastic tubs; the stacks' boxes all wear
  the same few marker words (a few more words in `art/boxes/spec.py`'s `CELLS`).
- **Stuff for a small unit (S1-04b2):** a small unit's crawl hole spots leave only a 1.4-stud
  strip at the back wall's middle and a pocket by the right of the door, so every small unit with
  stuff shows the rolled rug. A narrow thing for that strip (two small boxes turned end on, a
  folded lawn chair) would vary them.

- **Blank wall that reads as built (S1-03):** fewer units leave stretches of the corridor kit's
  plain wall up to four hall pieces long. Judge them in Studio on a phone first; if they read as
  missing doors, dress the odd one with a fire-hose cabinet, a pillar with a painted bay number,
  a strip of hazard tape or a wall-mounted extinguisher, the corridor kit's way.

- **The front office's finish (L-08e1a):** the room's middle is bare concrete (the ride needs
  it, but a floor plan board by the door, a bench, a wet-floor sign or a mop bucket would say
  "office" before the counter does); padlocks and tape on the shelves and a pegboard of locks
  (the GDD's shop stock: only boxes now); Everkeep's name in vinyl on the door glass; a lit
  pylon sign or a lamp post out on the concrete so the night outside has a shape; the bay
  numbers as backlit sign boxes. All of it after the loop works (owner, Nov 7).

- **The wheel's finish (L-20a):** the button's three dots are plain round Frames; a small drawn
  icon (a fan of three tools' outlines) made the art way would read as "your tools" at a glance.
  On a computer a hovered slot could grow and tick as GTA V's does, with the tool's name over the
  wheel. A phone's haptic tick per slot (`HapticService`, where the phone has it) would make the
  fan felt as well as heard. The pocketed box is the picture dimmed and sunk; a short slide of the
  picture down into a pocket edge would say "put away" more plainly.
- **The pad's wheel (L-20a):** a pad steps slots with the d-pad; holding L1 to open the wheel and
  the right stick to pick (GTA V's pad wheel) would match the touch and mouse wheel.

- **A door's row as it changes (L-19b):** a button fading out (0.08 s) and the one arriving in
  its neighbour's place overlap for that moment (Open fading as Slam swells in beside it). A
  crossfade that waits for the leaver, or a shorter fade on a door's row, if it reads as a flicker.
- **The world under the wheel (L-17):** a door's buttons vanish while the wheel is open; dimming
  the whole view a touch behind the fan (GTA V's wheel greys the world) would say "the wheel has
  the screen" more plainly than the chips alone going. The kept player's wheel sliding off could
  take a soft cloth rustle, as hands go empty.
- **The buttons' finish (L-19a):** the hold ring is Roblox's own ring picture, thin round a
  48-point chip; a ring of our own (a bolder stroke, a soft glow as it closes) would read better
  at arm's length on a phone. A row's shared name ("Padlocked") jumps to the next button when the
  leftmost goes; a quick cross-fade would hide the hop. A held key could sink the chip a touch
  more on a keyboard (it sinks to 0.93 today).

- **Behind a sawn hole, no dead buttons (L-16b1):** Climb down and Drop down are ignored there;
  hiding them on your screen while the slide would cross the hole (LadderView, `Tops.pathClear`
  from where you lie) would leave nothing to press that does nothing.
- **A friend's landing in step (L-16b1):** their knees bend on your screen's clock of their move,
  their body dips on theirs, about a tenth of a second apart; delaying their crouch by the
  replication lag would make it exact.
- **The end's own sounds (L-08d):** the far doors are the roll-up door's slam, low and muffled,
  and "Kept" lands on the padlock's dread hit; a recording of the building itself (a long
  settling groan through the steel) and a sting for "Made it" (air, a door to the night) would
  make both ends their own.
- **The escape seen (L-08d):** the white is a flash over the car; light pouring down the shaft
  through the gate's bars first (the shaft's walls brightening as the car rises into it) would
  show the way out before it takes the screen.
- **The results' paper (L-08d):** the lost friends' photos as Missing posters (a thin paper border,
  a pin, the floor written in marker), ahead of the lobby's real board.
- **Watching a friend ride (L-08c):** a watcher sees the friend's car lit as a rider does, but
  not the shaft sliding past the gate (RideView draws only your own ride) nor the sway; draw the
  watched friend's ride on the watcher's screen too, so the cut into the next car reads as theirs.
- **The car leaving you, seen from the landing (L-08c):** today its lamp draws away and the car
  sits dark behind the gate. Slide the car itself up out of the opening on the left player's
  screen, its underside and the lamp's glow rising past the landing, an empty shaft behind.
- **Left behind's own sting (L-08c):** the low hit is the padlock's ("Evil Mind 9"); a sting of
  its own (a long downward groan, the cable singing away) would set it apart.
- **The hand-off's long frame (L-08b):** if a phone stutters or the car goes dark at the
  second clank (`OWNER.md`), spread the cost: clear the floor below a hall piece a frame over the
  slowdown instead of at once, and warm the new car's lighting first (`Camera.Focus` there a
  moment before the move, D-104).

- **A full map behind a button (L-10):** the owner may later want a map you stop to open, exposed
  while you read it (R.E.P.O.'s map in hand). `MinimapDrawing` draws the whole floor already; it
  needs a bigger frame, a button and the pause it costs you.
- **The map's marks drawn as art (L-10):** your dot's nose, the gate's mark and the tick are plain
  Frames and a fallback-font "✓"; an arrow, a lift icon and a hand-drawn tick, made the art way,
  would read sharper on a phone.

- **A far friend's bang, heard (L-07c):** beyond the door's 70 studs a friend only sees the mark
  appear. A muffled distant thud as a friend's mark first shows (one per run of bangs, not each)
  would turn heads the way DbD's hook sound does.
- **The kept mark drawn as art (L-07c):** the mark over a banging door is a plain blue dot and a
  name; a fist or a door icon, made the art way, would read faster at phone size.
- **Feet under the door (L-07e):** while the padlock's hand works at your door, two shadows
  breaking the hall's light under it (`UnderDoor`) would say someone is standing right there.
- **The Bang button urging you (L-07e):** through the warning, the Bang button's ring could pulse
  with the countdown, so the kept player knows banging is the way to bring a friend in time.
- **Padlocked on the map (L-07e):** a padlocked friend's bang mark and map dot could carry a
  small padlock, made the art way, so a friend knows to grab bolt cutters before they set off.

- **The unroll's own sound (L-14b2a):** the sheet's unroll plays the pick-up's crinkle slowed
  down; a real unrolling rustle (measured, Pro Sound Effects) would sell the roll going across.

- **A pop that sounds like popping (L-14b2c):** the owner, Nov 10: the pops read as rustling, not
  popping. Pro Sound Effects' bubble wrap take 2 is a crackle into one sharp pop; find or layer a
  louder, sharper burst (several bubbles going at once, a hard snap on top) so a sheet underfoot
  reads as an alarm to players across the hall, not a bag being moved.

- **Bubble wrap you can see through (L-14b1):** the wrap is opaque, painted as clear film over
  grey. A `SurfaceAppearance` with `AlphaMode` Transparency and an alpha in its colour map would
  show the real floor through the sheet's film and the roll's outer layer (one transparent part a
  sheet: check it on a low-end phone). The kept wrap (L-07b) shows how: wire the alpha in the
  export's material and give the part Transparency 0.02 (docs/STUDIO.md).

- **A wrap that tears open (L-07d):** the film comes off as the whole cocoon slumping down the
  body, which reads as film dropping off at the speed it moves but not as torn. A second mesh made
  the art way, the cocoon split down the front with its flaps peeled back, swapped in at the rip
  and then slumped, would show where the friend tore it.
- **The rip, heard far (L-07d):** a friend down the hall hears the rip within 50 studs; past that
  nothing tells the floor someone's free. A short far cue (the rip muffled through walls) would,
  the way a far bang could (L-07c).

- **The wrap going on (L-07b, L-06c2):** friends see the film climb you as you turn once round,
  but the film is one mesh scaled up from the feet; a band spiralling up (the cocoon's own bands
  revealed in turn, as a pallet wrapper lays them) would read as wrapping, not rising. The squeal
  is one recording; layering a crackle of film under the peel would sell it more.

- **The air horn, felt by friends (L-14a2):** a friend standing beside your blast gets a small
  kick to their view too, fading over a few studs; and a breath of air hissing out of the can as
  the blast dies, so a horn sounds held, not played. A keeper that hears it could snap its head
  round before it walks (the Mannequin's stillness makes that an untested bet).

- **Its tell, from its feet (L-06b4b2):** the footfalls and scrapes play from the keeper's root,
  at its hips; from the planted foot (and the scrape from the dragged one) would place them a
  stud or two truer up close. A heavier, louder footfall while it hunts than while it roams,
  and a different footfall on the tops' steel than on the halls' concrete.
- **The reveal, seen (L-06b4b2):** the thunk and creak as a door clears its feet have no motion;
  a small settle of its head or a hand on the same frame would make it read as alive to anyone
  looking, not only listening (an untested bet: it stands still in its shop pose by design).
- **The rush (L-06c1):** dead still while lit, then the moment the light leaves it a fast, jerky
  rush across the gap before it settles back to its limp (SCP-173, Doors' Seek). It needs the
  server to move it faster for a moment, against the GDD's "nothing outruns you" unless the rush
  stays short; the owner's call, then its own ticket.
- **Its walk heard through walls (L-06c1):** its steps carry the same through a wall as down an
  open hall. Muffling the thunk (less top) when a wall stands between, as Lethal Company's
  footsteps go dull through doors, would let you tell next door from your hall.
- **Breath in the silence (L-06c1):** when it stops close to you in the dark, a faint creak of
  its shell settling every few seconds would make you sure it's still there (an untested bet:
  the silence may be scarier; the owner judges).

- **The kneel, fitted to the door (L-06b5b):** a friend's kneeling body puts its head about two
  thirds of a stud and its hands about a stud and three quarters ahead of where they stand, so
  one who knelt pressed to the door reaches into it on other screens. Fit `Back` to their
  distance from the door.

- **The dent, cheaper at rest (L-06b3d2):** a dented door keeps its 38-slat chain plus up to 16
  bowed ribs (about 8k triangles, 17 draws) while it stands shut; three merged dented curtains,
  one per step, would draw it as one part like a plain door.
- **The dent's fist on the door (L-06b3d2):** the trapped keeper stands back from its door and
  its hand never touches the slats; a blow could lunge its arm to the pocket the dent shows.

- **The catch's scream, varied (L-06c2):** every catch plays the same screech; two or three
  takes (the other pterodactyl screeches, pitched alike) picked never twice running, as its
  walk's takes are, would keep the tenth catch as sharp as the first.
- **Its face in the light it's in (L-06c2):** the light on its face as it lunges is hung before it
  from nowhere, warm white; a light that takes the colour of the hall's tubes or the unit's bulb
  it came out of would sit truer.
- **Waking in the dark (L-06c2):** the wake's blur and grey are lost in a shut unit's dark; the
  blinks carry it. A faint glow under the door brightening as your eyes open (UnderDoor's spill)
  would give them something to soften.

- **The torch's freeze, nearer still** (L-06b4b3): your screen holds a keeper where it showed it,
  about 1.5 studs short of where the server froze it at a hunt (its 0.1 s delay plus your aim's
  trip); the fitted delay below shrinks that. If players find a beam on its edge misses, the server
  could test your beam against where your screen showed it (as shooters favour the shooter).

- **Each screen's keeper delay fitted to its own lag** (L-06b4a): screens show keepers a fixed
  0.1 s behind the server (`KeeperMotion.Delay`). A screen could measure how late its records
  arrive and show them just that far behind: nearer the truth on a good connection, smoother on a
  bad one.

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
- **The shaft** (L-05a1, L-08a): the ride's sleeve is a wall, its seams, a painted number and
  the landings; it wants guide rails either side, a cable or two, the counterweight passing the
  other way, grease streaks, and what's left when the car goes up without you (L-08c).
- **The ride's art** (L-08a): the shaft's walls are Roblox's Concrete and Metal, not baked from
  Blender like the car; a shaft texture set (stained concrete, a landing's apron with hazard paint,
  a stencilled number) would match the car. And the car's floor readout is a SurfaceGui plate:
  a modelled indicator box over the gate would sit better.
- **The arriving hall's mouth** (L-08a): it's flat black until the car levels; a thin line of the
  hall's light at its sill as it comes down would say a floor is there before you see it.

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
- **Its look at the door** (L-06b2a): while it waits at a door it heard, its head turns slowly
  along the door and back, within the Neck's limits, as Granny looks round where she heard you;
  then it turns away. Today it stands square to the door, still.
- **Its turns** (L-06b2a): it snaps to each new heading at a hall's joint and to face the door
  when it arrives; a stiff quarter-second turn, or a snap timed to its walk's key, may read better
  once L-06b4a poses it on each screen.

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

- **The results board** (L-08e2): a soft pin tap as each photo lands on it, the board's paper
  look (a cork or a painted steel board with the Everkeep mark), your own card lit warm a beat
  after the rest, and the car's lamp (dim in its bay: HANDOFF's Seen) once it lights the walls.
- **Stepping into a lobby car** (L-08e1b1): a soft clank of the car's steel floor under your
  first step in, heard by those near, so joining a group sounds as well as chimes; and an L lit
  over each car's gate on the lobby side (today the floor readout faces into the car).
- **The dials' finish** (L-08e3): the dial is a SurfaceGui plate over the bay's art number
  plate; built the unit's way it would be a steel indicator box with six round glass lenses and
  a real needle sweeping L to 10 as a party climbs (the "floor dial over the landing" above).
  A soft tick from the dial as its floor changes, for those nearby; the line's words could
  stencil on rather than pop.
- **The ride's finish** (L-08e4b1): your hands on the handle's grip instead of the torch held
  out (FlashlightView poses the arms after the cart; with the lobby's torch question); a hop as
  you step on (your view rising onto the deck, not a snap); a kick pushed against a wall that
  only strains (no scuff, a grunt of steel); the scrape looped while you slide along a wall; a
  caster squeal in a tight turn at speed; the casters' rattle louder over the floor's seams; a
  friend's kick in step with their screen (today read from how their cart moves).
