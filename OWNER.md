# Owner

Everything waiting on you, in order. Work down and tick boxes. Agents add new items here and
nowhere else.

## Now

- [ ] **Each session: click Connect** in Studio's Rojo plugin when it says `rojo serve` is running.

## Now: judge L-07d, cut free (built Nov 10)

Verified in Studio on seed 7, floor 1, alone (four catches by 157's Mannequin): lifting the kept
unit's door no longer lets you out; a "Cut free" button with your name stands on the film in
front of you only while the door is all the way up; your own trigger was refused, and so were a
stand-in friend (a copy of my body, `docs/STUDIO.md`) holding too short, down, across the hall,
next door through the wall, behind the back wall and up on the tops; from the doorway its cut
went: the rip played, strips of film flew, the wrap slumped to a heap round the ankles by 0.6 s,
crunched, faded by 2.2 s and was gone by 3 s; my view jolted and widened to 77 degrees and back;
the Bang button faded off, buttons and walk came back. The strain under a hold played when the
server marked a friend holding. Output clean. A real friend's hold (two players) and the sounds
by ear are untested; the button's place at phone size is measured, not seen.
- [ ] **The rescue** (Studio's Test > Clients and Servers, two players; get one kept by the
  L-07a steps below). The other finds the unit, opens it all the way and steps into the doorway
  facing the wrapped friend: "Cut free" with their name shows (E, X on a pad, a hold on a
  phone). Hold it: for a second the film strains round them, louder as you hold; then it rips,
  strips of film fly at you, the wrap drops down their body into a heap round their ankles,
  crunches and fades. Their view jolts and opens up; yours jolts a little. Is it violent and a
  relief? Is the rip loud enough, the strain right, one second right?
- [ ] **The kept side.** As the one kept: you see nothing of your friend's hold, only hear the
  strain; at the rip the film falls away past your eyes, the Bang button fades and you can walk.
- [ ] **At phone size** (the Galaxy A16 view): with the door up, Close and Slam sit either side
  of where Open was and Cut free shows in the middle, on your friend; nothing should overlap
  (measured at 197 pixels apart at the closest).
- [ ] **Decide, defaults in place** (D-099): (1) the hold is 1 s; (2) Cut free shows within 7
  studs of the film in front of their chest: from the doorway of a big unit, a step out of a
  small one; (3) no grace once you're free: in Studio the Mannequin saw me 48 studs off and
  caught me again within seconds. Dead by Daylight gives an unhooked survivor a few seconds a
  hit can't down them; say if you want a few seconds the keepers ignore you; (4) keepers don't
  hear the rip (L-15 lists what they hear; a loud rescue that draws the keeper is the other
  way). Numbers in `src/shared/Kept.luau`.

## Now: judge L-07c, banging (built Nov 10)

Verified in Studio on seed 7, floor 1, alone: caught by 157's Mannequin and kept in 120, then 118,
then 120; the Bang button came up in the dark; four quick Space presses gave three bangs 0.6 s
apart (each jolted the door: `DoorMotion` read Bang), and the floor carried the mark; a script
firing the remote every frame for 3 s (362 presses) landed 8 bangs, never closer than 0.40 s;
the Mannequin, 54 studs off along the halls, heard a bang and came to stand at the door; a
marker tripping the hall light outside lit a warm line under the door with a faint spill
inside, dark again once it stopped; being let out cleared the mark. A friend's mark over the
door can't be seen in Studio's captures (they draw no billboards), so its look is untested;
the corner map's dot showed, held on the edge. Not heard by ear, not seen by a second player or
on a phone.
- [ ] **The moment, kept** (get caught: the L-07a steps below). In the dark a round Bang button
  comes up low in the middle with "Click" under it (on a phone, big under your right thumb).
  Click, tap Space or tap the button: your view jolts, then the door thuds and shakes. Mash it:
  it hammers at two heavy thuds a second, never faster. Does hammering feel like hitting a steel
  door? Is two a second right, or should it allow a faster frantic rattle?
- [ ] **What friends see** (Team Test, two players): one gets kept and bangs. The other, anywhere
  on the floor, should see a blue dot with the kept friend's name over that door, through the
  walls, a ring going out from it at each bang; it fades about 8 s after the last bang, or at
  once when they're let out. Near the door you hear the thud. On the corner map the unit gets a
  bigger blue dot with a ring at each bang, held on the edge when it's off the window. Does it
  read as "your friend is in there, go"? Too big, too small, wrong colour?
- [ ] **A keeper hears it.** Bang while the Mannequin roams within about 70 studs of hall: Output
  says it heard the door bang and it comes to stand outside. Is that the right risk (friends
  coming to free you meet it there)?
- [ ] **The light under the door.** Kept, wait in the dark while a friend walks past outside:
  the hall's motion light trips and a thin warm line shows under the door, with a faint glow on
  the floor; it goes as the light goes off. The Mannequin doesn't trip lights, so it passes in
  the dark. Does the line read as someone out there? Too bright, too faint?
- [ ] **Decide, defaults in place** (D-097): (1) a kept friend's own blue dot leaves the corner
  map, so friends find them by their banging, not by the dot (the GDD's "friends have to look");
  (2) your torch keeps working while you're wrapped and lights the unit (the ticket's question:
  say if being wrapped should put it out, so the dark and the line under the door matter more);
  (3) the mark lasts 8 s after the last bang; (4) a keeper hears a kept player's bang as far as a
  trapped keeper's (70 studs along the halls). Numbers in `src/shared/Kept.luau`.

## Now: judge L-07b, the wrap you can see and hear (built Nov 10)

Verified in Studio on seed 7, floor 1, alone: caught twice; the film went on in the black, fitted
to my body, never drawn on my own screen; seen from the open door (a copy of me, the ambient
raised) it's a cloudy cocoon with the body blurred inside (`art/sheets/keptwrap-studio-door.jpg`);
the squeal started on the catch's frame; opening the unit took the film off. Not heard by ear,
not seen by a real second player, not seen on a phone.
- [ ] **The squeal, by ear.** Get caught (the L-07a steps below): in the black you should hear
  film screeching round you for about two seconds, a tape torn off its roll. Does it read as
  being wrapped? Too loud or too quiet over the silence the catch leaves?
- [ ] **What a friend finds** (Team Test with two players, or a friend in the published game):
  one gets caught near the other, who should hear the squeal from where it happened (not from
  the unit). Then find and open their unit: are they plainly wrapped? Is it too clear (the face
  plain to read) or too cloudy (can't tell it's your friend)? On a phone, from the doorway, with
  only your torch?
- [ ] **Hats and big avatars.** If you have an avatar with a big hat, wings or an Rthro body,
  get caught in it: the film is fitted to the body, so a hat may poke out of the top. Say if
  that looks wrong.

## Now: judge L-07a, getting kept (built Nov 10)

Verified in Studio on seed 7, floor 1, alone: three catches, each one stored me in a different shut
unit (153, 124, 112), never the nearest, facing its door, held still with no buttons showing;
an air horn I carried lay 1.9 studs from where I stood; opening the unit's door from the server
let me out the moment it reached the top, and I walked out. Not yet seen with a friend or on a
phone, and getting out alone by Reset is untested.
- [ ] **The moment** (Play on a computer, then at phone size). Open Unit 157 from (47, 3, -632)
  and stand still: the Mannequin catches you, the screen closes to black with "Caught", and opens
  on the dark inside of a unit somewhere on the floor, the door's slats ahead and "Wait for a
  friend" low on the screen. You can look round but not walk, and no buttons show. Output names
  the unit ("(you) is wrapped and kept in Unit124"). Does waking in the dark land? Is it too
  dark to tell you're in a unit until the light under the door comes (L-07c)?
- [ ] **Your things drop.** Carry a tool when it catches you: it lies where you stood, and a
  friend can pick it up.
- [ ] **Alone, Reset gets you out** (Esc, Reset Character): you come back at the spawn. With
  nobody to cut you free (L-07d), that's the only way out.
- [ ] **With a friend** (Studio's Test > Clients and Servers, two players): one gets caught; the
  other reads the unit from Output, goes there and opens it. The kept one stays held until the
  friend cuts them free (L-07d, above). Neither of you can hand the other a tool while one is
  kept.
- [ ] **Untested bet: stored in a random unit, never the nearest.** It's the GDD's own twist on
  Dead by Daylight's hook, which hangs you close to where you fell. Is the search fun, or a chore
  until banging shows your unit (L-07c)?
- [ ] **Decide, defaults in place** (D-095): (1) which unit: door all the way down, not
  padlocked, no keeper in it, nobody kept in it, never the nearest, and one nobody has opened
  ahead of one that's been opened; (2) the unit you're kept in is never dealt, so a friend finds
  only you there (a note already in it stays); (3) you wake 62% of the way in, facing the door;
  (4) a Bang button in the dark (L-07c, it replaced "Wait for a friend"); (5) the way out is a
  friend's Cut free at your open door (L-07d; the door going up no longer does it); (6) with no unit free (rare) you're held through the wrap and let
  go where you stand. Numbers in `src/shared/Kept.luau`.

## Now: judge L-10, the minimap (built Nov 10)

Verified in Studio at Galaxy A16 size (seed 7, floor 1): the map slides in at the top right as you
reach the floor, the lobby and the car drawn from the start; two walked halls filled in; unit 103,
opened, went green with a tick; the gate's amber mark sat on the edge once the car was off the
window; the torch and jump buttons stayed clear. Not yet seen on a real phone or with a friend.
- [ ] **The moment** (Play, "Walk a floor", seed 7). Walk out of the lobby and through two or
  three halls: each fills in as you step onto it, with its units beside it; the rest stays dark.
  Turn round: your dot's point follows your view. Walk far enough that the lobby leaves the
  window: an amber mark waits on the edge the way the gate is. Does a glance get you back?
- [ ] **On a real phone:** the map top right under Roblox's buttons, clear of the torch and jump
  buttons. Big enough to read the halls (about a third of the screen's height)? Too big?
- [ ] **North stays up** (a default, D-094): the lobby and gate are always at the bottom and the
  map never turns. Say if it should turn with you, as GTA's radar does.
- [ ] **Opened units** (a default, D-094): any unit anyone has opened or peeked into goes green
  with a tick, on everyone's map, once they've walked that hall. Say if it should be only the ones
  you opened yourself.
- [ ] **Friends** (Team Test, two players): your friend is a blue dot where they stand, held on
  the window's edge (paler) when they're out of it; their walking fills in nothing on your map.
  While they're kept their dot leaves the map (L-07c: they're found by banging).
- [ ] **The player list is off** (a default): Roblox's list of players (Tab on a computer) would
  open over the map, so it's hidden. Say if you want it back somewhere.

## Now: judge L-14b2b and L-14b2c, the pops (built Nov 10)

Verified in Studio (the test hall): lay a sheet, walk across it four times: Output says "popped
the bubble wrap (1 of 3)", "(2 of 3)", "(3 of 3)" and nothing for the fourth; your screen plays
each pop and wears the sheet down to flat, grey and partly clear. Your "only heard it once" was a
bug: your screen ignored a sheet whose part reached it after the sheet itself, so its pops were
silent there (fixed, D-093). You played it Nov 10: "better"; the sound reads as rustling, not
popping, which waits for polish (ROADMAP's polish list). Not yet seen on a phone.
- [ ] **Does the spent sheet read as popped?** Flat, grey and partly see-through, from standing
  height and on a phone. If not, say so and L-14b2d bakes it its own look (burst bubbles,
  creased film) before more tools.
- [ ] **A short rest between pops** (a default, D-093): a walk across within 0.8 s of the last pop
  pops nothing and spends nothing, so a friend right on your heels gets over free. Say if two
  friends running across should cost two pops.
- [ ] **A keeper treads on it:** lay one in a hall between you and the awake Mannequin in Unit
  157 (D-069's recipe in docs/STUDIO.md: open its door and back off down the hall). It should
  pop as the keeper walks through, and you hear it from where you hide.
- [ ] **A jump clears it** (a default, D-092): you can hop a sheet, as you can hop a Minecraft
  tripwire; keepers never jump. Say if any step over it should pop it.
- [ ] **Friends pop it too** (Team Test, two players): your friend walking onto your sheet pops
  it on both screens; the jolt only on theirs.

## Now: judge L-14b2a, laying the bubble wrap (built Nov 10)

Verified in Studio: where the sheet lies (the server, as `Wraps` does it) and the unroll sampled
mid-way on a screen, Output clean. The press itself is untested: this session the MCP couldn't
pick the roll up (no prompt showed to it). A phone, a friend and your ears are yours.
- [ ] **The moment** (Play on a computer). In the test hall pick up the roll beyond the horn,
  face down the hall and click (or L2): the roll comes out and down in your view, and a sheet
  unrolls across the hall from your left to your right just in front of your toes, a roll
  rolling over the floor and thinning to its core, then gone, with a crinkle. The slot is empty
  after: one roll, one sheet. Output says "Wraps: (you) laid bubble wrap across the hall". Try
  it in a unit, up on the tops and in the lobby: your screen says "Lay it in a hall" and you
  keep the roll. On the walked floor ("Walk a floor") lay one at a junction. Does the unroll
  read as wrap going down, or as a stretched picture?
- [ ] **The softer bubbles** (your note, Nov 10): each now goes gently milky toward its edge
  with a soft glint on one side instead of a white ring (sheets `art/sheets/bubblewrap-*.png`).
  Look at a laid sheet and the roll on a phone (Galaxy A16): rounder and more real, or too faint
  to read as bubbles from standing height? (`MILK`, `GLINT` in `art/bubblewrap/spec.py`.)
- [ ] **On a phone:** the Lay button sits left of the jump button, as the horn's Blow. Lay one
  while walking backwards: is the sheet where you expected it?
- [ ] **One sheet a roll** (a design call; the GDD gives no count): the roll is used up. Say if
  a roll should lay two or three shorter sheets.
- [ ] **By ear:** the unroll plays the pick-up's crinkle slowed down, a stand-in until a real
  unrolling rustle is measured (ROADMAP's polish list). Fine for now?
- [ ] **A friend holding the roll** (Team Test, two players; from L-14b1, you'll check later):
  they carry it by its middle along their forearm, like a rolled mat. Tell me if it swallows
  their fist or points the wrong way (`Catalog.BubbleWrap.inHand`). And watch them lay one: it
  unrolls from their left as they face.

## Now: judge L-14a2, blowing the air horn (built Nov 10)

Blown in Studio at desktop size on seed 7: a sleeper in Unit 154 woke 100 studs off along the
halls and came to where you blew it; a roaming one 44 studs off came, looked about 4 s and
wandered on. A phone, a friend and your ears are yours.
- [ ] **How far it carries** (a design call; D-087): keepers hear it 130 studs along the halls,
  as far as a door bursting open, past an open's or a slam's 110, about five hall pieces. The
  last handoff suggested about 60 (a bit over two pieces), which would make it quieter than
  opening a door. Play a floor: if every blow wakes a sleeper you never meant to, try 80
  (`Horn.Reach`).
- [ ] **A friend blowing it** (Team Test, two players): you hear it from their horn, and their
  left arm swings up and forward through the blast and back down (`Horn.Arm`, 135 degrees). Tell
  me if the horn goes through their head or the arm points the wrong way.
- [ ] **By ear:** Pro Sound Effects' stadium air horn, one 1.1 s blast and its echo, measured but
  never heard here. Loud enough, too long, or too comic for the building?
- [ ] **It never runs out** (a design call): Lethal Company's horn doesn't, and the GDD gives no
  count, so it's one blow every 2.5 s forever. Say if a can should empty after a few blows.

## Now: judge L-14a1, the air horn's look (built Nov 10)

Picked up, held and dropped in Studio at desktop size; a phone, a friend and your ears are yours.
- [ ] **On a phone** (Galaxy A16 in the Device Simulator): the test hall's air horn stands beside
  the bolt cutters by the spawn. Pick it up with your torch on. It
  should read at once as an air horn, low on your left: the orange trumpet standing up beside the
  hall, the black band's orange sound-wave mark facing you. Does it cover too much of the hall?
  (`Catalog.AirHorn.hold`; the saw sits about as big.)
- [ ] **In a friend's hand** (Team Test, two players): the horn in their left fist, trumpet up, the
  band's mark out to their side. It was measured facing their body and the turn flipped
  (`inHand` 0, 90, 0) without a second look: tell me if the mark faces in or the can goes through
  the arm.
- [ ] **By ear:** picking it up is a steel slap, dropping it an empty can landing and bouncing.
  Do they sound like a steel can, or too tinny?
- [ ] **The look** (a design call): a white can with a black band and an orange trumpet standing
  straight up, as the common canned horns are (D-086). Keep it, or say what to change.

## Now: judge L-12c, the hole trap end to end (built Nov 10)

Verified in Studio at a 1 ms ping (D-085); a real network, a friend and a phone are yours.
- [ ] **Spring it** (published game, or a Team Test for a real ping), floor 1 of seed 7: take the
  saw (it lies by the test hall's spawn), open Units 155 and 153 (east side of the hall north of
  the junction), saw from 155 into 153, open 157 from beside it and let its guard out, then let
  it see you at 155's front from well up the hall. Run into 155 and press Crawl the moment the
  button shows: the crawl should start at once, never a dead press. Crawl through, run out of
  153 and slam 155. It should never come through the hole, and your slam should trap it (it
  bangs). Before this ticket the press did nothing and it caught you at the hole.
- [ ] **Look back through the hole** before you run round: it should stand back in 155, a few
  studs off the walls, facing the hole, nothing of it through the wall. Does it read as hunting
  for you where you vanished? In a small unit it stands near the middle (default: it keeps its
  arm's room, 3.4 studs, off a unit's walls; say if it should press closer).
- [ ] **The lead it needs** (feel, a design call): you're only lost once you're through the wall,
  so as you press Crawl it must be about 16 studs behind (a little over a second at its hunt); a
  few steps behind, it catches you at the mouth. Today the trap is something you set up and lure
  it into from afar. Keep that, or make the crawl a panic escape too (a quicker drop at the
  mouth, or no catch on someone already lying in the hole)?
- [ ] **Dead presses anywhere else:** the server sees your run up to 0.4 s late; Crawl now allows
  for it. Press any other button the instant you reach it (Saw, Lean, Climb, Drop down, a door's
  Cut or Lock) and tell me if one ever does nothing.
- [ ] **Saw buttons where they belong:** on any floor, every wall two units in a row share should
  show its Saw button in both of those units, never only in one or in a unit further along (one
  went to the wrong unit before this ticket, so some walls couldn't be sawn).

## Now: judge L-06b4b3, the freeze on your screen (built Nov 10)

Verified in Studio at a 1 ms ping only (D-084); a real network and a phone are yours.
- [ ] **Swing onto it** (published game, or a Team Test with a friend for a real ping): open
  Unit 157 from the side, let the guard come, then swing your lit torch onto it mid-stride. It
  should stop dead the instant the beam lands, on a hard pose, never a step on and back. Then
  look away: it comes, closing a little quicker than its walk for a stride. Does that read as
  it lunging once the light leaves (good), or as a glitch? Feel numbers: `KeeperMotion.CatchUp`
  (5.4 studs) and `KeeperMotion.Patience` (0.15 s plus two pings).
- [ ] **It never catches you under your light:** let it hunt you and keep the beam on it as it
  comes. Before this ticket it walked on under the beam for a quarter of a second and caught me;
  now the server freezes it within a frame or two of your screen.
- [ ] **Two screens:** a friend watching sees it stop where the server froze it, about a stud
  and a half further on than on your screen at a hunt, never moving back; tell me if a friend
  ever sees it step back or slide.
- [ ] **A swipe across it:** flick the beam over it and off. It may stop for an instant on your
  screen, then walk on (a short hold the server didn't answer). Does that ever look like a
  stutter you'd notice?

## Now: judge L-06b4b2, its tell: footfalls and knocks (built Nov 10)

Nobody here could listen: the sounds were picked by measuring them (D-083), so this is by ear.
- [ ] **Hear it before you see it** (Play with sound on). "Walk a floor", open Unit 157 from the
  side and step back: the guard comes out and roams. Stand in a dark hall it walks toward: a
  stiff clack each time a foot plants (Pro Sound Effects' "Wood Drop Light"), heard from about
  three hall pieces off, and once it's within about 40 studs a hollow knock between the clacks
  (its joints, "Knock Slap Plastic"). Does it sound like a hard, hollow figure walking, or like a
  plank? Could you point to where it is with your eyes shut? Volumes and reaches are the row's
  `tell` in `src/shared/KeeperRows.luau` (footfall 0.75 to 70 studs, knock 0.55 to 40).
- [ ] **In a chase** the clack-knock comes about five times a second. Clatter that makes you run,
  or too busy? If too busy, drop the knock's volume, or say and the knocks can go to every
  other pass.
- [ ] **The peek's knock:** peek at 157 (the guard) and at 154 (a sleeper, asleep in its shop
  pose): as the door clears its feet, one deeper knock. Does it tell you "something stands in
  here" without spoiling the look? Open after the peek: no second knock. Peek, drop it, peek again
  within 3 s: one knock only (`revealGap`).
- [ ] **On the phone's own speaker** (the Galaxy A16): the footfalls should still read; both
  sounds sit at 700 to 900 Hz, where a phone speaker plays. If they don't, say so.
- [ ] **Two screens** (2 players): a friend near the keeper hears its steps from the keeper, not
  from you; a friend near the door you peek hears its knock too.
- [ ] **Decide, defaults in place** (D-083): (1) a footfall on each step and a knock on each pass
  (the stop-motion walk's every snap makes a sound); (2) a sleeper knocks as you peek it, as an
  awake one does (a sleeper gives itself away); (3) everyone near hears the peek's knock, not
  only the one peeking.

## Now: judge L-06b4b1, the sting and the chase bed (built Nov 10)

Nobody here could listen: the sounds were picked by measuring them (D-082), so this is all by ear.
- [ ] **The moment** (Play on a computer with sound on). "Walk a floor", stand in front of Unit
  157 and tap Open: the instant the guard turns on you, a hit cuts in (APM's "Rising Fear Hit 1")
  and a low drone swells under it ("Tension Repeat Drones 39"). Does the hit make you jump? Is
  it louder than a slam, and should it be? Volumes are `Chase.Sting.volume` (0.8) and
  `Chase.Bed.volume` (0.45) in `src/shared/Chase.luau`.
- [ ] **On the phone's own speaker** (the Galaxy A16, no headphones): is the drone still there
  under the chase? It was chosen because most of its sound sits where a phone speaker plays; the
  other beds measured were mostly under 150 Hz and would vanish. If it doesn't feel like a chase
  on headphones, try "Rhythm Drone 44" (1843764058) or "Tension Repeat Drones 28" (1843867230);
  other hits to try: "Brute Force Sting 3" (1837950656), "Evil Mind 9" (1846887425).
- [ ] **The fade and the glance back:** get seen in a long hall, run, and break its sight round a
  corner: the drone should hang on and die away over about 4 s (`BedOut`). Step back into its
  sight within 4 s: the drone comes back with no second hit (`Regain`). Get seen afresh later
  (4 s after a loss, 8 s after the last hit, `StingGap`): a new hit.
- [ ] **The catch:** let it catch you: the music should cut dead as the screen jolts, and the
  black is silent.
- [ ] **Two screens** (Test > Clients and Servers, 2 players): the hunted player hears it; the
  friend beside them, not hunted, hears nothing of it.
- [ ] **Decide, defaults in place** (D-082): (1) only the hunted player hears the music; (2) a
  glance back within 4 s doesn't sting, nor a second keeper within 8 s; (3) a catch cuts the music
  to silence; (4) the drone starts from its top on each fresh chase.
- [ ] **Decide:** at 157 the guard sees you only once its door is all the way up, 11 studs off,
  and catches you half a second later, so the hit lands with no time to run if you open it
  standing in the doorway. Is that the lesson (peek first, open from the side), or should the
  guard get a beat before it comes?

## Now: judge L-06b5b, the peek's kneel (built Nov 10)

- [ ] **The moment** (Play on a computer, then at phone size, the Galaxy A16 view). "Walk a floor"
  and peek Unit 157: you drop low in a blink as the door lifts and see the guard's legs mid-stride
  under it. Peek 154: a sleeper's two feet, square and still. While down, Open, Close and Slam
  should sit just above the gap, on screen; tap Close and you stand as it shuts. Step off a stud,
  or jump, and you stand. Judge the eye's height (1.0 off the floor, `Kneel.Eye`), the drop's
  speed (0.35 s, `Kneel.Down`) and where the buttons sit (`Kneel.ButtonAngle`). Captures show
  neither the buttons nor sound, so both were checked by numbers only.
- [ ] **The rustle, by ear:** a soft cloth rub as you drop and as you stand (Pro Sound Effects'
  "Cloth Rub Soft Rustle 3", `Kneel.Rustle`). Too quiet, too loud, wrong stretch of the clip?
- [ ] **Two screens** (Test > Clients and Servers, 2 players): one peeks while the other watches
  from the hall. The kneeler's body should ease onto both knees, chest to the floor, forearms out
  toward the door, head up, and ease back up when they step off or the door moves. Look for: the
  body flickering against its standing animation, a head or hands reaching into the door when
  they knelt pressed to it (in ROADMAP's polish list), odd poses on a non-standard avatar.
- [ ] **Decide, defaults in place** (D-081): (1) every Peek drops you; there's no separate crouch
  button; (2) eye 1.0, so shins show as well as feet; (3) a step of more than a stud stands you
  (no shuffling along while down); (4) keepers don't hear the rustle.

## Now: judge L-06b5a, the guarded note (built Nov 10)

- [ ] **Heads-up for every test below that opens Unit 126 for an awake Mannequin:** on seed 7,
  floor 1 the floor's one awake keeper is now the guard of the note in **Unit 157** (`1 _ 9 _`),
  so 126 (and 112, 154) deal theirs asleep. Use 157 instead: its door faces west, a short walk
  east and north of the lobby; the guard stands 6 studs in. The directions in those tests (run
  west, stand beside the door) were for 126. To see 126 awake again, trap 157's guard first.
- [ ] **The moment** (Play on a computer). "Walk a floor": Output's notes line says
  `Unit157 (1 _ 9 _, guarded)`. Peek 126: Output says it held the Mannequin asleep. Peek 157:
  you drop low (L-06b5b) and see its feet under the door. Open 157
  in front of it: it comes for you. Then try D-072's plans for getting the note past it: a
  friend's torch freezing it while you grab the note, a slam elsewhere to draw it out, or the
  hole trap; once it's trapped, other doors can deal an awake keeper again.
- [ ] **Decide, defaults in place** (D-080): (1) one guarded note per floor; (2) the guard takes a
  note behind an unlocked door where it can, since a padlocked door can't be peeked; (3) on floors
  1 and 2 every other keeper is dealt asleep until the guard is trapped, so the floor stays calm
  until you take it on (D-072's open question: should the director wake keepers while you
  search?); (4) a sleeper woken by a noise plus the guard can make two loose on floor 1 (the cap
  limits only what the deal deals).

## Now: judge L-06b3d2, the dent (built Nov 10)

Same setup as L-06b3d1 below: seed 7, floor 1, slam 126 on its Mannequin, then stand in the hall
in front of it (a step or two back; walk a little so the hall light stays on).
- [ ] **The moment, at phone size.** The first blow already leaves a fist-sized pocket at chest
  height; by about 36 s the door is bowed from side to side with a fold across it; by about 68 s
  it buckles a full stud out, past the wall's line. Peek at it every half minute: does it read
  worse each time, and does the last step say "it's nearly through"? (Verified in Studio Nov 10:
  the steps landed at the first blow, 38.5 s and 68 s; `docs/art/L-06b3d2-*.jpg`.)
- [ ] **On low graphics** (a phone, or Studio's quality slider low): Studio's Automatic drew the
  dent nearly flat and Level21 showed it clearly. If it's lost on your phone, say so: the fix is
  deeper steps or a lighter fold in `art/unit/dent.py` (`STEPS`).
- [ ] **Walk along the wall past it** at the worst step: it stands about 0.4 proud of where the
  door stops you, so pressed right against it you may clip into the bulge. Fine, or should the
  door's collider grow with it?
- [ ] **Decide, defaults in place** (D-079): (1) a door keeps its dent for the floor, lifted or
  burst; (2) three steps, from the first blow, 0.4 and 0.75 of its time (`Dent.Lands` in
  `src/shared/StorageUnit/Dent.luau`); (3) as the door rolls up, each bowed rib goes flat behind
  the header, so an open dented door's coil looks normal; (4) the trapped keeper stands 3.4 in
  (`Keeper.Against`), its hand short of the door.

## Now: judge L-06b3d1, trapped, it bangs and breaks out (built Nov 10)

Seed 7, floor 1; Unit 126 holds the awake Mannequin. The trick: stand beside 126's door, not in
front of it (it sees you through the doorway and hunts), press Open and press Slam the instant the
door is all the way up, before it walks out (you have about a second).
- [ ] **The moment** (Play on a computer, then at phone size). After the slam, a breath later it
  hits the door from inside: the door jumps on its rail, a low boom, your view jolts if you're
  near. The blows come every few seconds and faster toward the end; at about 90 s the door flies
  up with a crash and it steps out to look. Does each blow land as something heavy behind the
  door? Is the jolt too much or too little at phone size? Does the speed-up tell you time's
  running out? (Verified in Studio Nov 10: 28 blows, out 90.25 s after the slam, the door
  jumping 0.2 studs, the boom at 0.55 of a slam's, the view turning up to 0.46 degrees a frame.)
- [ ] **Peek at it.** While it bangs, peek 126: its feet should show a few studs in (it now stands
  3.4 inside the doorway, L-06b3d2, so its reaching arm no longer pokes out through the door).
- [ ] **Padlock it** (with a real padlock in hand; my Studio test set the padlock from the
  server): it bangs on until its time, gives one last blow, then goes quiet for the floor. Cut the
  padlock with bolt cutters after that and it bursts out at once, in your face. Is that right?
- [ ] **Other keepers come.** With a second keeper awake on the floor, each blow (heard about a
  hall and a half off) brings it to the trapped one's door to look. Watch for keepers piling up
  there; say if blows should carry less.
- [ ] **Decide, defaults in place** (D-078): (1) slamming a door on a sleeping one wakes it
  trapped and banging, closing quietly lets it sleep; (2) the first blow at 1.2 s, then every 5 s
  closing to 2 s, a quarter either way; (3) out at 90 s; (4) padlocked, it falls quiet at 90 s
  instead of banging all floor (banging forever would call every keeper to that door); (5) the
  padlock cut after its time, it bursts out at once; (6) a blow carries 70 studs, the burst 130;
  (7) out, it goes after the last sound it heard through its door, else steps out to look.
  Numbers in `src/shared/KeeperRows.luau` (`bangFirst`, `bangEvery`, `bangEveryLast`,
  `bangJitter`, `breakOut`) and `src/shared/StorageUnit/DoorSound.luau` (`BangGain`,
  `BangShake`, the `Bang` and `Burst` rows).

## Now: judge L-06b3c, the catch (built Nov 10)

Seed 7, floor 1, as for L-06b3a2 below; Unit 126 holds the awake Mannequin.
- [ ] **The moment** (Play on a computer, then at phone size). Stand in the dark outside 126
  (walk away from the hall lights until they're out), open it and stand still. It comes out, and
  as it reaches arm's length your view jerks, the screen drops half dark and closes to black,
  "Caught" sits in the dark, and you can't move; then it opens inside a unit (L-07a, above).
  Output says "the Mannequin catches (you)". Does it land as its
  hand closing on you, or as a cut? Is 2 s in the dark right? (Verified in Studio Nov 10: caught
  at about 3.4 studs; held still exactly the 2 s.)
- [ ] **The torch saves you.** Again, torch on it as the door lifts: it hunts you frozen and never
  comes, however long you hold it. Torch off: it comes and catches you. (Verified in Studio: 12 s
  frozen, then caught 1 s after the torch went off.)
- [ ] **Run.** Let it chase you at your full run: it's slower (0.9 of your run), so it never
  catches you in a straight hall; stop, or walk, and it does. Is that fair, or too easy?
- [ ] **With a friend** (two players, Studio's Test > Clients and Servers): it catches only the
  one it hunts; a friend in its face is let be. Your friend sees you vanish into a unit (L-07a).
- [ ] **Decide, defaults in place** (D-077): (1) its grasp, 3.5 studs feet to feet (a stud past
  where its hunt stops) and 45 degrees either side of where it faces; (2) no wind-up: the moment
  it reaches you, you're caught; (3) a jump at its face is still caught, the units' tops never;
  (4) caught, it stands over the spot its 5 s linger, then roams; (5) keepers leave a caught
  player alone until they're let out (L-07a); (6) "Caught" is the only word on screen. Numbers in
  `src/shared/KeeperRows.luau` (`reach`, `reachAngle`) and `src/shared/Caught.luau`.

## Now: judge L-06b3b, light freezes the Mannequin (built Nov 9)

Seed 7, floor 1, as for L-06b3a2 below; Unit 126 holds the awake Mannequin.
- [ ] **The moment, the torch** (Play on a computer, then at phone size). Open 126 and run west,
  torch off. Round the junction, stop, turn and right-click your torch on it: it stops dead on a
  stride, reaching for you, and stays however long you hold the beam on it. Look away or switch
  off: it comes on at once. Output says "freezes in (your) torch" and "walks on". Does the stop
  read as a freeze, not a stumble? (Verified in Studio Nov 9 with the motion lights blind to me:
  froze 13.5 studs off the instant the beam found it, held 3 s, walked on to arm's length.)
- [ ] **The moment, the hall lights.** Let it chase you down a lit hall: it can't follow through
  the lights you leave behind you ("freezes in the light"). Stand still: the lights time out after
  7.5 s, and it closes in. Is that the "freeze and it closes in" dread the GDD wants, or does it
  make it too easy to outrun? (Verified in Studio: froze 24 studs back, closed in 3 s after the
  lights went out.)
- [ ] **Decide, defaults in place** (D-076): (1) frozen, it still sees you and can start hunting
  you, but never turns to face you; (2) frozen, its clocks stop too (a light on one standing at a
  door makes it stand there longer); (3) a hall light freezes it within 13 studs of a lit fixture,
  in the hall only, never inside a unit; (4) a torch freezes it within the beam you see (42 studs,
  54 degrees across), measured on its middle, not its width; (5) a torch shone from up on the
  units' tops doesn't freeze it (keepers can't see between the tops and the halls yet); (6) it
  walks on the very instant no light is on it, with no beat of hold. Numbers in
  `src/shared/MotionLight.luau` (`PoolReach`) and `src/shared/Flashlight/Torch.luau`.

## Now: judge L-06b4a, keepers move smoothly on every screen (built Nov 9)

Seed 7, floor 1, as for L-06b3a2 below. What a keeper does is unchanged; how its walk reaches each
screen changed.
- [ ] **The moment, at phone size** (Studio's Device emulator; your own phone too if you can):
  open Unit 126 and run. It comes after you in one smooth, stiff-limbed walk, holding each stride
  and snapping to the next, never hopping or sliding, and pivots sharply at the junction rather
  than popping round. Stopped at arm's length, it stands on a stride, never between two.
  (Verified in Studio Nov 9 at Studio's 15 frames a second: drawn at its pace, no stalls. That's
  numbers, not feel.)
- [ ] **Two screens** (Test > Clients and Servers, 2 players): one opens 126 and runs, the other
  watches from down the hall. Both see the same smooth walk in about the same place.
- [ ] **Decide, defaults in place** (D-075): (1) each screen shows a keeper 0.1 s behind the
  server, so turns and stops land exactly; at its top speed that's 1.4 studs behind where it truly
  is (`Delay`); (2) at a corner it pivots in about 0.15 s (`Turn`); (3) on a bad connection a
  correction over 4 studs snaps rather than slides (`Snap`). Numbers live in
  `src/shared/KeeperMotion.luau`.
- [ ] **Heads-up:** Studio's Server view now shows the keeper in its rest pose, moving in hops of
  up to 8 studs. That's expected: only screens draw its walk. Judge from the Client view.

## Now: judge L-06b3a2, it sees you and hunts (built Nov 9)

Seed 7, floor 1, as below; Unit 126 holds the awake Mannequin. It doesn't catch you yet (L-06b3c):
it comes to arm's length and stands in your face.
- [ ] **The moment** (Play on a computer). "Walk a floor", stand in front of Unit 126 and open it:
  the moment the door is up it sees you and comes straight out at you. Run west down the hall: it
  stays a few studs behind, a little slower than you, and follows you round the junction if it
  still has you in sight. Get out of its sight (round a corner well ahead of it, into a unit with
  the door pulled down, or up on the tops) and it rushes to where it last saw you, stands there
  five seconds, then wanders off. Stand in a hall it roams down and it turns and comes. Creep up
  behind one walking away: it doesn't see you. Output says "sees (you), N studs off, and comes at
  them" and "lost (you)". Does the chase feel fair, and scary? (Verified in Studio Nov 9: all of
  the above but the unit and the creep, by teleporting and walking the character from the MCP.)
- [ ] **Decide, defaults in place** (D-074): (1) it sees 48 studs (two hall pieces) and 60
  degrees either side of the way it faces, blind behind; (2) it notices you the instant you're in
  view, with no slow "it's noticing you" build-up (Alien: Isolation has one; Granny doesn't); (3)
  hunting, it keeps you while it can see you at all, any way it faces, out to 48 studs; (4) it
  hunts at 0.9 of your run and stops 2.5 studs from you; (5) hunting, no sound pulls it off you,
  but once it has lost you a slammed door takes it to look (a friend can draw it away); (6) it
  never sees you up on the tops, nor in the elevator car; (7) where it lost you it stands its
  usual 5 s, facing the way it was going. Numbers live in `src/shared/KeeperRows.luau`.
- [ ] **Heads-up on L-06b3a1's test below:** standing in front of 126 as you open it now starts a
  hunt. To watch it step out and roam, open it from the side, out of its view.

## Now: judge L-06b3a1, once out it roams (built Nov 9)

Seed 7, floor 1, as below; Unit 126 holds the awake Mannequin.
- [ ] **The moment** (Play on a computer). "Walk a floor", open Unit 126 and step back: it walks
  out, stands at the door's front looking for five seconds, then wanders off down the halls.
  Slam 126 behind it: nothing changes, it never goes home. Follow it a minute: it walks some way,
  stops three seconds mid-stride, walks on, never to one of its last four stops. Open a door
  near it and it comes to look, then roams again. Output says "wanders off down the halls" each
  time it sets off. Does losing track of it make the next door scarier? Does it read as hunting
  for you, or as aimless? (Verified in Studio Nov 9: it left 126, roamed 75 s without going back
  in, never stood still over 3 s, and came to Unit 139's open 33 studs off.)
- [ ] **Decide, defaults in place** (D-073): (1) each roam goes 40 to 120 studs along the halls to
  a hall piece's middle, at its looking pace (about 7 studs a second), and it stops there 3 s;
  (2) it avoids the last 4 places it stood; (3) it may roam the lobby and past the elevator's
  gate; (4) stopped, it holds the stride it stopped on, facing the way it walked, rather than
  turning to look down the hall; (5) one whose door came down before it got out stands watching
  in its unit until the door is up again (the break-out, L-06b3d, will have it bang). Numbers
  live in `src/shared/KeeperRows.luau`.

## Now: judge L-06b2b, keepers behind doors (built Nov 9)

The walked floor in the place is seed 7, floor 1 (Workspace's `DevFloorSeed`, `DevFloorNumber`):
Unit 112 holds a Mannequin asleep, Unit 126 one awake, Unit 154 one asleep. Output says each.
You judged the sleeping and awake ones Nov 9 (not bad; the walk jerky; too easy to shut away):
D-071 and D-072 answer it, and the tickets are in ROADMAP's L-06b3 to L-06b5.
- [ ] **The cap.** Open Unit 112, then Unit 113 to wake 112's sleeper, then Peek Unit 126: Output says it held the
  Mannequin asleep, because floor 1 allows one awake keeper and one already is.
- [ ] **Decide, defaults in place** (D-070): (1) a keeper dealt asleep doesn't wake to its own
  door opening, only to the next loud sound that reaches it while its door is up (the open's
  rattle starts while the doorway is shut, and the floor's cap of awake keepers would mean
  nothing if every open woke the one inside); should a full open wake it after all, or a peek
  never? (2) a slam on its own door while it's up does wake it, shut in (the bang sounds before
  the door is down); (3) a woken keeper stays awake for the floor (one trapped will take no
  place in the cap, D-071); (4) the awake one, dealt, holds its walk's first stride, reaching
  at the door.

## Now: judge L-06b2a, the Mannequin comes to look (built Nov 9)

- [ ] **The moment** (Play on a computer). "Walk a floor", then press **Stand one** on the post in
  the lobby's corner (across from "Come back"): a Mannequin stands 60 studs down the halls, facing
  the lobby. Open or slam a door near the lobby and watch it come down the hall, stand square in
  front of that door facing it for five seconds, then wander off down the halls (L-06b3a1: it no
  longer walks back). Output says
  each step ("heard Unit 101's door open, 40 studs off along the halls"). Does it feel like
  something heard you? Does seven seconds or so from a slam two halls off give you time to hide?
- [ ] **Never through walls.** Open a door the Mannequin could see past a wall but would have to
  walk round to reach (a hall over): beyond 110 studs along the halls it stays still, even when a
  straight line is much shorter. A peek never brings it; a slam round a corner brings it the
  shortest way round. Stand inside a unit with the door pulled down while it waits outside.
- [ ] **Decide, defaults in place** (D-069): its walk to a sound at about 7 studs a second (half
  its top speed of 0.9 of your run); it waits 5 s; it hears an open, a slam and a lift from inside
  as far as you do, but not a close, a rattle at a padlocked door, a padlock going on or the
  cutters' snap. Should a close or a rattle draw it too? Numbers live in `src/shared/KeeperRows.luau`.

## Now: judge L-13b2d2c, the hole on the tops (built Nov 9)

- [ ] **Crawl at a hole** (Play on a computer). Saw Unit 101's top as before, then crawl round
  behind the hole and push at it: you stop at its edge, your view out over it. Torch on, look
  straight down: the unit's floor and the fallen panel. Crawl along its sides too. Does stopping
  at the edge feel like a ledge you're leaning over, or like an invisible wall?
- [ ] **Slide off it.** Saw again on another unit lying beside the hole's spot with your feet or
  side over it (your middle on it still gets "Move off it"). As it goes through you glide a stud
  or two onto the steel with the steel's ring and a small jolt. Is the glide clear but not
  jarring? **Two players:** a friend lying across the hole when it goes through glides off on
  both screens, never into the hole.
- [ ] **Climb onto a sawn top.** At a sawn unit's ladder, Climb: you land by the ladder, clear of
  the hole. A second climber gets "No room up there" until the first crawls a body away. On a
  small unit the first climber now lies a quarter stud further out from the ladder's middle (every
  small unit, sawn or not): does it look off?
- [ ] **The bulb from the tops** (phone, Galaxy A16). Open a unit so its bulb is on, saw its top,
  crawl along the next units' tops and look back. On a computer at high graphics the hole's rim
  glows and the ceiling above it catches light, the rest dark. On a phone, lower graphics may light
  the whole top through the steel (they ignore what's in the way): say how it looks there.
- [ ] **Decide, default in place** (D-065): on a sawn top the ladder gives one lying spot, by the
  ladder (the others lie on the hole or roll across it), so a team climbs one at a time.

## Still to judge from L-13b2d2b, sawing down through a unit's top

- [ ] **Watch the panel drop** each time: once in Studio (the first cut of a session) it lay on
  the floor at once with no fall; every cut after dropped. Say if you see that.
- [ ] **Phone size** (Device Emulator, a Galaxy A16, the same lie): is the line clear but thin,
  and is the Saw button easy to hold without catching Drop down at the front's edge?
- [ ] **Two players:** a friend in the hall, and one inside the unit with the door shut, hear the
  saw and the clang from where they are and see the line from the tops and the panel fall.

## Now: judge L-13b2c2, what you hold kept out of walls (built Nov 9)

- [ ] **Your hands** (Play on a computer). Your torch and a tool in your other hand (pick up the
  bolt cutters or the saw) should look exactly as before: same size, same place, same sway. Walk
  nose-first into a closed door and a wall: nothing pokes through. Lean the ladder, climb up and
  lie on the steel: look straight down, up at the ceiling and about; nothing goes through the steel
  or the roof, and looking straight down the torch ducks out of view and comes back as you look up.
  At a unit's front, look down and out: the beam lights the hall below. Look for: does the duck read
  as natural or as a glitch? Does the beam ever look like it starts in the wrong place?
- [ ] **A tool in hand** (nobody here could pick one up from a script): walk the bolt cutters, the
  saw and the ladder into a door; Cut a padlock and Saw a wall as before. The saw at the wall and
  the cutters at the lock should look as they did.
- [ ] **Two players** (Clients and Servers, 2 players): a friend lies on a top with their torch on,
  or presses it to a closed door; the inside of the unit stays dark.

## Now: judge L-13b2c, crawling the tops and dropping down (built Nov 9)

- [ ] **Listen** (nobody here could): each pull is a soft low boom of the steel with a quiet
  drag; sliding off is the steel's ring; landing is a body's thud. From the hall below, a friend's
  crawl should be heard a unit or two away. Say which is wrong.
- [ ] **Round a corner** (Walk a floor): where a row of units meets a junction and the cross hall
  has units too, crawl past the last unit onto the steel lid in the corner and on round onto the
  other row. Checked on floor 1 only onto a lid that ends a row (unit 105's).
- [ ] **Two players** (Clients and Servers, 2 players): your friend crawls smoothly on your
  screen, arms reaching and hauling in turn; you hear their booms from the hall. While they're up
  there, Take works (they drop down instead). A second climber lands in a spot nobody lies in.
- [ ] **On the phone** (Galaxy A16): crawl with the thumbstick; tap Drop down and Climb down.
- [ ] **Decide, defaults in place** (D-059): (1) the crawl is 4.5 studs a second, backward at
  half; (2) dropping off is a button, not crawling off the edge (on a phone an accidental crawl
  off would be an unwanted escape); (3) your body turns toward where you crawl, not with your view,
  so looking about doesn't swing your view round your hips.

## Now: judge L-13b2a, leaning the ladder and climbing it (built Nov 9)

- [ ] **Lean it, climb it, come down, take it** (Play on a computer). Pick up the ladder by the
  spawn (E) and walk to unit 102 across the hall. Look up at the top of its front: a "Lean"
  button (R) sits up there on the left of the door, only while the ladder's in your hand. Press
  it: the ladder swings off your shoulder against the front (a bang as its top lands), the top
  half runs up with a metal rattle and stops with a clack, rails resting on the edge and reaching
  past it (`docs/art/L-13b2a-leaned.jpg`). At its foot: Climb (E) and Take (F). Climb: you go up
  rung over rung in about a second and roll over the edge onto your belly on the top with a
  thud (now steel, L-13b2b) (`docs/art/L-13b2a-view.jpg`; the tops are dark, so turn your torch on).
  Turn round to the hall: "Climb down" (E) sits just past the edge over the ladder (moved in
  L-13b2c). Down you go, a step back into the hall. Take: it's back on your shoulder. Look for:
  is the climb quick enough for an escape and slow enough to read? Is the roll onto the top too
  sudden or too slow?
- [ ] **Listen** (nobody here could): the top landing, the rattle running up, the locks' clack,
  the rungs (one recording of a metal ladder climb). Say which is wrong.
- [ ] **Two players** (Clients and Servers, 2 players): you see your friend climb with Roblox's
  own climb animation, then lie on the top reaching ahead (`docs/art/L-13b2a-lying.jpg`). A second
  climber gets the next spot along the front (three fit on a small unit, four on a big one).
  While one is on the rungs, Climb and Take say "Wait for them" and "Someone's on it" (since
  L-13b2c, Take works while people are up top: they drop down). Check a friend's climb looks
  smooth, not stepped.
- [ ] **On the phone** (Galaxy A16): not checked this session (the simulator can't be set from a
  script). Tap Lean, Climb, Take and Climb down; is the Lean button reachable without walking
  under it, and does lying on the top read on a small screen?
- [ ] **Decide, defaults in place** (D-057): (1) climbing is a pressed move the game makes, as
  the crawl is, not Roblox's own truss climbing (on a leaned truss it flicked between climbing and
  falling in Studio); (2) the ladder leans on the left of the door as you face the unit, so the
  doorway stays mostly clear.

## Now: judge L-13b1, the ladder carried (built Nov 9)

- [ ] **Carry it** (Play on a computer). A ladder now lies along the hall past the saw, by the
  spawn: pick it up (E). You hear a bang and a rattle; in your view it sits low on your left,
  rolled to show its rungs, its top end reaching across the bottom of the screen; your walk
  slows to three quarters. Press 2 or pick up anything: "Drop the ladder first". Drop it (G): it
  falls flat in front of you with a clatter on concrete and your walk comes back. Look for: does
  it feel heavy and slow without being a chore (12 against 16; say a number)? Is it too big in
  your view? With a light behind you it goes dark in your view (your own body's shadow): say if
  it bothers you, and it moves further out.
- [ ] **A friend carrying it** (Clients and Servers, 2 players): it rides on their left shoulder
  on its edge, top leading, the rope and rungs showing (`docs/art/L-13b1-carried.jpg`). Their
  arms swing free (a raised arm is in the polish list). Hand it over (the Give button near them):
  they get it, slowed; a friend holding it can't be handed anything ("Their hands are full").
- [ ] **Where the deal lays it** (floors 1 and 2, one ladder each): across a small unit wall to
  wall under the bulb (`docs/art/L-13b1-unit144.jpg`), deeper in a big one. Open units until one
  holds it (Output says "held a tool, Ladder"). Does it read from the doorway?
- [ ] **On the phone** (Galaxy A16): not checked this session. Its size in your view, the slot's
  picture, the "Drop the ladder first" line.
- [ ] **Decide, defaults in place** (D-056): (1) friends see it on the shoulder, not in the hand;
  (2) both hands, as Lethal Company's two-handed items: no switching or picking up while held;
  (3) walk 12 while it's in your hand.

## Now: judge L-13a, the tops closed (built Nov 9)

- [ ] **Read the tops on a map:** in a terminal at the project, `lune run scripts/floor-map 7 1`.
  Under "The tops", `=` now marks a junction's lid: an S unit's wire top over the hollow corner
  square where two rows meet, so a run goes on round the corner into the next row's run instead
  of dropping into a pit. Look for: runs joined round most corners, so a friend on the tops has
  somewhere to go. Nothing to try by hand yet: nobody can get up there until L-13b's ladder.
- [ ] **Decide before the ladder (now pressing):** a standing avatar wedges on the tops (3.9 studs
  to the deck; it neither falls nor moves). The default stays crawl-only up there (L-13b builds a
  crawl), the other way is taller floors (every unit and hall piece rebuilt). Say if you want
  taller floors.

## Now: judge L-12b3, crawling through (built Nov 9)

- [ ] **Crawl through** (Play on a computer). Saw 106 into 108 first (the next section's first
  check). A "Crawl / Unit 108" button now sits low at the hole on 106's side: press E. You drop
  onto your belly at the hole's mouth (a body's thud, a small jolt), drag yourself through in two
  pulls (a drag on each, a steel scrape as your shoulders reach the cut, your view rocking, your
  eyes just over the bright lip), then stand up in 108 looking on the way you went: about 1.4 s.
  108 is padlocked, so this is the only way in; crawl back ("Crawl / Unit 106" on 108's side).
  Is the length right, tense with a keeper behind you and not a cutscene? Do the three sounds
  sound like a body and steel (picked by loudness, unheard)?
- [ ] **The button:** you see only your own side's (the far one shows through the hole
  otherwise), none while you crawl, and none from the hall or more than 5 studs off.
- [ ] **A friend watching** (Clients and Servers, 2 players): one crawls while the other watches
  from 106, then from 108. Look for: the body dropping, sliding through head first with the arms
  reaching ahead and hauling in turn, the hands meeting ahead of the head, then standing up; the
  sounds heard about a unit each way. Both press Crawl at once: the second gets "Wait for them".
  Screens here show the crawler's own view and an outside view of the same body (Studio).
- [ ] **A small unit:** saw 109 into 111 (the short hall past the turn) and crawl it both ways:
  you stand up clear of the far wall.
- [ ] **On the phone** (Galaxy A16): where the Crawl button sits, and the low view's read.
- [ ] **Decide, defaults in place** (D-054): (1) a pressed button and a short move the game makes
  (or a crawl you steer, as DOORS' vents?); (2) one body in a hole at a time; (3) the hole's 3
  studs fit a default avatar's shoulders only with its arms tucked to its head, so a bulky avatar
  may graze the sides for a moment: widen the hole to 4 (an art rebuild) if you see it; (4) E to
  crawl, the door's key.

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

- [ ] **Look at a sawn hole** (Play on a computer, after sawing 106 into 108 above; the test
  hall no longer cuts holes as it's laid). Open 106 (E) and look at its wall toward 108: a low
  ragged hole, a bright strip of bare steel round its cut, a few tongues of steel bent away from
  you, and the cut panel lying on 108's floor beyond. Then crawl through and look back from 108:
  the panel flat on its ribs in front of the hole, the tongues bent toward you; 108's door stays
  shut (padlocked), so its floor by the hole is lit only by 106's bulb through it. Does it read
  as sawn, and does that square of light land? Is the hole too big or too small for a crawl (3
  studs wide, 2.6 tall)?
- [ ] **On the phone** (Galaxy A16, set in Edit first): from 106's doorway, once sawn, it reads as
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
- [ ] **Decide, defaults in place** (D-050): (1) a find is a prop you can't carry yet (Phase 2);
  (2) a short thing (a tool, a find, under 3.5 studs) may stand under a note, only a keeper keeps
  off the whole line to it; (3) tools lie in the bulb's pool, never against the back wall, so
  they read on a phone. (Every dealt tool is built since L-14e: a tool unit always holds one.)

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

## Decide: the monsters (Nov 10)

- [ ] **The monsters, reworked:** the GDD's roster beyond the Mannequin was my early draft, never
  your pick, and much of it starts from what a storage building holds (a rug, a clock, boxes, a
  moth) rather than from the loop. The Moth and its mothballs are out (your call, Nov 10). My
  proposal: rebuild the roster from what each one does to a floor (hunts you while you search,
  cuts off a hall, goes after the code, chases you to the gate), each with a hit game's rule and
  storage only as its look. The ones with a clear precedent today: the Mannequin (Lethal
  Company's Coil-head), the Grandfather's rule (DOORS' Rush), the Tenant (Lethal Company's
  Hoarding Bug) and the Haul (DOORS' Seek). Their name too: "keepers" is only our working word in
  the docs and code, and nothing on screen says it. Say when you want a session on this.

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
