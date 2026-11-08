# Owner

Everything waiting on you, in order. Work down and tick boxes. Agents add new items here and
nowhere else.

## Now

- [ ] **Each session: click Connect** in Studio's Rojo plugin when it says `rojo serve` is running.
- [ ] **Save the place** (File > Save to Roblox) after this session (Nov 8): the elevator's
  templates live only in the open place, at `ReplicatedStorage.Props.Elevator` and
  `ReplicatedStorage.Props.Note`. Unsaved, the next open loses them and every floor's lobby has
  an empty hole in its back wall (Output warns).
- [ ] **A home for the code:** the repository has no remote, so "push" had nowhere to go; the work
  is now on a local `main` (`storage-unit` renamed, `third-person-walls` deleted, Nov 6). Say if
  you want a private GitHub repository created and `main` pushed to it.

## Now: judge L-05a2, the elevator in Studio (built Nov 8)

- [ ] **Judge the shots** in `docs/art/`: on a Galaxy A16 at Quality Level 21,
  `L-05a2-hall-mouth.jpg` (across the lobby from the hall), `L-05a2-at-gate.jpg` (a stride from
  the gate, the keypad on the right) and `L-05a2-aboard.jpg` (inside, the gate three-quarters
  shut); in Edit, `L-05a2-gate-open.jpg`, `-gate-half.jpg`, `-gate-shut.jpg` and `-note.jpg` (a
  note reading `_ 7 _ _` on a box). Look for: the car the one warm, safe place; the gate reading
  as a folding gate, its lattice shadow on the lobby floor; the note's digits plain.
- [ ] **Walk it yourself:** Galaxy A16 in the Device Simulator, Play, take "Walk a floor" by the
  spawn, walk across the lobby and into the car, turn and look out; at Quality Level 01 and 21.
  Then, with the Server view selected, run
  `require(game.ReplicatedStorage.Shared.Elevator).setGate(workspace.DevCorridor:FindFirstChild("Elevator",true),0.75)`
  in the Command Bar and look again (0 folds it, 1 shuts it). The gate doesn't block you yet; that
  comes with L-05b.
- [ ] **Decide, defaults in place** (D-041): (1) the lamp lights the lobby only through the
  opening, but its spill fans wide, so the lobby's side walls glow more than on the sheet; say if
  it should be darker (`Elevator.Lamp`, range 22, brightness 1.2, in
  `src/shared/Elevator/init.luau`); (2) the keypad's red light is too small to see from the hall
  on a phone, so L-05b will show red dashes on the readout at rest; say if you'd rather the
  keypad stay dark until someone types.

## Now: judge L-05a1, the elevator's art (built Nov 8)

- [ ] **Judge the sheets:** `art/sheets/elevator-lobby.png` (from the hall's mouth across the dark
  lobby, the gate folded open), `elevator-shut.png` (the gate halfway, a stride away, in a torch),
  `elevator-aboard.png` (inside, the gate nearly shut, the Mannequin come to the gate),
  `elevator-keypad.png` and `elevator-note.png` (a note on a box, `_ 7 _ _`). Look for: an
  elevator at a glance from across the lobby (from the hall's mouth only the lit car and the
  keypad's red glow show, the frame lost in the dark); the gate reading as a folding gate; the
  car feeling like the safe place; the note spotted from a unit's doorway and its digit plain.
  Say if the car wants another paint than cream, steel boards instead of oak, a bigger note or a
  bolder hand.
- [ ] **Decide, defaults in place** (D-040): (1) one gate, the car's own lattice gate, seen
  through while you wait; (2) it folds to the left post as you face the car and closes toward
  the keypad on the right; (3) the notes' digits written by the game in Kalam, Roblox's pen hand,
  not baked; (4) the lobby lit only by the car's lamp. Say which to change.

## Now: judge L-06a, the Mannequin (built Nov 8)

- [ ] **Judge the sheets:** `art/sheets/mannequin-lineup.png` (as it's found, from behind,
  mid-step, mid-stride), `mannequin-torch.png` (the bulb out, a step nearer, reaching, in a torch:
  the GDD's moment), `mannequin-unit.png` (among the boxes by a unit's bulb), `mannequin-close.png`
  (its face), and from Studio `docs/art/L-06a-hall.jpg` (30 studs down the hall in a stand-in
  torch). Look for: a mannequin at a glance; the frozen reach scary rather than silly; a face you
  can't read but can tell which way it faces; old paint, chipped, with seams. Say if it should be
  taller or shorter (6.3 studs, `HEIGHT` in `art/mannequin/spec.py`; a player is about 5.2), if
  the face wants a plain egg (no nose) or more of a face, or if it wants more wear.
- [ ] **See it on the phone view** (the doorway capture timed out, so no shot): Galaxy A16 in the
  Device Simulator, Play, open 101 (E), then with the Server view selected run in the Command Bar
  `local M=require(game.ReplicatedStorage.Shared.Mannequin) local f=require(game.ReplicatedStorage.Shared.StorageUnit).RollUpDoor.frame(workspace.DevCorridor:FindFirstChild("Unit101",true)) M.clone(f*CFrame.new(-1.6,0,7.6)*CFrame.Angles(0,math.rad(-14),0),workspace,M.Pose.Poses.Still) M.clone(f*CFrame.new(-30,0,-5)*CFrame.Angles(0,math.rad(90),0),workspace,M.Pose.Poses.StepRight)`.
  Look from 101's doorway (one standing by the bulb, head hung) and up the hall (one mid-step,
  reaching, 30 studs off), at Quality Level 01 and 21. Look for: both read as mannequins at once,
  pale against the dark; nothing about them reads as a player.
- [ ] **Decide, defaults in place** (D-039): (1) it's posed by code, not uploaded animations, so
  every pose is checked by tests; (2) its walk is stop-motion, holding each of four keys for 55%
  of a step then snapping (`Pose.Walk.Hold`), and a light freezes it on a key; (3) its keys are
  mid-step with one arm out level, palm down; (4) no Humanoid until the hunt (L-06b) needs one.
  Say which to change.

## Now: read L-04d, the deal (built Nov 8)

- [ ] **Read a few floors' deals:** in a terminal at the project, run `lune run scripts/floor-deal 7 1`,
  then `lune run scripts/floor-deal 7 6` and seeds of your own (`floor-map` with the same two
  numbers draws that floor). Each prints the code, the notes (which unit, which digits, which
  wing), the padlocked doors, and what every door holds as you'd meet them from the lobby. Look
  for: notes you'd split up to find; tools enough to play with (about 9 on a short floor); keepers
  rare enough that a door is a gamble, not a trap.
- [ ] **Decide, defaults in place** (D-038): (1) a door in a calm stretch holds, out of 100: 40
  nothing, 25 a find, 20 a tool, 10 a keeper asleep, 5 awake (`Deal.Odds`); (2) padlocked: 6 in
  100 units on floors 1 and 2, 12 above; (3) keepers awake at once from doors: 1 on floors 1 and
  2, 2 on 3 and 4, 3 above; sleeping ones have no cap, so floor 1 can hold 5 or 6 sleeping
  Mannequins behind its doors; (4) the lobby's hall on floors 1 and 2 holds no keeper; (5) the
  bag of tools: two saws, two bolt cutters, two padlocks, one of each other tool, a saw first on
  floors 1 and 2. Say which to change.

## Now: judge L-04b, the unit's bulb (built Nov 7)

- [ ] **Judge the shots:** `docs/art/L-04b-open.jpg` is unit 101 opened with the boxes inside, seen
  from the hall on a Galaxy A16, by its bulb alone (the hall light off): Level21 left, Level01
  right. `L-04b-peek.jpg` is 101 peeked, from across the dark hall. `art/sheets/corridor-bulb.png`
  is the bulb up close (Blender). Look for: the boxes plain from the doorway, the back corners dark,
  a warm light that reads as a different thing from the hall's cold tubes; at a peek, a band of
  warm light under the door. Say if it should be dimmer, brighter or reach farther
  (`UnitLight.Brightness`, 0.6, and `UnitLight.Range`, 11, in `src/shared/UnitLight.luau`).
- [ ] **The guard's shadows:** `L-04b-guard-shadows.jpg` is the same unit with the guard's wires
  casting shadows (and the light at 1): six hard black bands across the room, which Roblox can't
  soften. I turned them off. Say if you want that caged look back anyway.
- [ ] **See and hear it yourself:** Play, put the boxes in 101 (with the Server view selected, run
  `local S=game.ReplicatedStorage.Shared local f=require(S.StorageUnit).RollUpDoor.frame(workspace.DevCorridor:FindFirstChild("Unit101",true)) for i,n in require(S.Boxes).Names do require(S.Boxes).clone(n, f*CFrame.new(-6+i*2.2,0,9), workspace) end`
  in the Command Bar), stand at 101 and Open (E). Look and listen for: a click as the door starts
  up, the bulb stuttering on (on, out, on, dim, on within a third of a second), then a faint buzz
  standing in the doorway. Slam (G): the bulb is out on the bang and stays out as the door
  bounces. Peek (Q): a warm band under the door. Do it at Quality Level 01 and 21. Say if the
  click is wrong for a bulb on a door switch, or the buzz too loud or too quiet
  (`UnitLight.ClickSound`, `HumVolume`).
- [ ] **Shut in next door:** open 101, then walk into 103 and Slam it on yourself, at Level 01.
  Look for: 103 black but for the line under the door, no warm glow through the wall from 101.
  Then Lift: 103's own bulb comes on with its door.
- [ ] **Several open at once:** open 101 to 104 and walk past them. Only the three nearest throw
  light (the others' bulbs only glow): look for a pool popping on or off as you pass. Read View >
  Render stats with four open.

## Now: try L-02, the doors' buttons (built Nov 7)

- [ ] **On a phone view first:** Play with the Galaxy A16 in the Device Simulator. Stand at 101:
  two buttons side by side, Peek left and Open in the middle. Tap Open: they become Close (left)
  and Slam (right), nothing in the middle, so a second tap lands on nothing. Tap Peek on a shut
  door, then the same spot again: that drops it (Close). Look for: every button easy to hit with a
  thumb, none on top of another, and on the S units past the corner (8 studs apart) the next
  door's buttons not crowding yours. The captures can't draw the buttons, so no shots this time.
- [ ] **A padlocked door:** 105 and 112 are padlocked. Press Open: the door jerks against its bolt
  (watch the line of light under it flicker), rattles loud, and the button says "Padlocked". Hold
  Cut (R): "Need bolt cutters". Take them at the "Test tools" post right of the spawn (R), come
  back and hold Cut a second: the padlock pops, and the door offers Peek and Open. Say if the
  rattle should be louder, longer or carry farther (`DoorSound.Sounds.Rattle`, 70 studs now).
- [ ] **From inside:** open 101, walk in, turn to the door and Slam (G) or Close (F): its buttons
  show from inside while it's up. Shut in, Lift (now E) heaves it up in 6 s. Then shut yourself
  in again and, with the Server view selected, run
  `workspace.DevCorridor:FindFirstChild("Unit101", true):SetAttribute("DoorLocked", true)` in the
  Command Bar: Lift now rattles and says "Padlocked" (a padlocked friend needs bolt cutters).
- [ ] **With a friend** (Test > Clients and Servers, 2 players): one shut inside lifts; the other,
  in the hall, sees no buttons on that door until it's all the way up, so they can't slam it back
  down mid-lift. Then slam the door on your friend: they can always Lift out.

## Decide: moving between units, and the map (your note, Nov 7)

- [ ] **The unit's bulb comes on with its door** (default for your call on Nov 7, a dim light
  in each unit and no torch; built Nov 7, L-04b): it lights as the door rises and goes out when
  the door is shut, so hiding in a shut unit stays black but for the line under the door. Say if
  it should stay on in a shut unit instead (easier to see who's in there with you, less dread).

- [ ] **Where a saw hole and a ladder can go** (built Nov 7 on the default, L-01d): a crawl hole
  only into the unit beside you, and the tops run along a row (D-031). Behind each row is a
  16-stud gap before the next hall's row, so a hole through a back wall or a run across to the
  next hall goes nowhere. The alternative: rows back to back (deeper units, or halls closer), so a
  hole or a top run crosses to the next hall, a shortcut keepers can't take, like Among Us's
  vents. Bigger change; say if you want it.
- [ ] **The map** (L-10, after the elevator): a map you open with a button that fills in only the
  halls you've walked (R.E.P.O.'s map does this), with the lobby and elevator always on it, never
  keepers (that stays the office light board's job). Default: your friends show on it as dots, as
  Lethal Company's ship radar shows the crew, so a team can regroup. Say if friends should stay
  off it (more tension, more getting lost), or if you'd rather it be a small corner map.
- [ ] **No Lock button on doors** (default, D-030): buttons show to everyone, so a padlock button
  would sit on every shut door for a tool few carry. The padlock tool will lock a door when it's
  built. Bolt cutters' Cut does show on every padlocked door and says "Need bolt cutters" without
  them. Say if you want either the other way.

## Now: judge L-01d, where the hole trap and the tops fit (built Nov 7)

- [ ] **Read a few floors' maps:** in a terminal at the project, run `lune run scripts/floor-map 7 3`,
  then `lune run scripts/floor-map 3 1` and a few seeds of your own. The first map now marks a
  unit no crawl hole leads from as `x` (it stands between plain walls, a dead end or the lobby);
  the second, "The tops", draws each run along the unit tops in a letter of its own, capital over
  a unit and small over a plain wall's lid. Look for: a pair of neighbours to saw between in the
  first hall out of the lobby on floors 1 and 2; runs long enough to lose a keeper on (most are
  48 studs, two straights; the longest on a floor usually 100 to 150); few `x`.
- [ ] **The numbers over 400 seeds** (`lune run scripts/floor-survey`): every floor has 36 crawl
  pairs or more (about 50 on floors 1 and 2, 64 above); floors 1 and 2 have 4 or more on the
  way out of the lobby and no unit cut off; full floors at most 2 cut off, both in the lobby's own
  hall. Plain walls are rarer than before (a random one that would strand a unit stays a unit),
  so floors 1 and 2 have about 4 more units (63 in the middle) and full floors 2 more (82). Say
  if you want more blank walls back, or more cut-off units as places to get cornered.

## Now: judge L-01a, the floor layouts (built Nov 7)

- [ ] **Judge a few floors as maps:** in a terminal at the project, run
  `lune run scripts/floor-map 7 3` (seed 7, floor 3), then other seeds, and floor 1 for a short
  floor. Seen from above: the lobby (L) and its elevator (E) at the bottom, `.` hall, `+`
  junction, `*` a light, `M`/`m` and `S`/`s` units (the case alternates so neighbours read
  apart), `#` a plain wall, `|` or `-` a dead end. Look for: halls you'd want to search, aisles
  long enough to see a keeper coming, a loop to run round, a dead end or two to get cornered in;
  about 60 units on floors 1 and 2, about 80 above. Say if you want bigger or smaller floors, more
  loops or dead ends, or fewer blank walls (`Floor.Plans` in `src/shared/Floor.luau`).
- [ ] **Decide, defaults in place** (D-027): (1) all of a floor's doors are one colour, oxblood,
  teal, mustard and navy in turn from floor 1 (the test hall mixes all four); (2) unit numbers
  count up as you walk out from the lobby (floor 3: 301, 302 ...), across the hall back to back,
  rather than odd on one side and even on the other; (3) the breaker's power zones are the lights
  from the lobby to the first fork, then one zone per wing.

## Now: walk L-01c, a floor laid from the data (built Nov 7)

- [ ] **Try other seeds:** select Workspace, add number attributes `DevFloorSeed` (any number) and
  `DevFloorNumber` (1 to 10; 1 and 2 are the short floors), then Play. Delete them after.
- [ ] **The lobby stand-in:** a plain room with a warm lamp where the elevator will stand, the one
  light on a floor that's always on, so you arrive in a glow and the hall's mouth stays dark. Say
  if the arrival should be darker or brighter (L-05 builds the real lobby and elevator).
- [ ] **What it costs a phone:** Galaxy A16 in the Device Simulator, Quality Level 01 and 21:
  stand in the lobby facing the hall, then at the first T looking down the long aisle, and read
  View > Render stats. In Studio's full window it drew 96,000 triangles from the lobby and
  112,000 down the aisle, in 43 draw calls; the test hall's spawn drew 74,000. Say if a low-end
  phone stutters; ROADMAP's polish list has what to try.

## Now: judge L-01b, the small unit (built Nov 7)

- [ ] **Try a small door:** Play, go down the hall, take the T's arm that runs to a corner and
  round it into the short hall. At 110: Peek (Q), Open (E), Close (F), Slam (G); 112 is padlocked
  (Open rattles). Then walk into 110, shut it on yourself (Slam from inside), turn to the door and
  Lift (E). Look for: the same sounds and
  slam as a big door; the room feeling tight with the door down; the next door's prompts never
  showing instead (the doors are 8 studs apart).

## Now: judge L-03, the motion lights (built Nov 7)

- [ ] **Walk the hall again, retuned from your play** (D-025): your own lights now come on the
  moment you move, with no wait on the server; the light ahead wakes as you pass under the one
  you're at (the reach is 40 studs, was 32); the tube is full on within a tenth of a second (one
  stutter); lights stay on 7.5 s after the last movement. The T, both its arms and the corner now
  have a light each. Look for: the light following you down the hall and round the turn, never a
  step into the dark; the click clear but not tiring at this pace. Galaxy A16, Quality Level 01
  and 21. Shots: `docs/art/L-03-*.jpg`.
- [ ] **Freeze under a light:** stop dead under one. It should cut out about 8 s later and leave
  you in the dark. Say whether the dark when nothing moves (`L-03-level01-dark-eyes.jpg`: near
  black, one red eye) is right until the flashlight exists, or a still player should still make
  out the hall.
- [ ] **The breaker:** at the post in the T's south half, Cut power (E): the eyes up the north
  arm, at the corner and in the east hall die grey, and that stretch stays black as you walk it;
  Restore power brings the eyes back.
- [ ] **With a friend** (Test > Clients and Servers, 2 players): walk apart and back. Look for:
  each of you waking lights for both screens, a friend's within a stride of them moving (those
  come from the server, 20 checks a second, plus the network); a friend fidgeting keeping a light
  on over you; the farthest lit tubes glowing without light (only the 3 nearest throw it) and no
  pool popping on and off as you walk. Read the View menu's Render stats with 4 or more lit.

## Now: judge P0-04, the door's sounds and the slam's jolt (built Nov 7)

- [ ] **Hear every door action:** Play, stand at unit 101 and use its buttons: Peek (Q), Open (E),
  Close (F), Slam (G) from open and again from a peek; cut 105's padlock (bolt cutters from the
  "Test tools" post, then hold R). Then go in, Slam it on yourself from inside, and Lift (E). Listen for: the
  latch clack as any lift starts; a peek's rattle quiet and low, an open's loud; the lift from
  inside loud and surging three times as the door heaves; the slam's bang on the very frame the
  door hits the floor, a thump under it, then the bounce's clatter; a close settling with a
  rattle; a clunk as an open reaches the top; locking: the bolt, then the padlock's snap;
  unlocking (cutting): the pop, then the bolt; locking is the Command Bar line under "Now: try
  L-02" on a shut door. I picked every sound by measuring its loudness, not by ear,
  so say which to swap: each is one row in `src/shared/StorageUnit/DoorSound.luau`. Most likely
  to miss: the bang (a gas tank dropped on loose metal), the top's clunk (a car door slam pitched
  up), the padlock (its snap is my reading of the recording).
- [ ] **The slam's jolt:** slam 101 while standing at its door, and again shut inside. The view
  should jump about half a degree and settle in half a second, on a Galaxy A16 at Level 01 and 21.
  Say if it should be stronger or softer (`DoorSound.SlamShake`, `Shake.MaxAngle`).
- [ ] **From down the hall:** have a door opened and slammed while you stand at the T (about 40
  studs off): the open faint, the slam clear, a peek silent from there.
- [ ] **With a friend** (Test > Clients and Servers, 2 players): one slams a door on the other.
  Look for: both hear the bang as they see the door land; the one inside jolts; the one outside
  jolts only standing close.

## Now: walk the turn (built Nov 7, P0-03d)

- [ ] **Walk it on a phone view:** Play with the Galaxy A16 in the Device Simulator at Quality
  Level 01 and again at 21. Walk to the hall's far end, where it meets a T under the red exit
  sign: one arm is a dead end, the other a hall to a corner and a short hall past it. Look for: no
  seam in the floor or the ceiling where a junction meets a straight; the heavier girder over
  each place the ceiling's ribs turn; the steel column at each corner of wall; the blind corner
  feeling blind. Walk into the corners: nothing to snag on or see through. Shots so far, lit by
  a debug fill: `docs/art/P0-03d-*.jpg` (`real-light-01` is the hall as it is, dark).
- [ ] **The render cost with the turn:** in Play, from the spawn and from the T, read the View
  menu's Render stats (triangles and draw calls). Before the turn the spawn's view was 73,844
  triangles in 28 opaque draws; Studio stopped answering before this session could measure it.

## Now: judge P0-02g (built Nov 6)

- [ ] **Judge the shots:** `docs/art/P0-02g-inside.jpg` is the view from inside shut unit 105:
  low graphics before (lit grey box), low graphics now, full quality now. `P0-02g-peek.jpg` is the
  same spot while someone peeks the door: low graphics (left), full quality (right). Look for:
  black inside with the door's slats faintly showing and one bright line under the door, the same
  at both qualities; at a peek, light pours in. Known gap at low graphics: the peeked room lights
  evenly rather than from the floor up.
- [ ] **Feel it yourself:** Play, open 101 (E) and walk in, turn to face the door, then shut it
  on yourself: Close (F) from inside while it's up. Look for: the room going dark as the door comes down, the line under the door. Then Lift (E)
  and watch the light come back with the door. Try it on Automatic and at Quality Level 21 (File
  > Studio Settings > Rendering), and put it back to Automatic after.
- [ ] **When judging light, fix the Quality Level** (File > Studio Settings > Rendering): on
  Automatic, Studio switches between low graphics and full quality by itself mid-Play, which is
  the light changing between your two screenshots (Nov 6). P0-02h brought the two looks closer.

## Now: check the hall stays lit (fixed Nov 7)

- [ ] **Walk the hall's middle:** Play, walk from the spawn to the far end and back through the
  middle of the hall, on both sides, past the spot where it went dark for you. Look for: the
  lights waking ahead and none dropping while you keep walking, and no white line on the floor. Then walk into 101, shut it on yourself
  (the steps under "Now: judge P0-02g"), and check the dark and the line under the door still
  come, and go again when it lifts.

## Now: judge P0-03c, the plain wall and the dead end (built Nov 7)

- [ ] **Judge the shots:** `docs/art/P0-03c-ends.jpg` is a Galaxy A16, Level01 on top and Level21
  below. Left: walking up to the far dead end with its exit sign. Right: looking back at the
  spawn's dead end. `P0-03c-hall.jpg`: from the spawn down the whole hall (left), and up close
  where unit 102 meets a plain wall, up to the deck (right). `art/sheets/corridor-deadend.png` and
  `corridor-wall.png` are the Blender look. Look for: the hall plainly stopping in a wall (not a
  dark doorway), and the doorless stretches reading as the same building as the units, with no
  seam or gap where they meet the units, the floor or the ceiling.
- [ ] **The exit sign's red, retuned:** beside the plain walls' pale paint the old glow turned
  the last stretch into a red room, and the wall it hung on stayed dark. It's now dimmer (0.2,
  was 0.45), shorter (10, was 12) and hung 1.5 off the wall, so it washes the end wall. Say if
  the end should be redder (a beacon) or darker (only the sign).
- [ ] **Walk it yourself:** Play, sprint to each end and turn round in the corner. Look for: no
  snag on the kick plates or posts, nothing to hide behind, and the camera not clipping into the
  end wall. Then look up at the end: the deck's ribs should stop against the wall with no light
  showing through.

## Now: judge P0-03b, the hall light (built Nov 7)

- [ ] **Judge the shots:** `docs/art/P0-03b-phone.jpg` is a Galaxy A16 at Level01 (top) and
  Level21 (bottom). Left: standing under the lit fixture over 105, looking up. Middle: the same
  fixture up close. Right: the hall from the spawn with every light switched off by hand, only
  the eyes watching, which is how L-03's hall will mostly look. `art/sheets/corridor-fixture.png`
  and `corridor-fixture-lit.png` are the Blender look. Look for: a real hung strip light (a
  steel housing, a frosted lens, chains up to clips on the deck, a cord to a junction box) and a
  red eye on its end you notice. Say if the eye should be bigger, brighter, or not red; and if
  the watching eyes should be dimmer (scarier as pin-pricks) or brighter (easier to read).
- [ ] **Walk it yourself:** Play, walk the hall end to end, looking up as you go. Look for: the
  three fixtures hanging straight between the joists, nothing floating or poking through the deck; and from last
  session, no line where two floor pieces meet (x = -12 and 12) and footsteps that sound like
  concrete.
- [ ] **Decide later (the ladder):** the ceiling's lowest steel is now 12.8, so standing on a
  unit's wire top (10) leaves 2.8 studs overhead, and an avatar is about 5. Before the ladder is
  built: crawl-only up there (the default), or taller floors.
