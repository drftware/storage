# Owner

Everything waiting on you, in order. Work down and tick boxes. Agents add new items here and
nowhere else.

## Now

- [ ] **Each session: click Connect** in Studio's Rojo plugin when it says `rojo serve` is running.
- [ ] **Save the place** (File > Save to Roblox) after this session (Nov 9): the elevator's and
  the flashlight's, the bolt cutters', the padlock's, the saw's and the crawl hole's templates live
  only in the open place, at `ReplicatedStorage.Props.Elevator`, `Props.Note`, `Props.Flashlight`,
  `Props.Tools.BoltCutters`, `Props.Tools.Padlock`, `Props.Tools.Saw` and `Props.CrawlHole`
  (without them nobody has a torch, no tool lies anywhere and no hole can be cut; Output warns). Unsaved, the next open loses them and every floor's lobby has
  an empty hole in its back wall (Output warns).
- [ ] **A home for the code:** the repository has no remote, so "push" had nowhere to go; the work
  is now on a local `main` (`storage-unit` renamed, `third-person-walls` deleted, Nov 6). Say if
  you want a private GitHub repository created and `main` pushed to it.

## Now: judge L-12b2, sawing the hole (built Nov 9)

- [ ] **Saw a hole** (Play on a computer). A green saw now lies on the hall floor by the spawn,
  between the cutters and the padlock: pick it up (E). Open unit 106 (the third door along on 102's
  side of the hall) and walk to its side wall further from the spawn: a "Saw / Unit 108" button
  low on the wall, just past the unit's middle. Hold R. Listen: a motor's whine and a
  blade grinding steel, loud. Look: your saw out at the wall, shaking; a bright orange line
  crawling down the hole's near side, along the bottom, up and back along the top; sparks; your
  view buzzing. After 4 s the hole is through and the panel tips over and slaps flat in 108 with
  a clang. Then hold Saw at 106's other side wall (into 104) and let go after 2 s: the motor winds down
  and the line fades, no hole. I picked the three sounds by loudness, unheard (`docs/STUDIO.md`):
  do they sound like a saw and a sheet of steel? Is the line readable, and too yellow or too
  orange? Is 4 s right?
- [ ] **The refusals:** with the saw in your other slot (press 2), the Saw button still shows and
  holding it says "Hold the saw". With no saw, no Saw buttons anywhere. Padlocked 105 and 108
  can't be walked into, so their walls are sawn from the other side.
- [ ] **A friend hearing it** (Clients and Servers, 2 players): one saws in 106, the other stands
  at the far end of the hall and then by the turn: the motor heard from anywhere in the test
  hall, the clang only nearer; the line and sparks seen through 106's open door; the jolt only
  close by. Your friend's arm doesn't move yet (ROADMAP polish).
- [ ] **On the phone** (Galaxy A16, set in Edit first; I couldn't set the simulator from a script
  this session): is the line readable at arm's length on a phone, and does the Saw button sit
  where your eye already is when you face the wall?
- [ ] **Decide, defaults in place** (D-053): (1) a 4 s hold, the cut lost if you let go (or kept,
  so you can saw in bursts between keepers, as Dead by Daylight's generators keep progress?);
  (2) the Saw button shows only to someone carrying a saw; (3) the saw heard 200 studs off, the
  whole floor; (4) in a small unit the hole's stretch is most of the back half, so its finds and
  keepers stand on a hole spot (the panel would land at their feet); the deal keeps tools off
  them everywhere. Fine, or move the hole forward in small units?

## Now: judge L-12b1, the crawl hole (built Nov 9)

- [ ] **Look at the two test holes** (Play on a computer, by the spawn; no saw yet, L-12b2 cuts
  them in play). The test hall saws one from unit 101 into 103 and one from 104 into 102. Open
  101 (E) and look at its right-hand wall: a low ragged hole, a bright strip of bare steel round
  its cut, a few tongues of steel bent away from you, and the cut panel lying on 103's floor
  beyond. Then open 103 and look back: the panel flat on its ribs in front of the hole, the
  tongues bent toward you. Shut 103 and look from 101: its floor by the hole lit by 101's bulb
  through it. Does it read as sawn, and does the far side's square of light land? Is the hole
  too big or too small for a crawl (3 studs wide, 2.6 tall)?
- [ ] **On the phone** (Galaxy A16, set in Edit first): from 101's and 103's doorways it reads as
  a hole at once (`docs/art/L-12b1-a16-*.jpg`). The sheets in `art/sheets/hole-*.png` show the
  dark side, the light through it, your torch on it.
- [ ] **Decide, defaults in place** (D-052): (1) the hole opens at the same place in every
  side wall (3.75 to 6.75 studs in from the hall, just past a unit's middle in a small one, in
  front of it in an M), so you learn where to look; or wherever you saw? (2) 3 wide by 2.6 tall,
  its bottom a third of a stud up (a saw cuts above the wall's bottom track); (3) the panel falls
  flat into the unit it was pushed into, and stays; (4) only two units side by side in a row can
  be sawn between (a unit's side against another's back, at a back corner, can't).

## Now: judge L-12a, the saw (built Nov 9)

- [ ] **Find it on floor 1** (Play on a computer, "Walk a floor" by the spawn; Workspace's
  `DevFloorNumber` is now 1, seed 7). The first tool on floors 1 and 2 is a saw: on seed 7 it's
  unit 104, among the doors nearest the lobby (Output: "Deals: Unit104 held a tool, Saw").
  Open it. Look for: a green cordless saw standing on its battery in the bulb's light, its
  blade out; does it say "saw" from the doorway before you walk in?
- [ ] **Pick it up and carry it** (E). Look for: it low on your left, turned in so you see its
  side, the sticker and the vents, the blade reaching towards the middle; the torch on your right
  balancing it; nothing covering the hall ahead. Listen: the pick-up's hollow plastic knock (a
  cooler lid, "Plastic Ice Chest 25"), then Drop (G): a plastic slam with a short rattle ("Chair
  Drop 3"). I picked both by loudness, unheard: do they sound like a power tool?
- [ ] **A friend carrying it** (Clients and Servers, 2 players). I could only check the numbers:
  it's upright in their left hand by its rear handle, blade forward, at hip height, about 3
  studs out ahead of them. Does it read as a saw? Too far out?
- [ ] **On the phone** (Galaxy A16, set in Edit first): shots `docs/art/L-12a-*.jpg`. On the
  floor it reads as a green power tool with a blade; in hand it sits left of the slots' bar.
- [ ] **Decide, defaults in place** (D-051): (1) green (the torch yellow, the cutters red); (2)
  standing on its battery where it's laid, not on its side; (3) a friend carries it upright at the
  ready, not hanging nose-down; (4) its size, about 1.3 times life, 2.9 studs blade to tail.

## Now: judge L-04e, the deal on the floor (built Nov 9)

- [ ] **Walk floor 3 and open doors** (Play on a computer, "Walk a floor" by the spawn). Output
  lists the code, the notes' units and the padlocked doors, and says what each unit held as its
  door first lifts. Peek a few doors, open a few. Look for: a peek's foot of gap already showing
  what's on the floor; bolt cutters (unit 301) or a padlock lying in the bulb's light, picked up
  with E; a find (TV in 306, boombox in 310) standing behind the bulb, facing you; a note unit
  with a find (332) where the note is still the first thing you see. Does every door feel like a
  gamble, or is it too often nothing (about 4 in 10 in Build; padlocked ones rarely)?
- [ ] **A dealt padlock** (unit 311, 314 and others in Output's list): Open rattles it; pick up
  the cutters from 301, hold Cut a second, then open it. It deals then, not before.
- [ ] **On the phone** (Galaxy A16, set in Edit first): from each doorway, can you tell what the
  thing is? The cutters read as a red-handled tool from the doorway, small; finds read plainly.
  Shots `docs/art/L-04e-*.jpg`.
- [ ] **Decide, defaults in place** (D-050): (1) tools with no art yet (the ladder, bubble
  wrap, air horn, moving blanket, glow sticks: about 5 in 11 dealt tools; the saw is built now)
  are dealt but lie nowhere until L-13 and L-14 build them; or should the deal skip unbuilt tools for now? (2) a find
  is a prop you can't carry yet (Phase 2); (3) a short thing (a tool, a find, under 3.5 studs) may
  stand under a note, only a keeper keeps off the whole line to it; (4) tools lie in the bulb's
  pool, never against the back wall, so they read on a phone.

## Now: judge L-11c, the padlock and the cutters at work (built Nov 8)

- [ ] **Lock a door, then cut it** (Play, a computer first). Pick up the padlock lying across the
  spawn from the cutters (E; stand a few steps off the posts, where E walks you to a floor). Walk
  to any shut door: a third button, "Lock", shows on the right (R, R2 on a pad); it shows to
  nobody without a padlock in hand. Hold it half a second. Look for: the padlock coming out
  towards the door as you hold, a jerk, the bolt shooting and the padlock snapping shut on the
  latch, the padlock gone from your bar, "Padlocked" on the door. Then pick up the cutters, come
  back, hold Cut (R) a second. Look for: the cutters reaching out at the door as you hold (the
  shot I couldn't light: is the pose right? `Catalog.BoltCutters.use`), a hard metal snap with a
  jolt of your view, the padlock flipping off the latch and landing about a stud and a half out
  on the hall floor with a clank, the bolt sliding back. It lies there 20 s, then fades.
- [ ] **The wrong hand:** with the cutters in slot 2 and the padlock in hand, hold Cut on a
  padlocked door: "Hold the cutters". Press 2 and it cuts.
- [ ] **A friend watching** (Clients and Servers, 2 players): one cuts, the other stands in the
  hall. Look for: the snap heard down the hall, the padlock flying off on their screen too.
- [ ] **On the phone** (Galaxy A16, set in Edit first; real taps): hold Lock and Cut with a thumb.
  Look for: the hold ring filling, the padlock big enough to spot on a unit's floor from the
  doorway (it's twice the doors' padlocks), the padlock in your view not crowding the bar.
  Shots `art/sheets/padlock-*.png`.
- [ ] **Decide, defaults in place** (D-049): (1) "One padlock per use" (GDD): I read it as the
  cut padlock is spent and the cutters last; or should the cutters break after one cut? (2) Lock
  held half a second, Cut a second; (3) Cut and Lock on R, and R2 on a pad (Cut was on R1, which
  is the torch's); (4) the padlock you carry is the doors' own, open, at twice their size; or
  should yours look different (brass, say) so friends know a keeper is shut in there? That one is
  an untested bet and costs the door drawing your padlock too.

## Now: judge L-11b, two tool slots (built Nov 8)

- [ ] **Hand the cutters to a friend** (Test > Clients and Servers, 2 players). One picks up the
  pair on the hall floor by the spawn (stand a few steps off the posts: E there walks you to the
  floor) and walks to the other. Look for: "Give" with the friend's name on them within about 10
  studs; press it: the cutters leave your hand and bar, swing up into theirs with a clank, and
  their screen reads "Bolt cutters from (you)". Then fill the friend's slots (the second pair is
  in the first unit on the right: open its door) and try again: "Hands full" on the prompt. The
  friend should see the cutters in your left hand, jaw forward, swinging as you walk.
- [ ] **On the phone** (Galaxy A16 in the Device Simulator, set in Edit first; real taps, mine
  can't reach buttons or prompts): tap "Pick up" on the cutters by the spawn; tap slot 2 and slot 1
  on the bar; tap Drop. Look for: the clank and the name above the bar, the cutters swinging into
  the left of your view, the raised slot, the fall and the clank on the concrete. Is the bar the
  right size and place between the thumbstick and the jump button? Shots `docs/art/L-11b-*.jpg`.
- [ ] **On a computer:** E picks up, 1 and 2 switch, G drops; with a gamepad, X, the d-pad's left
  and right, and its down.
- [ ] **Decide, defaults in place** (D-048): (1) handing over as a "Give" prompt on a friend:
  Lethal Company has none (you drop it at their feet), so this is an untested bet; keep it, or
  only drop? (2) the tool in your left hand, since the torch has the right; (3) keys 1, 2 and G,
  the d-pad, and E/X to pick up; (4) the cutters' size (1.5 times life, 2.6 studs) and where they
  sit in your view (`Tools/Catalog.luau`, `hold`).
- [ ] **Brix:** it has no carried-items system; a Brix session should file the ticket in
  `docs/FRAMEWORK.md` (the "Carried items" row) in Brix's ROADMAP. Say if you want that now.

## Now: judge L-11a, the flashlight (built Nov 8)

- [ ] **Your torch on the phone:** Galaxy A16 in the Device Simulator (set it in Edit first), Play.
  The round button with a torch on it sits above the jump button. Tap it with a real tap (my taps
  can't reach it). Look for: the click, the lens and the warm pool at once; the button's torch and
  a glow turning warm; tap three times quickly (off, on, off) and each blink lands. Walk: the torch
  bobs and the pool shakes a little; stop and it settles; swing the view hard and it trails and
  catches up. Is it the right size and place in the corner (`Torch.Hold`), or too big over the
  thumb buttons? Shots `docs/art/L-11a-phone.jpg`, `-button.jpg`, `-hall.jpg`, `-wall.jpg`.
- [ ] **On a computer:** a right click switches it; with a gamepad, R1.
- [ ] **A friend's torch** (Test > Clients and Servers, 2 players): one walks into a dark hall and
  switches on. The other looks for: the torch in their right hand, its lens lit, their arm coming
  up to point it (and following them as they look up and down), the beam on the walls, the click
  heard near them; three quick blinks read as "it's me". Off, the arm drops and the torch hangs.
- [ ] **Six torches** (Clients and Servers, 6 players if your machine copes; the Galaxy A16 view
  on one): all six on in one hall. Look for: the frame rate holding, the three nearest friends'
  beams lit and the rest showing only their lens. Say if the budget (`Torch.RealBeams` 4) is
  wrong either way.
- [ ] **Decide, defaults in place** (D-047): (1) a right click and R1, since F closes a door, or
  another key; (2) no battery and no flicker, as the GDD has none; (3) the beam 54 degrees wide and
  42 studs long; (4) the torch about 1.5 times life so it reads in a fist.

## Now: judge L-05b1b, the code's notes in their units (built Nov 8)

- [ ] **Find the notes yourself** on the Galaxy A16 in the Device Simulator: Play, take "Walk a
  floor"; Output prints floor 3's code and where its notes are ("Unit313 (_ 0 _ _), ...").
  Walk to one, Open its door, look in from the doorway, then step in until you can read it, and
  do the same in a big unit (377). Look for: the note the first thing you see as the bulb comes
  on; its digit plain a couple of steps into a small unit and about five into a big one; the four
  notes spelling the code; then punch it at the keypad. Shots: `docs/art/L-05b1b-doorway.jpg`
  (a big unit from its doorway, 14 studs) and `-close.jpg` (6 studs, the "5" plain).

## Now: judge L-05b1d, reading a note (built Nov 8)

- [ ] **Read one on the phone:** Galaxy A16 in the Device Simulator, Play, take "Walk a floor",
  open Unit 313's door (a small unit) and take two steps in: "Read" shows under the note. Tap it
  with a real tap (mine couldn't reach a prompt's button). Look for: the note rising from below
  with a paper flap and settling crooked, as it hangs; its 0 plain at a glance; the tap that
  opened it not dropping it. Then drop it each way: tap the card, press Read again (E), walk back
  out (it drops at the doorway). Do the same in a big unit (377): Read shows about halfway in.
  Judge the flap (brighter lifting, lower dropping), the lift's speed and overshoot (0.28 s), the
  dim behind it, and its size. Shot: `docs/art/L-05b1d-card.jpg`.
- [ ] **On a computer** (Device Simulator off): E reads, then a left click anywhere drops it.
  With a gamepad, if you have one: X reads, X or B drops.
- [ ] **Decide, defaults in place** (D-045): (1) you can walk and look while the note is up (a
  keeper doesn't wait), or should reading hold you still? (2) the world dims to 55% behind it.

## Now: judge L-05b2, the gate's clock (built Nov 8)

- [ ] **Two players** (Test > Clients and Servers, 2 players, both on the Galaxy A16 if you can):
  both take "Walk a floor". One punches 5062 at the keypad; the other walks to the far end of the
  floor. Look for: both screens showing the green clock in the middle of the top bar as the gate
  slams open, with the PA's chime; at 10 the clock going red, the car's lamp starting to blink
  (watch it from the lobby) and the heartbeat starting; a bell on each of the last five seconds.
  The far player runs back: one gets in, one stays in the lobby. At zero the gate slams shut;
  the one inside reads "Going up", feels the lurch and fades out and back in at the spawn; the
  one outside reads "Left behind" as the car's light draws away. Then swap, and try diving
  through the gap as it shuts. Shots: `docs/art/L-05b2-clock.jpg`, `-warning.jpg`,
  `-going-up.jpg`, `-left-behind.jpg`.
- [ ] **Listen** with sound on: is the heartbeat too loud or too quiet under the rest
  (`Departure.HeartQuiet` 0.2, `HeartLoud` 0.6), and do the bells and the chime sound like the
  building's elevator?
- [ ] **Decide, defaults in place** (D-046): (1) the 30 s start once the gate has slammed open,
  not at the code; (2) the clock sits in the top bar's row, green then red at 10; (3) the car's
  light goes out for those left behind (the car took it); (4) for now a chime and the bell count,
  no PA voice (ROADMAP polish: a recording or text-to-speech). Say which to change.

## Now: judge L-05b1c, the keypad and gate on screen (built Nov 8)

- [ ] **Two players** (Test > Clients and Servers, 2 players): one types the first three digits;
  the other watches from the hall's mouth. Look for: the watcher hearing each beep and seeing the
  wall's readout fill and its keys sink; both hearing the alarm on a wrong code; the gate folding
  at the same moment on both screens. Then the watcher walks up and types the last digit: both
  readouts go green.
- [ ] **Keyboard and gamepad:** E opens it, the number keys type, Backspace clears, E closes; the
  mouse is free while it's open and locked again after. With a gamepad: X opens, the D-pad moves
  between keys, A presses, B closes.

## Now: judge L-05a2, the elevator in Studio (built Nov 8)

- [ ] **Judge the shots** in `docs/art/`: on a Galaxy A16 at Quality Level 21,
  `L-05a2-hall-mouth.jpg` (across the lobby from the hall), `L-05a2-at-gate.jpg` (a stride from
  the gate, the keypad on the right) and `L-05a2-aboard.jpg` (inside, the gate three-quarters
  shut); in Edit, `L-05a2-gate-open.jpg`, `-gate-half.jpg`, `-gate-shut.jpg` and `-note.jpg` (a
  note reading `_ 7 _ _` on a box). Look for: the car the one warm, safe place; the gate reading
  as a folding gate, its lattice shadow on the lobby floor; the note's digits plain.
- [ ] **The keypad's glow** (your test, Nov 8): it went black because the car's lamp is behind
  the wall it hangs on, and no hall light reaches that far. It now has a dim red light of its
  own (`docs/art/L-05a2-keypad-21.jpg`, a stride away at Level 21, after 15 s still). Stand at
  it 15 s at Level 21: look for the keys readable and a glow round the panel, not a red disc on
  the wall. Say if it should be brighter, wider or another colour (`Elevator.KeypadGlow`). At
  Level 01 the wall stays lit and the glow doesn't show (`-keypad-01.jpg`); matching the two is
  in ROADMAP's polish list. If yours went dark at 01, a screenshot would help: here it didn't.
- [ ] **Walk it yourself:** Galaxy A16 in the Device Simulator, Play, take "Walk a floor" by the
  spawn, walk across the lobby and into the car, turn and look out; at Quality Level 01 and 21.
  Then, with the Server view selected, run
  `require(game.ReplicatedStorage.Shared.Elevator).setGate(workspace.DevCorridor:FindFirstChild("Elevator",true),0.75)`
  in the Command Bar and look again (0 folds it, 1 shuts it). The gate is laid shut: open it from
  the keypad (L-05b1c, above).
- [ ] **Decide, defaults in place** (D-041): (1) the lamp lights the lobby only through the
  opening, but its spill fans wide, so the lobby's side walls glow more than on the sheet; say if
  it should be darker (`Elevator.Lamp`, range 22, brightness 1.2, in
  `src/shared/Elevator/init.luau`); (2) the readout shows red dashes at rest (L-05b1), beside
  the keypad's glow; say if you'd rather it stay dark until someone types.

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
  Cut (R): "Need bolt cutters". Take the pair lying by the spawn (E), come back and hold Cut a
  second: the padlock snaps off (L-11c, below), and the door offers Peek and Open. Say if the
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
