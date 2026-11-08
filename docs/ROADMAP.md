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
  find, a tool, nothing, or a keeper (GDD "What's behind the door"). Split in three (Nov 7):
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
  - [ ] **L-04c The first finds.** A handful from one of the GDD's sets (the 1980s bedroom), each
    one readable on a phone from the doorway, dusty (a mimic has no dust, GDD), and light enough
    in triangles for a floor of them. Rarity's look (a glint, a colour) only if the GDD names one.
  - [ ] **L-04d The director deals each unit.** On the open: a find, a tool, nothing, or a keeper
    (a marker until L-06), the boxes stacked to fit the unit's size; padlocked units get the best
    finds and the worst odds (GDD), and a laid floor decides which doors start padlocked (they all
    start unlocked now, L-01c). The sticky note is L-05's. Needs L-04b's light, so the
    open's reveal can be seen.
- [ ] **L-05 Notes, the keypad and the elevator.** The floor's 4-digit code on sticky notes, the
  keypad, the gate that shuts 30 s after the last digit (Dandy's World). Needs the elevator,
  gate, keypad and note art first. Brix: Zone for "aboard", the Clock for the gate's timer.
  A wrong code flashes every light on the floor (GDD): add that to `MotionLights` beside `cut`.
- [ ] **L-06 The Mannequin.** The first keeper, at no more than player speed: a data row on
  Brix's Pursuit (floor pathing, a cone reach). Needs its model and animations first, and Brix's
  ENG-06 and ENG-07. Keepers hear a door (the GDD: an open, a slam, a lift from inside) as far as
  its sound carries: take each action's reach from `DoorSound.Actions`, so what players hear and
  what keepers hear stay one table.
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
other keepers; tools (bolt cutters, saw with the crawl-hole wall, ladder onto the wire tops); the
hole trap with a dented-door variant; the light board; finds with rarity; your lobby unit; the
store; Captures. Player data, remotes, telemetry and UI from Brix (ENG-09 to ENG-16). Then soft
launch.

- **Before the ladder, close a top run's edges** (L-01d). A run's back drops into the 16-stud gap
  behind its row (no floor, no deck: you'd see the sky between the decks), and a run's end beside
  a junction drops into the junction's hollow block of wall (floored, 8 by 8, no way out). Close
  both before a ladder can reach the tops: a panel from each row's back up to the joists, as a
  plain wall's above its cap, and a lid on each block (an S wire top fits it, and lets a run turn
  the corner); or make the tops crawl-only. `Floor.runs` lists each run's slots in order.

## Polish waiting for a slot

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

