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
  - [x] **L-11a2 The torch let down, and its switch moved** (the owner, Nov 18; D-435;
    `docs/art/torch-letdown-a16.jpg`). Off, your torch now drops out of the bottom of your view
    a beat after the click, as friends already saw your arm drop it; on, it swings straight back
    up with its beam. It comes up by itself to take a battery flying in, and to show a dead
    torch when you press it. On a phone or tablet its switch sits right of the jump button at
    the screen's edge (the jump button moves left to make room), out of the camera drag above
    the jump button where it was pressed by mistake. Seen in Studio Play on the Galaxy A16: the
    switch beside the jump button, the torch hidden off, rising lit on a tap and dropping a beat
    after the next. The battery's catch, the dead press and real devices: `OWNER.md`.
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
- [x] **S1-07 What a door holds.** A padlocked door always has something good, with the best
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
- [x] **S1-10 The machine on the ride.** The ride grows to about 20 seconds. From the second
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
  - [x] **S1-10b The machine: art, in every car, waking on the ride.** Split Nov 14 in two
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
  - [x] **S1-10c Buying.** Split Nov 14 in two (c1 the stock shown, c2 the buy).
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
  - [x] **S1-10d Pick from a menu, at a shallower machine. Done Nov 14.** (owner, Nov 14 morning, verbatim:
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
    - [x] **S1-10d2 A shallower machine. Done Nov 14 (D-162); three buys seen in Play.** 2.4 deep
      to 1.8, a quarter (a third left no room for a bottom coil's second battery): the face where
      it was, the drop between the coils and the glass 0.4, coils of 3.5 turns, a slimmer motor;
      it stands 0.3 further from the gate. Each thing now lands in the bin by its own size and
      stops riding off the tip before its corner would reach the glass (MachineVend).
      Originally: `art/machine/` spec made shallower (about a third less deep: the owner's "a
      bit"), rebuilt, re-uploaded and prepared; the coil, bin, flap and the vend still read.
    - [x] **S1-10d3 The menu stays shut after a buy. Done Nov 14 (D-164); passes checks,
      untested in Studio.** A sale closes the menu; its Buy comes back once the vend is over.
      Originally (the owner, Nov 14: "I don't think the
      vending machine needs to pop back up after you purchase. You'd click it again to buy
      another item."). Today the panel drops away for the vend and rises after; instead it stays
      down once you've bought, and the Buy on the glass opens it again. A refused pick (too few
      coins) still keeps it up.
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
  - [ ] **S2-02d The camera shows the Mannequin cut the power** (the owner, Nov 14: "when the
    mannequin is just about to kill the power, I want the minimap to be replaced with a CCTV
    style view showing the mannequin pulling the power, so it's clear what happened rather than
    players having to guess. It will also be a good WTF moment for first time players, and we
    can make use of that CCTV mechanic with other monsters as well later on."). As Five Nights
    at Freddy's security cameras show the animatronic standing where it wasn't. As a Mannequin
    on its errand reaches the box, every player on that floor sees the corner map cut to a
    security camera's view of the breaker: grainy, a cold tint, a camera number and a blinking
    red dot, the Mannequin's hand on the lever pulling it down, the clunk, then static and the
    map back. Built as a camera feed any monster can use later (where the camera hangs, what it
    watches, for how long), not wired to the breaker alone. Its own sounds (the feed's hiss
    cutting in, the static out). Defaults the session picks (how long, the angle, whether it
    plays when the box is thrown by the dev command) go in `OWNER.md`.
    Split (S2-02d1's session), one per session:
    - [x] **S2-02d1 The feed with its look and sound.** (Nov 14, D-165; run in Studio Play: cut
      in 2.5 s before the throw, dimmed on it, gone 2.2 s after) `Feed` (rules, tested),
      `Feeds` (server: who watches, where the camera hangs, show and close), `FeedView` (the
      picture grown out of the map's square, the halls copied in once, the body and box followed
      at 12 frames a second, grain, snow, number, dot, sounds), art/feed (grain and snow).
    - [x] **S2-02d2 The hand on the lever.** (Nov 14, D-166) Two stop-motion keys, `Reach`
      (right hand up on the grip, head tipped back) and `Pull` (the lever dragged down, elbow
      tucked, weight thrown onto it, head dropped), each with its hand within 0.2 of the grip in
      `tests/mannequin.spec.luau`. The brain stands it a beat with its hand on the grip
      (`Breaker.Grip`, 0.6 s; a light holds it there, a sound or sight calls it off), then
      throws, and it lingers holding the lever down; it no longer hears its own clunk. Screens
      are told "Reaching"/"Pulling" (`Keeper.shown`), so the hall and the feed both show it.
    - [x] **S2-02d3 The feed judged. Judged by the owner in play, Nov 14: "This looks great! ...
      the static look is great."** No agent session needed. Its one code item (a feed that
      starts while the map is still sliding in takes the map's place as it lands) moves to d4.
    - [x] **S2-02d4 The owner's two feed fixes** (owner, Nov 14, after playing it). (Nov 14,
      D-168; seen in Studio Play: the shut cut a feed up on the rider's screen, a Mannequin at
      the box turned away once nobody was on the floor, both hisses on time, a feed started
      during the map's slide landed in its place.) One session.
      1. **No feed once you've left the floor.** Owner: "after finishing a level, when I was in
         the elevator and moving up, the mannequin had cut the power on the previous floor and
         it still showed me. We should probably have a flag that stops that from happening."
         Why: the brain picks who watches by where they stand (`watchers` in `Keepers.luau`:
         within 40 studs up or down and over the floor's plan), and a rider in a car still
         climbing out of that floor passes. The fix: a floor keeps a flag for each player who
         has left it, set the instant its gate shuts with them aboard (`Climbs.shut`, which
         names the riders and the floor); `watchers` skips them, and any feed already showing
         to them cuts to static and the map that moment (`Feeds` keeps who watches each open
         feed). Also: a Mannequin stops starting errands on a floor nobody is on any more.
      2. **Plain static in and out.** Owner: "I think we want more of just a static sound when
         it first opens the view, the static look is great, then a static sound when it
         disappears showing the minimap again." Today it cuts in and out on bursts of
         interference (`Feed.InSound`, `Feed.OutSound`). Swap both for plain TV static, the hiss
         of a set between channels: a short hard-edged hiss as the snow comes up, the same as it
         goes. Each its own clip so they don't sound pasted, timed to the snow (`Feed.SnowIn`
         0.22 s, `Feed.SnowOut` 0.4 s) with a short tail. The quiet static under the picture
         and the clunk through the camera's speaker stay (my default, `OWNER.md`). Search the
         Creator Store for free static (Pro Sound Effects first, as now) and check each id
         loads in Play without the permission errors in HANDOFF's Queue.
      3. A feed that starts while the map is still sliding in takes the map's place as it lands
         (FeedView `mapWindow`), from d3.
      **Verify in Play:** throw the box by a Mannequin while you stand on the floor (feed, static
      in and out heard in Output's sound list), then again just after your car's gate shuts
      (nothing shows); count `RenderStepped` first (STUDIO.md "draws no frames").
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
- [x] **S2-04 A wrong code lets monsters out.** One unit with a monster in it rolls up by
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
  - [x] **S2-04c The hall lights go out for the alarm. Done Nov 14 (D-163); seen in Play.**
    Every hall light on the floor goes out for the keypad's dead span (`MotionLights:out`, shown
    "Out"), the car's lamp stays, and they come back dark (my default, `OWNER.md`); lit tubes
    and dark eyes stutter out under a power-down whine and stutter back under a fluorescent
    flicker. In Play: 23 fixtures out 3.5 s and back, the freed Mannequin walked in the dark.
    Originally: today a wrong code turns every light
    on (`MotionLights.flash`), freezing the Mannequins, so a team is safer for guessing (seen
    in Play: every Mannequin let out froze in the light). The GDD: the hall lights go out for
    the length of the alarm instead (the elevator keeps its own light). Its own sound and the
    lights' flicker as they cut and come back.
- [x] **S2-05 The tap when you shut a door on a sleeper.** Pull the door down on a monster
  that is asleep or hasn't seen you and a bar with a moving marker comes up by itself. Hit it:
  the door settles quietly. Miss, or don't tap: it bangs, and the monster wakes and pounds. As
  Dead by Daylight's skill checks: a bar comes up unasked, one tap in the zone. The moment: your
  thumb hovering while the door comes down a foot from something that might open its eyes.
  Split (S2-02d4's session, for the evening run), one per session:
  - [x] **S2-05a The rules and the server.** Built Nov 14 (D-169): `ShutTap`, `Taps`, the door's
    "Ease", "Settle" and "Drop", `Keeper.wakeShut`, a plain bar (`TapView`). In Play a hit settled
    307 with its Mannequin asleep; no tap on 327 dropped it and the Mannequin pounded; taps for
    a door with no window, nonsense and a late tap were all ignored. Originally: Pure rules first with a Lune spec (`ShutTap` or
    the like: when a shut earns a tap, the marker's sweep, the zone's width and place, how
    long the bar waits, hit or miss from the tap's time; feel numbers in shared Config). The
    server: a door pulled down on a unit whose monster sleeps (or is awake but hasn't seen the
    puller) opens a tap window for that player only; one remote for the tap, checked (type,
    then range, then that it's theirs and in its window) and rate-limited. A hit: the door's
    last stretch slows and lands soft, nothing heard. A miss or no tap: the door bangs (heard
    as a slam is), the monster wakes behind it and pounds (`Keeper.trap`, S2-03b's path). A
    plain bar on screen to test with; verify in Play both ways.
  - [x] **S2-05b The bar's feel.** Built Nov 14 (D-170): the bar rises in under the Close button
    with a metal warning tick, the door buttons near it hidden and the rest aside; a glow trails
    the marker; a tap freezes it with a flick; a hit goes green, pops and sinks, the door
    latching softly as it lands; a miss goes red, shakes and drops as the door bangs. In Play:
    327's hit (green 50 ms after the tap, buttons back after), 335's miss (the tick loaded and
    played, the shake 5 px and gone), no new Output lines. Untested by script: the screen's own
    tap path (Studio won't let a test press keys). Originally: The bar at phone size, where a thumb already is, rising in
    with motion, the marker's sweep, the zone; a soft latch on a hit and the bang on a miss,
    the door's soft landing against its slam; no words. Verify in Play, phone steps in
    `OWNER.md`. From S2-05a: hide the door's Open and Slam buttons on the puller's screen while
    the bar is up (a thumb going for the bar can land on Slam, which counts as the miss); the
    tap today is a click, a touch anywhere not on a button, F, or a gamepad's A or B; a warning
    tick as the bar rises (Dead by Daylight's); the bar's own sound on the marker's sweep, if
    it helps. `TapView` and the cues in `DoorSound` ("Settle", "Drop") are where it lives.
- [x] **S2-07 The fix pass before Step 3** (added Nov 14 from HANDOFF's Queue, so Step 2 ends
  clean before anyone is carried up wrapped). Built before S2-06. In
  three sessions (S2-07a split in its session, Nov 14: five fixes with Play checks didn't fit):
  - [x] **S2-07a Monsters and the camera.**
    - [x] **S2-07a1 The camera's two.** (Nov 14, D-171.) Every monster on the floor is followed
      in the picture, not only the one the feed is for, and only parts that moved are stepped;
      one streaming in during a feed joins it, one streaming out leaves no statue. A second
      feed never cuts off the first (`Feed.arrive`): from the same camera it joins the picture
      (its time renewed); from another it waits and cuts in after, skipped if its moment came
      while it waited (`Feed.kept`). In Play: a wandering Mannequin the server never named
      walked in two staged feeds (moved in 46 of 57 samples, seen in a capture); a join kept
      one picture and ran it 2 s longer; a third camera waited 7.5 s and cut in; a Cut ended
      it; the real errand feed followed as before.
    - [x] **S2-07a2 The monsters' three.** (Nov 14, D-172.) On its way to the breaker a
      Mannequin hears a third as far (`Keeper.ErrandHearing`), so a slam in its own hall still
      turns it but one two halls off doesn't, and the alarm always does; a sound that calls it
      off takes it off the errand at once. Monsters called to one spot each take their own place
      round it, 4 studs apart, on the floor and in sight of it (`KeeperMap.spread`,
      `Keeper.spread`): one standing keeps its place, the nearest takes the spot, one shut in is
      kept a place for once it's out. One a wave woke breaks out only while the floor has room
      under `Deal.awakeCap` (`Waking.free`), the longest shut in first; held, it gives one last
      blow at its time and falls quiet until a place opens (`Keeper.hold`; pounding on kept the
      loose ones at its door for good in Play). In Play: floor 3 (limit two) woke three, the
      third held at once, two loose 110 s in; two wrong codes brought three to the keypad at once,
      the closest two 4.3 studs apart. Specs: `errand`, `spread` (new), `waking`, `trapped`.
  - [x] **S2-07b Screens and things.** Split Nov 14 in its session (six fixes with Play checks
    didn't fit one), one session each. (S1-12's saved cash total waits for S4-07, when cash
    buys.)
    - [x] **S2-07b1 The player's three.** (Nov 14, D-173.) A hall light coming back from a
      wrong code's alarm sees whoever already stands under it, still or not (`watch:look`), so
      it comes back lit over them and holds like any other; the keypad itself is in the lobby,
      which no hall light reaches (the car's lamp only), so whether it gets one is the owner's
      (`OWNER.md`, with L-05). A battery's Take hides on your screen while its unit's shut door
      keeps you apart (`Battery.UnitValue`, `RollUpDoor.keepsApart`), as the server refuses
      it. Caught, your torch lights the face rushing you and goes out as the black comes down
      (`Caught.Dark`), on the server and your screen; wrapped, it can't be switched on. In
      Play: a still player under Straight2's light, Out at 6.96 s, Lit at 10.48 s; a lit torch
      still on 0.5 s into a catch, off at 0.97 s, charge 299 of 300, your own torch's lights
      off; a dying torch's Take hidden outside shut Unit301, shown shut inside it, hidden
      outside again.
    - [x] **S2-07b2 The screen's three.** (Nov 14, D-174.) A friend's beam shows the faint mark
      as yours does: FaintMarkView takes every lit beam this screen draws (`Beam.friends`, the
      real ones, from their lens along their raised arm) and `FaintMark.under` shows it as much
      as the best beam on it, in the brightest light on it. A long thing in the machine tumbles
      only as far as its reach fits behind the glass (`Buy.tumble`): the saw leans 41 degrees
      into the bin instead of tumbling to 100 (no art change: the vend's path). The Output
      lines traced, not the game's: the 23 `rbxassethash` permission lines come on both sides
      as the place loads, with the avatar off too, and no content id the place names fails
      (77 loaded, 331 not yet asked for, none failed); 203785492 as before. 89260803894903 is
      the owner's own TexturePack (type 63) made 18 s after the coin's mesh, named by no
      property; three coins cloned on each side in Play didn't bring it. In Play: a stand-in
      friend's beam took the mark from hidden to 70% in 0.5 s, 0.3 light sagged it to 20%, it
      lingered 0.1 s after the beam swung off and was gone by 1.5 s; the real saw's box run
      through the vend's path came 0.056 past the glass before, and stays 0.022 behind it now.
- [ ] **S2-06 The second monster: the Packrat, which collects things, not people** (the owner
  chose it Nov 14, D-167, in place of the silent one that moved only in light; GDD "The Packrat
  collects things, not people"; Packrat is a working name). The moment: a friend drops their
  lamp so the monster behind them picks it up and walks off. It carries the floor's finds to
  its own unit one at a time and ignores everyone while its arms are full. With empty arms it
  comes for a player and takes their most valuable find, or wraps them if their slots are
  empty. Its unit holds the pile, there to take back. One on a floor, none below floor 3. As
  Lethal Company's Hoarding Bug carries scrap to its nest, and as Sonic's rings take the hit.
  One session each, in this order:
  - [x] **S2-06a The Packrat's art.** Built the unit's way in `art/packrat/`, as the Mannequin
    was (L-06a): a tall, faceless bundle of grey moving blankets and packing tape with long bare
    arms. Poses for walking with its arms full (the find held against its chest), walking with
    them empty, reaching, taking and putting down. Judge the look sheets and Studio at phone
    size for one thing first: full arms read apart from empty arms from the far end of a hall.
    Split in two (Nov 14, context):
    - [x] **S2-06a1 The model and its two walks** (Nov 14, D-175). Built in `art/packrat/`:
      quilted grey blankets, an X of tape over the chest, a dark hollow in the hood, long pale
      arms; its still pose and the key poses of both walks (`Packrat/Pose.luau` on the shared
      `Rig.luau`), the `Carry` point, Lune checks, look sheets `packrat-lineup`, `-close` and
      `-hall` (both walks from 30 studs at a phone's size: the full one a pale knot at its chest,
      the empty one two pale lines wide of its sides). Not yet in the place.
    - [x] **S2-06a2 Into the place** (Nov 14, D-176). Uploaded (79124901483193), prepared by
      the new `Packrat` module (prepare, pose, rest, motors, transforms by pose name, clone,
      `carry(model)`, on `Rig.luau`), the template standing `Still` at
      `ReplicatedStorage.Keepers.Packrat`. Judged in Studio from 30 studs down a lit hall with a
      boombox at the carry point: full and empty read apart (`docs/art/S2-06a2-packrat-hall.jpg`,
      `-close.jpg`). The judge moved the carry point back behind the forearms, which the find
      had swallowed.
    - [x] **S2-06a3 Reach, take and put down** (Nov 14, D-177). Reaching, one long pale arm
      straight out at a player's chest, the find at its fingertips 4.2 studs ahead, the hood
      craned after it; taking, both hands closed on it halfway in; putting down, crouched and
      folded over it, the find low between its hands (`Pose.grip`). The walks glide: a smooth
      curve through each walk's four keys by distance, a key carrying it half its feet's spread
      (1.6 studs empty, 1.15 full). 68 numbered frames (`Pose.held`, `frame(walk, travelled)`,
      `ofFrame`), and `Packrat.transforms(frame)`. The Lune spec checks every frame stands and
      reads; checked in Studio that all 68 build on the real rig, hands where the spec says.
      Sheets `packrat-take` and `-reach-hall` (side on from 30 studs at a phone's size).
  - [x] **S2-06b It carries finds home.** Its row on the keepers' brain (`KeeperRows`), with a
    unit of its own and one new ability: it picks up a find lying in an open unit or a hall,
    carries it home, lays it on the pile and comes out for more, ignoring players while it
    carries. The server owns where every find is. The pure rules first with Lune specs (which
    find it goes for next, the trip home). It sets hall lights off as it walks (a default in
    `OWNER.md`). The deal puts one on floors 3 and up, asleep in a unit that already holds
    finds of its own. Split in two (Nov 14, context: the brain alone is a session):
    - [x] **S2-06b1 The trip home, on the brain** (Nov 14, D-178). Its row in `KeeperRows`
      (a new optional `collects`: grab 4 studs, reach 0.8 s, take 0.5 s, put down 1.2 s, its
      full walk 72% of its empty one; light does nothing to it) and the trip on `Keeper.luau`:
      told what lies loose (`Keeper.lying`, the server's `Finds`), it goes for the nearest it
      can walk to, never one in its own unit; stops its grab short facing it and reaches
      (`hands` Reach), takes it (`took`), walks home full seeing and hearing no one, puts it
      down (`laid`) and comes out for the next. A find gone first sends it to another; none
      left, it roams; its way home shut, it roams carrying. `shown` says Reaching, Taking,
      PuttingDown and Carrying; `nest` moves its pile. `tests/collect.spec.luau`.
    - [x] **S2-06b2a The server's finds and its body on screens** (Nov 14, D-179). Slots knows
      each find by number (`finds`, `loose`, `lift`, `putDown`); `Keepers` tells each Packrat
      what lies loose and lifts the find into its arms on `took` (welded at its chest) and lays
      it on its pile on `laid`, takeable again; its body on the server (`KITS`) and on screens
      (KeeperView's Kit: full and empty walks, reach, take and put down held). The dev floor's
      lobby has a Packrat post. Seen in Play: out, reach, take, home full, put down, out again.
    - [x] **S2-06b2b The deal, the hall lights and the find in its hands** (Nov 14, D-180). One
      on every floor from 3, asleep at the back of a medium unit (never a note's, a padlocked or
      another sleeper's) among two or three different finds of its own laid at its feet; laid
      finds go beside the pile; the halls light as it walks; screens hold a taken find where it
      lay until the hands close, then ease it into them, to its chest and down into the crouch.
      Seen in Play: floor 3 dealt it asleep in medium Unit 314; the dev post's fetch took, carried
      and laid with no errors, the weld carrying where the find lay, four hall lights lit as it
      walked. Not watched on a screen: the lifted door on its pile and the ease (`OWNER.md`).
    - [ ] ~~**S2-06b2 Into the game.**~~ Split into b2a and b2b above. The server moves each find (lifted, carried at its chest,
      laid on the pile) and owns where it is; screens show the Packrat's walk full or empty and
      its reach, take and put down (its Kit row in KeeperView, and how a screen learns it
      carries, D-177; `Keeper.shown` now names Carrying, Reaching, Taking and PuttingDown);
      hall lights off as it walks (a default in `OWNER.md`); the deal puts one on floors 3 and
      up, asleep in a unit holding finds (`Keeper.nest` facing its pile, `Keeper.lying` told on
      every change: a find lifted, dropped or laid, a door up or down). Its row borrows the
      Mannequin's sounds until S2-06e: its Kit plays no beats. Verified in Play.
  - [x] **S2-06c It takes from you, or wraps you.** With empty arms it comes for a player it
    sees at just under walking speed, and light doesn't stop it. Reaching one, it takes their
    most valuable find and carries it home: a tool only if they carry no find, never the
    flashlight, and the big find doesn't count. Empty slots mean an ordinary catch. A find
    dropped in its path (the drop that exists, `Slots`) is picked up instead of the player.
    The take answers: its reach, the thing leaving your slot on the wheel, a sound, a kick of
    the view.
    Split in two (Nov 14, context):
    - [x] **S2-06c1 The take** (Nov 14, D-181). The brain takes rather than catches when the
      server says the player carries something it takes (`Players.loot`, `robbed`), pulls it in
      and goes home with it; empty slots, an ordinary catch. Which slot is `Carry.prize`
      (heaviest find, else a tool, the one in hand first; never the ladder or the flashlight);
      Slots `prize` and `snatch` move it from the hand into its arms, eased from where you held
      it. The robbed screen: a view kick, its creak and the thing's own sound, the thing torn
      from your grip toward it and its picture pulled off the wheel. Seen in Play: it took the
      TV, took it home, laid it, took the teddy, then with empty slots wrapped the player.
    - [x] **S2-06c2 A find dropped in its path, and its own catch** (Nov 14, D-182). Hunting
      with empty arms, a find it sees nearer than the one it would hunt is fetched instead, never
      one on its own pile, and its landing clank doesn't call it off; a find dropped at a run
      falls at your heels. Its catch throws its own body, reared up with its pale hands either
      side of its hood (`CaughtLunge` `BODIES`, its Lunge pose). Seen in Play: hunting the
      player, it turned off them for the dropped teddy, took it and went home. The runner's drop
      and the catch's frames not watched (`OWNER.md`).
  - [x] **S2-06d Its pile, and trapping it** (Nov 14, D-183). The pile shows in its unit as the
    finds themselves, each with "Take", and taking one back works as any find does. Bait works: it
    walks into a unit for a find at the back and the door comes down on it. Shut in, it pounds
    and breaks out as any monster does. Shut in its own unit, the pile is shut in with it. Built:
    a find turning up `Keeper.Nearer` (4 studs) nearer than the one it's going for turns it there,
    so bait draws it as it passes; the rest already held and is now spec'd in Lune
    (`tests/collect.spec.luau`: drawn in, trapped reaching or holding, pounding, out at 90 s,
    home with what it holds; shut in its own unit holding a find, out, it lays it). Seen in Play
    on floor 3: it laid the boombox, walked into Unit 308 for a teddy at the back, reached, the
    slam trapped it, it pounded and burst out at 90 s and caught the player standing at the door.
    Taking back from its pile not watched (`OWNER.md`).
  - [x] **S2-06e How it sounds.** One sound while it carries and another while its arms are
    empty, each heard before it's seen, made the way the Mannequin's were (L-06c). Real
    recordings, primed. Done Nov 14 (D-184): empty, padded steps and a screech of tape once a
    stride; full, heavier steps with the find jostling and rattling.
  - [x] **S2-06e2 The Packrat heard in Play.** The S2-06e session heard nothing from it live.
    Done Nov 14 (D-185): the game was never silent. Studio was drawing no frames in that test,
    so no monster's walk was shown or heard on the client; with frames, both its sets play,
    and the Mannequin's walk too. Fixed on the way: each body's sounds are made as it streams
    in, so its first steps into earshot, and its first steps with its arms full, land on the
    beat instead of about 0.28 s late and clipped.

### Step 3: Getting caught (the first products)

Done when nobody quits a climb because they were caught.

- [x] **S3-01 Stay wrapped, carried up.** Nobody is out of the climb any more. Wrapped or late
  when the gate shuts, you watch the ride and turn up wrapped in a unit on the next floor, with
  empty hands, floor after floor until a friend cuts you free. Wrapped, you can bang on the
  door or watch a friend, and nothing else. The climb ends only when everyone is wrapped at the
  same moment (GDD "Getting caught"; changes L-08c's and L-08d's rules). Split in two:
  - [x] **S3-01a The carry up** (Nov 14, D-186). Left on a floor, you watch the ride; a beat
    after the gate opens on the new floor your view dips to black with the film's squeal and a
    door slamming, and you wake wrapped in one of its units (never the nearest), empty-handed,
    the padlock's clock fresh. Floor after floor until a friend cuts you free. The watch bar's
    "Back in when they finish" line is gone. The wake seen in Studio Play; the carry itself
    waits on `OWNER.md` (two players).
  - [x] **S3-01b Everyone wrapped at once** (Nov 14, D-187). A friend being carried up counts as
    wrapped on the floor they're carried to, so "Kept" lands as the last free friend's catch cuts
    to black, and their photo names that floor. Once the end begins, the carries stop under it.
    A wipe mid-carry seen in Studio Play with stand-ins; two players wait on `OWNER.md`.
    The ticket as written: the end's rule already is "nobody left climbing"
    (`ClimbEnd.over`): check it under the new rules and fix what's off. A watcher mid-ride
    counts as wrapped; a carried player between the black and the unit (a few seconds, while
    the unit streams in) counts as climbing, so a wipe can't land in that gap: decide whether it
    should. The results' "lost on floor N" for a carried player should be the floor they're
    kept on, not the one they were left on (`ClimbFate`). Playing alone: one catch still ends
    it. Studio's "CutFree" let-in for a watcher still stands you in the lobby (S3-03 owns it).
    Spec the rules; one-player checks with a stand-in friend (STUDIO.md "Testing left behind").
- [x] **S3-02 Purchases that are never lost.** Split for size (D-206); done Nov 15 (D-207). The moment: a player pays
  Robux and gets it at once, exactly once, never lost, even when a save fails or they change servers.
  - [x] **S3-02a The save's ledger and the product table** (Nov 15, D-206). The pin moved to Brix
    `5cdb8c2`; the save's version 2 (`purchases`, `recipients`, `bought`); `Products` (each row's
    Dashboard title, live switch, grant; the owner's "Test purchase"); Record's plan takes Brix's
    `shopViewed` and `offerBought`; `tests/products.spec.luau` runs Brix's Purchases over the
    game's own save: granted once, a repeat, a failed write, a hop, switched off.
  - [x] **S3-02b The server takes receipts** (Nov 15, D-207). `Purchasing`: product ids found by
    Dashboard title, Brix's Purchases and `PlayerPurchases` over `Saving`'s saves, `prompt`,
    `granted`, `shown` (Recording's `offerShown`); `Live`: LiveConfig over ConfigService for the
    switches; Workspace's `DevPrompt` and `DevSaveFails`, Studio's `DevReceipt`. Seen in Studio
    Play with made-up receipts: granted once, a repeat ignored, a failed write waited and then
    granted once, a switch taking the offer off sale. A real purchase, a hop and the switch from
    the Creator Hub wait on `OWNER.md` (also Brix's ENG-23e).
- [x] **S3-03 Cut Free, Free a Friend, Free Everyone.** Offered only on the screen you see
  while caught, and Free Everyone before the results when the whole team is wrapped. Cut Free
  while you're being carried up stands you in the car at the next floor. Split for size:
  - [x] **S3-03a1 Cut Free sold and used, on the server** (Nov 15, D-220). The `Cut Free`
    product row; the save's version 3 holds `spares` (paid, not yet used); `CutFrees` takes the
    press (`Remotes.CutFree`, or the watch bar's), spends a spare or puts up Roblox's prompt, and
    on the grant frees you: wrapped, the film rips and the door hauls itself up, padlock or
    not; carried up, you stand in the car once it reaches the next floor. A grant that lands
    once you're free waits as a spare. Seen in Studio Play: a made-up receipt granted and kept
    as a spare. The catch-then-free walk waits on S3-03a2's Play test and `OWNER.md`.
  - [x] **S3-03a2 The Cut Free button on the caught screen** (Nov 15, D-221). A warm pill eases
    in a beat after Bang, left of it (a thumb's width clear on a phone; F under it on a computer,
    Y on a gamepad), only while `Remotes.CutFree`'s `On` is true; the watch bar's button is the
    same pill on the same flag. A press springs, clicks, asks the server and dims it while the
    prompt is up; freed, both buttons fade. Seen in Studio Play: a catch freed by F with a spare
    from the save (no prompt), a second freed by a click (Studio's free path) with no bang sent,
    the door up and the walk out; the phone layout at 844 by 390. The real purchase, a phone and
    the watch bar's press wait on `OWNER.md`.
  - [x] **S3-03b Free a Friend** (Nov 15, D-222). The `Free a Friend` product row (bought for a
    friend, granted as a spare in the buyer's save); `Remotes.FreeFriend` takes the friend's
    UserId, checked (rate, a whole UserId, in this server, not you, caught), spends a spare or
    prompts with the friend's save key as recipient; the grant frees the friend the sale names
    (cut by the buyer) or waits as a spare. A free player sees a warm pill per caught friend
    under the corner map, their face and "Free" (Y on a gamepad). Seen in Studio Play: the pill
    and a grant with no friend named kept. Freeing a real second player waits on `OWNER.md`.
    Polish not built: the pill doesn't follow the map off screen (the lobby, the feed).
  - [x] **S3-03c Free Everyone before the results** (Nov 15, D-223). The `Free Everyone`
    product row (switch `sellFreeEveryone`, a spare in the buyer's save). Once everyone's caught
    and the offer is on sale, the results wait (`ClimbEnd.WaitAttribute` on Workspace,
    `ClimbEnd.OfferFor` 12 s from the catch, longer while a prompt is open, `OfferPrompt`); every
    caught screen's pill (the caught screen's and the watch bar's) grows into "Free Everyone"
    with a swell and a low click; a press (`Remotes.FreeEveryone`, checked: rate, caught, the
    wipe waiting) spends a spare or prompts; the grant frees every caught player, cut by the
    buyer, or keeps. Alone, the pill stays Cut Free and the end waits on it. Nobody is freed once
    the end's black has begun. Seen in Studio Play: the remote on, a made-up receipt with nobody
    caught kept as a spare, and a stand-in catch (the `Kept` attribute set by hand) holding the
    results 12.1 s, then ending. Not run: a real catch (CatchTest finds no keeper, STUDIO.md),
    the pill's swap on screen, everyone freed by one press; those wait on `OWNER.md`.
    Polish not built: the swap's own sound (now Cut Free's click pitched down).
- [ ] **S3-04 The counter's shop, and wrap colours.** Walk up to the counter and the shop
  opens; a Shop button in the lobby and Roblox's own. Its first shelf: wrap colours, with gift
  versions (GDD "Monetization", D-112). The gifts lean on Brix's gift choices (its E-075 to
  E-078), which wait on `OWNER.md`. Split Nov 15 for the session's size:
  - [x] **S3-04a Wrap colours owned and worn** (Nov 15, D-224). Six colours (Blue, Red, Green,
    Pink, Orange, Black; `WrapColours`), each its own product ("Blue Wrap" ...); bought, it's
    owned for good (save version 4: `wraps`, `wornWrap`) and worn at once; an owned colour is
    never prompted again. `Wearing` (server) mirrors the worn colour onto the Player
    (`WrapColour`), and the film a keeper wraps you in is tinted it (its SurfaceAppearance's
    `Color`), so every screen sees it; the cut-free shreds take the tint too. Seen in Studio
    Play: a version 3 save loaded and saved at version 4; a made-up receipt for `wrapBlue`
    granted, worn at once, and a second prompt refused ("already owns"); all six tints on
    stand-in films read as coloured film at phone size. Not run: a real catch in a colour (no
    keeper awake for CatchTest; `OWNER.md`).
  - [x] **S3-04b The counter's shop screen** (Nov 15, D-225). Walk up to the counter and press
    Shop (a prompt only your screen makes), or the Shop button at the left of the top bar, both
    only in the front office: the shop slides up and deals out seven cards, the plain film then
    the six colours, each a copy of you turning in that film. Buy (the warm pill, with the Robux
    price once Roblox reports it) asks the server, which puts Roblox's prompt up; bought, the
    film snaps tight with a high, short squeal, the rim flashes and the card says Worn. Wear puts
    on an owned colour or the plain film. Seen in Studio Play: the cards painted within 0.6 s of
    opening; Wear on the plain film and a Studio buy of Red each flipped the cards and the
    attribute. Not seen: phone size, a real price, the snap's sound (`OWNER.md`).
    **Polish left:** a gift button on each card once gifts are decided; a "new" glint on colours
    added later; the counter lit a touch warmer while the shop's up.
  - [ ] **S3-04c Patterned wraps** (later, with art): the GDD's "colour or pattern" at the top
    of the price range (caution-tape print, camo, glow in the dark through the SurfaceAppearance's
    `EmissiveStrength`, STUDIO.md), each a texture set made the art way.
- [x] **S3-05 Caught players each in an empty unit of their own** (bugs from the owner's
  three-player playtest, Nov 15; sessions 11 and 12 of the ten-ticket run, after F-G1b). The
  moment: caught or left behind, you wake shut in a unit of your own, wrapped, and bang on the
  door until a friend follows the noise to you and cuts you free. Two bugs broke it:
  - [x] **S3-05a Two players left behind land on top of each other, and can't be cut free.**
    (Nov 16, D-243: on a group's own server Trips stood every new character still on the spawn
    at the car a frame on, and the carry's new character waited on the spawn while its unit
    streamed in; now it's moved in at once and Trips leaves anyone carried or held alone. Seen
    in Studio on a trip server, one player; three players wait on `OWNER.md`.)
    Two players missed the car. On the next floor each watched the ride over the shoulder of the
    friend who made it, as meant; then both woke wrapped on the same spot in front of the
    elevator instead of in units, each one's camera inside the other's body. The third player's
    Cut free said "Get closer" every time and never worked. Should be: each wakes in a unit of
    their own (never the same one), wrapped, with the Bang button, and a friend at the door can
    cut them free. Look at why both missed a unit: the carry's `KeptPlayers:store`, `Kept.choose`
    and the fallback that stands you in the lobby when no unit is free (D-186); whether two
    carries in the same moment can pick the same unit before either is marked as holding
    someone; whether the new floor's units are ready when the pick runs. If the fallback stays,
    it never stands two players on one spot and never leaves a wrapped player nobody can free.
    Reproduce with two stand-ins left behind (STUDIO.md "Testing left behind").
  - [x] **S3-05b A caught friend put in the unit you're standing in.** (Nov 16, D-244: the
    pick now skips any shut unit a player's body stands in, free or caught; Studio stand-ins
    count too. Seen in Studio Play: with stand-ins in 20 of floor 1's 23 free units, six catches
    all landed in the empty three; with 24 of floor 2's filled, a carry landed in an empty one.
    Three real players wait on `OWNER.md`.) A friend was caught and
    turned up wrapped in the shut unit the owner was standing in. `Kept.free` asks only that a
    unit is shut with no monster and no caught player in it, so a free player inside a shut unit
    doesn't count. Should be: the pick skips any unit with anyone inside, free or caught, door
    up or down. A failing Lune spec for the pick first.
  Both: `OWNER.md`'s carried-up steps (S3-01a) become three-player steps that cover these.

### The box you open (the owner, Nov 15, D-205)

Done when opening a box is the moment players come back for. Comes right after S3-02 (the
owner, Nov 15). The moment: a door rolls up on somebody's stuff, and in some units one
box, marked just enough to show something's inside. Opening it is the payoff, built to feel like
opening a blind box (Pop Mart's Labubu, blind-bag squishies): a find lifts out and shows how rare
it is, coins go to your bank, a tool goes to your hands, or it's a piece of the code.

- [x] **B-01a The box, built** (Nov 15, D-208). The marked box in `art/boxes`: a plain Medium
  box, maker's print only, eight parts (body, four flaps, two tape halves, the seam's glow lines)
  on the Cardboard atlas; its Open motion as keys in `Boxes/Specs.luau` (the tape snaps in the
  middle and whips back, the long flaps burst past upright, the end flaps a beat behind); the cue
  (warm Neon lines along the tape, an optional warm light); three sounds in `Boxes.Sounds`. Sheets
  `art/sheets/boxes-marked-*.png`, judged at phone size. Not yet in the place.
- [x] **B-01b The box, in Studio.** Done Nov 15: six templates in the place, the Open motion
  matches the filmstrip in Edit, the cue reads at Level01 and 21 in Play, the sounds load (D-208).
  Was: Upload `Boxes.fbx` (`lune run scripts/upload_art Boxes`, the
  same asset updated), insert it, and make the templates: the five scenery boxes replace those in
  `ReplicatedStorage.Props.Boxes` (they now share the new atlas), the marked box's eight parts go
  in a Model `Marked` there. Write `Boxes.prepareMarked` (anchor, no touches; only the body
  collides, as a box; each part's PivotOffset on its Specs hinge; the seam Neon in the cue's
  colour at Transparency 1) and `Boxes.cloneMarked`. Prove in Edit: the Open motion played with
  `Art.sample` looks like the filmstrip; the seam lit reads at phone size from a unit's doorway
  at Level01 and Level21 (Neon smears at low graphics: STUDIO.md); the three sounds play.
- [x] **B-02 Opening a box: the reveal.** The payoff, built with care and studied from real
  unboxings and game reveals (Pet Simulator's egg hatch; Brawl Stars' Starr Drops, whose colour
  tells the prize before it shows). Press Open: the tape tears, a beat with light leaking
  through the flaps in the grade's colour (blue Rare, purple Epic, gold Legendary, each with its
  own sound: F-G1c's idea, moved to the box), the flaps burst, the find lifts, turns once and is
  yours. Two seconds you can't skip; friends nearby see and hear it, a Legendary further off. A
  Common must still feel good. Feel numbers in Config. Split for size (Nov 15):
  - [x] **B-02a The box opens.** Done Nov 15 (D-209): `MarkedBoxes` (server: `stand`, the Open
    checked by `Opening.refuse` and `allow`, stamped `OpenedAt`/`OpenedBy`, `opened` signal),
    `MarkedBoxView` (every screen: the lit seam, the hum and one warm light while shut; the open
    from the stamp, the rip and slap on their beats), `Boxes/Opening.luau` (pure, specced);
    Studio's Workspace `DevBox` stands one in the next unit that opens. Verified in Studio Play.
    Was: A marked box answers "Open" (server-owned: alive, in reach, not
    through a shut door, rate-limited, opened once); every screen near it plays
    `Specs.Marked.Motions.Open` with the tear and flaps sounds on their beats; the cue's lines and
    hum go as the tape tears. Until B-03 deals boxes, a Studio-only way stands one in a unit.
  - [x] **B-02b The find comes out.** Done Nov 15 (D-210): the server stamps the find and grade
    with the open (`Find`, `Grade`, `LaidAt` before `OpenedAt`) and gives it at `Opening.handAt`
    (`Slots.give`, or laid beside the box for full hands); screens hold the flaps for the grade's
    hold, trembling and rocking, a Neon glow and one light in the grade's colour building, its
    own sounds (`Boxes.Reveal`), then the find's copy rises, turns once and flies to the hand.
    Verified in Studio Play (a Rare into the hand; a Legendary's hold captured).
    Was: The beat of light in the grade's colour leaking through the
    flaps with its own sound, then the find lifts, turns once and is yours; friends see and hear
    it, a Legendary further off. A Common must still feel good. B-02a's open runs straight from
    the tear into the burst (0.1 s, then 0.16 s): the grade's beat needs a hold between them on
    screens (HANDOFF's steps).
- [x] **B-03 What's found comes in a box.** Done Nov 15 (B-03a, B-03b). The deal puts a unit's find, tool or coins (one or
  more) in its one marked box instead of loose on the floor; coins go to the bank as they do
  now, a tool to your hands. Most units show somebody's stuff you can't use (a mattress, stacked
  boxes, a rug: D-136's dressing, now in most units rather than half the empty ones); some stay
  bare. Big finds stay out of boxes. Split for size (Nov 15):
  - [x] **B-03a A unit's find or tool comes in its box.** Done Nov 15 (D-211): `Deal.packs`
    (pure, `tests/boxdeal.spec.luau`) says what packs into the marked box turned any way, the
    cardboard's `Deal.BoxWall` off each side; Deals stands the unit's one box where a find would
    stand holding it (`layBoxed`), else lays it loose as before. 16 of the 23 built finds pack
    (every Common, Uncommon and Epic but the boombox, TV and desk lamp; four of six Rares) and
    of the tools only the padlock; no Legendary or Secret fits today (`OWNER.md`). `DevBox`
    now deals the next unit any find or tool in a box, whatever its size. Verified in Studio Play.
  - [x] **B-03b Coins in boxes, and somebody's stuff in most units.** Done Nov 15 (D-212): a
    unit's coins go in its box with its find or tool, else in a box of their own (beside a big
    loose find, or alone); loose on the floor only where no box can stand. The opener's count
    takes them with the open (`Coins:pay` "box") and waits while each coin jumps out of the box
    at the burst, fans out round the find and flies in, ticking (CoinView). Somebody's stuff in
    7 of 10 units with no keeper or note (`Deal.StuffShare`, read from the scrambled pick, no new
    draw), laid last clear of all else (`DealSpot.stuff`'s `taken`). The battery stays loose.
    Verified in Studio Play on seed 2000013 (Units 301, 312, 319).
    Was: A unit's coins come in its
    box (alone, or with its find or tool) and go to the bank as the box opens; somebody's stuff
    (D-136) in most units rather than half the empty ones, beside a box or alone; some bare.
- [ ] **B-04 The code's notes in boxes.** A note is no longer on a unit's back wall (D-044): it's
  in a marked box. Take it and carry it; hold it up to read it (D-045). Drop it in the car and it
  stays by the keypad for anyone to read, so a team gathers the pieces there (as DOORS' library
  hands you its hint books to carry). Caught holding one, it drops where you were caught.
  Split for size (Nov 15):
  - [x] **B-04a A note comes in a box.** Done Nov 15 (D-213): a note's unit is dealt no find or
    tool (`Deal.noteIn`); its box holds the note and its coins (`layNoteBox`, back wall only if no
    box stands); the note's reveal (`Opening.Reveals.Note`) flies the paper to the opener's eyes
    and lifts the card; the pocket (`NoteCard.Held`) keeps it, a paper at the screen's left edge.
    Verified in Studio Play (Unit317, seed 2000013). Was: The note's unit has its one marked box with the note in
    it (and its coins), never a note on a back wall; the open's reveal is the note's own, lighter
    than a find's (a paper flap, a warm glimmer), the paper rises, turns and flies to the opener,
    and lifts onto their screen as D-045's card. They keep it in a pocket of its own, not a
    hand: a paper tucked at their screen's edge that holds it up again on a tap.
  - [x] **B-04b Carry it to the car.** Done Nov 15 (D-214): the pockets are a server system of
    their own (`Pockets`); walk up to the keypad holding notes and they fly onto the wall beside
    it in a row with a tack's tap, each with its Read button; caught or leaving, they tumble out
    flat on the floor where you were, and a friend's Take pockets them. Polish later: the pocket
    paper slides off the screen's edge toward the keypad as it goes (today it just goes).
- [ ] **B-05 Packed units.** Some medium and large units (about one in three, more on higher
  floors) are boxes stacked to the ceiling with a path through to the back, where the marked box
  or a sleeping monster waits, never nothing. Art first (each stack a few models, for low-end
  phones); the camera in a narrow path judged at phone size. Small units stay open.
  Split for size (Nov 15):
  - [x] **B-05a The stacks' art.** Done Nov 15 (D-215): seven blocks of moving boxes, each one
    MeshPart of 84 to 326 triangles wearing the boxes' own Cardboard texture (three columns to
    the ceiling, two wide stacks on a wardrobe box laid down, a half-height stack, a fallen pair),
    built by `art/packed/` and in the place at `ReplicatedStorage.Props.Packed` (`Packed.clone`).
    Sheets: `art/sheets/packed-*.png` (a sample packed unit from the doorway, in the path, at
    the clearing). No floor deals them yet.
  - B-05b The deal and the path, split for size (Nov 15):
    - [x] **B-05b1 The layout and the deal.** Done Nov 15 (D-216): `PackedLayout.lay` (a path 3
      wide up the middle from the doorway, one bend at the back into a clearing about 3 deep the
      doorway can't see, 9 to 11 blocks, at most about 2,100 triangles) and which M units pack
      (`Deal.packedShare`: 0.3 on floor 1, rising 0.02 a floor to 0.5; `deck.packed`); a packed
      unit holds no stuff and is never empty (`Deal.PackedCoins`). Specs:
      `tests/packedlayout.spec.luau`, `tests/packeddeal.spec.luau`. Nothing laid in the place yet.
    - [x] **B-05b2a The stacks on the floor, in code.** Done Nov 15 (D-217): `Deals` stands a
      packed unit's blocks as its door first lifts or a saw's hole goes through (`layStacks`),
      before anything it holds; everything it holds stands in the clearing (`DealSpot.Unit.room`,
      `stacks`), the marked box just round the bend (`lure`), a sleeper at the hidden end
      (`nook`); the corner's low stack stands last, only where nothing else does (`layCorner`).
      Keepers' map: the unit is its path and its clearing joined at the bend (`KeeperMap.pack`).
      A crawl hole into a packed unit has no Crawl button. Spec `tests/packedwalk.spec.luau`.
      Passes checks, untested in Studio.
    - [x] **B-05b2b Walk a packed unit in Studio** (D-218). Seen in Play on floor 3 (seed
      2000013): Unit302's stacks stand true, its path one dark squeeze; Unit316's Mannequin woke
      to a horn, turned at the bend and came down the path's middle, through no stack. The box
      round the bend hid wholly from the doorway: a box with no guard now peeks 0.4 into the
      path's line (`PackedLayout.Peek`; passes checks, its look untested in Studio: Studio
      stopped drawing frames). The phone camera and the saw's missing Crawl button are the
      owner's (`OWNER.md` "Walk a packed unit").
      - [x] Polish: a sleeper walked through the box in its clearing (the code's note, or
        coins) on its way to the bend: the clearing is too shallow to step round it. Fixed Nov 15
        (D-219): the sleeper stands just round the bend, side-on and facing the path, its floor
        flush with the path's line; the box goes behind it at the far end, and nothing laid after
        it goes on the path's end. `tests/packedwalk.spec.luau` walks 169 sleepers past their
        boxes. Passes checks, untested in Studio (`OWNER.md` "Walk a packed unit", step 4).
      - [ ] Polish: a guard's box (padlocked) still hides wholly round the bend; a sound or a
        glint from it would be its lure.

### Step 4: The climb with no top

Done when two climbs in a row feel different and players talk about their best floor.

- [x] **S4-01 Floors made by rules, to floor 100.** One table says for any floor number what
  it holds and how hard it is (GDD "Floor rules"); the climb no longer ends at floor 3 (D-106).
  Room left for floors that play differently. Split Nov 15 for a session's size:
  - [x] **S4-01a The rules table and the top gone.** One pure table (`FloorRules`, Lune-tested)
    answering, for any floor number, what `Deal` and `Climb` read today from fixed numbers; the
    climb goes on past floor 3. The escape ("Made it") keeps its code but has no trigger; note it.
    Done Nov 15 (D-226): `FloorRules.at(n)`, four named steps (floors 1, 3, 5, 6) and the packed
    curve, today's numbers unchanged; `Climb.Top` and `Building` gone; floor 3 rode to floor 4
    and floors 5 and 101 laid in Studio Play. Passes `tests/floorrules.spec` to floor 300.
  - [x] **S4-01b What changes floor to floor.** The table's rows actually change the floors as
    you climb (more units, more monsters awake, fewer notes), each step named in the table.
    Done Nov 15 (D-228): six steps past floor 6 ("More doors" 8, "Four loose" 10, "Big floors"
    12 with a third plan, "Two notes behind padlocks" 15, "More doors still" 20, "Five loose"
    25), then it holds; the notes stay four (`OWNER.md` decides). Floors 8, 11 and 25 laid in
    Studio Play, 11 rode to 12; laying's worst frame is 6 ms.
- [x] **S4-02 Monsters by lowest floor.** Each monster's row carries the lowest floor it can
  appear on; above it the game mixes it in at random. The moment: last climb you lifted a door
  on floor 3 onto the Packrat asleep on its pile; this climb floor 3 is only Mannequins, and it's
  waiting for you on floor 4. Done Nov 17 (D-401): each row has `lowest` and `share` (the
  Mannequin every floor, the Packrat from 3 on about three floors in five); `KeeperMix.on` rolls
  each floor's monsters from the climb's seed and the floor's number, a floor version can lean it
  (bring a monster or keep it away), and a floor always keeps one that hunts; the deal places
  only the floor's monsters. Seen in Studio Play: floor 4 of climb 7 had only Mannequins, of
  climb 4 the Packrat on its pile too. `tests/keepermix.spec.luau`.
- [x] **S4-03 The choice on the elevator's buttons.** Three buttons light up on the car's
  panel, each a version of the next floor and what it pays; most presses wins, a tie at random;
  it lasts that one floor (GDD "The team's choice"). A version that brings or keeps away a
  monster passes a lean as `KeeperMix.on`'s third argument (D-401). The owner calls them the
  next-floor cards: the mechanic that makes no two climbs the same. Done Nov 18 (D-403 to
  D-413): on every ride from floor 2 up, three picture cards slide up as the car lurches off;
  the team taps them (heads on cards, most wins, a tie at random) and on the cable's second
  knock the winner flares, rides with you and flies into the next floor as its gate opens. The
  four versions (the power's out, twice the monsters, twice the padlocks, caught goes back to
  the lobby) each change that floor as promised and pay their own pop at its gate. All seen in
  Studio with one player; left for the owner (`OWNER.md`): the vote with a friend on phones,
  two players on the back-to-the-lobby floor, and the defaults listed there. Split Nov 17 (D-403):
  - [x] **S4-03a The versions and the vote.** The moment: the car lurches off, friends jab at
    three versions of the next floor and change their minds; on the cable's second knock the
    winner is the floor the car stops at. Proven: a lobby's map vote (most presses wins, a tie at
    random); Deep Rock Galactic's warnings (harder, pays more). A pure table of versions, three
    dealt from the climb's seed and floor, the vote's count; the server's vote on the riding car
    (one press per rider, changeable until the knock, checked and rate-limited); the floor's
    halls built at the code as before, its deal (padlocks, mark, breaker, monsters) put on as the
    vote ends, with the winner. Done Nov 17 (D-403): `NextFloor` (four versions, `deal`,
    `winner`, `payOf`), `NextFloors` (the vote, the `NextFloorPress` remote), Climbs' `build`,
    `pick` and `deal`, `FloorBuilder.dress`. Passes checks, untested in Studio: b starts with a
    ride in Play. `tests/nextfloor.spec.luau`.
  - [ ] **S4-03b The cards on the panel.** The moment: three lit cards on the car's panel, each a
    picture of its floor and its coins; a press clunks, lights the card and puts your mark on it;
    on the knock the losers go dark and the winner flares and stays lit to the floor. Proven:
    Hades shows each door's reward before you pick. Split Nov 17 (D-404):
    - [x] **S4-03b1 The faces.** One picture per version, rendered from the game's own models
      (`art/cards/`), each in its own colour of light, uploaded; each row's `face`. Done Nov 17
      (D-404), and S4-03a's vote seen working live in Play (floor 1 to 2: offer, a press, a
      change of mind, junk ignored, "picked TwiceMonsters" on the knock).
    - [x] **S4-03b2 The cards on the panel.** Three cards slide up from the bottom as the car
      lurches off (screen-space, as the lobby car's panel does), each its face, its coins
      (`NextFloor.payOf`, the coin icon) and a short name at most, big enough to tap at Galaxy
      A16 size; a press clunks, lights the card and drops your avatar's head on it (every
      rider's, from `NextFloorPresses`, so friends see the vote move); on the knock
      (`NextFloorPicked`) the losers go dark and the winner flares and stays lit until the gate
      opens on the floor (the riders change cars at 13.4 s: keep the cards up across it).
      Reads the riding car's attributes, presses `NextFloorPress`. Captures into `docs/art/`:
      the three lit, a mark on one, the winner flared.
      Done Nov 18 (D-405): `NextFloorCards` (pure: layout, heads, phase;
      `tests/nextfloorcards.spec.luau`), the client's `NextFloorView`, each row's `light`, the
      wheel stowed under them (`Tools.CardsStowAttribute`). Seen in Studio Play on the A16, floor
      1 to 2: the three up, a real tap lighting TwiceMonsters with my head on it, friends' heads
      (stand-in presses), a change of mind carrying my head to PowerOut, and on the knock PowerOut
      alone in the middle, lit; Output "picked PowerOut". Captures `docs/art/S4-03b2-*.jpg`. Not
      seen: the flare's first half second, the cards across the 13.4 s car change, the coin strip
      after it was made bigger (S4-03d).
  - [ ] **S4-03c Each version felt on its floor.** The moment: the gate opens on a pitch-dark
    lobby, or two Mannequins at the end of the hall. Floor model's `FloorVersion` attribute says
    which. Split Nov 18 (D-406):
    - [x] **S4-03c1 The deal reads the version, and the gate pays it.** Twice the padlocks
      (exactly twice a plain floor's count), twice the monsters (twice the sleepers, twice the
      awake ones behind a lifted door, twice as many loose, `Waking.cap`, never past five, the
      Packrat brought by the lean), and the version's coins in the gate's pay (`Pay.owed`'s
      `picked`). Done Nov 18 (D-406): `Deal.Bend`, `tests/floorversion.spec.luau`. Seen in Studio
      Play, seed 7: floor 2 picked twice the padlocks (3 against a plain 2: it rounded the
      doubled share then; now it doubles the count, by spec, not seen), its gate paid 18 (12 and 6); floor 3 picked twice the monsters: Mannequin and Packrat, 9 asleep, 4 loose
      at most. The coins pour with the floor's own until c2 gives them their pop.
    - [x] **S4-03c2 The arrival and the version's pop.** Done Nov 18 (D-407): seen in Studio
      Play at A16 size, floor 1 to 2 (the card flew in, the hall lit green, the wash caught
      fading) and the pop fired from the server with floor 2's numbers (captures
      `docs/art/S4-03c2-*`). Polish: the pop's card picture reads dark at 50 px (brighten or
      frame it); catch the arrival's flight mid-air in a capture (S4-03d). The moment: the gate rises and you know
      which floor you chose before you see it: the winning card leaves the screen into the
      floor in its own colour of light with its own sound (no words), as Hades' door reward
      flies to you as you walk through. At the gate, the version's coins burst as their own pop
      in the card's colour after the floor's pour and the traps' (`Pay.parts` gets a third part;
      the remote sends the version's name and coins; CoinView). Read `NextFloorView`'s exit
      (the cards leave as the gate opens, D-405) and CoinView's trap pops (D-402).
    - [x] **S4-03c3 The power's out.** The gate opens on dark halls and dark units; the floor's
      breaker (S2-02) brings the lights back, as Lethal Company's breaker brings a facility's
      power back; the version still pays. Done Nov 18 (D-408): the box hung thrown, the floor's
      `FloorPower`, `NextFloor.dark`, UnitLights' power, Keepers' `cut`; `tests/powerout.spec`.
      Seen in Studio Play (seed 7, floor 1 to 2): 17 hall lights cut, the lobby black, the box's
      red glow, a lifted door's bulb dead, the real hold bringing it back (captures
      `docs/art/S4-03c3-*`). Polish: catch the halls' flash as the power returns (they read
      powered and dark 3 s after, S4-03d); the gate rising on black, frame by frame (S4-03d).
    - [ ] **S4-03c4 Caught there goes back to the lobby.** A catch on that floor takes you out of
      the climb to the lobby (not wrapped for friends to free); friends left on the floor carry
      on. Split Nov 18 (D-409):
      - [x] **S4-03c4a Down the shaft to the lobby car.** Done Nov 18 (D-409): `ToLobby` (shared,
        server, `ToLobbyView`), `tests/tolobby.spec.luau`. The lunge as any catch, then the card's
        picture rushing up out of the black, the gate's slam and a jolt, and the black lifting in
        the lobby car the climb left from, with its ding; the end counts you caught on that floor
        (`ClimbEnd.look`'s `sent`); Trips never stands you back in the climb. Seen in Studio Play
        at A16 size: the screen's whole timeline, driven by the sent-down marks from the server
        (captures `docs/art/S4-03c4-*`). Not seen: a real catch there and the server's swap
        (floor 1 has no monsters; a ride to floor 3 didn't fit): `OWNER.md`.
      - [x] **S4-03c4b Friends see you taken.** On friends' screens the caught body is dragged
        down through the floor in the card's red light with its low hit, as a Dead by Daylight
        survivor is taken. Done Nov 18 (D-410): `ToLobby.drag` (spec in `tests/tolobby.spec`),
        the client's `ToLobbyDrag`: the red light and pool coming up as the lunge comes, the
        yank as the hands close, the drag from the cut to black, under at the landing with a far
        slam, the name tag hidden once under; the film's screech no longer plays for these
        catches (KeptWrapOn). Seen in Studio Play at A16 size on floor 3 set to the card: a
        stand-in friend dragged (held frames by `DevCatchHold`, put back when the mark came off)
        and a real Mannequin's catch through `CatchTest`: the fall, Output's "back in the lobby
        car", the black lifting in the car (captures `docs/art/S4-03c4b-*`). Two players:
        `OWNER.md`. Polish: a falling rush under the fall (no wind sound in the project yet).
      - [x] **S4-03c4c The car waits for your team.** Done Nov 18 (D-411): the car you land in
        stands open and never counts down while your team climbs on (LobbyCars never takes a
        sent-down player into a car's group); it hums low from its ceiling, coming up under the
        ding (`ToLobby.Hum`, spec in `tests/tolobby.spec`); the dial over its gate shows the
        team's floor (LobbyCars' `teamCar`, every server; ToLobby stands you in that car). The
        count was only Studio's test hall: a group's own server never counted. Seen in Studio
        Play at A16 size on floor 3 set to the card: a real catch, 25 s in car 1 with no group
        and the keypad at rest, the dial reading "Floor 3", the hum at 0.35, then the end
        clearing the mark, the dial and the hum (captures `docs/art/S4-03c4c-*`). Not seen:
        Again standing the team back in a trip's own car (test hall: a fresh floor 1); two
        players: `OWNER.md`. Polish: the team's faces in the dial's seats while they climb, and
        the floor on the car's inside readout too, so you see it without stepping out.
  - [x] **S4-03d The whole climb in Studio.** Ride floors 1 to 5 in Play with the cards, each
    version picked once, captures; fixes. Two-player vote and phones go to `OWNER.md`. Split
    Nov 18 (D-412):
    - [x] **S4-03d1 The held ride and three cards ridden.** Done Nov 18 (D-412): `DevRideHold`
      stepped through floor 1's ride (the cards and coin strip at 4 s, the flare caught on floor
      3's, the cards kept through the car change, the flight into the gate); floors 2 to 4 picked
      the power out, twice the monsters, twice the padlocks, each floor as promised, the pops at
      floors 2 and 3's gates. Fixed: the arrival's light flooding the car (`NextFloorView`).
      Captures `docs/art/S4-03d-*.jpg`.
    - [x] **S4-03d2 The back-to-the-lobby card on a ride.** Play from floor 1 (seed 7; floor 3's
      ride offers it, or floor 5's): pick caught-to-the-lobby, see the arrival with the tamed
      light (burst running before the 19.6 step; capture it), its floor's red, a catch there
      (STUDIO.md's c4b recipe), and its pop at the gate if the team gets out. Then the
      twice-the-padlocks pop at its gate, and one look at the halls coming back on the
      power-out floor with the camera down a hall (not at the box's wall). Done Nov 18 (D-413),
      nothing needed fixing: from floor 2 (seed 7) a tap on the middle card picked it; floor 3
      arrived with the red wash and ring, the hall past the gate glowing red for about a second
      and a half while the car kept its own colour; a real catch there sent me down the shaft into
      the lobby car. A second Play picked the power out for floor 3: its breaker's hold brought
      the hall back as one ragged wave inside 0.3 s; then twice the padlocks for floor 4 (10
      padlocked) and its pop at the gate after the floor's pour (paid 24). The pop on a floor
      where a friend was sent down is the riders' to see: two players, `OWNER.md`. Captures
      `docs/art/S4-03d2-*.jpg`.
- [x] **S4-04 Trapping pays** (Nov 17, D-402). Each monster the team has shut in a unit as the
  gate shuts pays everyone aboard 5 more coins (`Pay.Trap`, D-188; Keepers' `trappedOn`); one
  freed first, or one the floor woke behind its own door, doesn't count. On your screen each
  pops after the floor's pour, beside it: a muffled bang, a chink, five coins to your count, the
  "+10" swelling to "+15", "+20". A trapped one now keeps its place in the deal's cap of awake
  monsters (`awakeOn`), so trapping never frees a door for a fresh one to trap again.
  `tests/pay.spec.luau`, `tests/shuttap.spec.luau`. Seen in Studio Play: three pops land in
  turn, "+10" to "+25" (fired by hand; a real trap and ride waits on `OWNER.md`).
- [x] **S4-05 The big find** (D-414 to D-419). Now: from floor 2, the code going in rolls up a
  unit down the halls by itself and the jukebox stands in it; a pink diamond on the corner map
  says where; one friend hauls it slowly in both arms; held or set down in the car as the gate
  shuts, everyone aboard is paid the floor's pay again with its own lit pop and tune; left, its
  tune winds down far below. Seen in Studio with one player. The ticket as written: a unit
  rolls up by itself and its place shows on the corner map. Carried in both hands, slower than
  any monster, no tools; it counts only if it's in the car as the gate shuts (Lethal Company's
  heavy scrap and the apparatus). Its art first. Split (D-414):
  - [ ] **S4-05a The jukebox's art.** The moment: the door rolls up on its own and there it
    stands in the dark, taller than you, its arch of coloured plastic and chrome grille plain
    from the far end of the hall on a phone. The first of F-12's eight, the one the design doc
    names: a new finds set, `art/finds/big/`, made the finds' way (`PIPELINE.md`, `CRAFT.md`),
    its glow off as found and on when played, its record on its own turntable. Its game row is
    written but not ticked built: a ticked find joins every unit's deal, and a big find is dealt
    only by a floor's big-find place (piece b).
  - [ ] **S4-05b The big find on the climb.** Split (D-415) into b1, b2, b3:
    - [x] **S4-05b1 The deal and the door** (D-415). The jukebox imported; from floor 2 the
      code going in rolls up a unit nobody has opened, down the halls when one is left, by
      itself with the door's rattle, and the big find stands alone in it with its Take prompt
      (`BigFind`, `BigFinds`, `deck.big`); its grade rolled Epic 75, Legendary 22, Secret 3 with
      the jukebox standing in; ticked built in `WAVES.md` but never in a unit's own deal; carried
      in both hands (`bothHands`). Seen in Studio on floor 2 (Unit228).
    - [ ] **S4-05b2 Its mark on the corner map, and the haul.** The moment: the mark pops on
      the map with a ring as the door rolls up, so everyone knows where; one friend hugs it low
      so they see over it and walks slower than any monster. The map's mark from
      `BigFind.SlotAttribute` on the floor model (as MinimapView's bang dot: ring, held on the
      edge while off the window; it follows the find once taken, or goes); its own hold (low,
      in both arms) and a walk speed under every monster's (the catalog's `walkSpeed`, as the
      ladder's); check the drop where you're caught and the pick up again (Slots already does
      both for two-handed finds). Split (D-416) into a and b:
      - [x] **S4-05b2a The haul** (D-416). One friend staggers out with the jukebox held low,
        every step slow and heavy (a thud per step, its rattle), at 9 a second, under every
        monster's hunt; a press of a tool answers with a shake and a thunk, never words; every
        small and medium unit has room to stand it (`Haul`, `HaulSteps`, the "Big" size).
      - [x] **S4-05b2b Its mark on the corner map** (D-417). A pink diamond pops in on its
        unit with three rings as the door rolls up, held on the window's edge while off it;
        round the hauler's dot while carried, where it lies once dropped, a ring each time;
        gone once kept, lost or in a monster's arms (`BigFind.mark`, `rings`; BigFinds' where).
        Seen in Studio on floor 2. Polish: a far-off ping as the mark pops, if the door's
        rattle doesn't carry (the owner's call, OWNER.md).
    - [x] **S4-05b3 Counted at the gate** (D-418). In a rider's arms as the gate shuts, the hauler
      keeps it (its worth into their save) and everyone aboard is paid the floor's pay again
      (`Pay.bigOf`); last of the pay's pops, the jukebox punches up dark over the pour, its glow
      stutters on with its swing tune, and it bursts into its coins, lit in its amber. Left
      anywhere else, every rider hears its tune from far below, muffled, winding down. Passes
      checks, unseen in Studio (S4-05c sees it).
    - [x] **S4-05b4 Set down in the car, it still counts** (D-419). The design doc counts it "inside the
      elevator" as the gate shuts, but today a find lying on the car's floor goes with the floor,
      so a hauler who sets it down in the car to grab a tool loses it. As the gate shuts, take it
      off the car's floor (Climbs' `inCar`, a Slots take of a lying find with its glint) and keep
      it for its last hauler if they ride, else the rider nearest it; it pays as one held.
  - [x] **S4-05c The big find seen in Studio** (D-419; `docs/art/S4-05c-*.jpg`). The moment: from floor 2's keypad, see the unit
    roll up, its mark on the corner map, carry the jukebox to the car, and watch the gate pay
    it. Captures to `docs/art/`; the two-player run (one hauls, one guards) in OWNER.md.
    Seen on floors 2 to 4 of seed 7: the roll-up, the mark held on the map's edge, the take
    (walk 9), set down in the car and kept (24), held aboard (35, the pop and coins), left
    behind (its tune muffled and winding down). Fixed: both tunes start at the band's swell
    (1.4 s), and analytics now knows the big finds (the jukebox's kept record was dropped).
  - [ ] **S4-05d Leftovers.** A hauler who dies with no body left (fell out of the world) drops
    what they hold at the world's origin (Slots' `dropAll`, `Vector3.zero`), far off any floor.
    A kept jukebox stands on a home shelf spot like a small find (GatePay's `Save.keep`, D-284):
    the home's to give big finds a floor spot. The walk back from the unit itself was never
    walked (pivots only): the thuds and the view's dip are OWNER.md's.
- [ ] **S4-06 The marker.** Sold in the machine. Face a door and tap Mark: a bright mark the
  team sees down the hall and on the corner map. Five marks. Its art first.
- [ ] **S4-07 On sale.** A starting tool for cash during the car's countdown, flashlight beam
  colours, and a fourth, fifth and sixth slot (this is L-20b).

### Step 5: After the climb

Done when players watch the results to the end and change their perks between climbs.

- [x] **S5-01 Finds valued one at a time** on the results: picture, name, how rare, what it's
  worth, the haul's worth counting up (the cash comes when you sell at your chest, D-251); then
  a line for each player. The moment: back in the lobby car after a climb, the team stands facing
  the board on its back wall and watches the haul flip up card by card, cheapest first, the
  total ticking with each, a Secret landing last with its own sting, then everyone sees who
  carried what. Proven: Lethal Company's end-of-day scrap tally, Hades' end-of-run summary.
  Never drags: a tap skips ahead, a long haul speeds up, all inside the car's 20-second count.
  - [x] **S5-01a The haul's order and timing, and the server's list** (pure, Lune specs first).
    Done Nov 18 (D-428; `Tally`, tests/tally.spec): passes checks, not seen in Studio (the
    Output line waits for S5-01d's ride back to the car).
    `Tally`: each find kept on the climb as a card (name, grade, what it sells for at the chest:
    sealed 3x, cracked half, the jukebox's own worth), cheapest first; each card's moment (a
    long haul's cheap cards quicken, the last three and every sting card keep their beat); the
    total at any moment; where a tap skips to (the next sting card, else the end); the list sent
    with the car's results. GatePay's kept event tells ClimbEnds each rider's own finds (not a
    friend's taken from home); ClimbEnds gathers the climb's haul and puts it on the board's
    value. Studio's Output prints the haul as the group is stood back in the car.
  - [x] **S5-01b The cards on the board.** Done Nov 18 (D-429; CarResults' haul page, `Tally.row`,
    `docs/art/S5-01b-haul-*.jpg`): seen in Studio Play at A16 size with a set haul (sealed, cracked,
    Legendary, Secret) and a tap skipping ahead; not after a real climb (S5-01d) nor heard by ear.
    The moment: each card flips up big in the board's
    middle (its 3D picture, name, the grade's colour, its worth), then drops into the row below
    as the next comes; the total ticks with a rising chink; a sting card (Secret, Legendary,
    sealed, the jukebox) lands with a hit, a flash in its grade's colour and a beat of quiet. A
    tap anywhere skips ahead (the cards between land at once). One picture drawn at a time
    (phone budget). Its sounds named and measured.
  - [x] **S5-01c Each player's line.** Done Nov 18 (D-430; `Tally.lines`, CarResults'
    `teamLines`, `docs/art/S5-01c-*.jpg`): seen in Studio Play at A16 size with four stand-in
    friends (a Secret, the jukebox, a $0 line); not with two real players nor heard by ear.
    After the total: the page turns, the total held at the top, and each friend's line slides in
    with a soft knock (their photo, name, a chip a find, a Secret or the big find called out by
    name, their worth), filling from the bottom so the best lands last on top with a glint and a
    gold edge; a tap brings the rest in. Every page now ends above the phone's round button.
    Not built: the proposal's deeds (who freed the most friends, opened the most doors, shut a
    friend in a unit): they need counting on the server and read as ranking (`OWNER.md`).
    Polish: the called-out find's small 3D picture (six viewports on a phone, a budget check);
    the stage card flying into its owner's line instead of the page turning.
  - [x] **S5-01d Seen in Studio.** Done Nov 18 (D-431; `docs/art/S5-01d-*.jpg`): three real
    climbs from the lobby car back to it in Studio Play at A16 size, finds banked at the gates
    (a sealed Teddy, a Legendary, a Secret), ended as a wipe, Again. The results now: the team
    page under the count, the page turning, five cards flipping up cheapest first with the
    total ticking to $7,535 and the Secret's red flash, then the line; a tap mid-haul went
    straight to the lines. Fixed: the camera landed level and left the board's title under the
    top bar and the count; it now turns to the board's middle (`Boarding.BoardHeight`).
    The two-player run and the sounds: `OWNER.md`.
    Fix (next): your own held torch, first person, crosses the board's lower middle (the chips'
    right end, the bottom lines' chips); hide its look locally while you stand facing a board.
    Seen once: the real board is read for ~7 to 12 s after the lines land, the count running.
- [ ] **S5-02 Rarity, and finds still sealed.** Rarer finds on higher floors, in the catalog's
  six grades (Secret on top, from floor 10; D-188); about one in
  twenty still in its packaging, worth three times as much. A padlocked unit's find draws a
  grade better (GDD: "the best chance of something great"; S1-07a left it a plain find).
  F-G1a already deals a grade by the floor (`Grades.Bands`: the catalog's odds for floors 1, 10
  and 25, a step at each), so the pieces are:
  - [x] **S5-02a Better finds every floor up, and the padlock's grade one better** (pure, Lune
    specs first). Done Nov 18 (D-422): seen in Studio Play on seed 7, floors 2, 10 and 12; a
    padlocked door opened by hand is `OWNER.md`'s. The moment: a team that pushes from floor 4 to 8 opens doors on better things
    each floor, not only at 10 and 25, and the padlock you cut on floor 12 is worth the bolt
    cutters, its box's light blue or purple more often than not. Precedents: Lethal Company's
    scrap worth more on each riskier moon, Diablo's deeper levels dropping better items floor
    by floor; Escape from Tarkov's locked rooms holding its best loot. `Grades.odds` climbs
    evenly from one catalog floor to the next (the catalog's numbers stand at 1, 10 and 25;
    Secret none below 10; doubled from 50 as before); `Deal.findFrom` takes how many grades
    better and a padlocked unit's find rolls one better among the grades the floor deals (the
    same pick: the plain roll's grade, one up; a top grade stays top). The same seed deals the
    same floor. Studio's Output names each find's grade and its padlock. No grade shows at the
    door (D-204): the marked box's light already tells it when it opens (B-02b).
  - [ ] **S5-02b Now and then a find still sealed in its packaging.** The moment: a box opens
    on a find still in its blister pack or window box, and you carry it home carefully, worth
    three times the loose one. Precedent: a small chance on any find of a variant worth far
    more, as Pet Simulator's shiny pets and Grow a Garden's gold crops are (Adopt Me and
    Bloxburg have no sealed-in-box premium we know of; the toy collectors' "mint in box" is
    the look, not the mechanic). About 1 in 20 finds rolls sealed (`Deal`, from the unit's own
    pick so the seed still deals it); worth 3x (`Grades`/`Chip.worth` beside the cracked rule);
    kept sealed through the gate (`GatePay`, `Save.keep`'s `sealed` count, already in Save v1)
    and on the home's shelves and selling panel. Its look the finds' art way: one shared
    packaging per find size (a card-backed blister for Small, a window box for Medium, a taped
    carton for Large) in `art/finds/`, its find shown through the window, judged at phone size.
    Defaults for `OWNER.md`: a sealed find takes no press (it's in its packaging) and a hard
    drop tears the packaging, leaving it a plain find (the way fragile finds crack, F-G1e5e).
    Split in two (art, then code):
    - [x] **S5-02b1 The packaging's art.** Done Nov 18 (D-423): the three packs in
      `art/finds/packs/` (the finds kit, no game rows), each fitted round a real find in the
      sheets as the game will fit it (`spec.py`'s `fit`), judged at phone size held and from a
      doorway (`art/sheets/packs-*.png`, `docs/art/S5-02b1-*.jpg`); uploaded, not yet imported.
      `export` also writes `Finds/PackFit.luau` (each pack's room for a find) for b2. A photo
      pass is owed (README).
    - [ ] **S5-02b2 Sealed finds in the game.** The pure part first, with Lune specs: the 1 in
      20 roll from the unit's own pick (the seed fingerprint unmoved for unsealed finds), the
      fit (`PackFit` and `fit`, mirrored from `spec.py`; a find much deeper than wide turned to
      show its side), the 3x worth beside the cracked rule, and whether a packed Large find
      still fits the marked box (else it stands loose, `Deal.packs`). Then the deal, the find
      shown in its pack in the box and in your hands, no press while sealed, the tear on a hard
      drop (the packaging pulled off with a rip and a few scraps, the crack's way), `GatePay` and
      `Save.keep`'s `sealed` count, the home's shelf and selling panel at 3x. First, in Studio's
      Edit view, import the packs (PIPELINE step 6: `Kit.import("Packs")` from a clone of
      `Shared`; the owner saves the place). Split in three (Nov 18, D-424):
      - [x] **S5-02b2a The sealed find's rules, dealt by the seed.** Done Nov 18 (D-424): seen
        in Studio's Edit view (32 of 589 finds sealed over seeds 1 to 20); packs imported.
        Pure, Lune specs first
        (`Finds/Seal`): the 1 in 20 roll from the unit's own pick, the fit mirrored from
        `spec.py` (a find much deeper than wide turned to show its side), 3x worth beside the
        cracked rule, the tear on a hard drop (`Chip.hard`), and whether a packed find still fits
        the marked box. `Deal.open` deals `sealed` on a find (never the big find, the Packrat's
        pile or a note's unit); the seed fingerprint unmoved. The packs imported in Studio's Edit.
      - [x] **S5-02b2b Sealed on the floor: in its box, in your hands, torn.** The find wrapped in
        its pack on the server (every screen, `Seal.fit`, turned when deep), in the marked box
        or loose where the packed size won't box (`Deal.packs`); the box's reveal and your view's
        copy wrapped too (as `ChipView` copies the crack); no press while sealed (the press
        ignored, no copy); a careful set-down's soft cardboard thud; a hard drop tears it (the
        pack pulled off with a rip and a few scraps, the crack's way), a plain find from then. A
        dev pick (`DealFind`) that deals one sealed; seen in Studio Play and captured. A flat
        find (the fairy lights) stood up so its face shows through the window (D-424).
        Split in two (Nov 18, D-425):
        - [x] **S5-02b2b1 Wrapped in its pack, in the box and in your hands.** Done Nov 18
          (D-425): wraps checked in Studio's Edit view, not yet seen in Play (b2). The pose rules
          (pure, Lune specs first: a flat find lies on its back in a blister, a deep one turned,
          how high the pack lifts it off the floor); `Finds/Pack` wraps the server's find and every
          screen's copy (the box's reveal, your hand); sealed carried from the deal through the
          box (or loose) into a slot and back to the floor; a press answered with a crinkle of
          the plastic and a small shake of the pack in your hand (nothing sent, the server
          ignores it too); a set-down's soft cardboard thud in place of the find's clank.
        - [x] **S5-02b2b2 The tear, and seen in Studio.** Done Nov 18 (D-426): seen in Studio
          Play on floor 2 (the monkey and teddy dealt sealed by `DealFind "<key> sealed"`, opened
          from the box into your hand, set down gently with the thud, dropped from high and torn;
          `docs/art/S5-02b2b2-*.jpg`); the press's crinkle not driven from a script (`OWNER.md`).
          A hard drop tears the pack off as it
          lands (the rip, the board and film thrown clear with a few scraps, a plain find from
          then, never cracked in the same drop); `DealFind` deals one sealed; seen in Studio
          Play (in the box, in your hand, the press, the set-down, the tear) and captured.
      - [ ] **S5-02b2c Sealed through the gate and into the home.** `GatePay` and the save
        (`Save.keep`'s `sealed`, its stamp), the kept glint, a trip and a friend's box
        (`Taken`), the home's shelf and placing (standing in its pack), the job box's panel
        selling at 3x (`Seal.worth`), your slot's picture in its pack. Split in two (Nov 18,
        D-427):
        - [x] **S5-02b2c1 Kept sealed, on the shelf and sold at 3x.** Done Nov 18 (D-427): passes
          checks, untested in Studio (S5-02c). A sealed find is kept under a name of its own
          ("Teddy:Sealed", `Seal.key`), as a Gold is, so the shelf and the box know which one
          is sealed; the book's sealed page stamped; it stands in its pack on the shelf, rises
          in its pack as the gate keeps it, shows in its pack in your slot, has its own card in
          the job box's panel ("Sealed Teddy bear", before its loose ones) selling at 3x, comes
          out to your hand still sealed, is never made Gold or worn; one out of your box torn on
          the climb comes back (or moves to a friend) plain (`Taken`'s `torn`, `Save.unseal`).
        - [ ] **S5-02b2c2 Set out in its pack, and a trip's torn one.** Arrange stands a sealed
          one in its pack (the footprint by its packed size, `Pack.outer`; raised by `Pack.lift`;
          the ghost wrapped in ArrangeView); today Arrange's tray leaves sealed cards out and the
          server refuses one (`Spots.Refusals.Unknown`). A trip's `Up` carries a torn one plain
          (one torn in the lobby before a car leaves is sealed again across the trip). The
          Packrat's snatched flyer (ToolView) in its pack. The shelf's fit may turn a pack
          sideways in a cubby: judge it in Studio and keep the window out.
  - [x] **S5-02c Seen in Studio.** Done Nov 18: seen in Studio Play on floor 2 (seed 7). The
    sealed teddy dealt by `DealFind`, opened into your hand in its window box, carried aboard,
    kept at the gate ("kept Teddy:Sealed", rising in its pack in the gold ring), saved as
    "Teddy:Sealed" with the sealed page stamped; at home its card "Sealed Teddy" sits before the
    loose teddy (the panel prices it 12 to the loose one's 4), Gold refused, sent to an empty
    cubby it stands in its box window out, Take puts it in your hand still sealed; torn by a hard
    drop on floor 2 it came home plain (`Teddy=2`, no sealed one, on a leave). Floors 2, 10 and 12
    deal the same twice; 10 and 12's padlocked finds all Uncommon or better. Captures
    `docs/art/S5-02c-*.jpg`. The press's crinkle and the Sell button: `OWNER.md`.
    A sealed find dealt (a dev pick), lifted out of its box,
    carried through the gate and shown on the home shelf and the selling panel at 3x; the
    padlock's better grade on floors 2, 10 and 12. Captures to `docs/art/`.
- [ ] **S5-03 Your home: a unit of your own on the ground floor** (the owner's plan, Nov 16, D-251
  and D-259). The plan is its own Claude Doc, "Your unit: the home in the lobby"
  (https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, read with the docs tools, never WebFetch):
  31 numbered ideas, each a moment, what the player sees and does, and its precedent; its "What
  you decided (Nov 16)" section wins where an idea differs. Built next, ahead of S4-02 (owner,
  Nov 16), by a chain of sessions at 300k context. In this order; a session splits a piece
  further (a1, a2...) when it won't fit:
  - [x] **S5-03a The ground floor** (ideas 1 to 5; the doc's "Where it goes", re-laid). The
    moment: you walk out of the car across the ground floor, every open unit down both walls
    shows someone's finds, and yours has your name over it. a1 the art: `art/lobby` re-laid
    (deeper; six XL unit slots, 20 by 30, down each side wall, their roll-up doors the climb's
    door opening onto the floor; a name card frame over each; a warm bulb inside; the cars'
    wall and bays, front door, counter and cart rack kept), look sheets at phone size,
    `Lobby/Specs` with each slot's door, inside and name card. a1 is split (D-260):
    - [x] **S5-03a1a The ground floor's numbers**: `art/lobby/spec.py` re-laid 156 deep, the
      front's pieces measured off the front wall, 12 slots (`slots`, `slot_rows`), their gaps,
      partitions, backs and tops in the colliders, a name card each, 26 hall lights, the
      Specs writer's `Slots`. Checked by script; `Lobby/Specs.luau` not regenerated yet.
    - [x] **S5-03a1b The ground floor's build and sheets** (D-261): `build.py` to the new spec:
      side walls with a gap per unit (the cap stops at the gaps, the M's own cap fills them),
      the units' shells from the unit kit at XL, the floor out to the units' backs, the joists
      split off the deck, a name card per unit; sheets `lobby-unit` and `lobby-inside` added, the
      M's front, bulb and stand-in boxes in every gap. Export checked (every part under 20,000,
      87,446 triangles); not imported: Specs.luau waits for a2a.
    - [x] **S5-03a2 The floor in the game**, split (D-261):
      - [x] **S5-03a2a Into the game with its unit fronts** (D-262): the new FBX exported,
        uploaded and imported with its Specs (`Slots`); `Lobby.prepare` squares the joists and
        units' parts; `Lobby.front` stands the climb's M unit in each gap (walls, floor and top
        dropped, oxblood door, teal facade, its number on the plate, tagged so the door rolls,
        slams and locks as on a climb, anyone may open it until a3). Pulled in from a2b at the
        conductor's ask: the fills in three rows down the room and each unit's bulb hung as a
        home's (`UnitLight.Home`: stronger, further, no shadow, always real when lit), so from
        the spawn every open unit reads as a warm doorway. Verified in Studio Play: twelve
        fronts, a door rolling, the lit view from the spawn, a car taking you to floor 1.
      - S5-03a2b The home look: calm, welcoming, yours (the owner, Nov 16, D-263). The
        moment: you step out of the car and the building breathes out: soft warm light, a
        finished ceiling, plants by the doors, twelve units that look like little homes rather
        than the climb's lockups; in yours you flick the light switch and it's warm. Split
        three ways (art, art, then the game):
        - [x] **S5-03a2b1 The ground floor re-done calm** (D-264): the home's own baked sets
          (`art/home`: painted plaster, oak planks); oak floor, sage and cream plaster walls
          with a wood baseboard and rail, a finished ceiling on wood beams with 28 round
          lamps and a bulkhead where it meets the cars' steel deck; the units' insides smooth
          plaster with flat ceilings and baseboards; a runner rug to the cars. The cars'
          strip keeps its concrete, deck, joists and hall lights. Exported, not uploaded.
        - [x] **S5-03a2b2 The home's furnishings and front** (art; D-266): the home front kit in
          `art/home` (a clean roll-up door in a warm colour on the climb's door rig, a painted
          frame with no diamond plate, a light switch plate inside by the door); potted
          plants by the doors and benches between units on the ground floor, a couple of
          islands in the open middle; a rug, a beanbag and a floor lamp for every unit.
        - [x] **S5-03a2b3 The home look in the game** (D-268; all but the switch's press, b4): upload and import the ground floor and
          the home front; `Lobby.prepare` paints the new parts (`Lobby.Paint`), makes Lamps
          glow (Neon) and the runner Fabric; the hall lights only over the cars; the home
          front in each gap in place of the climb's M; the switch (Switch; a click; the light
          warms up or down over about 0.2 s; dark with the door down and the light off).
          From b2 (D-266): import `art/home/out/Home.fbx`; the home front's parts per
          `Home.Specs` (the M's door rig with its slats, curtain and bar in HomeDoor, no padlock
          or number plate); each unit's own round Lamp in place of the climb's bulb; the
          starter set (`Home.Specs.Starter`) and the floor's furnishings
          (`Lobby.Specs.Dressing`: 24 plants, 10 benches, 2 planters) placed, with colliders
          and Seats on the benches and planters; the floor lamp's PointLight.
        - [x] **S5-03a2b4 The switch's button shows and presses** (D-268): the switch was never
          broken. The test's first-person view faced away from it, and a button off screen never
          shows. Facing it in Studio Play, T flipped the light with the door down and up (the
          click played, both lamps went out), and on the Galaxy A16 simulator a tap on the drawn
          button flipped it. Every seat sits you facing out. The look at phone size waits on the
          owner (captures timed out all session).
      - [x] **S5-03a2c The ground floor weighed for a phone** (D-271): measured in Studio Play on
        the Galaxy A16 simulator, every home lit. Real lights 43 down to 31 (33 in a home): only
        the two floor lamps nearest you throw real light, easing in and out, the rest glowing.
        The spawn view 160k triangles down to 145k: a front's drum and head plates are drawn
        only from inside that home. The run from the spawn to a car is 8.5 s. Nothing warm was
        cut. Left over the triangle default: the cars' 51k (below).
      - [x] **S5-03a2d The cars' hidden triangles** (D-359; seen in Studio Play on the A16):
        measured part by part and settled by the pixels. Only the lamps' wire cages are unseen
        from afar (behind the fascia: not a pixel from 50 studs), so a lobby car's cage is drawn
        only within 60 studs of it (`LobbyCarsNear`): the spawn view 174,404 down to 167,420.
        The gates (29k) are seen; drawing them simply from afar waits on the owner's phone test.
        Climb floors untouched.
    - [x] **S5-03a3 A unit each**: a unit for each player as they join (12; a plots system
      built in Brix first, D-252), your name over your door, doors open by default, pulled down
      keeping everyone out with a locked rattle, spare units padlocked. Split if it won't fit:
      Split in two:
      - [x] **S5-03a3a Brix's plots system** (D-273): built in `../engine` as its ENG-25a, `Plots`
        with `PlotPick.inOrder()` and `Roblox.PlayerPlots` (a plot claimed on join, let go on leave,
        a line when full, signals and a `Plot` attribute), its suite and specs green; the pin moved
        to `482368f`. Brix's `main` isn't pushed yet (OWNER.md).
      - [x] **S5-03a3b The game's homes on it** (D-275; seen in Studio Play with one player, the
        two-player door test waits on `OWNER.md`): FrontOffice adopts `PlayerPlots` for the twelve homes:
        your name over your door, doors up by default, a pulled-down door locked to all but its
        holder (the climb's locked rattle), unclaimed homes padlocked, the switch the holder's only
        (D-263), ShutIn's depth for a home. It runs Brix's ENG-25b in Studio as it goes.
  - [x] **F-G1b4a1 The hard hat on your head, lit** (D-277; its own ticket in Step 4's finds,
    the owner put it here, Nov 16; seen in Studio Play with one player).
  - [x] **F-G1b4a2 The headlamp's beam** (D-420; see Step 4's F-G1b4a2).
  - [x] **S5-03b The mirror test** (ideas 21, 22; D-280): a mirror leaning in every home, a
    world built behind its glass; checked by numbers in Studio Play (copies within 0.002 studs of
    their reflections, your right hand on your right), the picture itself not yet seen (Studio
    wasn't drawing). The owner judges it before S5-03f (OWNER.md); if it doesn't convince, a fix
    ticket goes in here first.
  - [x] **S5-03c The shelf and the chest** (ideas 6 to 9, D-251): finds that come home land on
    the shelf (6, 10, 16, 24 spots by size), sparkling until you walk up to them, a never-owned
    kind chiming and turning; when it's full they go in the job box. Press it: the panel (each
    kind once with its count, a search box, rarity filters): into your hands, out in your unit,
    sell, four make a Gold. Split (context, Nov 17):
    - [x] **S5-03c1a The shelf's art and its spots in the save** (D-284): an oak open shelf with a
      cream painted back, six cubbies, in every home's starter set behind the rug facing the door
      (`art/home`, `Home.Specs.Shelf`); save version 5 keeps each spot's find and how new it is,
      and every find kept at the gate takes the first empty spot (`Save.keep`), a kind never owned
      marked to chime. Passes checks; the art isn't uploaded or in the place yet (c1b).
    - [x] **S5-03c1b Finds on the shelf, sparkling** (D-284, done D-285): upload and import the new Home.fbx;
      the server stands each spot's find in its cubby, fitted and scaled down to fit; a new one
      sparkles until you walk up (a soft tink, the sparkle bursts and stops), a never-owned kind
      chimes, turns once slowly and shows "New"; the server checks you're near before marking it
      seen. Seen in Studio Play at Galaxy A16 size and captured; stays after a rejoin.
    - [x] **S5-03c2a1 The job box, built** (D-287): its art the unit's way in `art/home` (a
      dusty-blue powder-coated job-site box on oak runners, graphite handles, hasp and hinge), in
      every home's starter set against the left wall by the shelf; save version 6 (`boxFresh`);
      `JobBoxes` (Open/Close for the holder, closes when they walk away), `JobBoxView` (the lid's
      eased swing, creak, clunk, sparkle, the chime for a new kind). The home bulb's light hangs
      3 studs under the lamp so the ceiling catches it. Passes checks, untested in Studio.
    - [x] **S5-03c2a2 The job box, in Studio** (D-290): Home.fbx uploaded and imported (from a
      fresh copy of the Home module: a stale one left the box grey and unanchored); seen in Play:
      the lid twinkles for a seventh find, Open eases it to 88 degrees with the creak and burst,
      Close drops it with the clunk, walking off shuts it, a rejoin finds it quiet; the ceiling
      reads warm past the lamp. `docs/art/S5-03c2a-from-door.jpg`, `-open.jpg`.
    - [x] **S5-03c2b1 The job box's panel, to look through** (D-291): the panel rises with the
      lid on the lid's own curve and falls with it on Close, its X, a tap outside or walking off;
      every find you own a kind a card (its picture as your slots draw it, rim in its rarity's
      colour, x2), rarest first; a search box and the rarities you own as chips narrow it at once.
      Seen in Studio Play at computer size: `docs/art/S5-03c2b1-open.jpg`, `-search.jpg`.
    - [x] **S5-03c2b2a Taking a find out, built** (D-293): the panel lists what's in the box
      (owned, less the shelf's and what's out, `Save.boxed`); tap a card, it lifts and glows, Take
      (and Shelf while a cubby is free) over its name; your three hands sit over the panel's
      corner; the picture rises at once and flies in a bow into the hand it went to with its
      pick-up sound, or up to the cubby with the shelf's tink; the count ticks down; hands full
      shakes the hands. One remote (`JobBoxTake`), rate-limited, checked: types, your open box, a
      known find, one in the box; answered on `JobBoxTook`. A find out of the box is still yours
      in the save, never kept at a gate, and goes back in the box when you leave. Passes checks,
      untested in Studio.
    - [x] **S5-03c2b2b Taking a find out, seen in Studio** (D-295): in Play at computer size
      (1380x761), cards clicked for real: the pick (lift, glow, Take and Shelf over the name), the
      flight into a hand with the count ticking down, the last one's card leaving, Shelf to a
      free cubby, hands full asking nothing, the find in your hand after Close; asks for a find you
      don't own or have none left of refused with nothing changed; a rejoin finds the box whole.
      Fixed: a hand drew the find before its picture arrived (it now waits for the landing).
      `docs/art/S5-03c2b2-pick.jpg`, `-flight.jpg`, `-shelf.jpg`. Sounds not heard (OWNER.md).
    - [x] **S5-03c3a Selling from the panel, seen** (Nov 17, D-297): Sell on the picked card
      with its price ("Sell $22", the find's catalog worth, `BoxPanel.price`); the server strikes
      one and pays in one step (`BoxPanel.sell`) and writes the save 6 s after a run of sales; the
      picture flies into your cash over the panel's corner, which chinks and counts up as the
      results board's does. A tap guard after a card leaves. Seen in Play, a rejoin keeping it.
    - [x] **S5-03c3a2 Selling a cracked find** (Nov 17, D-301): a name with `chipped` sells a
      cracked one first at half (`Chip.worth`), one off `chipped`, so `chipped` never tops
      `finds`; the box sends how many are cracked and Sell shows the next one's price ("Sell $9",
      then "Sell $18"). Seen in Play: a cracked Blob lamp sold for 9, the whole one then offered
      at 18. A Studio-only hook cracks one (`ServerStorage.StudioCrack`).
    - [x] **S5-03c3b1 Four make a Gold, on the server** (Nov 17, D-298): a Gold is a name of its
      own in `finds` ("Teddy:Gold", `Home/Gold`), no new save version; Gold is the take's fourth
      way (`BoxPanel.gold`: four in the box struck, cracked first, one Gold added and its book page
      stamped, in one step, written as a sale is); not for Secrets; a Gold sells at five times;
      its card sits beside its find's, gilded (ToolPicture), Sell only. Passes checks, untested in
      Studio.
    - [x] **S5-03c3b2 Four make a Gold, the big animation, seen** (D-251, D-299): a Gold verb glowing on
      a card with four or more (`BoxPanel.offers`); press it and the four pictures fly out round
      the screen's middle, swirl inward faster with a rising shimmer, flash, and one gold picture
      lands big with its own sound, then deals onto its new card (`BoxPanel.made`). Seen in Play.
    - [x] **S5-03c3b3 A Gold on the shelf and in your hand** (D-300): Take and Shelf on a Gold's
      card; carried as its find with a gold mark (`Gold.slotAttribute`), gilded on the server for
      everyone and in your own view, the slot wheel and the panel's hands; stood gilded on the
      shelf; counted and kept by its Gold name. Seen in Play: taken to the hand, held, shelved.
    - Polish for Golds (later): a Gold's own textures where the find art has them (the goo
      ball's `GooBall_GoldColor.png`), else the generic gild; a glint as a Gold is drawn; the
      Packrat wanting a Gold most (Slots' `worth` reads the find's row, not five times it).
    - Polish for the panel (later): a hairline crack drawn over a card's picture while its next
      one is cracked (D-301); a chip tap you can hear differently per rarity; cards drawn
      only as they scroll into view if a player ever owns 60 kinds or more (ViewportFrames cost).
  - [x] **S5-03d Taking finds up** (idea 10, D-251, D-302): take any find from the chest into a
    slot and carry it to the elevator. On the climb it's at risk like any find: stolen, dropped
    where you're caught or where you leave, lost if it isn't aboard when the elevator leaves.
    Whoever carries a find aboard takes it home. The save marks a find out until its climb ends
    and strikes it off only when lost on a climb that ended properly; a crash never costs one.
    Split for context:
    - [x] **S5-03d1 The save's rules, pure** (Nov 17, D-302): `Save.lose` and `Home.Taken.settle`
      (Aboard: yours stays out, nothing written; a friend's is kept into theirs and struck off
      yours, one between you; Lost: struck off; Back: its crack comes home); `tests/taken.spec`.
      Nothing wired yet.
    - [x] **S5-03d2 Wired on the server** (Nov 17, D-304): a find out of a job box goes up as its
      holder rides a lobby car into floor 1 (`Slots:up`); Slots' `taken` (Lost, Back) and `keep`'s
      `Moved` reach GatePay, which settles each through `Taken.settle` and writes every touched
      save at once; an owner leaving mid-climb strikes theirs in their last write (Saving's
      `leaving`) and frees them for a friend; nothing settles as the server stops. Passes checks,
      untested in Studio.
    - [x] **S5-03d3 Taking finds up, seen** (Nov 17, D-305): seen in Studio Play with one player
      (the Blob lamp up, kept in your hand at the gate, dropped on floor 2 and struck as it went,
      the rest kept across a rejoin, one left at home never struck; `docs/art/S5-03d3-*.jpg`).
      Found and fixed: Studio's Stop mid-climb struck a taken-up find; GatePay now settles on
      the next Heartbeat. The two-player steps are in OWNER.md.
    - [x] **S5-03d4 Across the trip** (Nov 18, D-358): the trip's data (version 4) carries each
      rider's taken-up finds (whose box, key, holder, cracked, worn); they leave the lobby quietly
      with their holder, or stay in hand if the trip fails; the group's server takes each
      owner's own word only, deals what their save backs (`Taken.backed`) into the holder's
      slots, already up, once the save loads. Seen with Studio's stand-in (`DevTripFinds`); the
      live trip and a live shutdown are OWNER.md steps.
  - [x] **S5-03e Arrange** (ideas 11 to 15), after a placements system built in Brix (D-252):
    lift, drag, a half-stud grid, quarter turns, Free for everyone, floor, tabletop, wall and
    ceiling spots (a column in the catalog), red where it can't go, Place, Put away, Done, the
    limit bar (25, 50, 100, 150 by size); saved in a new save version; every move checked on the
    server. Split for context:
    - [x] **S5-03e1 Placements, in Brix** (D-252): a pure placements system built in `../engine`
      by Brix's own AGENTS.md (neutral names, its checks and specs, its commit): a room's
      surfaces (floor, tabletop, wall, ceiling), footprints snapped to a half-stud grid with
      quarter turns, in-bounds and overlap checks with a reason for each refusal, a limit; then
      the pin moves here. No game code beyond the pin.
      Done (D-306): Brix's ENG-26a at `7f25310`, `Brix.Placements` and `Brix.PlacementSnap`
      (grid and free); the pin moved; nothing wired here yet.
    - [x] **S5-03e2 Arranged, saved and checked**: a new save version holding each home's
      placements (with its migration), the catalog's spot column, every move checked on the
      server through e1 and rate-limited. The spot column lives in a home file of its own, not
      the find run's `Rows.luau`; the unit's areas come from its XL slot, the limit from its size;
      rows a load leaves out go back to the chest; only the unit's holder may move its things.
      Split for context:
      - [x] **S5-03e2a The save and the spots** (D-308): save version 8 holds `placed` (Brix's
        saved form) with its migration; a find set out is still yours and comes off the job box
        (`Save.boxed`, `Save.settable`); `Home/Spots` gives each find's spot and footprint, the
        room's areas from its XL box, the starter set's tops, the limit by size, ids, the asks'
        checks and the load's trim to what you own. Pure, specs green; nothing on the server yet.
      - [x] **S5-03e2b The server arranges** (D-309): `Home/Arranged` (D-308's frames), the
        `Arranging` system (one `Brix.Placements` per held home, the room's own things stood in
        it first: the starter pieces on the floor, the ceiling's lamp, the mirror), Place and
        PutAway rate-limited and checked, each change saved and drawn for everyone. Seen in
        Studio Play: four set out, six refused, kept through a set-up from the save and the
        DataStore, all put away; a true Stop and Play rejoin not yet watched.
    - [x] **S5-03e3 The Arrange screen** (split for context):
      - [x] **S5-03e3a Lift, drag and set down** (split for context):
        - [x] **S5-03e3a1 The screen, built** (D-311): `ArrangeView` (the Arrange button in your
          own home, the camera up in the corner, a faint grid, the box's tray, lift from the tray
          or the room, drag snapped on the client's own judge, green or red, Turn, Place, Put
          away, ×, Done) and `Home/Arrange` (the room's set-up shared with the server, the box
          remote). Passes checks, untested in Studio.
        - [x] **S5-03e3a2 Seen in Studio at phone size** (D-312): on the Galaxy A16, lifted from
          the tray and the room, green on the job box, red in the shelf, Turn, Place, Put away,
          ×, Done, and a true Stop and Play rejoin (the finds stood again). Fixed: the Arrange
          button over the torch's switch (now top right, where Done stands), the grid unseen,
          your own body, torch and the tool wheel in the room, the verbs row over the find (now
          a corner cluster, the tray sliding away while a find is lifted). `docs/art/S5-03e3a2-*`.
          Not seen: a find riding the TV's top (the test save has no TV or drum; OWNER.md).
      - [x] **S5-03e3b The limit bar, the lid and friends** (D-313): a bar top middle while
        arranging fills honey as Place answers (the server's count and limit, sent with the box;
        3/25 to 4/25 seen on the A16); at the limit the tray's cards dim and a press shakes the
        card and pulses the bar. Finds on the job box's lid ride it up and back down; the lid
        stops propped where a rider would touch the wall (the lamp reached half a stud into it
        at 88 degrees; now 60, seen). A friend's find set out drops in with a knock
        (SettleView; needs two players, OWNER.md). `docs/art/S5-03e3b-*`.
        S5-03e (Arrange) is done.
  - [x] **S5-03f The mirror and the clothes rail** (ideas 21 to 24), split five ways:
    - [x] **S5-03f1 The mirror's real frame** (D-314): a moulded oak frame mitred round the glass,
      the glass's bevelled edge catching the light, felt pads under its foot and on its top's
      back, leaning so the pads just touch the wall; built the unit's way in `art/home`, in every
      home. `art/sheets/lobby-mirror*.png`, `docs/art/S5-03f1-*`.
    - [x] **S5-03f2a The clothes rail's art** (idea 23, D-315): a rolling oak garment rail past
      the mirror in every home, three rows for what you wear (hats on its top shelf, clothes on
      oak hangers from its graphite bar, shoes on its rack), castors under it; built the unit's
      way in `art/home`; seen in Play on the A16. `art/sheets/lobby-rail*.png`,
      `docs/art/S5-03f2a-*`.
    - [x] **S5-03f2b Wearing from the rail** (D-316): every kind you own that you wear (the hard
      hat and its Gold) stands on the rail's hat shelf, at the size you wear it, while one is in
      your job box, never on the shelf again; Wear puts one from your box on your head with its
      knock and click, lit for good at home, and Hang up puts it back in a glint with its knock.
      Only you see the presses; the server checks them. Seen on the A16: wear it, see it in the
      mirror, hang it back. `docs/art/S5-03f2b-*`.
    - [x] **S5-03f3 Nothing worn or switched on runs down at home** (idea 23's rule, D-317): any
      light lit at home burns for good there; as the lobby car lands on floor 1, each one you
      carry or wear gets its own full minute from then, its press not played again. Server seen
      in Play (the hat's light read forever, then 60 s from arrival); your screen in OWNER.md.
    - [x] **S5-03f4a Trying a wrap colour on at a mirror** (idea 24, D-318): every mirror has Try
      on; you turn once round as the film winds up you in the next colour on the shelf, stand
      wrapped three seconds, then it loosens with a crinkle and slumps to a heap. Free, nothing
      saved. Seen in Play on the A16 (`docs/art/S5-03f4a-*.jpg`).
    - [x] **S5-03f4b The counter's mirror** (idea 24, D-319), in three:
      - [x] **S5-03f4b1 Built**: the home's framed mirror leaning on the front wall past the
        counter's door end (`Shop.Mirror`, `Home.mirrorAt`), its picture standing the front
        office's walls (`Lobby.MirrorRoom`); each colour card's figure a Try on near a mirror
        (`TryWrap`, that colour); your view eased to the glass as the film winds. The counter's
        Shop button moved to the counter (it stood at the old lobby's z -35). Passes checks.
      - [x] **S5-03f4b2 Seen in Play** (D-320): the mirror by the counter and its picture judged
        on the A16, the cards' Try on pills, Pink tried on from the shop (`docs/art/S5-03f4b-*`).
        Fixed what the eye found: a flash in the glass at each try-on sound (MirrorView copied your
        body again for every sound), and you off the glass's edge from the counter (the mirror
        moved in line with the counter's button; the cards' Try on only when you'd see yourself).
      - [x] **S5-03f4b3 In line, seen** (D-320): from the counter facing it, Pink's Try on turns
        you to yourself centred in the glass, wound in pink, with no slab through the peel; three
        studs to one side the cards carry no Try on. Seen in Play on the A16
        (`docs/art/S5-03f4b3-*`). The dark glass came once, on the session's first look; the
        polish section has it.
  - [x] **S5-03g Walls, floor, door, name cards and furniture** (ideas 18 to 20), art first
    (every piece done Nov 18; the three Polish lines under S5-03g2b stay open):
    - [x] **S5-03g1 The art**, the unit's way (`art/home/`), calm and warm (D-263), in three. The
      plan doc's ideas: paint or paper the partitions; lay a floor of boards, carpet, checkerboard
      tiles or rubber matting; colour your roll-up door, which is what the hall sees while it's
      down; a name card over the door in stencil (everyone's to start), hand-painted, chalkboard
      or neon (it glows down the hall; neon for Robux, the rest for cash); furniture at the
      counter: milk crates, pallets, moving blankets, a folding table, a camp bed, a beanbag, a
      rug, string lights, a steel shelf, a neon sign.
      - [x] **S5-03g1a Floors, papers, paints and door colours** (D-321): carpet, checker tiles
        and rubber matting beside the oak boards, stripes, leaves and daisies beside plain plaster,
        baked in `art/home/looks.py`; eight paints, eight door colours and each floor's colours in
        `Home.Specs.Looks` (`tests/homelooks.spec`). A look's colour is the part's (Overlay), so a
        checker's squares, a carpet, a mat's rubber and a paper's ground take what you pick.
        Judged at phone size on `art/sheets/home-floors.png` (eight units, the doors on the teal).
      - [x] **S5-03g1b The name card's four styles** (D-322): stencilled steel, a painted board, a
        chalkboard in oak and pink neon that lights the wall, each its own parts in Home.fbx
        (`art/home/cards.py`), lettered in Studio's own fonts; `Home.Specs.Cards`; the sheet
        `art/sheets/home-cards.png` from the floor, down the hall and across it. Not uploaded.
      - [x] **S5-03g1c The counter's furniture** (idea 19; the beanbag and rug exist), in
        `art/home/furnish.py`, split in two (S5-03g1b):
        - [x] **S5-03g1c1** milk crate, pallet, folding table, steel shelf (D-323): an upturned
          crate you sit on, holes through it; two pine pallets stacked into a coffee table (the
          `Pine` set, nails where the boards cross); a pale moulded table on graphite legs; a
          sage powder-coated shelf, four tiers on angle posts. `Home.Specs.Tops` gives their flat
          tops. Sheet `art/sheets/home-furniture.png`, judged at phone size. Not uploaded.
        - [x] **S5-03g1c2** moving blanket, camp bed, string lights, neon sign (D-324): a quilted
          mover's blanket folded into a floor cushion, cream binding at each fold; an olive canvas
          camp bed sagging on X legs, a pillow at its head; twelve warm globes in three swags from
          hooks that clip to the wire ceiling; a neon crescent moon and star on clear acrylic.
          `Home.Specs.Glows`: each lit piece's Neon and clear parts and its one light, near only
          (D-271). The sheet adds them by a person, then the hangout at night, the lamp off. Not
          uploaded.
    - [x] **S5-03g2 Paint and floors on the Arrange screen**, saved per home, in two:
      - [x] **S5-03g2a The panels and swatches** (D-325): a floor panel and a wall panel per
        partition, the back wall and the front wall's inside round the doorway, 0.02 proud of the
        lobby's walls, UVs in studs over the tile so papers run level and carry round the back
        corners (`art/home/panels.py`); a swatch per look set; `Specs.Panels`, `Specs.Swatches`,
        `tests/homepanels.spec`. The looks sheet now dresses its rooms in the real panels and adds
        a row looking back at the doorway. Not uploaded.
      - [x] **S5-03g2b The picker and the save** (Animal Crossing's wallpaper and flooring), in
        three:
        - [x] **S5-03g2b1 Saved, worn and wiped in** (D-326): Home.fbx uploaded (18.8 MB taken,
          same asset); the save's `looks` (version 9, a migration, `tests/save.spec`);
          `Home.Looks` judges a pick and plans the wipe (`tests/homepick.spec`); `Decorating`
          lays a held home's panels once its look isn't a new home's, dresses them from the save,
          and takes `PickLook(kind, id)` (rate-limited, checked, your own home, saved at once),
          changing the panels as the wipe ends; `LooksView` grows the new paper from the back
          wall's middle round to the door and the floor from the back wall, with a roller's
          squish, on every screen near. Passes checks, untested in Studio.
        - [x] **S5-03g2b2 Seen in Play** (D-327): Home.fbx inserted (worst 0.0007); papers wipe
          round the room and floors roll under the rug, the panels taking them with no jump
          (`SHIFT = 1` holds); the roller loads (2.2 s); the look survives a rejoin. Fixed: every
          look's maps and the panels' meshes fetched once a home is near (a first pick wiped in
          plain and popped its pattern 3 s later), sheets that wait for the panels to draw, the
          floor's sheet under the rug. Pictures `docs/art/S5-03g2b2-*.jpg`. Not seen on the A16.
          - [ ] **Polish: the hand-over's shade.** The sheet (a Texture on plain plastic) reads a
            shade darker than the panel's SurfaceAppearance under the bulb; match its material.
          - [ ] **Polish: the mirror keeps the old look.** MirrorView's copy of the room keeps the
            floor and paper it had when you came in; re-copy the panels when `LookWorn` changes.
        - [x] **S5-03g2b3 The paint tab on the Arrange screen** (D-328): two tabs on the tray's
          top edge, the finds and the looks (a fan of paint chips); the looks tab is two rows, the
          walls over the floor: papers then paints, floors then the chosen floor's colours. A
          paper's or floor's chip is its colour map over what it would wear; dots for colours; a
          white ring on what the home wears, moved when `Look` changes; a tap fires `PickLook`
          with the soft click. `src/client/LooksTab.luau`. Seen in Studio Play on the A16
          simulator: every kind picked, ringed and wiped; the save kept it. Pictures
          `docs/art/S5-03g2b3-*.jpg`.
          - [ ] **Polish: the floor's wipe half under the tray.** The looks tray (120 of the A16's
            280 points) hides the near half of the floor as it unrolls; let the tray dip to its
            tabs while a floor rolls, or lift the camera a touch on this tab.
    - [x] **S5-03g3 Door colours and name card styles**, chosen at home, seen from the lobby, in
      three:
      - [x] **S5-03g3a The door's colour**, in two:
        - [x] **S5-03g3a1 The door's colour saved, painted and rolled** (D-329): `looks.door` (save
          version 10, clay for older saves), a fifth kind for `PickLook`, the id on the unit
          (`Looks.DoorAttribute`), apart from the room's look so a door pick never stops a wall's
          wipe. Every screen rolls the colour down the slats from the top in half a second
          (`RollUpDoor.paint`, `Looks.rollShare`) with a quicker squish of the roller; the server
          paints the door itself 0.8 s on (`Home.paintDoor`); a home let go goes back to clay.
          Seen in Studio Play on the A16 simulator from the hall (picked through `LookTest`):
          top first, foot last, then the shut door's one mesh in the new colour. Pictures
          `docs/art/S5-03g3a-*.jpg`.
        - [x] **S5-03g3a2 Your front, a third tab** on the Arrange tray (D-329, D-330): a little
          roll-up door tab, one row of the eight door dots (66 points tall; g3c's card styles take
          its second row), the camera swung round to face the door from 13.4 studs in, the limit
          bar risen away, finds in the room not lifted on this tab. Seen in Play on the A16 (open
          door; the coil rolls), pictures `docs/art/S5-03g3a2-*.jpg`.
      - [x] **S5-03g3b The name card plates**, in two:
        - [x] **S5-03g3b1 The style saved and its plate over the door** (D-331): `looks.card` (save
          version 11, the stencil for older saves), a sixth kind for `PickLook` (Starter styles
          only until g3c), the id on the unit (`Looks.CardAttribute`). The lobby's plain plates are
          gone (`signs()`, Lobby.fbx re-uploaded in place); the server hangs each home's style
          (`CardPlate.hang`, from the home template's card parts) and moves the writing onto
          its face in its font and ink; a spare home wears the blank stencil. Seen in Play on the
          A16: the stencil with the name close up and from mid-floor, and the painted, chalk and
          neon plates hung from the server down the row. Pictures `docs/art/S5-03g3b1-*.jpg`.
        - [x] **S5-03g3b2 The neon lit** (D-332; seen in Play on the A16): its name in a glow stroke (UIStroke in `Glow`,
          LightInfluence 0 so the tube's letters glow), the tube Neon (done in g3b1) and a light
          on the wall (`Specs.CardLight`, range 9) thrown only near you, as the floor lamps' are
          (`Home.FloorLamp.Near`, D-271), so a hall of neon cards stays inside the A16's light
          budget; from across the floor the neon reads as the brightest thing on the wall.
        Polish (g3b): a new style's plate swapping in plays (the old one down, the new one up,
        a clunk) instead of snapping; names are small from mid-floor at A16 size (`OWNER.md`).
      - [x] **S5-03g3c Choosing a card's style** in the paint tab: Starter styles free, Cash and
        Robux ones shown as not yours yet (a small coin or Robux mark on the chip, never a popup);
        a tap on one you don't own does nothing until the counter sells it (the store's rules).
        Done Nov 18, D-357 (passes checks, untested in Studio; steps in `OWNER.md`): a second
        row on the front tab, the camera dipping out to the hall, the new plate swinging down.
      - [x] **S5-03g3d The other card styles sold at the counter**: the painted board and the
        chalk for cash, the neon for Robux, as the furniture is. Split Nov 18 (D-360):
        - [x] **S5-03g3d1 Owned, saved and picked** (done Nov 18, D-360; seen in Studio Play at
          Galaxy A16 size): `Home.CardSale` (the board 120 cash, the chalk 200, the neon as the
          product "Neon Name Card"), save v15's `cards`, `CardSales` on the server (written before
          it answers; the neon through Roblox's prompt, granted in the save first), `Looks.cardLock`
          and the server's pick reading what you own, the paint tab's mark popping away. Prices
          wait on `OWNER.md`.
        - [x] **S5-03g3d2 The styles' cards at the counter** (done Nov 18, D-361; seen in Studio
          Play at Galaxy A16 size): the painted board, the chalk and the neon as cards on the
          Furniture tab after this week's pieces (StyleCards), each its plate drawn flat with your
          name (`LooksTab.plateFace`: a viewport can't draw the lettering), swaying a little, the
          neon's letters breathing; Buy held till `CardBought` answers; the plate swings out and
          falls back with the hall's clack, the coins tick off the shared purse, Owned as it
          lands; the neon at Roblox's price with the Robux mark through the prompt. Pictures
          `docs/art/S5-03g3d2-*.jpg`.
    - [x] **S5-03g4 Furniture at the counter in a weekly stock** (idea 19; Animal Crossing's
      Nook's Cranny and Fortnite's item shop for the stock that changes, Lethal Company's ship
      store for buying furniture with what the run earned). The moment: back from a climb with
      cash, you see this week's pieces at the counter, buy the camp bed, and it's in your job
      box waiting to be set out. Split (S5-03g3b2's session, too big for one):
      - [x] **S5-03g4a The stock and the sale, server and save.** (D-333; seen in Studio Play.) A pure `Home/Furniture.luau`:
        the eight pieces (D-323, D-324) as rows (id, parts, cash price, how it stands: floor,
        wall or ceiling, a cap on how many you own); this week's stock from the date alone
        (the same in every server, every piece back at least every other week; never a random
        roll you pay for); the buy check. Save version 12: `furniture` (owned counts) with its
        migration and a save.spec sample. Server: a `BuyFurniture` remote (a string id, in this
        week's stock, under the cap, cash enough; rate-limited) takes the cash, adds the piece,
        writes the save and only then answers. Lune specs for the stock, the check, the
        migration. Prices are defaults for the owner (`OWNER.md`), scaled from a floor's pay.
      - [x] **S5-03g4b The furniture at the counter on screen** (D-334; seen in Studio Play on the
        A16, `docs/art/S5-03g4b-*.jpg`): a second tab beside the wrap
        colours in the counter's shop (ShopView): this week's pieces turning in their cards, each
        with its price and Buy; a buy answers with the coins ticking down, a thunk and the card
        saying it's in your box; one you can't afford dims its price, with no popup. The server
        answers each buy on `FurnitureBought` after the save's write: "busy" and "save" need a
        gentle settle (the coins never tick for those); a "notStocked" means the week turned.
      - [x] **S5-03g4c Bought furniture in the job box and set out with Arrange**, split (too big
        for one session):
        - [x] **S5-03g4c1 The server sets it out** (D-336; seen in Studio Play through
          `ArrangeTest`, `docs/art/S5-03g4c-camp-bed.jpg`): a floor piece set out under its
          placed name ("CampBed:Furniture#1") in `placed` (no new save version), checked like a
          find (in the box: owned less set out; its footprint from its parts' boxes, the floor
          only; clear of walls, the starter set and everything set out), drawn for everyone as
          the home's own art, solid; moved, turned, re-laid from the save, put back to the box.
          Wall and ceiling pieces are refused ("notYet") until g4d. The box remote now sends the
          furniture in the box as a fourth value. Before it, the counter's pictures were white:
          the furniture got its paints (D-335).
        - [x] **S5-03g4c2 The box and Arrange on screen** (D-337; seen in Studio Play on the A16,
          `docs/art/S5-03g4c2-*.jpg`): the job box lists the furniture first, its painted art in
          warm wood rims; a floor piece's one verb is Set out, which shuts the lid and opens
          Arrange holding it, risen out of the box onto the nearest free spot, green; it lands
          with a deeper knock than a find's. Arrange's tray lists floor pieces too; one set out
          lifts by a tap, moves, turns, and Put away sends it back. Wall and ceiling pieces are
          listed without Set out. Seen: a pallet bought at the counter, set out on the rug, there
          after a rejoin, put back.
      - [x] **S5-03g4c3 A find on a piece's top** (D-338; seen in Studio Play on the A16,
        `docs/art/S5-03g4c3-*.jpg`): the crate's, the pallet's, the folding table's and the steel
        shelf's top tier take a find, at the art's own height (`Spots.pieceTop`); what stands on
        a piece rides in its ghost while you drag it, follows it, and goes back to the box with
        it. Seen: the moon lamp on the pallet, the pallet slid and placed by the screen with the
        lamp aboard, the firefly jar aimed green onto it and set down, both still there after a
        re-lay, all three put away together; a jar on a crate's rim. The camp bed and the floor
        cushion are sat on (Seats, later); the shelf's lower tiers wait.
      - [x] **S5-03g4d The lit pieces**: the string lights hang from the ceiling by their
        origin, the neon moon from a wall like a name card; their Neon parts Neon in `Colour`,
        clear parts Glass (`Specs.Glows`), their one light made only near you as the neon
        cards' are (HomeCards' wash, D-332) within the A16's budget (D-271). Done Nov 17, D-339:
        seen on the A16; the moon's glow with the door down and two clients wait on the owner.
  - [x] **S5-03h Four sizes and the walls that move** (ideas 30, 31): small to start, medium for
    cash, large and XL for Robux; the partitions grind back and the door widens, everything set
    out staying where it was. Split Nov 17: the save's and the purchases' rules first, each with
    a failing spec, then the layout, the walls and the moment.
      - [x] **S5-03h1 The size in the save, the room from it**: Small 8 by 8, Medium 12 by 12,
        Large 16 by 20, XL 20 by 30 (`Home.Sizes`), each a box cut from the slot's XL one at the
        door; save v13 `homeSize` and `placedSize` (a v12 save loads Small, laid at XL); rows
        laid at another size carried to it as the home is set up (floor and ceiling keep their
        place in the unit, wall finds ride their wall), what it doesn't hold back in the box;
        the room's own things a size doesn't hold left out of it. Done Nov 17, D-340: checked
        in Studio Play from the server at all four sizes; the grid at Small not yet looked at.
      - [x] **S5-03h2 Medium for cash at the counter**: the rules in a spec first (the price a
        feel number in Config; no sale when you're short or already Medium or bigger; the cash
        taken and `homeSize` written in one save before anything else happens), a validated,
        rate-limited remote, then the counter's offer and its answer (sound, motion, a short
        headline), as Bloxburg's and Adopt Me's house upgrades are bought. Done Nov 17, D-341:
        the counter's third tab, Units; seen on the A16 in Studio Play, the price the owner's.
      - [x] **S5-03h3 Large and XL for Robux** (moved here from S5-07): developer products through
        Brix's Purchases as S3-02's are: granted only after the save, never lost on a failed save
        or a server hop (the purchase ledger), every offer switchable off in Config, prices read
        from Roblox, never sold smaller than you have; spec first. Split Nov 17:
          - [x] **S5-03h3a Your own home**: Large and XL cards in Units (`Grow`'s Robux rows,
            `UnitsTab`), Roblox's prompt from the server, the grant written before it's marked.
            Done Nov 17, D-342: products "Large Unit" and "XL Unit" (switches `sellHomeLarge`,
            `sellHomeXL`); checked in Studio Play from the server and the client's remote with
            made-up receipts (a failed save held, granted once written, a late one changing
            nothing); the cards on a screen and Roblox's real prompt not yet seen.
          - [x] **S5-03h3b The gift versions**: a friend grows your home, the recipient picked
            on the server, the same ledger; never sold to a home already that big. Split Nov 17:
              - [x] **S5-03h3b1 The rules and the server**: `Grow`'s gifts, `Products` rows
                "Large Unit Gift" and "XL Unit Gift" through Brix's gift, `Growing`'s Gift press,
                spare, grant and `HomeGifted`. Done Nov 17, D-343: specs green; untested in Studio.
              - [x] **S5-03h3b2 The Gift screen and the friend's moment**: a Gift pill on Large
                and XL in Units (dealt even below your size), the friends here with their faces
                and sizes, the press held till answered, "Sent!" with the steel's roll; the friend's
                own "More room!" with the giver's face wherever they stand; Studio's 2-player test.
                Done Nov 17, D-344: friends dealt as cards; the banner seen arriving in Studio Play,
                the rest untested in Studio (Studio stopped drawing); the 2-player test the owner's.
      - [x] **S5-03h4 The starter set laid by size** (folded into S5-03i1, D-345): where the shelf, the job box, the rug, the
        beanbag, the floor lamp, the mirror, the rail and the ceiling lamp stand at each size,
        from `art/home/home_spec.py` (Small holds what's "snug": the shelf, the box, the mirror
        and the rail, idea 30); each piece rides its wall as the home grows; look sheets at
        phone size.
      - [x] **S5-03h5 The walls drawn by size**: the partitions and the back wall where the size
        ends (the unit kit's steel, the home's panels following, D-325), the door frame per size
        (Small's doorway narrower than the M door), the room depth and width the door counts you
        in by, and the Arrange button's inside box from the size. Art first, the unit's way.
        Split Nov 18:
          - [x] **S5-03h5a The walls where the size ends**: three movable walls per home (steel
            under the home's own plaster panel, `Home.Walls`), the ceiling lamp over the room's
            middle, the picked paint and paper riding them, and the door's count, the lights'
            room, Arrange's fixed lamp and its button's inside box and the look's wipe all from
            the size (`Sizes.inset`, `Sizes.onWall`). Done Nov 18, D-354.
          - [x] **S5-03h5b Small's narrower doorway**: the front built round the S door's
            opening (6 wide, in the M's wall: plaster and oak casing fill the M's sides, the M
            curtain rolling behind them), shown at Small, the M's at Medium and up; art first
            (`art/home/front.py`), rebuilt, uploaded and seen at phone size. Done Nov 18, D-355:
            the doorway's sides, plaster and head slide (`Walls.doorway`); h5a and h5b seen in
            Studio Play at A16 size.
      - [x] **S5-03h6 The walls grind back** (idea 31): when it grows, you're there to watch: the
        partitions slide along their rails, the back wall rolls away, the door frame widens, dust
        drifts down, with the steel's grind (Animal Crossing's house growing). Built to slide:
        `Walls.doorway(unit, frame, inset)` takes any inset between a stud and none, and the walls
        need the same (a blend of two sizes' `Sizes.onWall`). The pieces that ride a wall (the
        shelf on the back wall) glide with it; what you set out mid-room stays put. Done Nov 18,
        D-356: `HomeGrowView` slides it over the server's snap, held for the holder until they're
        next inside; Small to Medium seen in Studio Play. Seeing Medium to Large, Large to XL and
        the hold is still unseen (Studio was busy in g3c's session; `OWNER.md`).
  - [x] **S5-03i Everything in the room moves, lifts and works** (the owner, Nov 18, D-345;
    Animal Crossing's house, Bloxburg's build mode). Next, ahead of S5-03h5 and h6. The moment:
    you buy an end table, set it by the bed, stand your lamp on it, walk up and press Switch, and
    the corner glows; the shelf goes wherever you want it. In this order:
    - [x] **S5-03i1 The starter pieces become furniture**: the shelf, job box, mirror, clothes
      rail, rug, beanbag and floor lamp as rows in the home's layout, lifted, moved, turned and
      put away in Arrange like bought pieces (the job box moved but never put away); the shelf's
      spots, the mirror's reflection and the rail's hangers go with their piece; a default layout
      per size for a new or grown home, none mid-room (this is S5-03h4, folded in); a home laid
      before gets its pieces as rows where they stood (a save version with a migration). The
      ceiling bulb and the switch stay with the room. Split Nov 18 (D-346):
      - [x] **S5-03i1a The rules**: the starter pieces as furniture rows (`Furniture.Starter`,
        never sold, free of the limit), each size's layout (`Home.Layout.default`: Small holds
        the shelf, the box and the mirror), a home laid before adopting its pieces where they
        stood with the finds on the shelf's and box's tops moved onto them (`adopt`), a growing
        home's pieces riding their walls (`grow`), the shelf's, box's and rug's tops as piece
        tops, save v14's `starterLaid`. Done Nov 18, D-346: Lune specs; nothing wired yet.
      - [x] **S5-03i1b The server lays them** (done Nov 18, D-347: passes checks, untested in
        Studio; the Studio pass moved to i1c): `Arranging` lays the rows (`adopt` while
        `starterLaid` is false, then writes it true; `grow` on a size change), draws them like
        bought pieces, refuses putting the job box away; `Arrange.room` drops the fixed set's
        blocks and the ShelfTop and JobBoxTop areas; `Lobby.front` lays a spare home by
        `Layout.default`; the job box's panel lists the starter pieces put away. The shelf's
        spots (`Shelves`), the job box's lid and panel (`JobBoxes`, `JobBoxView`), the mirror
        (`Home.mirror`, `MirrorView`) and the rail (`Rails`) find their piece by its row.
      - [x] **S5-03i1c1 Lift them in Arrange** (done Nov 18, D-348; seen in Studio Play at Galaxy
        A16 size on the XL test save): the shelf, finds and all, lifted from mid-room to the back
        wall; the mirror carried to the left wall, where it turns its back to the wall and leans
        (`Layout.leanTo`, `stands`; red mid-room); the job box moved by the door with no Put away;
        the floor lamp moved; all saved and laid again by "relay". The job box keeps its lid's
        room off a wall (`Layout.clearOf`, the server refuses nearer). The lid swings about the
        box's new hinge (`JobBoxView.frame`), the lamp's nearness reads its shade where it is
        now, a lifted mirror's picture leaves the hidden one. Captures `docs/art/S5-03i1c-*`.
      - [x] **S5-03i1c2 Seen through a rejoin and a resize** (done Nov 18, D-349; seen in Studio
        Play at Galaxy A16 size): the job box stops at its lid's line and opens clear; the rail
        moved with its hangers and Wear; the rug put away with its beanbag and set out again; a
        true Stop and Play laid everything where it was left. Found and fixed: made Small, the
        whole set went in the box, the job box too; a shrunk home now takes its size's layout
        first (`Layout.grow`) and a save without its job box gets it back (`withBox`). Captures
        `docs/art/S5-03i1c2-*`.
    - [x] **S5-03i2 Take anything directly**: outside Arrange, walk up to any find set out (shelf,
      a top, the floor, a wall) and Take puts it in your hands; in Arrange, lift a find straight
      off the shelf or any top. Server-checked, never lost or doubled. Split Nov 18:
      - [x] **S5-03i2a Take from where it stands**: a Take button on every find in your shelf's
        cubbies and every find set out, yours only; the server frees its spot or row and puts it
        in a free slot in one step (`Slots:unbox`, its pick-up heard), so it's never lost or
        doubled; hands full, the press does nothing. Its copy hops into your hand. Split Nov 18:
        - [x] **S5-03i2a1 Built** (D-350): `Save.unshelf`, `Spots.takeable`/`lift` (spec first,
          `tests/hometake.spec`), Takes' button on cubby and set-out finds, `Slots:room`, the
          flight (HomeTakeView). Passes checks, untested in Studio.
        - [x] **S5-03i2a2 Seen in Studio Play at Galaxy A16 size** (done Nov 18, D-351): a real
          Take press lifted the boombox off the job box into your hand; the floor teddy through
          the hook. Fixed: Take never showed on a find that also has its own button. Not seen:
          a cubby take by a real press, the flight frame by frame, a rejoin's counts (`OWNER.md`).
      - [x] **S5-03i2b Lift a find out of the shelf in Arrange** (done Nov 18, D-352; seen in
        Studio Play at Galaxy A16 size): a tap on a cubby's find lifts that find, growing out of
        its cubby (`Shelf.hit` against its box); the shelf's own boards still lift the shelf;
        Place sets it on a top (the teddy onto the folding table) and Put away sends it to the box,
        the server moving it off the spot in one step (`Spots.offShelf`, `tests/homeshelflift`).
        Captures `docs/art/S5-03i2b-*`. Not seen: a refused place sliding it back into its cubby.
    - [x] **S5-03i3 Every find set out keeps its button** (done Nov 18, D-351; seen in Studio
      Play at Galaxy A16 size: the lamp on the folding table switched on): its `Finds/Use` press
      beside Take for every find at once (`Home.Press`, HomeUses, HomeUseView, FindUses'
      `setOut`); lights under D-271's caps; anyone in the home may press. Queued: a lamp left on
      kept through a rejoin; the shelf's cubby finds' own buttons.
    - [x] **S5-03i4 Sit on the furniture** (done Nov 18, D-353; seen in Studio Play at Galaxy A16
      size): a Sit button over every seat (R/ButtonB; `Sits`, `HomeSitView`, `Home.Sit`), the
      crate, the beanbag, the blanket and the camp bed's two; jump to stand; the landing's sound,
      the cushion's give and your view gliding in. Queued: cross-legged on the blanket (needs our
      own animation; script joint writes lose to a seated body's Animator) and lying on the bed.
  - [ ] **S5-03j The room editor, rebuilt** (the owner, Nov 18, D-436; the plan is the Claude Doc
    "The room editor and the recipe system", https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU,
    read its "Part 1" and "How it's built" sections only). Arrange with The Sims 4's control:
    a camera you turn, slide and zoom, drag anything and let go to place, snapping that does the
    thinking, undo, and placing by hand without opening Arrange. Precedents: The Sims 4's build
    and buy mode, Bloxburg's build mode, Animal Crossing's house decorating, Adopt Me's furniture
    editing, Grow a Garden's held egg placed where you point. Pure cores go in Brix (D-252),
    each by Brix's own AGENTS.md, then the pin moves. `ArrangeView` is taken apart as each piece
    is rebuilt: each ticket moves its piece into its own module; ArrangeView ends as wiring.
    - [x] **ENG-27 Gestures, in Brix.** Pointer events in (id, position, began, moved, ended,
      time); intents out: tap, double tap, hold, drag on a thing or on empty floor, pinch,
      twist, two-finger slide; the game answers what's under a point. Pure, a contract and a
      suite, a module page; the game's pin moves. **Acceptance:** each promise fails its suite
      when broken; check green in both repositories.
      Done (D-437): Brix `f291d7f`, `Brix.Gestures`: 12 promises, each proven to fail a broken
      stand-in; mouse right-drag twists and tilts, middle-drag slides, the wheel pinches or turns
      a dragged thing, sticks and triggers move the camera at each `advance`. Pin moved.
    - [x] **ENG-28 The orbit camera, in Brix.** A focus point, heading, tilt and distance on
      springs (Brix's Smoothings), a flick's drift, a box it can't leave, near and far stops,
      the edge follow while dragging; numbers in, a camera position and look point out. Pure,
      contract, suite, module page; the pin moves.
      Done (D-438): Brix `0b2230c`, `Brix.OrbitCamera`: 14 promises, each proven to fail a broken
      stand-in; critically damped springs, a flick's drift, soft stops (any Zone, near, far, the
      tilt's ends), a ceiling the eye stays under, an edge follow, `floorAt` and `cutaway` for the
      walls' fade. A frame allocates nothing. Pin moved; nothing in the game uses it yet.
    - [x] **S5-03j1a The build camera, built.** Arrange's camera turns, slides, zooms and tilts:
      one finger on empty floor slides, two fingers pinch, twist and tilt; right-drag, wheel and
      WASD; gamepad sticks and triggers. The walls between the camera and the room's middle fade
      (and what hangs on them), as The Sims cuts walls away. Opening swoops up from your eyes,
      closing swoops back; double tap on empty floor resets. The front tab's door view and the
      hall dip still work.
      Done (D-439): `ArrangeCamera` (client) on Brix's `Gestures` and `OrbitCamera`, the pure
      sums in `Home/BuildView` (Lune spec), feel numbers in `Arrange.Camera`; the eye stays in
      the lobby slot and up to 5 studs out into the hall; the old camera code left ArrangeView.
      Passes checks, untested in Studio.
    - [x] **S5-03j1b The build camera, seen and tuned.** Studio Play at Galaxy A16 size: Arrange
      opens with a swoop, right-drag turns, the wheel zooms, a left drag on empty floor slides,
      WASD slides, double click resets; the walls fade from the door's side, both sides and the
      back as it turns (a Small home, then Medium); the front tab's swing and the hall dip; close
      swoops back. Tune `Arrange.Camera`'s signs and numbers by feel. Capture to `docs/art/` at
      half scale; phone and gamepad steps in OWNER.md. Edge follow (`ArrangeCamera.follow`) is
      wired in j2 with the drag.
      **Acceptance:** seen in Studio Play at A16 size, captured; walls fade from every side;
      check green.
      Tried Nov 18 (D-440): Studio was running this morning's code (Rojo not connected), so the
      camera couldn't be seen. Rojo connected later that night: Studio has the camera now.
      Also question D-439's "an XL home's side walls don't fade" once it's seen (D-440).
      Done on a Small home (D-442), split at the run's context cap: the opening view sat inside
      every wall, so nothing faded; it now opens out past the near walls (`BuildView.homeView`,
      Lune spec), focus 1 up. Seen: the swoop, right-drag turns the right way, wheel zooms, a
      drag slides, every wall fades in turn all the way round. Captured
      (`docs/art/s5-03j1b-small-*.png`); phone and gamepad steps in OWNER.md. A Studio-only
      `CameraTest` hook drives the camera as a mouse would (STUDIO.md).
    - [x] **S5-03j1c The build camera's eye over the room, aimed into the clear band.** The
      conductor's two faults, found and fixed on a Small home (D-443): the side view's paper was
      the back wall's run past the corner (walls only slide, D-354), so the eye stays over the room
      and out the door (`BuildView.eyeBox`, Brix ENG-28b `eyeArea`, brought in level); the room sat
      under the tray, so the focus shows mid-band (`aim`, ArrangeView's `clear`). Captured before
      and after (`docs/art/s5-03j1c-small-*`). Split at the run's context cap.
    - [x] **S5-03j1d1 The roof comes off: your room alone on a dark floor.** While Arrange's
      orbit is the view, everything but your unit and the players goes from your screen
      (`ArrangeStage`), so the camera rises over the open-topped room to a dollhouse look from a
      front corner (`HomeTilt` 0.95), the near walls fading. Done (D-444): seen on a Small home,
      `docs/art/s5-03j1d-small-stage.png`; haze, blur and the bulb's distance cut handled.
    - [x] **S5-03j1d2 The room fits the band and ends at its corners.** The walls' and the floor
      paint's runs past the corners masked in the dark (`BuildView.runs`); the home view as near
      as the room fits the band, its far walls under the top bar's free middle (`BuildView.fit`);
      the limit bar to the top left; world buttons off while open; the light a touch up. Done
      (D-445): seen on Small and XL, `docs/art/s5-03j1d2-small.png`, `-xl.png`.
    - [x] **S5-03j1d3a The floor fills the band, on the screen the camera draws.** The home
      view now stands as near as the room's floor fills the band, snugly (the far walls' tops may
      run off the top; what stands on the floor up to 5 studs stays on screen); the orbit, aim
      and fit take the whole screen the camera draws (Roblox's `ViewportSize` is the safe area:
      on the A16 everything sat 10 points low and 6% small). Done (D-446): Small, Medium and
      Large seen at A16 size, `docs/art/s5-03j1d3-small.png`, `-medium.png`, `-large.png`;
      Done's close seen (your eyes, prompts and light back). Split at the run's context line.
    - [x] **S5-03j1d3b The build camera's turn, its shots and a lift.** Studio Play at A16 size:
      on Medium and Large, `CameraTest` "right" drags round the circle (the masks fade with their
      walls, no dark slab in front of the room); XL's home view captured; the front tab's dip to
      the door and, after a card chip, the hall dip; WASD on a desktop device; then a tap on a
      find in the room still lifts it (today's drag), so S5-03j2 starts from a working base.
      Verification only: fix what's broken, anything bigger goes to S5-03j2's lines.
      **Acceptance:** each seen and captured; check green.
      Done (D-447): all seen at A16 size, `docs/art/s5-03j1d3b-*.png`. One fault fixed: lobby
      signs' text drew over the dark as a white line (`ArrangeStage` now switches it off).
    - [x] **ENG-26c Nearest free spot and guides, in Brix.** Placements answers the nearest free
      pose to a blocked one within a reach, and the guide lines where a footprint's edge or
      middle meets a neighbour's on the same area. Suite cases first; the pin moves.
      Done (D-441): Brix `3cceb24` and `b8f5d71`, pinned. `nearestFree(id, shape, pose, search)`
      with `Brix.PlacementSearch.grid({ step, reach })`; `align(id, shape, pose, tolerance, into)`
      answers the settled x, y and up to six guide lines. Both pure; j2 and j3 wire them.
    - [ ] **S5-03j2 Drag it, let go** (the doc's "Moving things", items 1 to 4 and 6). Split
      in two (D-447): the drag first, on the build camera's one Gestures reader, then the tap's
      buttons, turning and riders.
    - [ ] **S5-03j2a The hand: drag it, let go.** Touch and drag anything in the room (finds,
      furniture, the home's own pieces, cubby finds) or a card up out of the tray: it lifts with
      a small stretch and a whoosh and hangs a thumb's offset above the finger (none for a mouse),
      a soft shadow on the surface under it where it would land. Let go places it: no Place
      button (D-436). Blocked, it slides to the nearest free spot and places there; nothing free
      near, it floats back where it came from (a tray card back into its card). Nothing is left
      waiting in the air. The screen near its edge follows the drag (`ArrangeCamera.follow`).
      Build:
      1. `src/client/ArrangeHand.luau` (new, header comment, typed `Hand` interface): the lifted
         state (`Lifted`) and everything that moves it, moved out of ArrangeView: `rides`,
         `aim`, `areaOf`, `settle`, `fitsAt`, `standAt`, `paint`, `setPose`, `aimAt`, the follow,
         `letGo`, `ridersOf`, `lift`, `liftDrawn`, `grow`, `liftBoxed`, `slideBack`, `puff`,
         `placeNow`, `settleOnto`, `pickAt`, `cubbyOn` and the place half of `answered`.
         ArrangeView keeps the gui, tray, tabs and verbs, and wires the hand in. Turn and Put
         away stay ArrangeView's buttons until j2b, calling the hand.
      2. One reader: ArrangeCamera's Gestures `pick` answers the thing under the point (the
         hand's `pickAt`: a placed model, or a cubby and its spot) instead of `true`; intents
         with a target (`dragBegan`, `dragMoved`, `dragEnded`, `tap`, `hold`, `twist`) go to a
         new `Options.hand(intent)`, the rest stay the camera's. ArrangeView's room
         `InputBegan`/`Changed`/`Ended` go. A tray card's drag still starts in its own gui
         input (Gestures never sees a press a button sank): ArrangeView hands its moves and
         release to the hand (`hand.move(x, y)`, `hand.release()`).
      3. Let go: fits, Place is sent at once (Arranging's existing ask, unchanged); blocked,
         `r.placements:nearestFree(id, shape, pose, Brix.PlacementSearch.grid({ step =
         Arrange.Step, reach = ... }))` over `Spots.starts(l.spot)` in turn replaces the
         hand-rolled `freeSpot` ring; nil floats back (`slideBack`). A refusal from the server
         floats back too.
      4. Feel numbers in `Arrange` (shared Config, a comment each): the thumb's offset (about
         60 points up), the stretch, the shadow's size and darkness. The shadow is one part
         made at open and moved, never made per frame; the follow steps only while dragging.
      5. Fix while there: a tapped card lifts to `ViewportSize / 2`, 10 points low on a notched
         phone (D-446): use the drawn screen's middle (`ArrangeCamera.lens`, expose it).
      6. Studio: `CameraTest` "drag" from a find's screen point (STUDIO.md's "Tapping a placed
         find") now drags it. Captures at A16 size: lifted with its shadow, placed, a blocked
         drop sliding free, a card floating back.
      **Acceptance:** each seen in Studio Play at A16 size and captured; ArrangeView shorter by
      the hand; check green.
    - [x] **S5-03j2a1 The hand in code** (steps 1 to 5, split at the run's context line, D-448):
      `ArrangeHand` holds the hand (ArrangeView 2,314 lines to 1,520); the camera's one reader
      picks the thing and hands it every drag on a thing and every tap; let go lands, hops to
      `nearestFree` within `Feel.SlideReach` or floats back; a tapped card and Set out land on
      their own after `Feel.SetOut`; thumb offset, stretch, one shadow part; Place is gone.
      Check green, untested in Studio.
    - [ ] **S5-03j2a2 The hand seen in Studio.** Step 6 of j2a, and fixes: Studio Play at A16
      size, Medium home. `CameraTest` "left" from a find's screen point (STUDIO.md's "Tapping a
      placed find") drags it to free floor: it lifts with the stretch, hangs above the point with
      its shadow under it, lands with a knock when let go. Drag it onto a blocked spot (the
      shelf's): it hops free and lands. Drag a card up out of the tray (its own gui input) and let
      go over the tray: it floats back into its card. Tap a card: it glides to the room's middle
      and lands. Tap a find, Turn, tap the empty room: it lands turned. Capture each to
      `docs/art/s5-03j2a-*.png`. Watch for: the thumb offset's sign (the thing above the finger),
      the shadow's size and darkness on oak, the shadow on a wall spot, a tap on the ghost
      itself (`pick`'s box test).
    - [ ] **S5-03j2b Select, turn, riders.** A tap without dragging selects: it lifts a hair and
      round icon buttons sit round it, Turn, Put away and Another (one more of the same out of
      your box, The Sims' eyedropper; not shown when the box has none); a tap on the empty room
      clears. Turn is a quarter turn with a ratchet click; while dragging, a second finger's
      twist turns it freely (Gestures' target twist), with a mouse R or the wheel while held;
      Alt held, or the phone's Free switch in a corner, places off the grid at any angle (check
      that Arranging and the judge take any angle; if they take quarter turns only, widen them
      with a spec). What stands on a piece moves with it (D-338's riders) and settles with a
      little bounce as it lands. The old verbs bar leaves ArrangeView.
      **Acceptance:** Studio Play at A16 size, captured; check green.
    - [ ] **S5-03j3 Snapping.** A pure snapper in `src/shared/Home` with Lune specs: the
      half-stud grid; furniture against a wall turns its back to it; a find dragged over a top
      hops onto it with a tock and back down off it; guide lines from ENG-26c drawn faint; wall
      things slide along their wall, a handle raises and lowers them.
    - [ ] **S5-03j4 Undo, and every action answers.** Undo and redo while Arrange is open (a
      pure undo list, Lune specs; the server takes each undo as an ordinary move). Every row of
      the doc's feedback table: lift, drag, onto a table, blocked (the blocker glows), turn,
      place (thud by weight, `Catalog` heft), put away (flies into its tray card), undo; phone
      taps through Roblox's newer vibration API only once checked on create.roblox.com
      (STUDIO.md).
    - [ ] **S5-03j5 Placing by hand.** In your own home a held find shows a see-through copy
      where you look, snapped and judged by the same judge; the Drop button reads Place there and
      sets it on that spot in one server step (a new ask to Arranging, checked as Take is,
      D-350). A find you Take keeps its spot (a faint outline) until set elsewhere or you leave
      your home; looking near it snaps back into it. Holding a finger on any of your things opens
      Arrange with it lifted. Elsewhere Drop is unchanged; nowhere to go, no Place (no text).
    - [ ] **S5-03j6 Several at once.** A box dragged round several things selects them; they
      move, turn and put away together; the server takes them as one move.
    - [ ] **S5-03j7 The editor seen whole.** Every row of the feedback table checked in Studio
      Play at A16 size and captured; fixes; ArrangeView's leftovers removed; OWNER.md's phone
      steps written.
  - [ ] **S5-03k The recipe system: what one thing does to another** (the owner, Nov 18,
    D-436; D-188's "hatched pets live there"; the doc's "Part 2" section). One data row per
    recipe; a fixed vocabulary of starts, stage ends, results and looks; thousands of rows by
    one lookup; nothing ticks; cheat-proof; checked by check.sh. Precedents: Stardew Valley's
    incubator and its 1.6 machine data, Grow a Garden's eggs and plants, Adopt Me's eggs.
    - [ ] **ENG-29 Recipes, in Brix.** Rows in, checked and filed at load (by what they're used
      on, then what's held: kind, then tags); `start`, `advance(record, now, event)` with
      catch-up across any gap, `due(record)`; stages ended by time, presses, things nearby,
      things given and named events; results become, make, use up, give back, chance (from a
      seed kept in the record), again. Pure; contract, suite, module page; the pin moves. Split
      a (the book: rows, checks, filing, lookup) and b (records: start, advance, due, chance).
    - [ ] **S5-03k1 Recipe rows and the save.** The game's rows in one data module (the hatch
      first: egg tag + Incubator, Place, Warming 2 h, Wobbling 10 min, becomes Chick beside);
      tags with each find's catalog row (`art/finds/rows.py`, never the generated file); Lune
      specs that fail a bad row (unknown find, unknown motion, a stage that can't end); a money
      report and a test against a ceiling in Config. The save's next version keeps each recipe
      in progress under its spot's id, with a migration and its spec.
    - [ ] **S5-03k2 The server's recipes.** A recipes system: presses checked (type, range, the
      home's holder, reach, what's really held, rate limit), applied in one save step (never lost
      or doubled, as D-350); one due list per server for loaded homes; catch-up on load; each
      stage on the drawn thing as attributes for every screen; Studio-only `RecipeTest` hook to
      skip time.
    - [ ] **S5-03k3 Egg, incubator, chick.** Their art the unit's way (finds kit for the egg and
      chick, the home's build for the incubator), each with the motions the stages name (the
      egg's wobble and crack, the incubator's lamp, the chick's tumble); the egg dealt on climbs
      at a grade the catalog gives; the incubator sold at the counter; the chick set out like
      any find. Judge each at phone size.
    - [ ] **S5-03k4 Recipes on screen.** The verb shows on a thing only while you hold what one
      of its recipes takes, near it (the incubator's lamp brightens as you come close holding an
      egg); each stage's look from its row (motion, glow, sound, growing toward the end), worked
      out from the server's two times; the hatch: wobble, crack, pop, the chick tumbling out, a
      "New" stamp. Only things on screen and near are stepped.
    - [ ] **S5-03k5 The hatch seen whole.** An egg from a climb to a chick at home in Studio
      Play at A16 size with time skipped, and a rejoin mid-hatch; fixes; OWNER.md steps.
    - [ ] **S5-03k6 The presses fold in.** Switch, Play and Wind at home run as empty-handed
      recipes through the one system; a climb's presses unchanged (their specs still pass).
  Later, each its own ticket (finds doing things at home moved into S5-03i3, D-345): living
  finds (17); the home score, visits to friends on other servers, photos (27 to 29; 29 is
  untested and waits on the owner). Trading comes later still.
- [ ] **S5-04 The collection book.** A page for every kind of find, stamped "New" the first
  time; each kind of monster trapped; sets.
- [ ] **S5-05 The shelf in the elevator.** The host's three best finds, shown in the car.
- [ ] **S5-06 Perks.** Unlocked by a first floor reached or a set finished, bought with cash,
  two picked before a climb.
- [ ] **S5-07 On sale.** Double cash, cash packs, the starter pack (after your first climb) and
  decor. Then the friend's matching beam colour for joining on your link, and cart cosmetics
  (D-112). The luck boost: one use, used in the elevator, better odds of rare finds next floor;
  its odds shown before buying and while it's on, never sold where Roblox restricts paid random
  items (D-188). The home's Robux sizes, large and XL,
  are S5-03h3 now (D-340); the chest holds everything for everyone.

### Step 6: Coming back

Done when players come back the next day without a friend asking them to.

- [x] **S6-01 Best floor.** Done Nov 18 (D-432 to D-434). On a plaque and on the dial over your car; badges at floors 10, 25,
  50 and 100, for each kind of monster trapped and each set finished. Split Nov 18 (D-432):
  - [x] **S6-01a The best floor saved, the badges awarded. Built Nov 18 (D-432); passes checks,
    the load seen in Studio Play (no ride yet).** The moment: you ride onto floor 10 for the
    first time and Roblox's own badge toast pops. Your best floor rises as the car brings you onto
    a floor and at the climb's end; the monsters shut in on a floor are stamped in the book of
    everyone who rides its gate out; badges are worked out from the save and sent once a visit.
    No save change: `bestFloor` and the book's monsters page were there from version 1. Every
    player's best floor is on them as an attribute for the lobby's screens. Badge ids are the
    owner's to make (OWNER.md). In Play the test save loaded with best floor 0 and earned the
    night-lights' and the big finds' set badges (Output; nothing sent without ids).
  - [x] **S6-01b The dial and the plaque. Built Nov 18 (D-433); passes checks, the plaque seen
    drawing in Studio Play (your row, your best, lit), the roll not yet seen.** The moment: you walk into the lobby and the dial over
    your car already reads your best, your friends' best floors on the plaque beside it. My plan
    (D-432): the line under the dial's bay number reads "Best 12" in gold for the best of those
    aboard whenever it has nothing more urgent to say ("Going up", "Floor N", "Full", "Friends
    only" still win), so you alone in a car, or a team landed back, read your own; it pops up to a
    new best as you land. The plaque: a brass plate on the bay wall beside each gate at eye
    height, those aboard listed best first, photo and floor, your row lit; a plain part with a
    SurfaceGui as the dial is (`CarDial`). Both read each player's `BestFloor` attribute
    (`Badges.BestAttribute`). Read first: `CarDial.luau` (`lineFor`, `build`, `draw`); D-124;
    `art/lobby/spec.py` (`bay_xs`, `BAY_PITCH`, `NUMBER`, `JAMB`).
  - [x] **S6-01c Seen in Studio Play. Done Nov 18 (D-434; `docs/art/S6-01c-*.jpg`).** From
    lobby Car1 to floor 3 and back: Output said "best floor is now 2", then 3 (floor 1 counts
    only at a climb's end). From the test hall's floor 9 to 10: "best floor is now 10" and
    "earned the Floor10 badge (no badge id yet)". Seen at A16 size: the roll (Best 3 to 10, and
    10 to 25 on a raised attribute), Friends only taking turns with "Best 10" (3 s, 2 s), the
    plaque's row "10" lit. Fixed: the dial and plaque read only those aboard, and from inside the
    car you can't see the dial, so your own new best never rolled on your screen; an empty car
    now keeps to its crew, those last aboard, until they board another car (`Bests.shown`,
    `Bests.without`). The clack, thunk and chime by ear: `OWNER.md`.
    Polish: the dial's gold line is about 7 pixels tall on the A16 from 13 studs out (the whole
    dial is 3 studs tall); a taller dial or line wants room on the bay wall (`art/lobby/`). A
    "New best" line with its own sting on the car's board as the haul ends (S5-01's board).
- [ ] **S6-02 The Missing board.** A wiped team's photos and the floor they were caught on.
- [ ] **S6-03 The free door once a day** in the lobby, a better find on the seventh day running.
- [ ] **S6-04 Private servers and clips.** Private servers free or nearly; Roblox saves a short
  clip at the GDD's ten moments.
- [ ] **S6-05 The weekly shelf.** Three cosmetics at the counter, changed each week.

Then the soft launch (GDD "Build order").

### In no step

Each waits on the owner (`OWNER.md`) or comes after launch: the monster you hide from; the
monster that takes your head; the stair chase and other floors that play differently; monsters
that hear your feet (held off, D-251); trading; a season pass; boss floors and units far bigger
inside than they look (D-188); the item catalog's waves (its own build order), with pets and
plants that live in your unit, and the arcade cabinets' games; fake notes, finds that are monsters in disguise, the monster
that moves walls, and the dolly. What the Packrat does with a marked box (B-03) is to be worked
out (for now it leaves shut boxes alone, D-211). A tall marked box for the big finds (the lamps,
the TV) waits on `OWNER.md`.

## Find art: the catalog's wave 1 (from Nov 14)

The owner asked on Nov 14 for the catalog's finds as world-class models, built through the night
(D-190). The bar and the method are in `art/finds/CRAFT.md`; each find's row and whether it's
built are in `art/finds/WAVES.md`. These tickets make the art and the motion data only: the
actions themselves and dealing the new finds on floors are later game tickets.

- [x] **F-01 The finds kit**, proven on the desk lamp (Nov 15).
- [x] **F-02 The Lights** (the other 15), a few finds a session:
  - [x] **F-02a** The plug-in night-light (Nov 15); the kit gained lofts for shells that
    aren't round.
  - [x] **F-02b** The tea light in a jar (Nov 15); the kit gained see-through glass, the
    `scale` and `stretch` channels and a first-person held sheet (D-192).
  - [x] **F-02c** The bundle of glow sticks and the string fairy lights (Nov 15); a light may
    give its own `rgb`.
  - [x] **F-02d** The camping lantern (Nov 15), with no kit change.
  - [x] **F-02e** The moon lamp (Nov 15).
  - [x] **F-02f** The blob lamp (Nov 15); wax parts can bake alone, a long loop previews at
    fewer frames a second.
  - [x] **F-02g** The oil lamp (Nov 15); renders can skip actions (`ACTIONS=`).
  - [x] **F-02h to F-02l** The disco ball, the neon OPEN sign, the miner's hard hat, the jar
    of fireflies and the theatre spotlight (Nov 15).
  - [x] **F-02m** The stained-glass lamp (Nov 15, D-198).
  - [x] **F-02n** The lamp that's on when you find it (Secret), the last Light (Nov 15,
    D-199); a motion may set its filmstrip camera (`view`, `drop`).
- [x] **F-03 The remote-control car and the die-cast car** (pulled forward from wave 4).
  - [x] F-03a The remote-control car and its transmitter (Nov 15, `art/finds/figures/`).
  - [x] F-03b The die-cast car (Nov 15, D-200; uploaded and in the place).
- [x] **F-S1 Into Studio:** the Lights and the cars uploaded, inserted and judged at phone size (Nov 15: `Finds/Kit.luau`, D-194; the die-cast car waits on F-03b).
- [ ] **F-G1 The new finds in the game.** The finds built overnight show up in units and work in
  your hands; until now a floor dealt only the bedroom four. The moment: a door rolls up on
  something you've never seen, and the rare ones are rare. Split Nov 15:
  - [x] **F-G1a Dealt, taken, carried and banked** (Nov 15, D-203; seen in Studio Play on floor 1:
    unit 109 dealt the disco ball, taken, held, dropped). 19 of the 20 join the deal with the
    item catalog's grade and worth (`Grades`, `Tools.Catalog` rows); a unit rolls a grade by
    its floor, then a find of that grade (`Deal.findFrom`), the Packrat's pile too; each is
    stood as it's found (`Finds.pose`, `Finds/Pose.luau`: the jack shut, flames out, the
    Secret lamp lit); the Packrat takes your most valuable find first. The theatre spotlight
    waits for big finds (both hands, the floor's big find behind the code door).
  - [ ] **F-G1b Using a find plays what it does.** Its own press while it's in your hand, as the
    air horn's Blow: the lantern clicks on, the tea light catches and flickers, the glow stick
    cracks, the jar's fireflies drift out, the jack-in-the-box cranks its tune and bangs open
    and every monster on the floor hears it. Split Nov 15 (the session ran short of room):
    - [x] **F-G1b1 The rules of every press** (Nov 15, D-229): `Finds/Use.luau`, pure and tested
      (tests/finduse.spec): each find's row (its word, the motions a press plays, how long it
      stays lit, how it runs down, a switch's off, the jack's shut before winding again, the
      motion monsters hear), `frame` (where a stamped find is in its motions), `press` (what a
      press does now, nil when it does nothing) and `noiseAt`. Rows for the tea light, oil lamp,
      glow sticks, fairy lights, lantern, hard hat, firefly jar, disco ball and the jack.
    - [x] **F-G1b2 The press in the game** (Nov 16, D-231): `FindUses` stamps a pressed find's
      model on the server; `FindUseView` plays its motions, light and sounds on every screen by
      its joints (`Finds.joints`), your own on your view's copy at once; the button hides while a
      press would do nothing. Each press seen in Studio Play.
    - [ ] **F-G1b3 The cymbal monkey's lure, the cars, found lights hold a Mannequin.** Split
      Nov 16:
      - [x] **F-G1b3a The monkey's lure and the toy car** (Nov 16, D-233; both seen in Studio
        Play): wound, the monkey clangs a cymbal on every clash and every monster on the floor
        hears it every 2 s until it stalls (`Use.lureUntil`); pushed, the toy car is set down in
        front of you and rolls about 7 studs, stopping short of a wall, where the server already
        laid it (`Use.FromAttribute`, `Finds.joints`'s `from`).
      - [x] **F-G1b3b A lit find on the floor holds a Mannequin** (Nov 16, D-234; seen in Studio
        Play): a found light lying lit is a light the Mannequin stops in, as far as its own lamp
        reaches (a camp lantern about 10 studs, a tea light 7), shaded by walls and shut doors,
        until it runs down (`Use.litUntil`, `Keeper.Glows`). In a hand it holds nothing yet
        (`OWNER.md`).
      - [ ] **F-G1b3c The lamps and the RC car work in the building** (the owner, Nov 16, D-250).
        Split Nov 16:
        - [x] **F-G1b3c1 The lamps switch on anywhere** (Nov 16; seen in Studio Play): the desk
          lamp, night-light, moon, blob and glass lamps and the neon sign each get a Switch,
          lit about a minute (`Use.LampLasts`), keeping what's left when switched off, fading out
          by their switch-off when spent; lying lit, each holds a Mannequin as far as its light
          reaches. The moon lamp's phase tap stays for home.
        - [ ] **F-G1b3c2 Drive the RC car** (Rainbow Six Siege's drones). The moment: you crouch
          in a unit with the door half down, and through a camera on the car's hood you watch
          the hall for what's coming. Press Drive: the car is set down in front of you and your
          view moves to its hood, low and wide; the move stick drives it (forward, back,
          steering) down the halls and into any open unit, never through a shut door or a wall;
          a button brings you back to your own eyes and the car stays where it is. Your body
          crouches still with the transmitter, and a monster can catch it there: caught, the
          drive ends. Smooth on the driver's screen, the server checking every move (a speed
          cap, no walls), friends seeing it drive. Answers: a motor whine rising with speed, a
          jolt on a bump, the transmitter's antenna in your hands. Take it back by walking to
          it, or by driving it to your feet. Split Nov 16 (D-252): how a driven thing moves is
          built in Brix, for every game, then used here. The car is a physics body the driver's
          own device moves (walls and shut doors stop it as they stop you, and friends see it
          move smoothly), and the server checks every move.
          - [x] **F-G1b3c2a How the car answers its stick, in Brix** (Brix ENG-24a): Brix's
            Handling, throttle and steering in, the speed to drive at and the turn out, a car
            that can't turn standing still, held back by whatever stops it.
          - [x] **F-G1b3c2b Driving a body from a player's device, in Brix** (Brix ENG-24b):
            the server hands the body to its driver and checks every move, the client reads the
            move stick on any device and steps the handling. Built and run in Brix's Studio.
            Done Nov 16 (Brix `c9f6667`, pushed, CI passes): `Brix.MoveCheck.ground` and
            `Brix.Roblox.Driving.server` and `.client`. In Brix's example place a car driven at
            the wall stopped flush against it, a teleport and a hop through the wall were put
            back, and the driver leaving ended the drive. What c needs to know: the server holds
            the car half a second after a bad move (`putBack` fires, for a jolt); the client's
            `asked()` gives the speed and turn for the whine and the wheels; `controls` is where
            the sideways push mixes in throttle; the car's floor parts need low friction.
          - [x] **F-G1b3c2c Drive it.** The pin moved; the car set down in front of you apart
            from its transmitter, which stays in your hands; your view on its hood, low and wide
            with a jolt on a bump; the stick drives it through Brix; a motor whine rising with
            speed; its wheels turn and steer; the back button; walking to it takes it back.
            Studio Play: from the lobby down a hall into an open unit, stopping at a shut door.
            Done Nov 16 (D-254, pin `c9f6667`): `Finds/Drive`, `Drives`, `DriveView`. In Studio
            Play, steered by script in the dev hall: set down, driven, from standing to 16 studs
            a second in 0.4 s and stopped dead at a shut door with no put back; Back gave your
            eyes back and anchored it; walking to it took it back. Not run: into an open unit
            (every dev-hall door was shut), the phone stick, a friend's view (OWNER.md).
            Polish, by name: the wheel, Drop and torch buttons still show while you drive (hide
            them, Back alone); the Back button's own press motion; a static fizz on a put back;
            the inner front wheel turning more than the outer (the art's Ackermann); the wheels
            and springs pose by `Finds.joints`, which allocates a little each frame for a car in
            view (fine for one car; a pooled pose if more drive at once).
          - [x] **F-G1b3c2d The driver's body.** You crouch still with the transmitter, its
            antenna up; caught, the drive ends; driving it to your feet takes it back; friends
            see it drive (their view and the phone stick go to `OWNER.md`).
            Done Nov 16 (D-256): `DriverBodies`, `Drive.Crouch`, `Drive.home`, Drives' tag,
            caught end and re-grip, DriveView's `leave`. In Studio Play: crouched on your heels,
            the transmitter upright in both hands (right hand within 0.06 of its wheel), seen
            from the hood after a U-turn; your root still while crouched; driven home from 11
            studs ("driven home" in Output) with your view, grip and stance back; caught (by
            hand: the caught mark and the catch message) ended the drive ("caught") and the
            lunge started from your own eye. Not run: a friend's view, a phone, a real
            keeper's catch (OWNER.md).
            Polish, by name: the aerial telescoping up as you press Drive (split it out of the
            transmitter in the art); the first-person view's transmitter still held by the car's
            roof while its car is out (ToolView's copy); a small settle of the shoulders as the
            car moves, so a crouched driver isn't a statue.
          - [x] **F-G1b3c2e The car sees in the dark** (the owner, Nov 16, D-255; Outlast's
            camcorder and Phasmophobia's video cameras). The moment: you drive out of a lit
            hall into a dark one, the view clicks over to grainy green, and at the edge of what
            it shows two white eyes look back.
            1. Where the lights near the car are on (motion lights tripped and powered, a unit's
               bulb lit), the hood view is in normal colour. Where they're out (not tripped,
               or a breaker thrown), it's infrared: black and white with a green cast and a
               little grain. Where the lit state lives: `MotionLights`, `HallLights`,
               `UnitLights`, `Breakers` (CODEMAP).
            2. The switch answers: a small relay click and a quick flicker as it changes, as a
               security camera's night mode does; lights tripped or switched back on near the
               car flick it back to colour the same way.
            3. Infrared, the car carries a lamp only the driver's screen sees, about 30 studs
               ahead and fading to black past that. Friends see no light. It isn't a light in
               the game's rules: it doesn't hold the Mannequin or stop anything light stops.
            4. Monsters' eyes shine white in it (Outlast's night vision), for each monster with
               eyes to light.
            5. Back gives you your own eyes in full colour at once.
            6. Your own torch is held to your view wherever it is (`Workspace.YourFlashlight`),
               so while you drive it sits on the hood and, lit, lights the hall ahead like a
               headlight: hide it and its light while your view is on the car (DriveView's
               `viewing`), its light back as it was when you're home.
            One real light on one screen, only while driving and dark: fine on low-end phones.
            Whether the car trips motion lights itself waits on `OWNER.md` (default no).
            Done Nov 16 (D-257): `Finds/Infrared`, `InfraredView`, DriveView's `hull`,
            FlashlightView's `away`. In Studio Play: the dark dev hall went infrared with the
            click and flicker once the view landed on the hood; a hall light tripped beside the
            car (a moving part tagged to trip lights) gave colour; as it timed out the view
            flickered back to infrared within a tenth of a second; a Mannequin 12 studs down a
            dark hall stood in the lamp with two pale eyes; Back gave colour on the frame the
            camera came home; a torch left on went dark on the hood and lit again after Back.
            Not run: a phone, a friend's view (OWNER.md, the RC car's steps 8-9).
            Polish, by name: the car's own front is black in infrared (the lamp lights only
            ahead; a faint spill on the bonnet); a quiet hiss under the infrared; a friend's
            torch on the car, or a lit find on the floor, counted as light (D-257 left them out).
        - [x] **F-G1b3c3 The collector steals it** (Nov 16, D-258). The car out is where the
          Packrat sees the RC car (`Slots.out`, told again as it moves); its hands closing on it
          bring the transmitter to the car and take the whole find to its pile, where it's taken
          back as any find. The driver's view lifts 2.8 studs, tips and rolls, shakes, cuts to
          the feed's snow and hiss, and comes home (`Drive.lifted`). Robbed from a driver's
          hands, the car comes home into the transmitter first. The car lives in its floor's
          model; at the gate an RC car with its car out isn't kept, and its transmitter dies
          with a crackle as the floor below is cleared (`Slots.lose`). Fixed: pocketing the
          transmitter destroyed the car. In Studio Play: driving from a unit's roof, a Packrat
          stood in Unit101 walked out and took the car at 3.6 s; the driver's camera rose 2.8
          studs over 0.5 s, solid snow 0.35 s, then home with the snow gone by 1.1 s; it laid
          the whole car (14 parts) on its pile with "Take"; standing in its way with the car
          parked, it robbed the transmitter and the car came home into it; pocketing left the
          car out; destroying Floor1 with the car out took the transmitter from the hand with
          the break answer. Not run: taking it back off the pile (it caught me there twice),
          a real gate shut, a phone, a friend's view (OWNER.md, the RC car's steps 10-12).
          Polish, by name: infrared stays on through the lift when the car was in the dark
          (it goes to colour as the car leaves the floor); the car's own crackle through the
          transmitter's speaker as it's lifted; a friend seeing the car vanish from the floor
          when the Packrat robs its driver (a puff, or the car flying to the hands); A friend
          picking the car up to end your drive (in the old line, not built: nobody can pick
          the car up; it's out of anyone's reach but its transmitter's).
        - Home: it drives round your home too, once home is built (S5-03).
    - [x] **F-G1b4 The hard hat goes on your head** (the owner, Nov 16, D-251; Phasmophobia's
      head torch). The moment: your flashlight stutters out, no battery, the Mannequin two halls
      off, and you pull the hard hat on. First a head and feet on the character, apart from the
      slots (welded as the ladder is). Wear lifts the hat onto your head with the shell's knock
      and the lamp's click, lit, and frees its slot. Its headlamp beam is tighter and whiter than
      the flashlight's, goes where you look and bobs with your walk; friends see the light on
      your forehead. It holds a Mannequin as any found light does. It lasts a minute, dimming and
      stuttering out as the flashlight dies, and no battery refills it: spent, it falls off your
      head and breaks as the saw does (D-141's break: bits fly, a clank monsters hear, a fade).
      Caught, it drops with everything else. On a phone only the nearest few headlamps light
      the walls, as the hall lights do. Split for one session each (Nov 16):
      - [x] **F-G1b4a1 On your head and lit** (D-277; seen in Studio Play with one player,
        the two-client view waits on `OWNER.md`). Wear (the hat's one word, replacing its
        Switch) takes it from your hand onto your head (`Slots:toHead`, `Finds/Head`'s fit),
        frees its slot, the shell's knock as it lands and the lamp's click as its switch flips;
        it lights the hall from your forehead for everyone with the hat's own lamp; it holds a
        Mannequin as a found light lying lit does, from where your head is; caught, it drops
        with the rest; aboard at the gate, it's kept with your finds; on the ground floor its
        light never runs down.
      - [x] **F-G1b4a1b Out of your own eye** (D-282; seen in Studio Play, `docs/art/F-G1b4a-own-view.jpg`).
      - [x] **F-G1b4a1c On top of your head** (D-283; it sat at your chin: seated by its rim, grown
        with your head, big enough to sit over your hair; seen in Play and in the mirror).
        With your camera at your head, the hat you wear is hidden from you alone (`HeadView`,
        eased), even under a camera the game holds, where Roblox's own first-person hiding
        stops; friends and the mirror still see it on you, and its lamp still lights the way.
      - [x] **F-G1b4a2 The headlamp's beam** (D-420; seen in Studio Play with one player, a
        friend's view through `HeadlampTest`, the two-player look waits on `OWNER.md`). Your own beam drawn from your eyes, tighter and
        whiter than the torch's, going where you look (pitch too, not just where your head
        turns) and bobbing with your walk (`Torch.step`'s stride); the beam swinging up into
        place as the hat goes on (the pull-on, felt in first person); friends' beams from their
        lamp along their aim (`Aim`), replacing the hat's warm art light while it's worn; the
        hat dropping onto a friend's head with a little settle rather than appearing there.
      - [x] **F-G1b4b Spent and broken** (D-421; seen in Studio Play with one player and a
        20-second minute, `docs/art/F-G1b4b-*.jpg`). Its last 15 seconds stutter, sag and buzz as
        a dying torch does, a friend's bulb dimming with its beam; then its bulb sputters out (the
        art's `RunDown`) with the beam following it; spent, it slips off your head and cracks
        apart on the floor, its bits flying, heard by monsters as a dropped tool (D-141's break),
        and it's lost. (On a phone only the nearest few light the walls: F-G1b4a2.)
    - [ ] **F-G1b5 Skates and slippers**, their art first (not yet in `art/finds/WAVES.md`):
      Wear puts them on your feet. Slippers are looks only. Skates make you faster (default:
      faster than your walk, still slower than a chasing monster, tuned in play), with the
      wheels' roll under you. Monsters don't hear feet (D-251).
  - [ ] **F-G1c The grade shows. Parked Nov 15 (owner: cut for now, D-204):** the reveal moved
    from the door to the box you open (B-02, D-205). As written (the catalog's
    "How you can tell"): a Rare's blue glow seen
    from the door and a chime, an Epic's purple light spilling as the door rolls up, a
    Legendary's gold light under the door before it opens, heard by the team. Needs the owner's
    look; the copy of what each grade is stays off screen (no text that explains a rule).
  - [x] **F-G1d The Nov 16 finds dealt** (Nov 16, D-253; seen in Studio Play on floor 1, seed 7:
    of 14 units opened, five dealt new finds (the stress ball, two mochi buns, the kazoo, the
    butter stick); the stress ball came out of its box into your hand, rode up and was kept at
    the gate). The other 12 wind-ups and 10 squishies built overnight join the deal with the
    catalog's grade and worth (`Tools.Catalog` rows, `Deal.Finds`), each stood at its rest as
    it's found; the glitter goo ball imported into the place. The four squishies not built yet
    (the goo ball, the colour-change goo ball, the cake slice, the mega goo ball) join as built.
  - [ ] **F-G1e Pressing the wind-ups and squishies.** Each one's own press while it's in your
    hand, as F-G1b did for the Lights (`Finds/Use` rows, `FindUses`): the wind-ups' noise that
    monsters come to (the teeth chatter off, the robot clanks down a hall, the mouse zips and
    squeaks, the tin bird hops and whistles, the carousel turns and plays, the siren car rolls
    off wailing; the kazoo, duck, drum, spinner, cowboy doll and fish on a press), and squeezing
    the squishies (the dent filling back in, the beads, glitter and stars swirling, the
    capybara's sigh). Split by the third find run's audit (Nov 16, A1: `art/finds/WAVES.md`,
    "Every built find, in the game"), each seen in Studio Play before it's ticked:
    - [x] **F-G1e1 Squeeze (the run's V1).** (Nov 17, V1a and V1b; D-267, D-269) The ten built
      squishies and the rubber duck: each
      squashes (its stretch or its bones) and squishes, squeaks or crinkles with a sound of its
      own. New piece, built once here: a loudness for each noisy find (how far monsters hear it,
      in place of the air horn's one reach) and a cap on lures at once and how often, for
      low-end phones. The duck's squeak lures down the hall; the squishies are quiet (the
      catalog's Squeeze). Untested: bones and stretch in one press.
      - [x] **F-G1e1a** (Nov 17, V1; D-267): the loudness (`heard`, `Use.loudness`) and the cap
        (`Use.Din`); all eleven presses as data with a sound each; seen in Play: each pressed,
        stamped and its sound playing, the duck's squeak waking a Mannequin 46 studs off.
      - [x] **F-G1e1b The squash in your hand.** (Nov 17, V1b; D-269: the root sized, bones bent
        by their CFrame since a character's Animator resets Bone.Transform; all eleven measured
        squashing in hand and in your view in Play.) Seen in Play before: `Finds.joints` never sizes a
        find's first part (its root, `i == 1`) and the strawberry's bones didn't move in hand,
        so the duck, mochi bun, paper squishy, toast, butter stick and strawberry don't squash at
        all, and the others' bodies stay still while their insides move. Size the root about its
        middle in hand (it can't move: the grip holds it) and find why bones don't bend in hand;
        then see all eleven squash in Play. Ticks F-G1e1.
    - [x] **F-G1e2 Wind and go (V2).** (Nov 17, V2a and V2b) The chattering teeth, walking robot, wind-up mouse and
      tin bird are set down and travel on their own paths, stopping at walls (the toy car's
      way), luring as they go: the lure heard where each one is along its path, not where it
      ends; the mouse's squeak where it stops. The tin carousel plays in place on the monkey's
      lure. Each with its loudness.
      - [x] **F-G1e2a The travel lure and the teeth.** (Nov 17, V2a; D-270) A noisy set-down
        find heard where it is along its path; a wind-up `walks` on at a wall; a hit on every
        peak (`Use.beats`); the chattering teeth wound, set down, chattering off with a clack
        each snap, a Mannequin drawn to them. Seen in Play, except the walk at a wall.
      - [x] **F-G1e2b The robot, mouse, bird and carousel.** (Nov 17, V2b; D-272) Their rows
        and sounds on V2a's verb, all four seen in Play: the robot's clanks drew a Mannequin to
        it, the mouse zipped into a wall and squeaked on there, the bird whistled in pairs (a hop
        no longer reads as a wall), the carousel's tune. Ticks F-G1e2.
    - [x] **F-G1e3 One press, one noise (V3).** (Nov 17, V3a to V3d) The kazoo, toy drum, farm-animal spinner,
      cowboy doll and singing fish: each its motion, its sound and a loudness on the jack's
      one-shot noise. The doll and the fish ship the owner's defaults (the cord's whirr, the
      motor's hum) until their voices are recorded (`OWNER.md`). Split at a find:
      - [x] **F-G1e3a The timed sound, the kazoo and the drum.** (Nov 17, V3a; D-274) A step's
        `cues` play sounds partway into its motion (`Use.timeline`, with its `hit`'s beats); the
        kazoo hums once at your lips, heard 60 studs; the drum bangs at each of its five hits,
        heard 130. Both seen in Play, each waking a Mannequin that turned to it.
      - [x] **F-G1e3b The spinner, the doll and the fish.** (Nov 17, V3b; D-276) Their rows on
        V3a's `cues`, each heard 60 studs: the spinner's lever clack, a tick each notch, the cat's
        meow as it stops; the doll's whirr and clack home; the fish's click, motors' hum and two
        knocks. A part's last key is no beat (`Use.beats`). All three seen in Play; the spinner
        woke a Mannequin that came to it.
      - [x] **F-G1e3c The kazoo's lift to your lips, in hand.** (Nov 17, V3c; D-278) A root's own
        tip and lift move the grip that holds it (`Pose.carry`, `Finds.shift`, `Finds.grip`,
        `Hand.shift`): the kazoo tips 7.5 degrees in your hand and your view, and settles back;
        the squishies still squash about their middle. Seen in Play.
      - [x] **F-G1e3d The farm spinner lands on any animal.** (Nov 17, V3d; D-279; seen in
        Play: six pulls landed rooster, cow, cat, rooster, dog, rooster, your view's copy with
        the held one, each call about 3.25 s in.) The server picks one of the eight
        each pull (never the one it's on) and writes it with where it started beside the stamp;
        every screen bends the arrow's keys so it ends there (all keys plus the start, the keys
        from its first move plus whole extra eighths) and plays that animal's call, the ticks
        unchanged. A step's `lands` field in the art spec (part, stop size, when the call plays,
        the eight calls in the face's order), rows.py and `Game.Step`, pure rules in `Finds/Use`
        with a Lune spec. The design and the sounds found so far are in `art/finds/WAVES.md`'s
        V3c note.
    - [x] **F-G1e4 The siren car (V4).** It rolls as the toy car does, its beacon spins and
      lights the hall while it rolls, and its wail lures along its path (F-G1e2's lure).
      - [x] **F-G1e4a Built** (Nov 17, V4; D-281; passes checks, not yet seen in Play: Studio
        was in the home chain's Play for the session's last 20 minutes). Its row (`down`,
        `walks`, the wail from the first push, the roll as it's let go, a 90-stud lure every
        2 s); a find's real lights only within the 90 studs screens pose finds, put out when
        it leaves (`FindUseView`); finduse.spec holds its light out after a wall stop.
      - [x] **F-G1e4b See it in Play** (Nov 17, V4b; seen in Studio Play, not on a phone).
        The wail measured (4.77 s, whoops audible from 1.0 s, dead at 3.67 s) and set to start
        there at 0.7 and 1.4, so the press answers at once and it whimpers away as the car
        slows (from 0.34 s the pushes were near silent). Seen: set down, pushed, rolled 9.6
        studs and ran down, or 6 studs into the lobby's wall at 2.6 s and held there with its
        wheels and beacon turning; lit till 6.9 s, then out; the red beam sweeping the dark
        lobby (`docs/art/V4b-siren-car-*.jpg`); a Mannequin 64 studs off walked to it and
        stood looking. Output: nothing from this work.
    - [ ] **F-G1e5 The rest the audit found (V5).** Each seen in Play before it's ticked:
      - [x] **F-G1e5a A press on a one-mesh find** (Nov 17, V5a; seen in Studio Play, not on a
        phone; D-286): the boombox's Play (its key clacks, 80s electro for 15 s, the case thumping
        on each beat and swaying from its handle, lures every 2 s as far as the air horn, in hand
        or where you leave it) and the teddy's Hug (squashed to 0.78, a tiny squeak, a wiggle
        back). `Finds/OneMesh` by hand; a tune joins where it is for a find come upon part way
        (`Use.join`). Seen: a Mannequin 56 studs off woke and came, then went to the dropped
        boombox; the song carried on after the drop.
      - [x] **F-G1e5b The glow sticks' other two sticks** (Nov 17, V5b; seen in Studio Play, not
        on a phone; D-292): each press cracks the next stick, three to a bundle: the bottom two
        kink outwards, snap and are shaken, each lighting its own small glow; every crack snaps
        (the first had no sound). A light's row can carry `more`, the stamp a `count`. Seen: the
        count 1, 2, 3 and a fourth press refused; each stick's glow and light on in turn; the
        bends peaking 32, 34 and 30 degrees, the shakes after; the snaps at 0.60, 0.60 and
        0.65 s, the slosh at 0.72 and 0.78 s.
      - [x] **F-G1e5c The fairy lights laid along a hall** (Nov 17, V5c; seen in Studio Play, not
        on a phone; D-294): set down lit, the string runs out 8 studs along the floor from the box
        in 0.6 s with a soft slither, twenty warm LEDs and the copper wire lying loose, the coil
        hidden; away from whoever let it go (on ahead, or back down the hall when dropped at a
        run), the longest clear way, to the first wall or the floor's edge. A Mannequin is held
        all along it, 4 studs either side (`Finds/Strand`, `StrandView`); one real light more.
        Seen: laid from -638.2 to -646.2; the Mannequin heard the drop 18 studs off, came for me
        and froze at -650.0, 3.8 studs past the far end (the coil's own hold ends 7.2 from the
        box), held 20 s with me in sight.
      - [x] **F-G1e5d The Old lamp holds a Mannequin while it lies lit** (Nov 17, V5d; seen in
        Studio Play, D-289): its row says found lit (`lit`), and the server reads it as lit for
        good with no press (`Use.lampUntil`). Seen: dropped in a hall, its clank woke a Mannequin
        17 studs off, which stopped 8.0 studs from it (its reach) and held there 50 s, hunting
        the player from 12.6 studs. Not seen: lifting it again to watch it walk on.
      - [x] **F-G1e5e Fragile, built** (Nov 17, V5e; D-296): the oil lamp's chimney and the glass
        lamp's shade crack when let go hard (a run, a fall, or from high up; `Finds/Chip`): heard
        over the clank, drawn on the glass, once, worth half, saved (version 7, `chipped`). Seen:
        a set-down standing didn't crack; let go 4 studs up, it cracked, heard on the clank.
      - [ ] **F-G1e5e2 Fragile, seen whole:** the crack drawn (its image ID fixed after Play), in
        your hand too (`ChipView`), and a cracked lamp banked at a gate (`chipped` in the save).
        (Nov 17, Q1a part two: banked cracked, `chipped` OilLamp 1 in the save; the dropped
        lamp's two decals fetched on your screen. Left: the crack on your view's copy in hand,
        and a look by eye, which the locked Mac didn't allow.)
      - [x] **F-G1e5f The carousel's tune slows as it runs down** (Nov 17, V5f; seen in Studio
        Play, not heard on a phone; D-288): no recording of a box running down was found, so a
        tempo change that keeps the pitch: the tune's speed follows the top's own run-down
        (`RIDE`: full to 9.5 s, then (1 - s) ^ 1.4 to nothing at 15.5 s), two pitch shifters
        hold its notes down to a quarter speed, then it fades as the top stops. A tune joined
        part way slows on from where it is; a drop that carries your own copy to the floor no
        longer plays the tune twice (the boombox's too).
    - [ ] **F-G1e6 Every built find in Studio Play (the run's Q1).** Each find dealt into a unit,
      taken, carried out through its door, banked at a gate (GatePay keeps it) and pressed
      (motion, sound, its effect on the floor), written in `art/finds/WAVES.md`'s "Every built
      find, in the game" table. Each failure gets a fix ticket below (Q2, Q3 ...) with its steps.
      - [ ] **F-G1e6a The deal command, the Lights, the cars, the bedroom four, a cracked lamp
        (Q1a).** Workspace's `DealFind` (Studio, or the owner's server console live) deals a
        chosen find into the shut unit nearest you and lifts its door. Then the 15 dealt Lights,
        the two cars, the Boombox, TV, Teddy and Skates, and F-G1e5e2 (a cracked lamp drawn and
        banked). (Nov 17: `DealFind` built and used in Studio Play; ten Lights dealt, taken,
        carried and pressed, six banked at the gate. Nov 17, part two: nine more banked over
        three floors, the night light, fairy lights, oil lamp and glass lamp lit in hand, and
        most of F-G1e5e2: the oil lamp cracked, taken back up and banked cracked. Left: the Old
        lamp, the two cars, the TV, teddy and skates, the crack in hand, WAVES.md's Next line.)
      - [x] **F-G1e6q2 The firefly jar's light, and a press right after a slot switch (Q2;
        Nov 17, D-400).** Found in Play: the jar keeps its light on a switch back (its fireflies
        glowed in 64 of 64 samples and drifted; its three real lights blink with them by its art,
        one on in 26), so Q1a read it between blinks. The press limit never refused (four a
        burst). Two real races: a box's find landing as its reveal ends took your hand back from
        a slot you'd switched to (fixed: `Carry.take`'s `keep`, seen in Play), and a press within
        one round trip of your own switch went to the find you held before on your screen, or
        nowhere if that one took no press (fixed: HornView waits for the switch, `hand.landing`;
        passes checks, the lag not reproducible in Studio). The original lines:
        Seen in Play (Q1a): `DealFind` the neon sign, disco ball and firefly jar (Units 107,
        106, 105 on seed 7's floor 1), open the three boxes, then for slots 1 to 3 fire
        `ToolSwitch(slot)`, wait 1.5 s, `ToolUse`. The jar stamps On (`UseState`), but switched
        back to it 25 s later its three PointLights in `Workspace.YourTool.FireflyJar` are off
        and no fireflies show, inside its minute. And a press 1.5 s after a switch twice did
        nothing or reached the find held before (the camp lantern's first press; the disco
        ball read Off). Find which: the press limit (`Carry.allow`), the switch still landing,
        or the jar's view not restoring a lit state on a switch back (the tea light's does).
        Whatever drops a press must answer it (AGENTS.md: no silent state changes).
      - [ ] **F-G1e6b The 14 wind-ups and noisemakers (Q1b).**
      - [ ] **F-G1e6c The 14 squishies (Q1c)**, with L1b: the rebuilt glitter and galaxy balls
        squeezed in hand (shorten the galaxy's light to 1.5 if it still tints a neighbour).
  - [x] **F-G1f Each find's game row comes from its art (the run's P1; Nov 17).** `art/finds/PIPELINE.md`
    (photos to playable in one ticket); each kit find's grade, worth, floors, verb, the verb's
    numbers and sounds in its art spec; the export generates the catalog rows beside
    `Finds/Sets` and a judged flag for the finds ticked in `art/finds/WAVES.md`; the deal takes
    every generated, judged find with a template in the place, so no hand-kept list for kit
    finds. Lune specs prove the generated rows match today's hand-written ones before those go
    (the audit found no grade, worth or floor mismatch). The theatre spotlight stays out of the
    deal until a floor has a big-find place; the bedroom set stays hand-written. Split in two:
    - [x] **F-G1f1 The rows in the art (P1a; Nov 17, D-265).** Each kit set's spec ends in its
      `GAME` rows (grade, worth, floors, the Old lamp's loose only, grip, heft, view, sounds,
      press); `art/finds/rows.py`, plain Python, writes `src/shared/Finds/Rows.luau` (with
      `judged` from WAVES.md's ticks) on every export or `scripts/art.sh rows`; `check.sh`
      fails a stale or hand-edited module; `tests/kitrows.spec` holds all 41 generated rows
      to the hand-written ones, frozen in `tests/fixtures/kitrows.luau`. The game unchanged.
    - [x] **F-G1f2 The game takes the rows (P1b; Nov 17, D-266, seen in Play).** The hand-written kit rows in
      `Tools.Catalog` and `Finds/Use` go, both built from `Finds/Rows`' judged rows;
      `Deal.Finds` becomes the bedroom set plus the judged rows, less any with no template
      in the place (the server as it starts); the Old lamp's `loose` read where the marked
      box is chosen (`Deals` `layBoxed`); `art/finds/PIPELINE.md` and CRAFT.md's pointers;
      one Studio Play check: kit finds still turn up in units and the jack or the monkey
      plays when pressed.
- [x] **F-04 Wind-ups and noisemakers.** Built, in `art/finds/windups/`: F-04a the cymbal monkey,
  F-04b the jack-in-the-box, F-04c the chattering teeth (Nov 15), F-04c2 the walking robot,
  F-04d the wind-up mouse, F-04d2 the clockwork tin bird, F-04e the toy siren car and F-04e2 the
  squeaky rubber duck, F-04f the kazoo, F-04f2 the toy drum, F-04g the farm-animal spinner and
  F-04h the pull-string cowboy doll, F-04i the singing fish plaque and F-04j the wind-up tin
  carousel (Nov 16, D-245). F-04k (Nov 16): all 14 imported and judged together in a lit
  unit in Studio; the fish plaque's board made paler so its fish reads, the jack-in-the-box's
  playing-card corners added (`art/finds/WAVES.md`, its note).
- [ ] **F-05 Squishies.** In `art/finds/squishies/`. F-05a (Nov 16, D-246): bones in the finds
  kit, checked in Studio, proven on the squishy butter stick. F-05b (Nov 16, D-247): the stress
  ball with a face, its eyes bulging out of their sockets. F-05b2 (Nov 16): the mochi bun, a
  powdered pink dome that sinks slow and heavy. F-05b3 (Nov 16): the toast slice, a crusted
  foam slice with a face that springs back like bread. F-05c (Nov 16): the jumbo slow-rise
  strawberry, a thumb's dent in its side that takes ten seconds to rise (bones; a boned find is
  one mesh, docs/STUDIO.md). F-05c2 (Nov 16): the squishy capybara, a foam loaf with a mandarin
  on its head that sinks in a contented sigh. F-05c3 (Nov 16): the paper squishy, a kid's
  taped marker cat that crunches flat and puffs back unevenly. F-05d (Nov 16): the gel bead
  ball, a clear ball of pastel water beads that swirl round inside as it squashes. F-05d2
  (Nov 16, D-248): the glitter goo ball, clear aqua gel hung through with glitter and gold stars
  that whip round and coast to a stop. F-05d3 (Nov 16, D-249): the galaxy goo ball, deep
  blue-violet gel with teal and magenta nebula clouds, star sequins, a pearl moon and a ringed
  planet, found glowing faintly; squeezed, the stars swirl round and the clouds drift. The
  last four are the third run's S1 to S4 (`art/finds/WAVES.md`). S1a (Nov 17): the goo ball's
  art and game row, a neon-pink goo-filled ball that bulges out between five fingers on bones
  and slowly comes back. S1b (Nov 17): its skin wet and glossy, lighter where the blisters
  stretch; ticked, imported and seen in Play (dealt, taken, squeezed, its squelch). S2a (Nov 17,
  D-303): the colour-change goo ball's trick proven in Studio (a tint mask in its skin) and its
  art and row: sky blue, orchid fingerprints that bloom as you squeeze and cool back; not ticked,
  imported or seen in Play. S2b (Nov 17): its prints made soft fingertip ovals, strongest in
  the middle (S2a's were hard bars); ticked, imported and seen in Play (dealt, taken, squeezed:
  the prints bloom and cool back on your view's copy and on the ball friends see, its squelch).
  S3a (Nov 17, D-307): the mega goo ball's art (the goo ball's builder as the class `Goo`, two
  palms, 8 in, acid green marbled violet) and its row (Epic, 120, a deep squelch heard 90
  studs); not ticked, imported or seen in Play. S3b (Nov 17, D-310): its ribbons kept to their
  width with hard edges (no grey), its hug deeper; ticked, held in both hands at your chest (a
  row's `bothHands`), imported and seen in Play (dealt, taken, switching refused, squeezed, a
  Mannequin woken). S4a (Nov 17): the squishy cake slice's art and row (Rare, 45: a 5 in rainbow
  layer slice, rosettes and a cherry; pressed, the cream lines push out of both cut sides on 47
  bones in bands); not ticked, imported or seen in Play. S4b (Nov 17): the rosettes rebuilt to
  bake clean (rings turning with the swirl), the cherry dropped (the owner), ticked, imported and
  seen in Play (dealt, squeezed in hand, the cream 7 mm out, its squish). S1 to S4 done; L1 (the
  14 at phone size) ticks F-05. Polish: friends' arms round a hugged find
  (`Joints`, as `HornView` raises the horn arm); the mega goo ball banked at the gate. Polish: a squishy squeezed
  again before its press is over (the colour ball's fade could then run 8 s).
- [ ] **F-06 Plush.**
- [ ] **F-07 Night Shift Minis and their blind box.**
- [ ] **F-08 Boxes and tins.**
- [ ] **F-09 Bags and cases.**
- [ ] **F-10 Locked and sealed.**
- [ ] **F-11 Treasures.**
- [ ] **F-12 The eight wave 1 big finds.**

## Polish waiting for a slot

- **The build camera frames the room above the tray** (S5-03j1b, D-442): the room's middle sits
  at the screen's middle, so on a phone the tray hides its front third. Shift the picture up so
  the room centres in the open band between the top bar and the tray (pitch the camera down a
  little past its focus, and map each finger's point back through the same shift for Gestures
  and `OrbitCamera`, so slides and pinches still land under the finger).

- **The jukebox's window and photo pass** (S4-05a, D-414): its bay window is a flat leaning
  pane, so up close it still reads a little like a screen; the arch-tops had a curved glass dome
  over the record. Do a photo pass (three or more arch-tops, `CRAFT.md`), then curve the glass
  and the bay's lid, and add fluted ribs across the plastics (it was ticked built in S4-05b1
  so the climb could deal it; this pass changes only its look).
- **The padlock with its shackle shut** (S4-03b2): `art/padlock` builds the padlock as one mesh
  with its shackle lifted and swung open (`LIFT`, `SWING`), so the doors' padlocks and the
  TwicePadlocks card face both read as unlocked. Build it shut (the click's moment), rebuild with
  `scripts/art.sh`, re-render and re-upload the TwicePadlocks face (`art/cards/`).
- **A mirror's first look in a session** (S5-03f4b3, D-320): the first time a mirror's picture
  goes live in a play session, its room can show dark behind you for a beat (about a quarter
  second) while you show lit; every later look, and a mirror rebuilt later, came in whole. Most
  likely the room's textures loading into the picture on first draw: try
  `ContentProvider:PreloadAsync` on the picture as MirrorView builds it, and judge in a fresh
  Play.
- **The rail's motion** (S5-03f2b, D-316): the hat lifting off the rail toward your head as you
  wear it (now it's gone from the rail as it lands on you, with its knock and click), and
  settling onto the shelf with a small drop as you hang it up (now a glint at your head and its
  knock on the rail).
- **Arranging's extras** (S5-03e3a1, D-311): finds standing on a lifted find ride its ghost (now
  they stay put until it's set down); pinch and pan the Arrange camera in a bigger unit; a faint
  grid on the walls for a hanging find; the tray's card lifting off as its find rises out of it;
  a lifted find riding a thumb's width above the finger, or keeping where it was grabbed, so the
  thumb never covers it (S5-03e3a2: it jumps under the finger, small at the far wall); the grid
  fading in under the lifted find only; the ceiling unreachable near the door from the camera's
  corner (a disco ball goes in the far half). From S5-03e3b: a friend's find put away lifts off
  and fades rather than vanishing (the server destroys it, so the screen would keep a copy); the
  job box's Open prompt hidden while arranging; the bar's count rolling up a digit at a time.
- **The finds' press sounds** (F-G1b2): the glow stick's snap, the firefly jar's lid and shimmer,
  the disco ball's motor hum, and a real spring bang for the jack's Pop (now the catalog's tin
  clang, lower and louder); time the music box against the Wind (its winding into the tune) and
  the match against the tea light's and oil lamp's Light. Pro Sound Effects first (`search_asset`,
  query ending "SFX"); store searches for "spring" and "boing" found nothing usable.
- **The monkey and the toy car** (F-G1b3a): the toy car's roll fading as it slows (the clip is
  cut), a tick as it meets a wall, the monkey's wind measured against its key, and a lighter
  clash than the pitched-up crash cymbal; a hand set-down as the car leaves it.
- **The lamps going out** (F-G1b3c1): each lamp fades out by its switch-off when its minute is
  spent, so the desk lamp's head nods as it dies. Each wants a running-down motion of its own
  in its art script (a flicker, a bulb browning out, the neon stuttering dark), and the neon
  sign a real hum under its Buzz (it clicks on as a torch does for now).
- **A pressed find's hand** (F-G1b2): your hand doesn't move as you press (the horn rises); a small
  thumb-press dip of the held find, and a friend's arm lifting a lit lantern to look, would sell it.

- **Saw panels in a packed unit** (B-05b2a): the top's cut panel falls half under the doorway's
  stacks (it lies at about x -1.9, 2.7 to 5.1 in), and a crawl hole's panel reaches 3.2 out from
  the wall, under the path's stacks. Both read as wedged under the boxes; a fall that stops on
  the stacks would be better.

- **The farm spinner's arrow lands on any animal (done Nov 17, F-G1e3d):** as built it always stops on
  the cat. The server picks an animal each pull, the view adds 45 degrees a step to the arrow's
  spin keys and plays that animal's call; the next pull starts from where it stopped (the art's
  README, "For the game"), not snapping back to the cow.
- **A beat heard twice when the server's stamp lands (F-G1e3a):** the drum's third bang played
  twice in Play; `FindUseView`'s `beat` recounts from the server's stamp once it replaces your
  predicted one. Count by the server clock so a played beat isn't due again.
- **The carousel's tune slows as it runs down (F-G1e2b, D-272):** its music box plays at full
  speed to the end. A recording of a box running down, or a tempo change that keeps the pitch.
- **The siren car's wail follows its flywheel (F-G1e4, D-281):** today one toy-siren recording
  plays from the first push; a real friction siren's pitch rises with each push and falls as the
  car slows, and dies with a whimper at the end.
- **Finds' own sounds (F-G1a):** the Nov 15 finds borrow the tools' and the bedroom set's pick-up
  and drop sounds, pitched (`Tools/Catalog.luau`'s CLINK, TIN and the rest). Glass wants a glass
  clink (the tea light, the firefly jar, the glass lamp), tin a hollow tin knock (the wind-ups),
  the disco ball its mirrors rattling. The Nov 16 finds (F-G1d) borrow the same way: the
  squishies and the cowboy doll take the teddy's cloth grab (`SOFT`), wanting a soft squelch.
- **Each find's own hold (F-G1a):** the Nov 15 finds sit in your view by size (small, medium,
  large) with grips picked from their boxes; judge each at phone size and give the odd ones
  (the desk lamp's long arm, the RC car with its transmitter, the neon sign) their own.

- **The tap's bar (S2-05b, D-170):** a faint sound on the marker's sweep (left out so the wait
  is silent over the door's creak; try it if the owner finds the sweep flat); a phone's buzz on a
  miss (`HapticService`, check it works on phones first); the zone could breathe once as the
  marker sets off.
- **The alarm's lights out (S2-04c, D-163):** the dark could roll out from the car down the
  halls (each fixture's start by its distance from the keypad) rather than drop raggedly at
  once; the exit signs could stutter with it; the bell could echo differently in the dark.
- **The menu (S1-10d3):** the Buy on the glass could pulse once as it comes back after a vend.
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
