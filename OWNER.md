# Owner

Everything waiting on you, in order. Work down and tick boxes. Agents add new items here and
nowhere else.

## Now

- [ ] **Each session: click Connect** in Studio's Rojo plugin when it says `rojo serve` is running.
- [ ] **Save the place** (File > Save to Roblox) after this session (Nov 7): the templates live
  in it: the small unit at `ReplicatedStorage.Units.S` (new this session, beside the `M`), and the
  hall's at `ReplicatedStorage.Corridor`: `Straight`, `Fixture`, `Wall`, `DeadEnd`, `Corner`, `T`,
  `Cross` and `ShortWall`. Unsaved, the next open loses them: the short hall past the corner
  falls back to plain walls, the hall to plain blocks and bare tubes (Output says which).
- [ ] **A home for the code:** the repository has no remote, so "push" had nowhere to go; the work
  is now on a local `main` (`storage-unit` renamed, `third-person-walls` deleted, Nov 6). Say if
  you want a private GitHub repository created and `main` pushed to it.

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

- [ ] **Walk a floor:** Play. The post on your left at the spawn says "Walk a floor" (E): it sends
  you to the lobby of floor 3 from seed 7, whose map Output prints at Play (the same one
  `lune run scripts/floor-map 7 3` prints). Walk out: round the loop, into the dead end (top
  right of the map), round the corners. Look for: the floor matching its map; no gap, doubled
  wall or flicker where a unit stands in a junction (304 and 305 across the first T; 342 to 345
  in the far left corner); the lights waking ahead of you down every hall and round every turn;
  every door working as in the test hall; mustard doors numbered from 301 as you walk out. "Come
  back", in the lobby's corner by the elevator, returns you. Shots: `docs/art/L-01c-floor.jpg`,
  Studio's window, not a phone (top: the lobby, the first hall, the T's two units; bottom: an
  aisle of plain walls, the arm to a corner, the corner of small units).
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
  round it into the short hall. At 110: Peek (Q), Open (E), Close (F), Slam (G), Lock and Unlock
  (R); 112 is padlocked. Then walk into 110, shut it on yourself (the Command Bar line under "Now:
  judge P0-02g", with `Unit110`), turn to the door and Lift (T). Look for: the same sounds and
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

- [ ] **Hear every door action:** Play, stand at unit 101 and use its prompts: Peek (Q), Open (E),
  Close (F), Slam (G) from open and again from a peek, Lock and Unlock (R). Then go in, Slam it on
  yourself with the Command Bar line under "Now: judge P0-02g", and Lift (T). Listen for: the
  latch clack as any lift starts; a peek's rattle quiet and low, an open's loud; the lift from
  inside loud and surging three times as the door heaves; the slam's bang on the very frame the
  door hits the floor, a thump under it, then the bounce's clatter; a close settling with a
  rattle; a clunk as an open reaches the top; locking: the bolt, then the padlock's snap;
  unlocking: the pop, then the bolt. I picked every sound by measuring its loudness, not by ear,
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
  on yourself: Close (F) if the prompt shows from inside; otherwise, in the Command Bar with the
  Server view selected, run
  `require(game.ReplicatedStorage.Shared.StorageUnit.RollUpDoor).play(workspace.DevCorridor:FindFirstChild("Unit101", true), "Close")`.
  Look for: the room going dark as the door comes down, the line under the door. Then Lift (T)
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
