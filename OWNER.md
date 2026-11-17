# Owner

Everything waiting on you, in order. Work down and tick boxes. Agents add new items here and
nowhere else.

## Now

- [ ] **Push Brix before you push this game** (S5-03a3a, D-273): the game now pins Brix at
  `482368f` (the plots each player's home comes from), which is only on this Mac. In `../engine`,
  `git push origin main`, then this repository. Pushed the other way round, a fresh clone can't find
  the pinned commit.
- [ ] **Your home, with a friend** (S5-03a3b, D-275; seen with one player only). Studio's Test
  tab, Clients and Servers, 2 players. Look for: each player gets a home by the front door (1 then
  7), their name sprays onto its card with a soft hiss and the door rolls up. Player 1 pulls their
  door down; player 2 presses Open and Peek on it: it rattles and stays shut, no words. Player 1
  opens it again. Player 2 doesn't see player 1's light switch. Close player 2's window: their card
  fades blank, their door comes down and a padlock clicks on. Listen: is the hiss right for a name
  going up? And my default: anyone may pull an open home's door down; only opening is the holder's.
- [ ] **The hard hat on your head, with a friend** (F-G1b4a1, D-277; seen with one player only).
  Studio's Test tab, 2 players; on the Server, `workspace:SetAttribute("GiveFind", "HardHat")`
  puts one in player 1's hands. Player 1 presses Wear. Look for, on player 2's screen: the hat sits
  on player 1's head (not floating, not sunk to the eyes, its battery hidden), you hear a hollow
  knock and then the lamp's click, and a warm light shines from their forehead the way they face.
  On player 1's screen: the hat's slot is empty and the hall ahead lights up. Then let a Mannequin
  catch player 1 on a floor: the hat falls with everything else. Say whether 1.4 times its real
  size looks right on a Roblox head. My defaults, say which to change: a worn hat is kept at the
  gate with your other finds (it goes from your head in a glint); you can't wear a second hat over
  one; the Packrat robs your hands, never your head.
- [ ] **The mirror test** (S5-03b, D-280; seen in Studio Play Nov 17 and fixed, as it was blank;
  pictures in `docs/art/S5-03b-*.jpg`). Play with one player; walk into your home and turn left
  from the rug: the mirror leans on the wall. Look for: you facing you, moving the right way round
  (turn, jump, walk sideways); stepping side to side shifts the room behind you as a real mirror
  does; your rug, plant, lamp and walls behind you. Come right up to it: your outline stays
  smooth. Flip the switch: the reflection dims with the room and its ceiling lamp goes dark. Wear
  the hard hat: it sits on top of your head over your hair, brim over your brow, lamp on your
  forehead (D-283, `docs/art/F-G1b4a-on-head-*.jpg`): bigger or smaller? higher or lower? Then the
  Device Simulator's Galaxy A16: does the frame rate hold in front of it? Walk out: the mirror
  goes still. With 2 players, your friend shows behind you. Known limits: no shadows and no lamp
  light in the picture (an even warm light), its walls are plain paint without the plaster's
  grain, and writing on clothes reads the right way round. Say: convincing, or not. My defaults,
  say which to change: the left wall by the rug, 2.4 by 5.6 studs, leaning 6 degrees. While this
  is open the build goes on as if it convinces (S5-03f1 built its real frame on it).
  **Its frame** (S5-03f1, D-314; seen in Play on the A16, `docs/art/S5-03f1-*.jpg`, sheets
  `art/sheets/lobby-mirror*.png`): a moulded oak frame, the glass's bevelled edge a pale sheen
  round the picture, felt pads under it and on its top's back against the wall. Look at it at
  phone size from the rug and close up. Say: warm and real, or not; the frame wider or slimmer
  (0.28 studs of oak), the bevel brighter or quieter.
  **The clothes rail beside it** (S5-03f2a, D-315; seen in Play on the A16,
  `docs/art/S5-03f2a-rail-a16.jpg`, sheets `art/sheets/lobby-rail*.png`): a rolling oak rail on
  castors past the mirror, a hat shelf on top, three oak hangers on a graphite bar, a shoe rack.
  My defaults to judge: it stands on the mirror's wall further in, 0.7 studs past the mirror (or
  nearer the door, or on the other wall); its size (4.5 across, 5.2 tall) beside you.
  **Wearing from it** (S5-03f2b, D-316; seen in Play on the A16,
  `docs/art/S5-03f2b-worn-mirror-a16.jpg`). With a hard hat in your save (on the Server,
  `game.ServerStorage.ShelfTest:Invoke(game.Players:GetPlayers()[1], "HardHat")`), walk up to the
  rail: the hat stands on its top shelf. Press Wear: listen for its knock and the lamp's click,
  then turn to the mirror. Press Hang up over the empty shelf: a glint at your head, the knock,
  the hat back on the rail. Say: the hat on the rail the right size (it stands at the size you
  wear it, so the brim overhangs the shelf a little), and whether it wants to lift off and settle
  back with motion (ROADMAP polish, "The rail's motion").
  **Its minute starts on the climb** (S5-03f3, D-317; the server side seen in Studio Play, your
  screen not, see STUDIO.md "Patching scripts without Rojo"). With Rojo connected, wear the hat
  from the rail, wait a while at home, then ride a lobby car up. On floor 1 the lamp should stay
  lit about a minute, then dim and go out; nothing should click or knock again as you arrive. Also
  switch a lantern on at home: it shouldn't run down there, and should get its own minute once
  you ride up. Say: is a minute from the car right, or should the ride itself count?
- [ ] **Try a wrap colour on at your mirror** (S5-03f4a, D-318; seen in Play on the A16 with the
  server's film, `docs/art/S5-03f4a-*.jpg`; Studio's copies were patched, so connect Rojo first).
  In your home, stand in front of the mirror and press Try on (R, or tap the chip). Look for: you
  turn once round as the film winds up you from the ankles with a quick zip; three seconds
  wrapped in Blue in the glass; a crinkle, the film slumps to a heap round your feet with a soft
  crunch and fades; then you can walk. Press again: Red, then Green, Pink, Orange, Black, Blue.
  With 2 players, your friend sees you spin and wrap too. Listen: is the zip too like the catch's
  squeal for a calm home? My defaults, say which to change: each press tries the next colour
  (no choosing at home; the counter's mirror will try the card's colour); anyone at any mirror
  may try one, a visiting friend too; you're held still the whole 5.6 s; the button is on R.
- [ ] **Try a colour on from the counter's shop** (S5-03f4b, D-319, D-320; I saw all of it in
  Studio Play on the A16, pictures in `docs/art/S5-03f4b3-*.jpg`; judge the feel on a real phone,
  Rojo connected). From the spawn walk left to the counter. Look for: the framed
  mirror leaning on the front wall just past the counter, you in it as you come up; the Shop
  button now at the counter (it used to stand by a home's door). Press Shop: each colour's
  figure has a "Try on" pill. Tap a figure (say Pink): the card pops, the shop slides away, your
  view swings to the mirror and you're wound in Pink there, then it peels off. Walk away from the
  mirror, or stand to one side of it, and open the shop from the top bar: no Try on pills. My defaults, say which to change:
  the mirror's spot (front wall, counter's door end); Try on works within 12 studs of the glass,
  so anywhere at the counter; the whole figure is the button; your view turns to the glass.
- [ ] **Your home's looks** (S5-03g1a, D-321; art only, not in the game until S5-03g2). Open
  `art/sheets/home-floors.png` on your phone: eight units as you'd walk in, each a floor, a wall
  and a paint, and the door colours on the lobby's teal along the bottom. Look for: would you want
  each one, and show it off to a friend walking past? Does anything look like the climb? My
  defaults, say which to change: floors are oak boards (a home's), carpet, checker tiles and
  rubber mats; walls are plain (a home's), stripes, leaves and daisies; eight paints from warm
  white to ink; eight door colours from clay; carpet, checker and mats each come in five colours;
  every paper takes the wall's paint as its ground.
- [ ] **Your name card's four styles** (S5-03g1b, D-322; art only, not in the game until
  S5-03g3). Open `art/sheets/home-cards.png` on your phone: along the top, each style over a door
  from the floor; below, the four from down the hall and from across the floor. Look for: can you
  read every name from across the floor, and does the neon one make you want it? My defaults, say
  which to change: stencilled steel (slate blue, cream letters) is every home's; a painted board
  (forest green, cream pinstripe) and a chalkboard in oak are for cash; neon (pink) is for Robux.
- [ ] **The counter's furniture** (S5-03g1c1 and c2, D-323, D-324; art only, not in the game
  until S5-03g4). Open `art/sheets/home-furniture.png` on your phone: top left, a milk crate, a
  pallet coffee table, a folding table and a steel shelf by a person for scale; top right, a
  folded moving blanket, a camp bed, string lights and a neon moon and star; then a unit made
  into a place to hang out, by day and at night with the ceiling lamp off. Look for: would you buy
  each to sit on, lie on, set a find on or gather round, and does the night one feel like a
  sleepover? My defaults, say which to change: the crate upturned to sit on (colours mustard, teal,
  terracotta), two pallets stacked into the coffee table, a pale table top, a sage shelf; the
  blanket folded into a floor cushion (mover's blue, cream binding), an olive canvas camp bed with
  a cream pillow, twelve warm globe bulbs in three swags, and a moon and star for the neon (warm
  yellow; the name card's neon is the word, this one the picture).
- [ ] **Come home to your shelf** (S5-03c1b, D-285; seen in Studio Play Nov 17 on a 1380x761
  window, not at phone size; pictures in `docs/art/S5-03c1b-*.jpg`). Play with one player. On the
  Server, `game.ServerStorage.ShelfTest:Invoke(game.Players:GetPlayers()[1], "Boombox")` keeps a
  find as a gate does (try "Teddy", "WalkingRobot" too; a kind your save has never had chimes).
  Stand in your doorway. Look for: each find in its own cubby, square and facing you, a big one
  shrunk to fit, a slow gold twinkle on each new one that you notice from the door. Walk up to
  the shelf: within about 7 studs each new one answers once, the twinkle bursts and stops with a
  soft tink; a kind never owned chimes, turns once slowly and shows a small "New" that fades.
  Stop and Play again: they're all still there, no longer sparkling. On the Device Simulator's
  Galaxy A16: is the twinkle visible from the door, is "New" readable, is the tink too quiet?
  Then play a real climb, keep a find at a gate, ride home: it's on the shelf, sparkling.
- [ ] **Hear your job box** (S5-03c2a, D-287, D-290). Seen working in Studio Play on Nov 17
  (`docs/art/S5-03c2a-from-door.jpg`, `-open.jpg`): the twinkle, Open, Close, walking away, quiet
  after a rejoin, and the ceiling warm past the lamp. What's left is yours to hear and judge. In
  Play with one player and your shelf full, keep one more find with ShelfTest (above): from your
  doorway the blue box by the lamp has a faint gold twinkle on its lid. Walk up and press Open (E):
  listen to the creak as the lid swings up (and the shelf's chime if it was a kind you'd never
  had); press Close and listen for the clunk as it lands. Say: does the creak sound like a steel
  lid and the clunk like a heavy one, can you see the twinkle from the door at Galaxy A16 size, and
  is the box's blue calm in your home?
- [ ] **Look through your job box on a phone** (S5-03c2b1, D-291). Seen in Studio Play at
  computer size on Nov 17 (`docs/art/S5-03c2b1-open.jpg`, `-search.jpg`): the panel rose with the
  lid, 18 kinds with their counts, typing "lamp" left the two lamps, the X dropped it with the lid.
  Yours: in the Device Simulator's Galaxy A16, open your job box (E, or its button). Watch the
  panel rise with the lid and fall with it; tap a rarity chip, tap it again; type in the search
  box; tap outside the panel; walk away with it open. Say: can you read the names and the x2 at
  that size, does the rise feel slow or right (it takes the lid's 1.1 s), and is the deep blue
  calm. My defaults, yours to change: rarest first then by name; chips only for rarities you own;
  a card shows the find as your slots draw it, with no price yet (selling is S5-03c3).
- [ ] **Decide: Gold defaults** (S5-03c3b1, D-298). My defaults, yours to change: four of one find
  make one Gold worth five times the find (the item catalog's table), so making one beats selling
  the four a little; cracked lamps go into a Gold first and come out whole; no Secret Golds; a Gold
  is solid gold, so it never cracks when dropped (D-300).
- [ ] **Decide: leaving mid-climb with a find you took up** (S5-03d1, D-302). My default: it's
  lost to you, as if you'd been caught, and a friend who carries it aboard keeps it. The other
  way, leaving would be a free way to save a find from a bad climb. A server crash never costs
  one either way. Say if you'd rather leaving sent it home.
- [ ] **Decide: does a find you take up ever come home to you?** (S5-03d2, D-302, D-304). As
  built:
  1. You take your lamp out of your job box and ride a lobby car up. It's on the climb now.
  2. Each time the gate shuts with it in your hand, it stays in your hand, so you can use it on
     the next floor too. Finds you found that floor rise out of your slots as usual.
  3. There's no top floor, so every climb ends with everyone caught. When you're caught, what
     you carry drops where you stood, your lamp too, and the floor goes with the climb.
  4. So your lamp only comes home if a friend picks it up and carries it aboard, and then it's
     theirs. Otherwise it's struck off your save.
  The other way: when the gate shuts with your own taken-up find in your hand, it goes home into
  your box like any find you keep (it rises out of your slot), so it helps you for one floor and
  is safe after. My default is as built (it's what D-302 says); say if you want the other way.
- [ ] **Test: taking finds up with a friend** (S5-03d3, D-304, D-305). Seen in Studio with one
  player on Nov 17: a lamp taken up stayed in hand at the gate, was struck off the save when left
  on a floor, and nothing was lost or doubled across a rejoin or a Stop. Yours, two players
  (Studio's Test tab, Clients and Servers, 2 players; Studio climbs on the same server):
  1. Player 1 takes a find out of their job box and both ride a lobby car up. On floor 1, Player
     1 drops it; Player 2 picks it up and is aboard as the gate shuts. It should rise out of
     Player 2's slot. Back home, Player 1's box has one fewer and Player 2's one more.
  2. Player 1 takes another find up, then leaves mid-climb (close their window). Output prints
     "GatePay: … out of …'s job box: Lost". Player 2 picks it up and carries it aboard: theirs.
     Player 1 rejoins: one fewer.
  Look for: nothing doubled, nothing else gone.
- [ ] **Arrange's limit bar, the lid and a friend's finds** (S5-03e3b, D-313; the bar filling
  and the lid seen in Studio Play on the Galaxy A16, `docs/art/S5-03e3b-*`; a friend and a full
  room not seen). Studio's Test tab, 2 players. Player 1 walks into their home and taps Arrange:
  a small bar top middle shows how many finds are out of 25; Place one and it fills a little,
  the count popping. Player 2 stands in player 1's doorway: each find player 1 sets out drops a
  hand's width into place with a soft knock, never just appears; a disco ball on the ceiling
  rises up into place. Player 1 opens the job box with the moon lamp on its lid: the lamp rides
  the lid up and back down. Look at it from the side: the lid stops at about 60 degrees, the
  lamp leaning back to the wall, with a knock (my default: a lid with something on it opens only
  as far as it can go; the other way is the lamp hidden through the wall). To see the room full,
  set 25 out: the cards dim, and a press on one shakes it and pulses the bar.
- [ ] **Judge: a Gold on your shelf** (S5-03c3b3, D-300). Seen in Studio in your hand (it reads as
  solid gold under the bulb) and in the hand wells, but the shelf's cubby never came clear in a
  capture. Open your job box, pick a Gold card, press Shelf, then stand at the shelf: does it
  shine gold in its cubby, or go dull where the bulb doesn't reach (D-290's warm fill)?
- [ ] **Judge: four make a Gold, on a phone** (S5-03c3b2, D-299). Seen in Studio at the window's
  size (1380 by 761), not on a phone. Keep four of one find (or have them), open your job box, tap
  that card: Gold glows over Sell with a shine. Press it. Look for: the panel dims; four pictures
  leave the card one by one with rising chinks; they swirl in faster, turning gold, a rattle and a
  rising tone building; a white-gold flash, a ring and sparks; the Gold big in the middle with
  turning rays and its name; it flies onto its card beside the four. Does it feel big enough, too
  long (about 3.5 s), and are the sounds right? A Gold when the four were the card's last: the
  card goes under the flash and the Gold takes its place (fixed after the Studio pass, unseen).
- [ ] **Sell a find from your job box** (S5-03c3a, D-297). Seen working in Studio Play at
  computer size on Nov 17, sounds not heard. Yours, at Galaxy A16 size: open the box, tap a kind
  you have several of, press the gold Sell (it shows the price): the picture should fly into your
  cash over the panel's top right, which chinks and counts up with rising ticks, landing with a
  jingle; the x5 goes to x4. Sell the rest quickly, then keep tapping where the card was: nothing
  else should be picked until you stop. Say: does a sale feel rewarding, is the price on the
  button welcome or clutter, can you hit Sell, Take and Shelf on a card that small. My defaults,
  yours to change: a find sells for its catalog worth; no "are you sure" (a Secret sells on one
  tap too: say if the rarest should ask first).
- [ ] **Take a find out of your job box** (S5-03c2b2, D-293, D-295). Seen working in Studio Play
  at computer size on Nov 17, sounds not heard. Yours, at Galaxy A16 size: open the box, tap a card
  (it lifts and glows), press Take: it should fly into one of the three round hands over the
  panel's corner with its pick-up sound, the x2 dropping to none. Take two more, then press Take
  again with your hands full (the hands shake). Tap another card and press Shelf: it flies up and
  the shelf tinks. Close the box: the find is in your hand. Say: does the flight feel quick and
  sure, can you tap Take and Shelf on a card that small, and do the three hands read as yours. My
  defaults, yours to change: the panel now lists only what's in the box (not what's on the shelf
  or in your hands); a find taken out stays yours and is never kept again at a gate (taking it up
  for real, with the risk, is S5-03d); when you leave, every find out of your box goes back in it,
  even one a friend is holding.
- [ ] **If Studio stops getting changes, click Connect** in Studio's Rojo plugin (connected Nov 13
  at 23:30; each session checks it first and says so in HANDOFF.md).
- [ ] **Playing on your phone** (D-109): with Rojo connected, use File > Publish to Roblox (Save
  alone doesn't change what live servers run), then play it from the Creator Hub on the phone.
  You load in at the lobby, facing its six cars; step into one and its count takes you to floor 1
  of a fresh climb, on a server of your group's own (L-08e1c); Again brings you back to your car
  there (L-08e2). The test hall is Studio only now
  (L-08e1b1). Still the baseplate? Shut its servers down from the Creator Hub and join again, and
  check its supported devices include Phone.
- [ ] **Once: restart `rojo serve`** (stop it, run it again, click Connect), then save: L-08e1c
  added a top-level folder (ReplicatedFirst's `TripCover`, which keeps the black up as you
  arrive on your group's server) and a running `rojo serve` only reads those at start. Without
  it the trip works, but the front office may flash for a moment as you arrive.

- [ ] **Set public servers to 12 players** (the home, D-259): each player on a lobby server gets
  one of the ground floor's 12 units. In the Creator Hub, open the place's settings and set its
  maximum players to 12. Nothing in the repo sets it.
- [ ] **Decide (defaults in, the home, D-259; change any in the home doc or here):**
  1. An XL unit is 20 by 30 studs (large is 16 by 20).
  2. Shelf spots for finds on show: 6 small, 10 medium, 16 large, 24 XL. The shelf (D-284) is
     oak with a cream back, not the plan's steel (D-263's calm), and stands behind the rug facing
     the door, so it's the first thing you see as your door goes up; the small unit's back
     partition (S5-03h) goes right behind it. A find too big for its cubby is shrunk to fit,
     a long one lying deep is turned a quarter to stand bigger (D-285); a small one is never grown.
     A new find answers when you come within 7 studs of it, and finds on the shelf never light.
     The job box (D-287) is powder-coated dusty blue on oak runners, against the left wall beside
     the shelf, facing the room; its lid opens to 88 degrees and shuts when you walk 14 studs off.
  3. Things you can set out with Arrange: 25 small, 50 medium, 100 large, 150 XL, so a full
     unit runs smoothly on a low-end phone.
  4. Four lamps in a unit cast real light; any more just glow.
  5. Only a unit's owner works its light switch (D-263); visitors see it as it is.
  6. Every unit starts with a rug, a beanbag and a floor lamp (D-263), as Animal Crossing's
     first tent comes furnished. My picks (D-266): a clay door in an oak casing, cream pots, a
     mustard beanbag, and no padlock on home doors. Look at `art/sheets/lobby-home.png`.
  7. The ground floor is 156 studs deep (the front office was 48), so a new player runs about
     9 seconds from loading in to the cars, past all 12 units.
  8. Each unit's door is the climb's 8-wide door, in a unit 20 wide. A 12-wide door would show
     more of each unit from the floor, but that door's paint still stretches (D-260).
  9. The ground floor's colours (D-264): sage walls below a wood rail, warm cream above, a soft
     white ceiling on wood beams, oak plank floors, a deep red runner down the middle to the
     cars. Look at `art/sheets/lobby-spawn.png`, `lobby-unit.png` and `lobby-inside.png`.
  10. A home's light starts on, and anyone may flip its switch until homes have owners (D-268).
  11. Where a find goes when you set it out (D-308, `src/shared/Home/Spots.luau`): the neon
      sign and the singing fish hang on a wall, the disco ball from the ceiling; the RC car and
      the skates stand on the floor only; everything else goes on the floor or on a top (the
      shelf, the job box, the portable TV, the toy drum). Until homes come in sizes (S5-03h)
      everyone arranges the whole room they see, up to the small unit's 25 finds.
  11. The ground floor's phone budget (D-271): the climb's 6 real lights can't hold with every
      home lit, so the floor keeps 31 (33 in a home), 7 of them shadowed (the 6 cars' lamps and
      the porch). Its busiest view, the spawn's, is 145k triangles against a climb floor's 61k
      to 112k; the cars' 51k is the next cut (S5-03a2d). Say if a phone of yours stutters there.
  12. Arranging (D-311): a find you drag stays lifted where you let go, green or red, until you
      press Place (or Turn, Put away, ×), rather than setting down the moment you let go, so a
      phone can turn it first. The camera sits high in the corner by the door and doesn't move.
      While a find is lifted the tray slides away and Place, Turn, Put away and × gather in the
      bottom right corner (D-312). On a real phone: is a find at the far wall big enough to
      drag, and do you want it to ride above your thumb rather than under it? Set something on
      the portable TV or the toy drum, then move that: the find on top should jump with it (my
      test save has neither, so I couldn't watch it).
- [ ] **Walk into your home** (S5-03a2b3 and b4, D-268; seen in Studio Play by me, the switch
  pressed with T and with a tap on the A16 simulator, but I couldn't take a single picture, so
  how it looks is yours). Press Play, or publish and play on a phone (Galaxy A16):
  1. From the spawn: does the floor read calm and warm, a plant by every door, benches between,
     two planters in the middle, the cars' steel only at the far end?
  2. Open a unit: is the round lamp on over a rug, a beanbag and a floor lamp? Sit on a bench,
     a planter's rim and the beanbag: do you sit facing the right way?
  3. Inside by the door, look at the switch (its button shows only while it's on screen) and
     press Switch (T, or tap): a click, the rocker rocks, the light eases off. Pull the door
     down with it off: is it dark? Is the switch easy to find when you turn round to leave?
  4. On a phone, walk from the spawn down past the homes to a car (D-271): does it stay smooth?
     With a few doors up, does a floor lamp's warm pool ease in as you come near and out as you
     go, never popping? Does any home look dark from the lobby? Look up at your own door from
     inside: the drum and its head plates over the doorway should be there.
- [ ] **Walk the new ground floor** (S5-03a2a, D-262; seen in Studio Play by me, not on a
  phone). Press Play in Studio (or publish and play on your phone, Galaxy A16 or similar):
  1. You load in just inside the glass door, facing the six cars 150 studs away, twelve roll-up
     doors down the side walls. Is the hall lit all the way, or too bright and flat for night?
  2. Walk to a unit and press Open: the door rolls up, the bulb inside clicks and stutters on,
     and warm light spills out of the doorway. Open a few more and walk back to the door: do
     the open units read as warm doorways from where you loaded in?
  3. On the phone: does it run smoothly with several units open? (Every open unit's bulb is a
     real light here, unlike on a climb.) Then step into a car: it still takes you up.

- [ ] **Hug the mega goo ball, with a friend** (S3b, D-310; seen in Studio Play by me, no
  picture: Studio's captures timed out). Studio's Test tab, 2 players; on the Server,
  `workspace:SetAttribute("GiveFind", "MegaGooBall")` puts it in player 1's hands. On player 1's
  phone-sized screen: the ball sits low in the middle, filling the bottom; pressing a slot or
  picking something up does nothing. Press Squeeze: the sides flatten, the goo heaves out and
  slowly comes back, a deep squelch. On player 2's screen: the ball is at player 1's chest, not in
  their belly or floating (my default: 1 stud ahead, half a stud below the chest's middle); their
  arms don't wrap it yet (ROADMAP polish). Say if the hold should sit higher or nearer.
- [ ] **Find the new finds** (F-G1a, D-203; seen in Studio Play by me on floor 1, not on a
  phone): play a climb and open doors. Floor 1 now deals the Nov 15 finds beside the bedroom
  four: glow sticks, night-lights, tea lights and toy cars often, a disco ball or lantern now
  and then, the glass lamp about 1 find in 200. Take one: does it sit right in your view and
  in your hand at phone size? (Each uses its size's hold for now, and borrowed sounds; ROADMAP
  polish.) The jack-in-the-box should be shut, the tea light unlit. Pressing one is the next item.
- [ ] **Decide (defaults in, F-G1b1, D-229; try them in the next item):** which finds have a
  press in the building, and how long each lasts.
  1. The Secret lamp is found lit and never goes out, so it has no press.
  2. The hard hat switches on in your hand for now; worn on your head comes with worn finds.
  3. How long each light lasts: tea light 60 s, oil lamp 150 s, lantern 90 s, hard hat 60 s,
     firefly jar 60 s, each lamp 60 s; the glow stick, fairy lights and disco ball never run
     down. A switch (lantern, hat, lamps, fairy lights, disco ball) keeps what's left when you
     switch it off.
- [ ] **Try (F-G1e5c, built Nov 17, D-294; seen in Studio Play by me, not on a phone):** the
  fairy lights laid along a hall.
  1. Play with `DevFloorNumber` 1; Server: `workspace:SetAttribute("GiveFind", "FairyLights")`.
     Press Switch: they light in your hand.
  2. Drop them in a dark hall, facing along it: the string should slither out ahead of you along
     the floor, a dotted line of warm lights. On a phone, does it read as fairy lights, not a row
     of sparks? Pick it up: it's the coil again, still lit.
  3. Drop them while running: the string should lie back down the hall behind you.
  4. Server: `workspace:SetAttribute("StandMannequin", true)` stands a Mannequin down the hall;
     slam a door by the lobby. Does it stop dead where it meets the line?
  5. **Decide (defaults in):** the string is 8 studs (the art's twenty lights); it holds a
     Mannequin 4 studs either side; it runs away from whoever dropped it.
- [ ] **Try (F-G1b3c1, built Nov 16, D-250; the desk lamp and neon sign checked in Studio Play,
  not on a phone):** the lamps switch on anywhere now.
  1. In Studio, set Workspace's `DevFloorNumber` to 1 and press Play. In the command bar (Server),
     run `workspace:SetAttribute("GiveFind", "DeskLamp")`: a **Switch** button shows.
  2. Press Switch: it clicks, the lamp's head nods, the bulb lights and a warm pool spreads in
     front of you. Press again: off. Again: on, with the rest of its minute.
  3. Leave it on: after a minute it fades out by itself and the button goes. Does the fade read
     as the lamp dying, or as someone switching it off? (A flicker of its own is ROADMAP polish.)
  4. Set `GiveFind` to "" and then each of "NightLight", "MoonLamp", "BlobLamp" (its blobs
     should flow once it's warmed up), "NeonSign" (it stutters on, then buzzes pink) and
     "StainedGlassLamp" (coloured patterns on the walls).
  5. Drop a lit one in the hall with the Mannequin coming (the lantern's steps below): it stops
     where the lamp's light reaches. The desk lamp's pool is small (about 4 studs); the
     night-light's barely reaches at all.
- [ ] **Try (F-G1b3c2c to F-G1b3c3, built Nov 16, D-254, D-256, D-257 and D-258; driven by
  script in Studio Play, not on a phone, not with a friend):** drive the RC car.
  1. In Studio press Play. In the command bar (Server), run
     `workspace:SetAttribute("GiveFind", "RCCar")`: a **Drive** button shows.
  2. Face down the test hall and press Drive: the transmitter clicks, the car is set down in front
     of you and your view swoops down onto its hood, low and wide. Is that drop quick enough, and
     is the hood view too low or too high (`Drive.HoodUp`)?
  3. Push forward: it leaps off with a whine rising in pitch, front wheels turning into a turn,
     and stops dead at a shut door with a jolt. Steer it round a corner. On the phone: does a
     thumb pushed left from rest pull it round (a little throttle is mixed in)? Is 18 studs a
     second too fast to steer between the unit doors?
  4. Press jump (or Back, top left): you're back in your own eyes and the car stays put. Walk to
     it with the transmitter in your hand: it's back in your hands with a clack.
  5. Drive it away down the hall, turn it round and look back: you're crouched on your heels,
     the transmitter up at your chest in both hands, its aerial past your bowed head, your torch
     pointed at the floor. Does the crouch read as "busy driving" from there? Keep driving to
     your feet: the view comes home and the car clacks back into your hands.
  6. With a friend (Studio's Test tab, Clients and Servers, 2 players, or a real server): stand
     by them while they drive. Do you see them settle into the crouch with a rustle, the
     transmitter held by its grip and wheel (not floating beside their hand), and stand back up
     when they press Back? Do you see the car drive smoothly, its wheels turning, and hear its
     whine? Is their torch held down, not raised to where their view is?
  7. Get caught while driving (drive near a sleeping Mannequin's unit and wake it, or use
     `ServerStorage.CatchTest` with one stood near you): your view should leave the car at once
     and the catch turns you from your own eyes to its face; the transmitter drops.
  8. The dark: drive out of a lit hall into a dark one. The view clicks (a small relay) and
     flickers over to grainy green, a lamp on the car lighting about 30 studs ahead. Have a
     friend walk under the light by the car (alone: Back, walk under it, Drive again within
     seven seconds): it clicks back to colour. Is the click too loud or too quiet, the grain
     too strong on a phone, the green too dark to steer by?
  9. Drive up to a Mannequin in the dark (Server: `workspace:SetAttribute("StandMannequin",
     true)` stands one asleep on the laid floor at (0, 0, -656), facing its lobby): two white
     points shine on its face, from about 40 studs, brightest close. Do they read as eyes
     looking back, and are they big enough on a phone far down a hall? Turn your torch on before
     you drive: it's out while you drive and lit again when you press Back. A friend standing
     by you sees no light on the car.
  10. The Packrat steals it: drive the car out by the lobby, then Server
     `workspace:SetAttribute("StandPackrat", true)` stands one in the unit nearest the lobby.
     Keep the car in its way: its pale hands close on it, your view lifts off the floor, tips
     and shakes, cuts to static with a hiss, and you're back in your own eyes. Does the lift
     read as being picked up, and is the static long enough to feel like the signal died
     (`Drive.LiftTime`, `Drive.TakenSnow`)? Follow it home and take the whole car back off its
     pile with Take.
  11. Let it reach you instead while you drive (stand in its way, the car parked away): it
     tears the transmitter from your hands and the car is gone from the floor with it. Does
     that read, or should the car be seen flying to its hands?
  12. Leave the car out when the gate shuts (drive it somewhere and walk to the elevator): no
     glint for it at the gate, and as the floor below goes the transmitter crackles dead in
     your hand. Is losing it fair, and does the crackle say why?
- [ ] **Decide (default in, F-G1b3c3):** an RC car whose car is still out when the gate shuts
  is lost: the car stays with the floor and the transmitter dies in your hand as the floor goes.
  Default: lost, so racing the car back to the elevator is a moment. Other ways: you keep the
  transmitter alone (worth little, a reminder), or the whole RC car is kept anyway.
- [ ] **Decide (default in, F-G1b3c2e):** does the RC car trip the motion lights as it drives
  under them, as you do? Default: no, it's too small and low for their sensors, so a dark hall
  stays dark and its view goes infrared. If yes, the car lights its own way down the halls and
  anyone near sees the lights trip, a giveaway to a friend and maybe a monster.
- [ ] **Try (F-G1b2, built Nov 16, D-231; each press checked in Studio Play, not on a phone, not
  with a friend):** press a find and watch it do what it is.
  1. In Studio, set Workspace's `DevFloorNumber` to 1 and press Play. In the command bar (Server),
     run `workspace:SetAttribute("GiveFind", "CampLantern")`: a lantern lands in your hand and a
     round **Switch** button shows (left click on a computer).
  2. Press Switch: it clicks, the lantern lights up and the hall around you brightens. Press
     again: it clicks off and goes dark. Again: back on, with its 90 seconds where you left them.
  3. Drop it (the wheel's Drop): it falls lit and stays lit on the floor; walk away and back.
  4. Set `GiveFind` to "" and then "JackInTheBox". Press **Wind**: the button goes, the crank
     turns to its music box for 9 seconds, then the lid bangs open and the clown springs out,
     and the button comes back. Listen: does the tune end where the bang comes? The bang is a
     borrowed tin clang for now (ROADMAP polish). Do it near a sleeping monster: it should
     come to look, as it does for the air horn.
  5. Press Wind again: the clown is pushed back in and the lid shuts first, then the winding.
  6. Do the same with "TeaLight" (a match strikes, the flame catches and flickers, and the button
     stays away until it gutters out after a minute), "OilLamp", "GlowSticks", "FairyLights",
     "HardHat", "FireflyJar" and "DiscoBall". The glow stick, jar and disco ball are silent for
     now (their snap, lid and hum are ROADMAP polish).
  7. With two players (Test > Clients and Servers, 2 players): one presses the lantern; the
     other should see it light in their hand and hear the click there.
  8. On a phone: is the button where your thumb wants it, and does the lit hall still run smooth
     with three or four lights lit near you? (Only the two nearest light the room; the rest glow.)
- [ ] **Try (F-G1b3a, built Nov 16, D-233; both seen in Studio Play, the monsters coming not
  watched, not on a phone):** wind the cymbal monkey and push the toy car.
  1. In Studio, set Workspace's `DevFloorNumber` to 1 and press Play. In the command bar (Server),
     run `workspace:SetAttribute("GiveFind", "CymbalMonkey")`: the monkey lands in your hand and
     a **Wind** button shows.
  2. Press Wind: its key turns with a winding sound, then it bashes its cymbals for about 21
     seconds, a clang on every clash, slowing and stalling at the end. Listen: does each clang
     land as the cymbals meet? Is the clang too big for a toy (it's a pitched-up crash cymbal)?
  3. Wind it near a sleeping monster, drop it in a unit and run: the monster should wake and
     keep coming back to the monkey for as long as it plays (it's heard every 2 seconds, as far
     as the air horn), then lose interest once it stalls. Press Wind again after it stalls: it
     winds from the start.
  4. Set `GiveFind` to "" and then "DiecastCar". Face down a hall and press **Push**: the car
     leaves your hand, sits on the floor just in front of you and rolls about 7 studs, wandering a
     little and slowing to a stop. Walk to it: Take is where it stopped.
  5. Pick it up, face a wall from 3 studs away and press Push: it should stop at the wall, not go
     through. (The roll's sound cuts off as it slows; a fade is ROADMAP polish.)
  6. With two players: both should see the car roll the same way and stop in the same place.
- [ ] **Try (F-G1e1, built Nov 17, D-267 and D-269; each squash measured in Studio Play, not
  watched on a phone):** squeeze the squishies and the rubber duck.
  1. In Studio, set Workspace's `DevFloorNumber` to 1 and press Play. In the command bar (Server),
     run `workspace:SetAttribute("GiveFind", "MochiBun")`: the bun lands in your hand and a
     **Squeeze** button shows.
  2. Press Squeeze: the bun squashes flat in your hand with a soft puff and slowly puffs back up;
     the button stays away until it has. Does the squash feel soft, and is it big enough to see
     at phone size?
  3. Do the same with "ButterStick" (a dent the size of a fingertip that slowly fills back in),
     "JumboStrawberry" (its dent takes about ten seconds to rise), "StressBall" (it squashes and
     its eyes bulge), "ToastSlice", "PaperSquishy", "Capybara", "GelBeadBall",
     "GlitterGooBall", "GalaxyGooBall" and "RubberDuck" (a squeak that wakes a monster down the
     hall). Each squashes about the middle of where your hand holds it.
  4. With two players: one squeezes; the other should see it squash in their friend's hand.
- [ ] **Try (F-G1e2a, built Nov 17, D-270; see WAVES.md's table for what Studio Play showed, not
  watched on a phone):** wind the chattering teeth and let them draw a monster away.
  1. In Studio, set Workspace's `DevFloorNumber` to 1 and press Play. In the command bar (Server),
     run `workspace:SetAttribute("StandMannequin", true)` (a Mannequin asleep down the hall past
     the lobby), then `workspace:SetAttribute("GiveFind", "ChatteringTeeth")`.
  2. Face down a hall and press **Wind**: the teeth sit on the floor in front of you, the key
     turns with a ratchet, then they chatter off for about ten seconds, a clack each snap,
     waddling and veering a little. Do the clacks keep time with the jaw, and can you hear them
     at phone volume?
  3. Wake the Mannequin, then wind the teeth again and run the other way: it should turn toward
     the clatter, following the teeth as they go, not you. Is 90 studs (round a corner or two,
     under the cymbals) the right reach, or should they carry further or less?
  4. Face a wall from 2 studs and wind them: they walk into it and keep chattering against it,
     staying put, until they run down.
- [ ] **Try (F-G1e2b, built Nov 17, D-272; seen in Studio Play, not on a phone):** the robot,
  mouse, tin bird and carousel. Same setup as the teeth above, `GiveFind` each in turn.
  1. Wind the **robot** facing down the hall: it sets off with a clank each footfall, slowing
     over 15 seconds. Does a clank land on every step?
  2. Wind the **mouse** 5 studs from a wall: it zips into the wall, its wheels buzzing on there,
     and squeaks twice where its run stalls ("eek-eek" as it rocks onto its nose). One squeak or
     two? Its whirr as it runs is silent today: should it have one?
  3. Wind the **tin bird**: three little hops, then two whistled notes, five times. Do the notes
     sound like a tin bird's bellows, not a referee's whistle?
  4. Wind the **carousel** and set it down: it turns and plays its music box tune for 15
     seconds. Since Nov 17 (V5f, D-288) the tune slows with the top over its last six seconds,
     its notes held at their pitch, and dies away as it stops. I could only measure it, not
     hear it: does the slowing tune sound like a real box running down, not warbly or smeared?
     If it does, the fix is lowering `Use.SlowHeld` or cutting the tune into notes. Loudness defaults
     chosen: the robot and bird carry 90 studs (as the teeth), the mouse and carousel 60 (down
     the hall, as the duck). Right?
- [ ] **Try (F-G1e5a, built Nov 17, D-286; seen in Studio Play Nov 17, V5a, not on a phone):**
  the **boombox** and the **teddy**. `GiveFind` each, then press.
  1. Press **Play** on the boombox: its key clacks, then 80s electro (APM's "Electroboogie")
     plays for 15 seconds, the case swelling on each beat and swaying from its handle; a monster
     across the floor comes to it. Drop it mid-song and walk off: the music plays on where it
     lies and the monster goes to it, not you. Then the stop key clacks. Is this the song (an
     80s boombox, not a club)? Is the thump big enough to read at phone size? My defaults, say
     which to change: 15 seconds a press (the monkey's 20 stays the longest); as loud as the air
     horn (130 studs), every 2 seconds; no stopping it mid-song.
  2. **Hug** the teddy: it squashes in your hand, gives a tiny muffled squeak and wiggles back.
     Is the squeak small enough for a teddy (the duck's, higher and quiet)? No monster hears it.
- [ ] **Try (F-G1e4, built Nov 17, D-281; seen in Studio Play Nov 17, V4b, not on a phone):**
  the **siren car**, on a phone, in a dark hall. `GiveFind` it, face down the hall,
  press Push: it's set down, pushed twice, and rolls off wailing, its red roof light turning and
  sweeping the walls; a monster across the floor comes after it. Push it at a wall: its wheels
  spin on there and it wails until it runs down, then its light goes out. Does the wail sound
  like a toy siren (a small whooper, played a little low so it lasts the roll; it fades out
  while the car crawls its last stud or two)? Does the red sweep read on the walls at phone
  size? Loudness default: 90 studs, as the robot. Right?
- [ ] **Try (F-G1e3a, built Nov 17, D-274; seen in Studio Play, not on a phone):** the kazoo and
  the toy drum. Same setup, `GiveFind` each, then press.
  1. Blow the **kazoo**: one buzzy note once it's at your lips, about a second. Does it sound
     like a kazoo, not a trumpet? (It's the last note of a kazoo fanfare, played a little low.)
     Since Nov 17 (V3c, D-278) it tips up about 7 degrees in your hand as it hums: with a friend,
     does it tip in their hand too, and is the tip enough to read as "to the lips" on a phone?
     (Your arm doesn't move; a bigger lift is an art change.)
  2. Bang the **drum**: left, right, left, right, then both sticks, a bang each. Does the double
     sound louder? (One recording for all five today.)
  3. Loudness defaults chosen: the kazoo carries 60 studs (down the hall, as the duck), the drum
     130 (as the air horn: the catalog says "loud"). Right?
- [ ] **Try (F-G1e3b, built Nov 17, D-276; seen in Studio Play, not on a phone):** the farm
  spinner, the cowboy doll and the singing fish. Same setup, `GiveFind` each, then press.
  1. Pull the **spinner**: the lever clacks back, the arrow spins, ticks into three notches and
     a cat meows. It always lands on the cat for now; does the pull still feel worth doing?
     (Since F-G1e3d it lands on a new animal each pull: the next item.)
- [ ] **Listen (F-G1e3d, built Nov 17, D-279; seen in Studio Play, not judged by ear):** the farm
  spinner landing on any animal. `GiveFind` "FarmSpinner", then pull it ten times or so.
  1. Each pull lands on a different animal from the last (cow, pig, sheep, horse, duck, cat,
     rooster, dog) and that animal calls as the arrow stops. Do you laugh at which one it is?
  2. The seven new calls were picked and leveled by measurement, not by ear (`art/finds/kit/
     game.py`: COW to DOG). Are they clean, about as loud as the cat, and short enough? The
     rooster's recording is quiet and plays near full volume: listen for hiss.
  2. Pull the **doll**: its cord whirs home under the governor and clacks in (its voice waits on
     the talking finds' question below). Does the whirr read as a pull-string toy?
  3. Press the **fish**: a click, its motors hum, the head swings out and back with two knocks.
  4. All three carry 60 studs (down the hall, as the kazoo). Right?
- [ ] **Try (F-G1b3b, built Nov 16, D-234; seen in Studio Play, not on a phone):** drop a lit
  lantern to stop the Mannequin.
  1. In Studio, set Workspace's `DevFloorNumber` to 1 and press Play. In the command bar (Server),
     run `workspace:SetAttribute("StandMannequin", true)`: a Mannequin stands asleep in the hall
     about 60 studs past the lobby's far side, facing the lobby (`Stand one` on the lobby's post
     does the same).
  2. Run `workspace:SetAttribute("GiveFind", "CampLantern")` and press **Switch**: it lights.
  3. Walk down the hall toward the Mannequin until it's about 15 studs ahead of you, then drop
     the lantern at your feet (the drop key). The clank wakes it and it comes at you: it should
     stop dead about 10 studs from the lantern, mid-stride, lit by it, and stay there.
  4. Walk away out of sight and come back: it's still standing where the lantern holds it.
     Does it look lit where it stopped, or does it seem to stop in the dark? (If it's dark, its
     reach is `Use.LightShare` in `src/shared/Finds/Use.luau`: lower it.)
  5. After 90 seconds the lantern runs down and goes out: the Mannequin walks on at once.
  6. Again with the lantern inside an open unit and the Mannequin out in the hall: pull the door
     down and the Mannequin should walk (the door shades the light); lift it and it stops again.
  7. Try a tea light (`GiveFind` "TeaLight", **Light**): it holds it only about 7 studs off, for a
     minute.
- [ ] **Decide (default in, F-G1b3b):** a lit lantern or tea light in your hand doesn't stop the
  Mannequin; only one lying on the floor does (the catalog says found lights hold it, and the
  moment is dropping it behind you). Holding one lit, it walks right up to you through its light.
  Should a lit find you carry hold it too, like your torch does? Say so and it's a small change.
- [ ] **Decide (defaults in, F-G1a):** the Secret lamp's name on screen is "Old lamp" (the
  catalog calls it "A lamp that's on when you find it"); the RC car carries with its
  transmitter beside it as one find; the theatre spotlight isn't dealt until floors have big
  finds. Say if any should change.

- [ ] **Decide (defaults in, the box you open, D-205):** say if any should change.
  1. The "something inside" cue: a faint warm line of light along the box's tape and a soft
     sound when you're close, as Fortnite's chests glow and hum.
  2. A note dropped in the car stays beside the keypad for that floor, for anyone to read.
  3. Caught holding a note, it drops where you were caught, so a friend can fetch it.
  4. One marked box a unit at most.

- [ ] **Buy the test purchase for real** (S3-02b, D-207; made-up receipts seen in Studio Play,
  never a real one). This spends real Robux: three purchases at the price you pick. Use the
  Roblox app on your computer, since the server's command line needs a keyboard.
  1. Creator Hub > Creations > this experience > Monetization > Developer Products: make one
     named exactly `Test purchase`, at the lowest price it allows.
  2. In Studio, with Rojo connected, File > Publish to Roblox.
  3. Play the published place. Press F9, pick Server, and find the line `[Purchasing] products:
     testPurchase <number>`: the number should be the product's ID on the Dashboard. If it says
     "not on Roblox", the name in step 1 doesn't match exactly.
  4. In the Server command line, type `workspace:SetAttribute("DevPrompt", "testPurchase")` and
     press Enter. Roblox's purchase box should show "Test purchase" at your price. Buy it. The
     Server log should say `[Purchasing] granted testPurchase to <you> (bought 1)`.
  5. Type `workspace:SetAttribute("DevSaveFails", true)`, then the DevPrompt line again, and
     buy. The log should warn `not written: DevSaveFails is on`, with no "granted" line.
  6. Leave the game at once, wait two minutes, and play again (a new server). Within a few
     seconds of loading, the Server log should say `granted testPurchase to <you> (bought 2)`,
     once: the purchase whose save failed, granted on the next server.
  7. Leave, and play once more: no new "granted" line.
  8. Creator Hub > this experience > Configs: add `sellTestPurchase`, a boolean, false, and
     publish it. Wait a minute in a game, then send the DevPrompt line: no purchase box, and
     the log says `'testPurchase' is switched off`. Set it back to true and publish.
  9. Tell the next session it passed (or what didn't), so Brix's ENG-23e is marked done in its
     HANDOFF.

- [ ] **Make the Cut Free product, pick its price, and buy your way out** (S3-03a1 and a2, D-220,
  D-221; in Studio Play Claude was freed by F with a spare from the save and by a click with no
  product, the door up and the walk out; a real purchase, a phone and the watch bar never tried).
  The GDD prices revives at 40 to 55 Robux.
  1. Creator Hub > this experience > Monetization > Developer Products: make one named exactly
     `Cut Free`, at your price (default if you don't decide: 45 Robux).
  2. Publish, play, and in the Server log (F9) look for `[Purchasing] products: cutFree <number>`.
  3. In Studio first, to feel it: Test > Clients and Servers, 2 players, Start (with a friend
     still free, one catch doesn't end the climb). In the Server window, View > Command Bar, run
     `workspace:SetAttribute("WakeSleepers", true)` so sleeping monsters wake now. With Player1,
     find one and get caught.
  4. Look for: in the dark of the unit, Bang comes up, then a beat later a smaller warm "Cut
     Free" pill to its left, with F under it on the same line as Bang's "Click". No price, no
     other words.
  5. Press F: a soft click and the pill dips; in Studio (no purchase there) the film rips off you
     at once, the door hauls itself up, and both buttons fade together. Walk out. Does the
     moment feel like a way out, not an ad?
  6. On your phone, playing the published game with a friend: get caught. The pill sits left of
     Bang, a thumb's width clear; hammer Bang with your right thumb and check you never hit Cut
     Free by accident.
  7. Tap Cut Free: Roblox's purchase box with your price. Cancel it: nothing happens, and the
     pill can be tapped again after a second and a half. Tap again and buy: the box closes, the
     film rips, the door hauls up, you walk out. Server log: `[CutFrees] <you> cut free`.
  8. Get left behind (the car leaves without you): above the WATCHING bar is the same warm pill.
     Buy it: you're standing in the car beside your friends as it reaches the next floor.
  9. With a gamepad: Y presses Cut Free, A still bangs.

- [ ] **Make the Free a Friend product and free a friend from across the floor** (S3-03b,
  D-222; in Studio Play Claude saw the pill drawn with a face and a purchase with no friend named
  kept as a spare; freeing a real second player has never been tried). Two choices are yours:
  (a) the GDD's table says Free a Friend shows on the caught screen, but its own line says you
  free a friend "from wherever you are standing", so it was built for the free player, under the
  corner map; say if you meant the caught screen. (b) A purchase that lands after your friend is
  already out stays with you as a spare Free a Friend, used by your next press with no box (the
  ticket's default was a spare Cut Free instead).
  1. Creator Hub > this experience > Monetization > Developer Products: make one named exactly
     `Free a Friend`, at your price (the GDD says 49 Robux).
  2. In Studio: Test > Clients and Servers, 2 players, Start. In the Server window's Command Bar,
     run `workspace:SetAttribute("WakeSleepers", true)`. Get Player2 caught; keep Player1 free.
  3. On Player1, under the corner map: a beat after the catch, a warm pill eases in from the
     right with Player2's face and "Free". No price. Nothing on Player2's screen changes.
  4. Player1: Left Alt, click the pill. A soft click, the pill springs and dims. In Studio (no
     purchase there) Player2's film rips at once and their door hauls up; on Player1's screen a
     faint rip, and the pill swells and fades. Server log: `[CutFrees] Player1 freed Player2`.
  5. Get two players caught with a third free (3 players): two pills, the first caught on top.
  6. A gamepad on Player1: a small "Y" sits left of the top pill; Y presses it.
  7. Published, with a friend, on your phone: get your friend caught, tap Free, buy. Their film
     rips and their door goes up. Then get them caught again, tap Free, and before you buy, have
     a third friend cut them free by hand; now buy. The log says your Free a Friend waits in your
     save; get them caught again and tap Free: no purchase box, they're freed at once.

- [ ] **Make the Free Everyone product and get the whole team caught** (S3-03c, D-223; in
  Studio Play Claude saw the results wait 12 s on a stand-in catch and a late purchase kept as a
  spare; the pill's swap and everyone freed by one press have never been seen). Two choices are
  yours: (a) playing alone, the pill stays Cut Free while the end waits (it frees you, the whole
  team; a dearer button for the same thing would be a trick); say if solo should see Free
  Everyone. (b) The wait is 12 s from the last catch (`ClimbEnd.OfferFor`), longer while a
  purchase box is open; say if it feels long or short.
  1. Creator Hub > this experience > Monetization > Developer Products: make one named exactly
     `Free Everyone`, at your price (the GDD says 149 Robux).
  2. In Studio, alone: Play, walk floor 3 with `workspace:SetAttribute("WakeSleepers", true)` in
     the server's Command Bar, and get caught. Before: the results came on the catch's black.
     Now: you wake in the unit with Bang and the warm Cut Free pill, and the results only come
     down about 8 s after the pill is up. Don't press: they come down as before.
  3. Again, and this time press Cut Free (F) while you wait: the film rips, the door goes up, the
     climb carries on. Log: `ClimbEnds: freed before the results; the climb carries on`.
  4. Test > Clients and Servers, 2 players. Get Player1 caught, then Player2. On both screens,
     as the second catch lands, the pill grows wider into "Free Everyone" with a low click and a
     small swell (Player2 sees it already reading Free Everyone as their pill comes in).
  5. Player1 presses it (F, or Left Alt and click). In Studio both films rip at once, both doors
     go up, and nobody sees the results. Log: `[CutFrees] Player1 freed everyone (2; ...)`.
  6. Get both caught again and press nothing: the results come down about 12 s after the catch.
  7. Leave one of them free and caught on the watch bar (left behind): its pill swaps the same.
  8. Published, with a friend, on your phone: both caught, tap Free Everyone, buy: both freed.
     Again, tap it and cancel the box: the results come down shortly after. Again, tap it and
     take your time in the box (20 s), then buy: the results wait for you, both freed.

- [ ] **Make the six wrap colour products and get caught in one** (S3-04a, D-224; in Studio
  Play Claude saw a made-up Blue purchase owned, worn at once and refused a second time, and all
  six colours on stand-in films; a real catch in a colour has never been seen).
  1. **Decide (defaults in):** the six are Blue, Red, Green, Pink, Orange and Black, at 99, 99,
     99, 149, 149 and 199 Robux (the GDD says 99 to 499; patterns would fill the top later). A
     colour bought is put on at once. Say if any name, colour or price should change.
  2. Creator Hub > this experience > Monetization > Developer Products: make six, named exactly
     `Blue Wrap`, `Red Wrap`, `Green Wrap`, `Pink Wrap`, `Orange Wrap`, `Black Wrap`, at your
     prices.
  3. In Studio, Test > Clients and Servers, 2 players. In the server's Command Bar:
     `game.ServerStorage.DevReceipt:Invoke({ offer = "wrapRed" })` (it answers PurchaseGranted
     and gives Player1 Red). Then `workspace:SetAttribute("WakeSleepers", true)` and get
     Player1 caught on floor 3.
  4. As Player2, watch the catch if you can: the film winding round Player1 is red. Then find
     Player1's unit and lift the door: they stand wrapped in red film, their body showing
     through. Hold Cut free: the shreds that fly are red too.
  5. Back in the server's Command Bar: `game.ServerStorage.DevReceipt:Invoke({ offer =
     "wrapBlack" })`, and get Player1 caught again: now the film is a smoky black. Look at it
     in a dark unit with the flashlight: can you still tell it's a person in film?
  6. Published, on your phone: in the Developer Console's server command line,
     `workspace:SetAttribute("DevPrompt", "wrapBlue")`. The real purchase box comes up; buy it.
     Get caught with a friend: they find you in blue. Run the same line again: no box this time
     (the log says you already own it).

- [ ] **Try the counter's shop on your phone** (S3-04b, D-225; in Studio Play Claude opened it
  from the top bar's Shop button, saw seven cards each showing the player in that film, Wear on
  the plain film and a Studio buy of Red flip the cards; not seen: phone size, a real price, the
  snap's sound, the counter's prompt pressed by hand). Needs the six products above made first.
  1. **Decide (default in):** the roadmap said the shop opens "from Roblox's own" too; nobody
     wrote down what that meant. Claude took it as a Shop button in Roblox's own top-bar row, at
     its left end, only in the lobby. Say if you meant something else.
  2. Published, on your phone, in the lobby: walk up to the counter (on your left as you come in
     the door). A Shop button shows in front of it. Tap it: the shop slides up from the bottom
     and seven cards deal out left to right, each one you, slowly turning, in a film: clear,
     then Blue, Red, Green, Pink, Orange, Black. Swipe the row: it scrolls sideways.
  3. Look at the buttons: colours you don't own show the Robux price in a warm pill (it may say
     just "Buy" for a second before the price arrives); the one you wear says Worn, others you
     own say Wear.
  4. Buy one: Roblox's box comes up. Buy it: that card's film snaps tight round you with a short
     high squeal, its rim flashes and it says Worn; the card you wore before now says Wear.
  5. Tap Wear on Plain: it says Worn, the colour says Wear. Get caught on the next climb: the film
     is clear.
  6. Close it with the X or a tap above it; open it again from the Shop button at the top left
     of the screen (it shows only in the lobby). Walk out through a car: it shuts by itself.

- [ ] **Climb past floor 3 with a friend** (S4-01a, D-226; in Studio Play Claude rode alone from
  floor 3 to floor 4, and started floors 5 and 101 straight away: each laid and dealt with no
  warnings. Not seen: two players, a long climb, a phone). Floor 3 used to be the top, where the
  ride ended in the light ("Made it"). Now every floor leads to the next.
  1. Published, with a friend: ride up from a lobby car and play floors 1 and 2 as usual.
  2. Punch floor 3's code and ride up together. The ride should go on as any ride does and open
     on floor 4, its units numbered 401 and up. No light, no "Made it".
  3. Keep climbing to floor 6 or 7. What to look for: from floor 3 every floor is full size with
     four notes; from floor 5 up to three monsters can be loose at once (two before); from floor 6
     one note is always behind a padlock, so you need bolt cutters or a saw through the side. Each
     gate pays 2 coins more than the floor before. Packed units get a little more common each floor.
  4. Let both of you get caught. "Caught" should show the floor you reached, two digits fitting
     if you made it past 9.
  5. In Studio you can start on any floor: set Workspace's `DevFloorNumber` (no longer capped at
     10) and walk through "Walk a floor".
  6. **Decide (default in):** "Made it" has nothing to trigger it now. Its screen and code are
     kept, unused, in case you want a way out later (say, cashing out between floors). Say if
     you'd rather it went.
  7. Tell the next session whether floor 4 felt any harder than floor 3. Floors 3 and 4 still
     play the same: the climb now changes on floors 5, 6, 8, 10, 12, 15, 20 and 25 (the next item).

- [ ] **Feel each floor get harder as you climb** (S4-01b, D-228; in Studio Play Claude laid floors
  8, 11 and 25 for real and rode from 11 up to 12; floors 3, 10, 12, 15, 20, 25 and 60 were laid
  from the server to time them. Not seen: anyone playing them, two players, a phone). The floor
  rules now step up eight times and then hold. Start on a step's first floor with Workspace's
  `DevFloorNumber`, in Studio or published with a friend, and play it to the gate.
  1. **Floor 8, "More doors":** about 50 doors instead of 40 on the same halls. Look for: the
     code takes longer to piece together, fewer long blank walls, and one note still behind a
     padlock.
  2. **Floor 10, "Four loose":** up to four monsters out at once (three before). Look for: a hall
     is rarely empty for long; while you hide from one you hear another.
  3. **Floor 12, "Big floors":** a wider building, two more columns of halls and a third loop,
     about 60 doors. Look for: the far wing feels a long way from the elevator, and the sprint for
     the gate is longer. On a phone, watch the frame rate as you walk the far halls (about half as
     many parts again as a floor 3).
  4. **Floor 15, "Two notes behind padlocks":** two of the four notes are always behind padlocks
     (about 11 padlocked doors in all). Look for: one pair of bolt cutters isn't enough; the team
     needs cutters twice, or cutters and a saw through the side.
  5. **Floor 20, "More doors still":** about 70 doors on the big floor. Look for: doors down every
     hall, nowhere to stand that isn't next to one.
  6. **Floor 25, "Five loose":** up to five monsters out at once, the most a phone carries with
     one more pounding behind a door. From here the floors stop getting harder; only the pay and
     the finds keep rising.
  7. Tell the next session whether any step lands too early, too late or too hard. Each step's
     floor and number is one line in `src/shared/FloorRules.luau`.
  8. **Decide (default in):** the notes stay at four from floor 3 up and never drop. The ticket
     said "fewer notes", but fewer notes make the code quicker to find (one note turns up sooner
     than the last of four), and the GDD's "Codes" says four above the teaching floors. The code
     gets harder instead with more doors to search and a second padlocked note. Say if you want
     fewer notes on high floors anyway (it would need more doors to make up for it).
  9. **Decide (default in):** the climb stops getting harder at floor 25 and holds there. Say if you
     want it to keep climbing longer, or level off sooner.

- [ ] **Clear Studio's doubled modules** (found Nov 15): `ServerScriptService.Server` and
  `ReplicatedStorage.Shared` hold two copies of each module made in recent sessions (Purchasing,
  Products, WrapColours, Wearing, FloorRules and more), as if Rojo were connected twice. Disconnect Rojo,
  delete both copies of each doubled module, click Connect once: Rojo puts one back of each.

- [ ] **Look at the packed unit's stacks** (B-05a, D-215; judged by Claude in renders, imported
  into Studio, not yet laid on any floor). The blocks a packed unit's walls will be built from are
  in the place at `ReplicatedStorage.Props.Packed` (seven MeshParts, put there by hand this
  session). B-05b lays them; its own steps will follow here.
  1. Open `art/sheets/packed-door.png`: a medium unit packed to the ceiling from its doorway, one
     dark path through. Does it say "something's in there" and "I'd have to squeeze in"?
  2. Open `packed-path.png` (in the path, the torch on the right-hand wall) and
     `packed-clearing.png` (round the bend at the back, the marked box waiting). Tell the next
     session if any box looks wrong up close, or if the walls feel too tidy or too messy.
- [ ] **Walk a packed unit** (B-05b2, D-217, D-218, D-219). Seen in Play by Claude: the stacks,
  the path, and a Mannequin walking out by the bend. Not seen: the box's new corner (Studio stopped
  drawing), the sleeper's new spot round the bend with its box behind it, the phone camera, the
  saw.
  1. In Studio, set Workspace's `DevFloorSeed` to 2000013 and `DevFloorNumber` to 3, then Play.
     Output says "Deals: packed with boxes on floor 3: Unit302, Unit303, ..." (eight units).
  2. Lift Unit302. Look for: a
     wall of boxes nearly to the ceiling, one dark path 3 studs wide up the middle, and at the
     foot of the back wall, bottom right, a hand's width of the marked box poking out from behind
     the last stack. Output: "Unit302 held a find, the FairyLights in its box ... round the bend
     to your right".
  3. Set Studio's device to a small phone sideways and walk the path: the stacks close round
     you. Look for the camera clipping into boxes as you turn right into the clearing, and open
     the box there.
  4. Lift Unit316 (Output: "held the Mannequin, asleep"). From the doorway you see nothing of it:
     look for any shoulder or hand poking past the last stack. Walk to the bend: it stands just
     round the corner to the right, side-on, facing you. If the unit holds a box (the code's note
     or coins), the box stands behind it at the far end; reach past the Mannequin and Open it.
     Back at the doorway, blow an air horn: it turns out to the bend and comes straight down the
     path's middle at you, never through its box.
  5. Saw a crawl hole into a packed unit from the unit beside it: there is no Crawl button, and
     the hole shows boxes.
- [ ] **Decide (defaults in, B-05b1, D-216, D-217): packed units.**
  1. A saw into a packed unit. Built as my default: the hole opens onto boxes and has no Crawl
     button either side. The other choice is that the stacks in the hole's way tumble down to
     let you through. Say if you want that instead.
  2. A packed unit that rolled nothing at all gets 1 coin in its box, so the walk to the back
     never ends empty-handed. Say if it should be more coins, or a find (that would add about one
     find for every seven medium units).

- [ ] **Judge the marked box** (B-01a, B-01b, D-208; judged at phone size by Claude, in renders
  and in Studio). The box a unit's find, coins, tool or note will come in. It is in the place now:
  its template is the Model `ReplicatedStorage.Props.Boxes.Marked` (eight parts), beside the five
  scenery boxes, which were replaced from the same upload (they share the new texture). No unit
  has one yet: B-03 puts them there. Studio's own capture of the cue at both graphics levels, at
  phone size, is `docs/art/B-01b-cue-level01-21.jpg` (low graphics left, full right).
  1. Open `art/sheets/boxes-marked-unit.png` beside `boxes-marked-unit-cue.png`: the same unit
     from the doorway, the box plain, then with its "something inside" cue lit (two faint warm
     lines along the tape). Say whether the cue is enough in the hall's light, or too much.
  2. Open `boxes-marked-dark-cue.png` (in a torch's beam): the lines should catch your eye.
  3. Open `boxes-marked-open-strip.png` (ten frames, read left to right, top row first) or play
     `art/boxes/out/marked-open.mp4`: the tape snaps in the middle and whips back, the long flaps
     burst up past upright, the end flaps a beat behind. Say if it should be slower or punchier.
  4. Decide my defaults (say which to change): the tape snaps across the middle rather than
     splitting along the seam; the cue is warm lines at the tape's edges plus a soft hum up close.
- [ ] **Open a marked box with a friend: the reveal** (B-02a, B-02b, D-209, D-210; one player
  seen in Studio Play by me, a Rare all the way into the hand and a Legendary's held breath
  captured, never two players, never on a phone). Studio deals the next unit you open the find
  you name, in a box even when it's too big for one, so every grade can be seen.
  1. In Studio, Test tab > Clients and Servers: Local Server, 2 players, Start.
  2. In the Server window's command bar, type `workspace:SetAttribute("DevBox", "NightLight")`,
     Enter (a Common). The next door anyone opens has one box with two thin warm lines along its
     tape; type the line again for another box.
  3. Both players: take "Walk a floor" by the spawn. Player 1 opens any unit's door; player 2
     stands in the hall about 10 studs away, looking in.
  4. Player 1 walks up (a soft hum, a faint warm glow) and presses Open (E). The tape rips, the
     box shivers for a moment in a warm light, the flaps burst, the night light rises out over
     the rim, turns once and flies into your hand with its pick-up sound. Say if a Common feels
     flat or empty.
  5. Do steps 2 and 4 again with each of these, one at a time, and watch for the colour and the
     sound building while the flaps hold shut and tremble: `"FairyLights"` (Uncommon, green),
     `"OilLamp"` (Rare, blue), `"FireflyJar"` (Epic, purple), `"StainedGlassLamp"` (Legendary,
     gold, the longest wait: about 1 s), `"UnpluggedLamp"` (Secret, red). Each should look and
     sound rarer than the one before. Say any that drags or that you can't tell apart.
  6. Player 2 should see and hear all of it from the hall, the find flying into player 1's
     hand. Walk player 2 about 80 studs away for the Legendary: its sounds should still reach.
  7. Fill player 1's three slots first, then open one: the find comes out, turns and lands on
     the floor beside the box, facing you, with its Take.
  8. Decide my defaults (say which to change): the colours (Common warm, Uncommon green, Rare
     blue, Epic purple, Legendary gold, Secret red); how long each holds (0.14 s Common up to
     1.2 s Secret); full hands put the find on the floor rather than refusing the Open; a
     Legendary heard 110 studs off, a Secret 140.
- [ ] **Find things in boxes** (B-03a, D-211; seen in Studio Play by me with one player, never
  two, never on a phone). Real units now deal their find or tool inside the marked box.
  1. In Studio, Test tab > Clients and Servers: Local Server, 2 players, Start.
  2. Both players: take "Walk a floor" by the spawn and open doors on floor 3 together.
  3. A unit with something to take shows one box with the two thin warm lines along its tape
     and nothing else to take: the find is never seen until someone presses Open. Open a few.
  4. A small find (a night light, the skates, a teddy) rises out and flies to the opener's hand;
     the padlock comes in a box too and opens like a Common. Player 2 should see it from the hall.
  5. A big find (a lamp taller than the box, the TV, the boombox, the neon sign) and the big tools
     (saw, bolt cutters, ladder, bubble wrap, air horn) still stand loose on the floor with Take.
  6. Seed 2000013 (Studio's floor 3) dealt: Unit312 a padlock box, Unit319 the skates, Unit321 a
     blob lamp, Unit323 a moon lamp, Unit326 a die-cast car, Unit340 a night light, all in boxes;
     Unit303 the oil lamp and Unit333 the desk lamp standing loose. Unit325 holds an awake
     Mannequin; Unit304's note is guarded.
- [ ] **Decide (defaults in, B-03a, D-211):** say if any should change.
  1. Big finds stand loose, as D-205 says. Today that means no Legendary or Secret ever comes in
     a box (all three of the top lamps are taller than it), so the gold and red reveals never
     play in a real climb. My suggestion: a tall marked box (a wardrobe box, built the way the
     marked box was) for finds too big for the small one; say yes and it becomes a ticket.
  2. A find fits if it packs in any way round, as you'd pack a moving box (the RC car lies on
     its side to fit), with a hair of room for the cardboard.
  3. The Packrat leaves shut boxes alone: it only fetches what lies loose (big finds, dropped
     finds, a find that came out onto the floor for full hands). It has less to take now.
- [ ] **Coins in boxes, and somebody's stuff in most units** (B-03b, D-212; seen in Studio Play
  by me with one player, never two, never on a phone).
  1. In Studio, Test tab > Clients and Servers: Local Server, 2 players, Start. Both players:
     take "Walk a floor" and go to floor 3 together.
  2. No coins lie on any floor now. Lift Unit301's door: one box with the warm lines, a column
     of boxes in a back corner. Player 1 opens it: the flaps burst, two coins jump out of the box
     spinning and fanning apart, with a chink and a jingle; on player 1's screen they fly to the
     coin count in the top corner, which waits at its old number and ticks up once per coin.
  3. Player 2 stands in the doorway as player 1 opens Unit312's box: player 2 sees and hears the
     three coins jump out round the rising padlock, and their own count doesn't change.
  4. Unit319: the skates and two coins in one box, an old mattress against the back wall. The
     coins tick in while the skates hang turning, then the skates fly to the hand.
  5. Walk the floor: most units with no monster show somebody's stuff (a mattress, a rug, boxes
     stacked), around the box or alone; some are bare; a unit with a monster has none. Nothing
     stands where you crawl through a wall or drop through a ceiling.
  6. On a phone (Device emulator, a small phone): the coins out of a box read as coins, and the
     ones flying to the count are easy to follow.
- [ ] **Decide (defaults in, B-03b, D-212):** say if any should change.
  1. A big loose find's coins come in a box of their own beside it, so every unit's coins are a
     box to open (one box a unit stays true for finds; coins with a big find get their own).
  2. A battery stays loose on the floor: it's a quick grab for a dying torch, not a reveal.
  3. Somebody's stuff in 7 of 10 units without a monster or note (it was half the empty ones).
  4. A box of coins alone opens like a Common: warm light, quick hold, then the coins.
- [ ] **A note comes out of a box** (B-04a, D-213; seen in Studio Play by me with one player,
  never two, never on a phone; tapping the pocket paper not yet tried).
  1. In Studio, Test tab > Clients and Servers: Local Server, 2 players, Start. Both players:
     take "Walk a floor" and go to floor 3 together. No unit has a note on its back wall now.
  2. Lift Unit317's door: one marked box. Player 1 opens it: a very short hold, a warm glimmer,
     a paper flap, and a yellow note rises out of the box rocking, turns once and flies at player
     1's face; on their screen the note lifts big ("_ _ _ 4"), the world dimmed behind it.
  3. Player 2 stands in the doorway as it opens: they see the note rise and fly to player 1's
     hand, and their own screen shows nothing more.
  4. Player 1: tap the note to put it away. A small yellow paper sits tucked at the left edge of
     the screen with "_ _ _ 4" on it in one line. Tap it: the note lifts again. Walk while it's
     up: it stays up. Tap again to put it away.
  5. Open Unit313's box too: a second paper slides in under the first; each holds up its own note.
  6. On a phone (Device emulator, a small phone held sideways): the pocket papers are easy to
     tap and don't sit under your thumb on the stick; the card still reads.
  7. Unit304's note sits behind an awake monster (the guarded note): its box is there with the
     monster; open it if you can get past.
- [ ] **Decide (defaults in, B-04a, D-213):** say if any should change.
  1. A note's unit holds the note and its coins, never a find or tool too (one box, one thing).
  2. Notes go in a pocket of their own, not one of your three hands, so taking the code never
     costs a find; each shows as a paper at your screen's left edge.
  3. A note you just took lifts onto your screen at once, so you read it before anything else.
- [ ] **Carry a note to the car** (B-04b, D-214; the pin, its flight and tap, a drop and Take
  seen in Studio Play by me with one player, the notes given by a test script; never two
  players, never a real catch, never on a phone). Do this right after "A note comes out of a box".
  1. Local Server, 2 players, both to floor 3. Player 1 opens Unit317's box (note "_ _ _ 4").
  2. Player 1 walks to the elevator's keypad (right of the shut gate, as you face it). Within a
     step of it, the paper at their screen's left edge goes, and on both screens a yellow note
     flies from player 1's hand onto the wall just right of the keypad, crooked, with a small
     tack's tap. Player 2, standing by: you see it fly and hear the tap.
  3. Either player walks up to the pinned note: it has its Read button; tap it and it lifts big.
  4. Player 2 opens Unit313's box and brings that note too: it goes up beside the first, in a row.
  5. A catch: player 1 opens another note's box (Unit304, past its monster) and lets a monster
     catch them. As the hands close, the note tumbles out of their hand with a paper flap,
     rocking, and lies flat on the floor where they stood (more than one: spread apart).
  6. Player 2 walks to it: a Take button over the paper; tap it, and the note lifts on player 2's
     screen and sits in their pocket. Player 1 (caught) never sees a Take answer them.
  7. Leaving: player 2 holds a note and closes their window. On player 1's screen the note lies on
     the floor where player 2 stood, with Take.
- [ ] **Decide (default in, B-04b, D-214):** notes go up by the keypad on their own as you walk up
  to it, as a Roblox simulator's sell pad takes your bag the moment you step on it: no button to
  find, and the last runner's note is up before they stop. The other way is a "Pin" button by the
  keypad you press (as Lethal Company has you drop scrap in the ship by hand); say if you want it.
- [ ] **Answer Brix's gift and receipt choices** (its DECISIONS E-075 to E-078, listed in Brix's
  HANDOFF) before S3-04 sells gift versions of the wrap colours.

## Now: two friends carried up wrapped, each to a unit of their own (S3-01a, D-186; fixed Nov 16 for S3-05a, D-243, and S3-05b, D-244)

Nobody is out of the climb when the elevator leaves without them: you watch a friend ride up,
then wake wrapped inside one of the new floor's units, for your friends to find. In your Nov 15
test two friends left behind both woke wrapped on one spot in front of the elevator and couldn't
be cut free. That was the trip server standing every new body at the elevator; it now leaves
anyone being carried up alone. Seen in Studio with one player on a trip server (woke in a unit,
stayed there); never yet with three real players. Play this on the real game (a lobby car, so
you ride on a server of your own), with three players: you and friends A and B.

- [ ] **Two left behind at once:**
  1. Start a climb from a lobby car with A and B. On floor 1, find the code and punch it in.
  2. You get in the elevator. A and B stay out in the lobby and don't get in.
  3. When the gate shuts, A and B should each get "Left behind" in red, the black, and then the
     view over your shoulder as the car rises and stops. Their bars show only "WATCHING" and
     your name, with the arrows.
  4. On floor 2, about a second and a half after the gate is fully open, A's and B's views should
     slowly go black, with the film's squeal and, in the black, a roll-up door slamming close by.
  5. A and B should each wake inside a dark unit, facing its door, with no "Caught" word, empty
     hands and the big Bang button. What to look for: each is in a different unit, neither is
     in front of the elevator, and neither camera is inside the other's body.
  6. Wait 10 seconds. Neither of them should move or get moved anywhere.
- [ ] **You find them both:** on your screen, after step 6:
  1. A and B press Bang a few times. You should see a blue bang mark over each of their two units
     through the walls.
  2. Walk to A's unit and open it. A should be standing inside, wrapped in film.
  3. Hold Cut free on A. The film should rip off and A is back in the climb with nothing in
     their hands. No "Get closer".
  4. Do the same at B's unit. What to look for: neither unit is the one nearest the elevator.
- [ ] **Not found in time:** leave A and B wrapped on floor 2, punch floor 2's code and ride up
  alone. Both should get "Left behind" again, watch the ride, and wake wrapped in two different
  units on floor 3.
- [ ] **Caught, then carried:** A gets caught by a monster on floor 1 and stays wrapped; B stays
  out of the elevator; you ride up. Both should wake in units of their own as in step 5.
- [ ] **Never put in with a friend** (S3-05b, D-244): in your Nov 15 test a friend was caught
  and woke wrapped in the shut unit you were standing in. Now the game never stores anyone in a
  unit someone stands in. Seen in Studio with stand-in friends filling all but three units: every
  catch went into one of the empty three. Never yet with real players.
  1. Start a climb with A and B. On floor 1, open a unit, step inside and get its door shut with
     you inside (as you did on Nov 15). Stay in there.
  2. B does the same in another unit and stays in.
  3. A goes and gets caught by a monster.
  4. What to look for: A wakes wrapped in a third unit, never yours or B's. You and B never see A
     appear beside you, and A's bangs come from a different door.
  5. Come out, find A by the bangs and cut A free. Do steps 1 to 4 twice more (the unit is
     chosen at random): A must never land in yours or B's.
- [ ] **Decide, defaults in place** (D-186): (1) The carry starts 1.4 seconds after the gate is
  fully open, so you see the new floor over your friend's shoulder before the black. (2) Nobody
  else hears anything when you're put in your unit (no squeal for them): the bangs are how they
  find you. (3) The padlock's 2.5 minutes start when you wake in the new unit. Say if any should
  change.

## Now: the last friend caught while another is carried up (S3-01b, built Nov 14, D-187; seen in Studio Play with stand-ins, not with two players)

The climb now ends the moment the last free friend is grabbed, even if another friend is in the
black on their way to being wrapped in a unit. Needs two players, as the test above.

- [ ] **Caught while your friend is carried:**
  1. Start a climb with a friend. On floor 1, punch the code.
  2. You ride up alone. Your friend stays out in the lobby and is left behind.
  3. When the gate opens on floor 2, step out and walk straight into a monster within a few
     seconds (or, if none is near, close Roblox on your device the moment the gate opens).
  4. What to look for on your screen: you get grabbed, and about a second later, as your catch
     cuts to black, the "Caught" black comes down. Your eyes should not open inside a unit first.
  5. What to look for on your friend's screen: their view may start to go dark from the carry,
     then the "Caught" black takes over. No door slam or film squeal after the "Caught" black starts,
     no "Back in" word, nothing flashing.
  6. On the results, your friend's photo should say floor 2 (the floor they were carried to),
     not floor 1.
  7. Press Again on both screens: both of you should come back with a clear screen, nothing
     stuck black.
- [ ] **Decide, defaults in place** (D-187): (1) A friend being carried up counts as wrapped, so
  the end doesn't wait the few seconds for their unit. (2) Their photo names the floor they were
  carried to. Say if either should change.

## Now: listen to the Packrat, arms empty and arms full (S2-06e and S2-06e2, built Nov 14, D-184 and D-185; both sets heard playing in Studio Play, not yet judged by ear)

The Packrat now has its own sounds. With its arms empty (coming for you) you should hear soft
padded steps and, once a stride, a screech of packing tape pulled off a roll. With its arms full
(hauling something home) you should hear heavier, quicker steps with the thing in its arms
jingling and rattling. An earlier test heard nothing, but that was the test: Studio was drawing
no frames. With frames, both sets play, and the first steps now land on the beat too.

1. In Studio, start Play on floor 3 (the dev floor). Wear headphones or turn the sound up.
2. Press the Packrat post (R). A Packrat stands by the lobby and carries its boombox to its pile.
3. Get on a unit's roof near its hall (it can't see the tops) and wait for it to roam. Listen
   before you see it: soft thuds and a tape screech every couple of steps. It should sound
   quiet and wrong, and you should hear it round a corner before it turns into your hall.
4. Drop a find in a hall (pick one up, then drop it). The Packrat walks to it, picks it up and
   carries it home. Listen: the sound should change the moment its arms close on it, to heavier
   steps with a rattle and jingle. You should be able to follow the rattle home.
5. What to tell me: whether you hear anything at all; whether you can tell empty from full with
   your eyes shut; whether the tape is creepy or just annoying (it plays once a stride); and
   whether anything clicks or cuts off.

## Now: bait the Packrat into a unit and slam the door on it (S2-06d, built Nov 14, D-183; the trap seen in Studio Play, taking back from its pile not watched)

The Packrat now turns for a find that turns up nearer to it than the one it is walking to, so
bait works as it passes instead of some trips later. Everything else here was already true and is
now checked: a find at the back of a unit draws it in, and pulling the door down while it reaches
for it traps it like any monster. It pounds and breaks out after 90 seconds, carrying the find if
its hands had already closed on it. Shut in its own unit, its pile is shut in with it.

1. In Studio, start Play and walk to floor 3 (the dev floor). Press the Packrat post (R) so a
   Packrat stands in a unit by the lobby. Pick a find up, or get one from a unit.
2. Before it sees you, open a unit a little way from it, walk to the back wall, and drop your
   find there (it should land against the back wall, well inside).
3. Get out of its sight. The roofs of the units work: it never sees you up there. Watch it.
4. Look for: it walks into that unit, stops a long arm's length from your find, and puts its
   arm out. Drop down to the door and press Slam then.
5. Look for: the door slams, and a moment later the first blow from inside, then pounding that
   gets faster. Stand back. About 90 seconds later the door bursts up and it comes out.
6. Judge the timing on a phone: from the moment its arm goes out you have about two seconds
   before it turns round with the find. Is that a fair, tense window, or too tight?
7. Taking your things back: follow it home and watch which unit it walks into. While it is out
   on a trip, go in and press Take on the finds in its pile. Look for: each comes into your
   hands like any find. Then stay in there until it comes home. Look for: it walks in past you
   with its arms full, lays its find down, then turns on you and takes your best one back.
8. Shut it in its own unit: when it walks home with a find, slam its door behind it. Look for:
   it is trapped like anywhere else, and its pile is out of reach until it breaks out.

## Now: buy off the Packrat with a find, and see its own catch (S2-06c2, built Nov 14, D-182; the turn-off seen in Studio Play, the rest not watched)

When the Packrat is chasing you with empty arms, a find dropped where it can see it, nearer to it
than you are, is what it goes for instead: it turns off you, reaches for the find, takes it and
carries it home. If you drop something while running, it now falls at your heels instead of in
front of you. When the Packrat does catch you, the jump scare throws its own body at you, not the
Mannequin's.

- [ ] **A friend's drop saves you.** In Studio Play on floor 3, walk to the lobby's "Stand one"
  Packrat post and press it (R).
  1. Pick up the boombox in the hall, or any find, so you hold something.
  2. Stand in a hall where the Packrat will see you, facing it, about 15 studs off.
  3. When it turns and comes at you (the chase music starts), drop what you hold (the drop
     button on the wheel, or its key).
  4. Look for: it turns away from you at once to the thing on the floor, its arm goes out, it
     takes it, and it walks home past you. The chase music fades. It never touches you.
- [ ] **The runner's drop.** Same set-up, but turn and run from it while holding a find.
  1. While it chases you, drop the find without stopping.
  2. Look for: the find falls just behind you, you keep running without bumping into it, and
     the Packrat stops for it. Tell me if the find landing behind you looks wrong anywhere else
     (dropping a tool while walking also puts it behind you now).
- [ ] **Its own catch.** Let it reach you with empty slots (drop everything first).
  1. Look for: the jump scare shows the Packrat, not the Mannequin: the grey blanket bundle
     reared up over you, both long pale hands raised either side of its hood, rushing your eyes
     before the black. On a phone, check the two pale hands show at the edges of the screen.
  2. Tell me whether it lands as hard as the Mannequin's.

## Now: let the Packrat rob you (S2-06c1, built Nov 14, D-181; seen in Studio Play, the robbed screen not watched)

When the Packrat's arms are empty and it reaches you, it takes the best thing you carry instead of
wrapping you, and walks home with it. With nothing in your slots, it wraps you like any monster.

1. In Studio, set Workspace's `DevFloorNumber` to 3 and press Play. Walk to the floor's lobby.
2. Press R at the "Packrat" post. A Packrat stands up in the nearest unit.
3. Pick up two finds (the boombox it lays in the hall, or any from an open unit), or switch the
   Test tab's view to Server and in the Command Bar set `workspace:SetAttribute("GiveFind", "Television")`, then again with
   `"Teddy"`. Hold the teddy in your hand.
4. Stand in front of the Packrat before it walks off, and keep still.
5. Look for: it walks at you, its long arm comes out and closes, and the television (the more
   valuable find, even though it's not in your hand) is torn away: your view jolts, you hear a
   creak and the television's own clunk, and the television's picture flies off your wheel's
   button toward the Packrat. You are not wrapped.
6. Look for: the television sits in its arms against its chest, and it walks back to its unit and
   lays it on its pile. Follow it: you can take it back off the pile.
7. Stand in front of it again: this time it takes the teddy from your hand. The teddy should
   jerk out of your hand toward it, not fall.
8. With empty slots, let it reach you a third time: it wraps you, as the Mannequin does (for now
   it still throws the Mannequin's face at you; that's the next piece's to fix).

Defaults I picked, tell me if any is wrong:
- **"Most valuable" is the heaviest find** until finds carry a worth of their own: the television,
  then the boombox, the skates, the teddy. A tool only if you carry no find (the one in your hand
  first). Never the flashlight, and never the ladder (it rides your shoulder, like the big find
  will).
- **The take is instant once it reaches you.** Its arm closing on you is the same moment a
  Mannequin's catch would be; there's no beat to pull away in, so it can't be dodged at arm's
  length, only kept away from.
- **The sound is a stand-in:** the Mannequin's lunge creak and the find's own pick-up sound,
  until the Packrat gets its own sounds (S2-06e).

## Now: find the Packrat asleep among its pile on floor 3 (S2-06b2b, built Nov 14, D-180; its deal checked in Studio Play, the opened door not yet looked at)

From floor 3 up, every floor has one Packrat, asleep at the back of a big unit with two or three
finds of its own lying at its feet.

1. In Studio, select Workspace and add a number attribute called DevFloorNumber set to 3.
   Press Play. (Remove the attribute afterwards to go back to the usual floor.)
2. Output lists the sleepers as the floor is laid: look for a line starting "Keepers: asleep
   behind shut doors on floor 3" and the unit marked "(Packrat)", for example "314 (Packrat)".
3. Take "Walk a floor" by the spawn to the floor's lobby, find that unit and lift its door.
4. Look for: as the door rolls up, a little heap of stuff in the bulb's light (a boombox, a
   television, a teddy, skates: two or three of them, all different, each turned a little,
   like something dumped there), and behind the heap, at the back of the unit, the tall grey
   Packrat standing slack, facing you, its long pale hands hanging. Output says "held the
   Packrat, asleep, among its pile: ...". Say if the heap or the Packrat looks wrong (things
   inside each other, inside a wall, or the Packrat squeezed into a corner).
5. Take one of its finds ("Take"). Its pile is yours to raid; the Packrat taking it back is a
   later piece (S2-06c and S2-06d).
6. Look for, on the way: halls lighting up as a Packrat walks them, if one is out (step 8 of
   the next section shows one walking).

## Now: watch the Packrat fetch a find home (S2-06b2a, built Nov 14, D-179; seen in Studio Play, not on a phone)

A post in the test floor's lobby stands one for you.

1. Press Play. Walk to the spawn's "Walk a floor" button and take it to the floor's lobby.
2. In the lobby's back corner, beside the Mannequin's "Stand one" post, is a second post called
   Packrat. Press R at it ("Stand one").
3. The shut unit nearest the lobby rolls its door up. The Packrat is inside: a tall grey bundle
   of moving blankets with two long pale arms. A boombox has just been laid in a hall two or
   three halls off. Go and stand somewhere you can see that boombox, but keep out of the
   Packrat's sight on its way: with empty arms it still hunts you as the Mannequin does.
4. Look for: it comes out of its unit, looks about, then walks off with its arms hanging wide,
   gliding, not jerking like the Mannequin.
5. Look for: it stops a little short of the boombox and puts one long pale arm straight out
   over it, holds it there for a moment (you could snatch the boombox now), then both hands
   close and the boombox rises off the floor into them, quick, like a snatch (about a fifth
   of a second), then slides in against its chest as it turns for home. Say if the rise looks
   too slow or too fast, or if the boombox ever shows up at its chest before the hands close.
6. Look for: it walks home hunched with the boombox hugged to its chest behind its crossed
   pale forearms, in shorter, quicker steps. Stand right in front of it now: it ignores you.
7. Look for: back in its unit it crouches over its pile; the boombox comes down from its chest
   into its hands as it bends, and it sets it on the floor from there (no jump). It comes out
   again with empty arms. The boombox now says "Take": you can take it back.
8. Look for: the hall lights come on round it as it walks, the way they do for you. Press the
   post again any time for a fresh Packrat in a fresh unit.

## Now: shut a door on a sleeping monster (S2-05, built Nov 14, D-169 and D-170; seen in Studio Play, not on a phone)

Try it on your phone too: Publish first (File > Publish to Roblox), then play from the Creator
Hub. Studio Play is fine for the first go.
1. **Find a sleeping monster.** Walk the dev floor and open doors (E, or tap the door's Open dot
   on a phone) until one has a Mannequin standing slack inside, asleep. (Output lists the
   sleepers' units as the floor is laid.)
2. **Pull the door down with Close (F, or tap its dot).** Look for: a sharp metal tick, and at
   the same moment a dark bar rising up into place just under where the Close button was, with
   a bright block (the zone) somewhere on it. The door's buttons vanish while the bar is up. The
   door comes down most of the way and hangs about a foot off the floor, the Mannequin's feet
   showing under it.
3. **Watch the white marker.** It waits at the left end for a breath, then runs across once,
   dragging a short glow behind it.
4. **Tap while the marker is in the bright block** (on a phone, tap anywhere on the right half
   of the screen; on a computer, click or press F). Look for: the marker stops dead with a little
   flick, then the block, the bar's rim and the marker go pale green, the bar pops and sinks
   away. The door eases the last foot down and lands with a quiet touch and a soft latch click.
   The Mannequin sleeps on (open the door again later: still slack).
5. **Do it again on another sleeper, and don't tap.** Look for: the bar goes red and shakes,
   then drops away as the door bangs down (a slam's boom and shake), and about a second later
   the Mannequin pounds on the door from inside.
6. **Once more, tapping early (before the block).** Look for: red and the bang at once.
7. **On the phone, say:** whether the bar is easy to read at a glance, whether its spot (just
   under the Close button) suits your thumb or should sit dead centre every time, as Dead by
   Daylight's does, and whether the tick is loud enough over the door.
8. **Decide my defaults** (say which to change): a hit always keeps the monster asleep (the
   design doc says "much more likely"); a monster awake inside that hasn't seen you is shut in and
   pounds either way, so the tap only spares the floor the bang; a peeked door's short drop never
   brings the bar up; the zone is about a sixth of a second wide, somewhere in the bar's middle
   to late part; while the bar is up every button on the screen fades and the doors close by
   can't be pressed, so no thumb lands on Slam by mistake; the marker runs in silence (no sound
   of its own) so the wait is a held breath.

## Now: two camera feed fixes (S2-07a1, built Nov 14, D-171; seen in Studio Play, not on a phone)

1. **Watch a feed with another monster about.** Play a floor for a few minutes, opening doors
   until two or more Mannequins are loose in the halls, and keep going until one walks to the
   breaker and the corner map turns into the camera picture.
   Look for: any other monster that crosses the picture walks in it, stiff and choppy like the
   one going to the box. None stands frozen in the hall.
2. **Two Mannequins at the box.** If two head for the breaker close together, look for: the
   picture stays up the whole time (no second burst of snow), and the second one walks into the
   same picture.
3. **Decide my default:** a feed from another camera never cuts off the one showing; it waits
   and cuts in after, unless its moment (the clunk) came while it waited, then it's skipped.
   Today every feed is the breaker's, so you'll only see this once a second monster uses the
   camera.

## Now: judge the Packrat's look (S2-06a1 to a3, built Nov 14, D-175 to D-177; pictures, and a model in the place that no floor uses yet)

What's new: the second monster's model, its two walks and how it grabs a find, as pictures, and
the model itself in the place (`ReplicatedStorage.Keepers.Packrat`). No floor puts one out yet,
so you won't meet it in a climb.

1. Open `art/sheets/packrat-lineup.png`. From left to right: asleep as it's found, walking with
   its arms empty, walking with a find (the teddy) hugged to its chest, and that from the side.
   Look for: does it look like a bundle of moving blankets and tape with long bare arms? Is it
   scary, or does it look like a costume?
2. Open `art/sheets/packrat-close.png`: the hug up close. Look for: the arms wrapped round the
   find, the hood bowed over it with nothing in its opening.
3. Open `art/sheets/packrat-hall.png`. It's a phone-sized picture of a hall with two Packrats 30
   studs away: arms empty on the left, arms full on the right. Look for: can you tell which is
   carrying something without zooming in? The full one should show a pale knot at its chest;
   the empty one two pale lines out from its sides.
4. Open `docs/art/S2-06a2-packrat-hall.jpg`. This one is from Studio itself: a real hall of the
   game, one ceiling light on, two Packrats 30 studs down it, arms empty on the left, arms full
   on the right with a boombox. Look for: the same thing as step 3. Can you tell which one is
   carrying something at a glance?
5. Open `docs/art/S2-06a2-packrat-close.jpg`: the full one close up. Look for: its pale forearms
   crossing in front of the boombox, holding it against its chest. (At first the boombox hid
   the forearms completely, so I moved where a carried find sits back toward its chest.)
6. Open `art/sheets/packrat-take.png`. From left to right, the three moves it makes with a find:
   reaching for it with one long arm, the teddy at its fingertips; taking it, both hands closed
   on it and pulling it in toward its chest; putting it down, crouched and folded over it.
   Look for: is the reach the thing you'd scream at, a long pale arm coming out of the dark
   bundle? Does the take look like it's pulling the teddy in, not just holding it out?
7. Open `art/sheets/packrat-reach-hall.png`. It's a phone-sized picture of a hall with the
   Packrat 30 studs away, side on, reaching across the hall. Look for: can you see the long arm
   and the teddy at the end of it without zooming in?
8. My defaults, change any you like: the find it carries in the pictures is the teddy; the
   tape is a dull tan, not shiny orange; it's 7.3 studs tall (a player is about 5.2). It reaches
   with one arm, not both (two arms out would read as a zombie). Its walks are smooth, not jerky
   like the Mannequin's, so the two monsters move differently.

## Now: the screen's three fixes (S2-07b2, built Nov 14, D-174; checked in Studio Play with a stand-in friend)

What changed: a friend's torch now shows the chalk mark on a door frame, as your own does; a
saw bought from the car's machine leans into the bin instead of tumbling through the glass;
and the odd lines in Output were traced (none of them is the game's to fix).

- [ ] **A friend's beam shows the mark** (Test > Clients and Servers, 2 players; set Workspace's
  `DevFloorNumber` to 1 first, so the floor has a mark, and clear it after).
  1. Both players walk to the same hall. Player 1 switches their torch off.
  2. Player 2 switches their torch on and sweeps it along the door frames, close up (about
     three steps away), the way you'd look for the mark yourself.
  3. On player 1's screen, look for: the faint chalk ring appears on one frame where player 2's
     beam lands, fades in, and fades away a moment after their beam moves off. Player 1 never
     switched their own torch on.
  4. Player 2 switches their torch off while it's on the mark. Look for: it's gone at once.
- [ ] **The saw leans in the bin.** Ride the car with coins, buy the saw from the machine and
  watch it come off its coil. Look for: it tips forward and drops into the bin leaning, and no
  part of it shows in front of the glass at any moment. Buy a battery too: it still tumbles
  and lies down as before. Does the lean look natural?
- [ ] **One Output line to watch for.** If you ever see `rbxassetid://89260803894903 ... No
  asset content representation found` in Output, write down what you'd just done (it came once
  when a unit rolled up after a wrong code). It's a texture pack the coin's import made; it
  couldn't be brought back tonight. The other lines at Play start (`rbxassethash ... permission`
  and 203785492) are Studio's own, not the game's.

## Now: the player's three fixes (S2-07b1, built Nov 14, D-173; seen in Studio Play, not on a phone)

What changed: a hall light you stand still under through a wrong code's alarm comes back lit;
a battery's Take no longer shows through a shut door; and your torch goes out when you're
caught, so it isn't empty by the time a friend cuts you free.

- [ ] **The light comes back on you.** Play floor 3. Walk to the first hall light outside the
  lobby, step back to the lobby and punch in a wrong code (any four digits), then run back and
  stand still under that light before the lights come back.
  1. Look for: the halls go dark with the whine. While it's dark, stand completely still.
  2. Look for: as the power comes back, the light over you flickers back on with its click
     (the others come back dark). Keep standing still: about seven seconds later it goes dark.
- [ ] **Decide: should the keypad have a light?** The keypad sits in the lobby, and no hall
  light reaches the lobby: only the car's lamp lights it, and that lamp never stops a
  Mannequin. So a player waiting at the keypad is in the dark to the monsters before, during
  and after the alarm, and that's how the earlier test got caught there. My default: leave it,
  because the alarm calling monsters to the keypad in the dark is its whole threat. If you'd
  rather the lobby had a motion light over the keypad (so standing at it lights you up and
  holds a Mannequin in its light), say "light the lobby" and it goes in with the lobby's dressing
  (L-05).
- [ ] **No Take through a shut door.** Play until a unit you open has a battery on its floor
  (about one unit in ten), with your torch down at least one tick on its ring.
  1. Look for: standing in the open doorway, the Take button shows. Pull the door shut and
     stand outside it: the Take button is gone.
  2. Lift the door again: the Take comes back. A peek (the door barely lifted) is not enough.
- [ ] **Your torch when you're caught.** Play with a friend. Switch your torch on and let a
  Mannequin catch you.
  1. Look for: your torch lights the face rushing at you, then clicks off as the screen goes
     black. You wake wrapped with it off; pressing the torch button does nothing.
  2. Your friend looks for: your torch goes out as you're wrapped.
  3. Once your friend cuts you out, press the torch button: it comes on, with the charge it had
     when you were caught (the ring hasn't run down).

## Now: three monster fixes (S2-07a2, built Nov 14, D-172; seen in Studio Play, not on a phone)

What changed: a Mannequin walking to the breaker box is harder to distract; monsters called to
one spot stand round it instead of inside each other; and sleepers that wake in a wave never let
out more monsters than the floor allows.

- [ ] **The keypad crowd.** Play floor 3. Punch in a wrong code (any four digits), wait for the
  bell to stop, then punch in a second wrong code. Hide somewhere you can see the keypad.
  1. Look for: several monsters walk up to the keypad and stand round it, each in its own spot,
     a body's width apart, all facing the keypad. None stand inside another.
  2. Look for: in a hall they line up along it; in the lobby they make a loose ring.
- [ ] **The busy Mannequin.** Play a floor until a Mannequin walks off toward the breaker box
  (the camera feed on your map shows it). While it walks, slam a door two halls away from it.
  1. Look for: it keeps walking and throws the breaker; the lights go out.
  2. Next time, slam a door in the same hall as it. Look for: it stops, turns to the slam and
     comes to look, and the camera feed lets it go.
  3. Judge: is it now too hard to pull it off the box? The default is it hears a third as far
     while it's on the way (`Keeper.ErrandHearing`). Tell me "more" or "less" if it feels off.
- [ ] **A wave held to the floor's limit.** Play floor 3 and stay about four minutes without
  opening doors, until doors start pounding.
  1. Look for: on floor 3 at most two monsters ever get out of their doors at once (floors 1 and
     2 allow one, floors 3 and 4 two, higher up three).
  2. Look for: a door that pounded for a minute and a half goes quiet with one last heavy blow
     when the floor is full. Then trap or lose one of the loose monsters behind a door.
  3. Look for: the quiet door bursts open soon after, and its monster comes out.
  4. Judge: is the quiet door scary (you know something is still in there), or does it feel
     like it gave up? Tell me if you'd rather it kept pounding (then loose monsters tend to stand
     guard at it).

## Now: check your five fixes (built Nov 14, D-158; seen in Studio Play, not on a phone)

Publish first (File > Publish to Roblox) so live servers run them.
1. **On your phone, step into a lobby car and let it go.** Look for: the gate slams, the car
   lurches, the lobby goes dark beyond the gate and the shaft wall slides down past it, a cable
   clank, and only then the black with "Going up". Then the black lifts while the car is still
   climbing (about six seconds of ride, the slowdown, the bell, the gate opening). If it still
   opens on a car already standing open, say so.
2. **Stay in the car after it opens on a floor.** About six seconds after the gate opens it
   shuts, and you're stood just outside it, facing the hall, as it folds shut behind you. Say if
   being moved feels too sudden.
3. **In the lobby, swing the camera round inside and in front of a car.** The car floors
   shouldn't flicker any more.
4. **Look at the coin count, top right.** The coin should be as sharp as the number, and give a
   quick flip each time a coin lands in it.
5. **Let a Mannequin loose and keep away from it** (a trapped one bursts out after 90 seconds).
   After a floor's first 45 seconds, a wandering Mannequin now cuts the power within about half
   a minute, once per floor; after that it's back to the old odds. Say if the first cut comes
   too soon or too often.

## Decide: the design doc after your answers (Nov 13, D-128)

Your answers, the four from tonight included, are written into the design doc (the GDD) and the
roadmap (Phase 2: Steps 1 to 6, tickets S1-01 on). `docs/PROPOSAL.md` is kept as the record.
Nothing in it is built yet. What still waits on you, in the order it holds work up:
- [ ] **The flashlight's details.** You said it runs down, and that batteries are in the
  machine on every ride and in units. I picked the rest: it's full at the start of each climb;
  a full one gives about five minutes of light, and only runs down while it's on; a small meter
  on its button shows what's left, and the beam flickers for the last half minute before it
  goes out; picking up a battery fills it at once and takes no slot (if yours is full you leave
  it for a friend); what's left carries over from floor to floor; a battery costs 3 coins in the
  machine; about one unit in ten has one. Say if any is wrong. (The running down is built this
  way, Nov 14: judge it under "Now: the flashlight runs down"; the batteries in units under
  "Now: take a battery".)
- [ ] **A trapped monster still counts toward the floor's limit** on how many can be awake.
  The old design doc said the opposite, which made trapping pointless. You gave the reason
  (trapping makes it easier to search) but didn't answer this directly: say if you disagree.
- [ ] **The small things I picked** so each idea was complete. They're marked "starting guess"
  or "my default" where they appear in the design doc: seven units in ten have coins; a tool in
  one unit in twelve; not tapping counts as a miss; a pounding monster breaks out after 90
  seconds unless padlocked; the breaker takes a one-second hold and the elevator keeps its own
  light; sleepers start to wake after four minutes on floors 1 and 2 and six above, three at a
  time, three more every two minutes; the third wrong code and every one after opens five
  units; the big find's unit opens by itself, shows on the corner map, and is no more than a
  20-second carry away; pay goes up a little each floor, and each trapped monster pays
  everyone 5 coins (you agreed trapping pays on Nov 14); a climb ends when everyone is wrapped at the same moment; the machine's stock
  changes each ride; perks unlock by reaching a floor or finishing a set; badges at floors 10,
  25, 50 and 100; the marker costs 4 coins, makes five marks and shows on the corner map. They
  stand unless you say one is wrong.
- [ ] **The old story and the old monsters are kept, marked "Nov 2 drafts, none agreed".** The
  Everkeep name, Unit 0, the $1 auction and the three families are in the story section; the
  rug, the box stack, the tenant, the mover and the inflatable are at the end of the monsters
  section. Nobody builds from them. Say if you'd rather they were deleted.
- [ ] **Two products the proposal's store list left out are still in the design doc's store:**
  cart wraps, wheel lights and a horn (your Nov 11 lobby plan) and an admin pass for streamers'
  private servers (from the first draft). Keep or drop each?
- [ ] **Untested bets.** The design doc's "Ideas with no hit game behind them" lists eight. Of
  my five, you chose the elevator buttons on Nov 13, agreed two earlier (valuing finds one at
  a time, the "still sealed" look), and agreed one on Nov 14 with the Packrat: it leaves you
  alone because you dropped it something. The last is each monster going after the thing that
  stops it: the Packrat carrying finds off has Lethal Company's Hoarding Bug behind it, and a
  monster that pulls open doors down is only the idea for later. So none of mine is waiting on
  a yes; say if any should stop.
- [ ] **The Packrat: a few small things, and none holds work up.** You chose it on Nov 14 as
  the second monster and agreed my six defaults (D-167), so its ticket (S2-06) no longer waits
  on you. Packrat is a working name: say if you want another. Defaults I haven't put to you:
  1. It sets the hall lights off as it walks, the way a player does, so you see it coming and
     a Mannequin near it freezes (built Nov 14). Say if it should walk in the dark instead.
  6. Where it sleeps (S2-06b2b): always in a big unit, never one holding a note (its tall body
     would hide the note from the doorway), never a padlocked one. Say if it should ever sleep
     in a small unit, with a pile of one.
  2. Which find it goes for next (S2-06b1, D-178): always the nearest one it can walk to. It
     knows where every loose find on the floor is, even ones it can't see, so it works the
     floor steadily outward from wherever it is. The other way would be: only finds it sees.
  3. While it walks to a find it hears sounds only a third as far, the way the Mannequin
     does on its way to the breaker, so it usually gets there. Once it holds a find it hears
     and sees nobody at all.
  4. If someone pulls its own unit's door down while it's out carrying a find, it can't get
     home, so it wanders the halls still holding that find, harmless, until the door goes up
     again. That makes shutting its door behind it a real trick. Say if it should do
     something else, such as stand waiting outside its door.
  5. Its numbers: it stands with its arm out for 0.8 seconds before it takes a find (long
     enough to snatch it from under its hand), and crouches over its pile for 1.2 seconds.
     Full, it walks at 72% of its empty pace. You'll judge these in play once S2-06b2 puts
     one on a floor.
- [ ] **Open at the end of the design doc:** a name for the monsters (the code says keepers);
  the story; where you pick your two perks (the counter or the elevator's panel); and the thumbnail line. "Don't
  move. The lights are watching." fitted the monster you dropped on Nov 14, and nothing in the
  game now rewards standing still.
- [ ] **Later, when you take them up:** the monster you hide from, and the monster that takes
  your head. The second has three things to settle first, listed under it in the design doc.

## Decide: what follows from your finds answers (Nov 14; nothing built)

You answered the [item catalog](https://claude.ai/artifact/29wkaNXM3Yw86xTMb3sjQQ)'s 14 questions
on Nov 14 (D-188); the catalog and the design doc now say what you chose. These are the gaps I
filled. Each default stands unless you say otherwise.
- [ ] **Kept's eight finds moved up to Secret.** So a Secret can turn up from floor 10 (1 find in
  500) and more often from floor 25 (1 in 100), and the whole server hears about it. The other
  way: move them down to Legendary, and Secrets stay floor 25 and up only (1 in 1,000).
- [ ] **The luck boost is yours alone.** It raises the odds only in the units you open on the
  next floor, so a friend in a country where Roblox restricts paid random items is never part of
  it. The other way: it lifts the whole floor for everyone in the car. Either way the shop shows
  the odds with and without it before you buy (Roblox's rule). It waits on the shop.
- [ ] **Trapping pays 5 coins** to everyone aboard for each monster shut in a unit as the gate
  shuts (floor 1's gate pays 10 and rises 2 a floor). You'll judge it in play once S4-04 is built.
- [ ] **Are the other lights used up too, as the hard hat is? (Nov 16, D-251)** You made the
  hard hat used up: when its minute runs out it falls and breaks, and no battery refills it. The
  other found lights that run down (the camp lantern, the oil lamp, the tea light, the desk lamp
  and the other lamps) aren't settled. My default: the same. When a light's time runs out on a
  climb, it breaks where it is and is gone, so spending a rare lamp is a real choice and there
  are more to find. The other way: a spent light comes home dark and only lights your unit.
- [ ] **The lamp that's on when you find it (the Secret Light) looks like an ordinary 1940s brass
  table lamp,** lit warm, its parchment shade glowing, its cord running across the floor to a plug
  lying loose: it's on with nothing to power it. The catalog didn't say how it looks, so this is my
  default. Pictures: `art/sheets/unpluggedlamp-front.png`, and `-unit.png` from a unit's doorway.
  The other way: something stranger, but then it stops being the quiet "that shouldn't be on".
- [ ] **Who records the voices for the talking finds?** The pull-string cowboy doll (built)
  says one of six short lines when you pull its ring, and the singing fish plaque (built) sings
  two bars: about 6 seconds at 120 beats a minute, starting 1.55 s after the press, its mouth
  already timed to 15 sung syllables. Both need recordings the game owns: you or a friend
  reading them, a hired voice actor, or text-to-speech run through an old-record crackle. The
  fish's tune has to be ours or long out of copyright (an old sea shanty or nursery tune), never
  a famous singing fish's songs. Default until you say: both play silently (the doll's cord
  whirrs, the fish's motor hums); the doll's six lines are in `art/finds/windups/README.md`.

## Now: judge L-08e3, Invite and the dials (built Nov 12, D-124)

Over each car's gate a dial now replaces the number plate: the bay's number with three round
seats either side, a photo in a warm ring for each player aboard, empty sockets for room, and a
line under the number ("Friends only", "Full", "Going up", or "Floor 3" in green while that car's
group climbs on the same server). Standing in the lobby in no car, the fullest car that will take
you glows: its dial's rim breathes warm, the seat you'd take with it, and a chevron bobs in its
doorway. Inside a car the panel has Invite beside Go, for anyone aboard: Roblox's sheet of your
friends, "Ride up with us". Verified in Studio, one player, the other cars' players faked: the
dials from the door and up close, a seat filling, "Floor 1" over the car you rode, the pointer on
and off, the invite sheet opening with your friends (no invite sent).
- [ ] **Invite, live (Publish first):** in a car, tap Invite and invite a friend. Do they land
  on your server (Roblox's invite follows you there on a public server; the docs don't promise
  it)? Once in, the chevron should point them to your car. Tell me if they land elsewhere.
- [ ] **The dials from the door, on your phone:** can you tell from the spawn which cars have
  people and how many? Up close, are the photos big enough? The line under the number is small
  from the door; it's meant to read from the room's middle.
- [ ] **The pointer:** with a friend in one car and you in none, their car glows and the chevron
  bobs in its doorway; it moves if another car gets fuller, and goes as you step in. Too much,
  too little?
- [ ] **Decide (defaults in place):** (1) anyone aboard can Invite, not only the host; (3) where
  the share link goes (Roblox pays on new or returning players who come by a share link, not on
  invites to friends already on Roblox): it's now a Share key on the panel between Invite and Go
  (L-08e3b); move it to the end screen after a climb, or have both?

## Now: throw the breaker and switch it back (S2-02a-b, built Nov 14, D-153, D-154; seen in Play)

The box hangs on every floor now, somewhere new each climb, never in the lobby's hall. In a real
climb only a Mannequin throws it (S2-02c, below), so test the box itself with the dev command.
1. In Studio Play, walk the test floor, then in the Server's command bar run
   `workspace:SetAttribute("ThrowBreakers", true)`. Look for: one heavy clunk wherever you
   stand, every hall light dead, and moving under them does nothing.
2. Find the box by its red lamp (STUDIO.md "The breaker" says where it is on the test floor).
   Look for: does the pulsing red lamp and its faint red wash pull you to it from down a dark
   hall, on a phone-sized window too?
3. Hold the lever's button. Look for: the lever creeping up under your hand, then a snap, a
   click, the lamp green, a low hum swelling and dying, and every light on the floor coming on at
   once before each goes dark on its own.
4. Decide (starting guesses, D-154): the lights all coming back on (an untested bet: real motion
   lights do; coming back dark would show nothing from the box); the lamp as glowing Neon, red
   off and green on; one second to hold, as cutting a friend free.

## Now: the shallower machine (S1-10d2, built Nov 14, D-162; three buys seen in Play)

The machine is a quarter less deep (1.8 studs, was 2.4), so the car has more room in front of
it. You asked for "a bit"; I stopped at a quarter because a third leaves no room for the second
battery standing in each bottom coil. Seen in Play: the stock stands in its coils, and the
bubble wrap, a battery and the saw each dropped into the bin and flew to the hand.
1. **Ride with friends and crowd round the machine.** Look for: does the car feel roomier, and
   does the machine still look solid from the side, not like a cabinet stuck to the wall?
2. **Buy something big (the bubble wrap, the saw) and watch from close up.** Look for: the
   thing rolls off its coil, drops in the gap behind the glass and lands behind the flap. Does
   anything poke through the glass or the flap?
3. Decide: a quarter is enough, or shallower still. Shallower means one battery per bottom coil
   (two a ride instead of four), or batteries shown smaller in the machine than in your hand.

## Now: pick from the machine's menu (S1-10d1, built Nov 14, D-161; seen in Play, not on a phone)

**New (S1-10d3, D-164; passes checks, untested in Studio):** as you asked, after a buy the menu
drops away and stays down; the Buy on the glass comes back once the thing is in your hand
(about 2 s), and pressing it opens the menu again. A pick you can't pay for keeps it up. Step 3
below is the one to watch.

The six Buy buttons on the machine are gone: one "Buy" on the middle of its glass opens the
machine's front on your screen, and you pick there. This replaces pressing the bays in "buy at
the machine" below; the coins, the drop and the flight to your hand there are unchanged. Seen in
Studio Play in a desktop-sized window: the panel draws right (sign, three lit rows, pictures,
labels, LED prices, dashes for a sold-out coil, dim bays you can't pay); a real buy dropped it
away and it rose again; walking off closed it. Not seen: phone size, the rows lighting as the
machine wakes, the real button sinking, a refused pick's buzz and shake.
1. **On your phone, ride from floor 1 to 2 and walk to the machine.** Look for: a "Buy" on its
   glass once the bottom row lights. Press it: the machine's front rises from the bottom of the
   screen with a heavy clunk, its tubes stutter on with two tinks, the prices show 88 then the
   prices. Is every bay easy to read and hit with a thumb? Does it feel like the machine?
2. **Open it as the machine wakes.** Rows not lit yet are dark on the panel and light with the
   real tubes, and the panel dips with the car's lamp.
3. **Buy something you can pay for.** Look for: the bay presses in, the real button clicks, then
   the panel drops away so you see the coins fly, the coil turn, the thing drop and fly to your
   hand; the panel stays down and the tool wheel comes back. The Buy on the glass shows again
   once the thing is in your hand: press it and the menu rises for another buy. Is that wait
   for the Buy to come back right, or should it be there at once?
4. **Pick something you can't pay for.** The machine buzzes, the price blinks on the panel and
   the machine, the bay shakes. With a full torch the battery bays are dim and don't press;
   with all three tool slots full, the tool bays are dim the same way (batteries still sell).
   As the menu rises, the round tool button with Lay and Drop slides off the bottom of the
   screen, and comes back up when you close it. Is losing it while you shop fine?
5. **With friends crowding the machine,** check you can still open it from behind them, and
   that walking away, the knob at its bottom right, E, or B on a pad closes it.
6. Decide (my defaults): its sounds (the flap's knock pitched down for the clunk, the tubes'
   tink) and its place (right of centre on a phone, clear of the jump button).

## Decide: small finds you can't see from a doorway (F-S1, Nov 15, D-194; nothing built)

The night's finds are in the place now (`ReplicatedStorage.Props.Finds`: nine lights and the RC
car, each a template made by code; save the place to keep them). Standing in a lit unit's
doorway on a phone, the desk lamp, blob lamp, moon lamp, lantern, oil lamp and RC car read at a
glance, off or on. The small ones (the tea light, the night-light, the glow sticks, the fairy
lights, all under about 6 inches) are specks when they're off, and the ones away from the bulb
are lost in the dark.

1. Today a player finds them by walking in and looking down, or by torchlight.
2. A choice: give a small find a faint glint now and then where the torch or a light catches it
   (as Fortnite's floor loot shimmers and Pokémon's hidden items sparkle), or leave them
   hard to see, which makes them a reward for searching.
3. Default until you say: nothing added; they stay hard to see.

- [ ] Glint on small finds, or leave them for searchers?

## Decide: the camera feed's defaults (S2-02d1-d2, built Nov 14, D-165, D-166; judged by you)

Your idea, first half: as a Mannequin walks up to the breaker, the corner map on every screen
on that floor bursts into snow and grows into a grainy security camera picture of the box's hall
("CAM 07", a blinking red dot); its hand goes up on the grip, the lever comes down, the clunk
comes thin through the camera's speaker, static, and the map is back.
Judged by you in play, Nov 14: "This looks great!" and "the static look is great."
**Check your two fixes** (S2-02d4, built Nov 14, D-168; seen in Studio Play, not on a phone):
1. Stay on a floor until a loose Mannequin walks to the breaker. Look for: the corner map
   snows over with a short, sharp hiss, like a TV between channels, and the hiss sinks into the
   quiet static under the picture as the picture comes up.
2. Watch it pull the lever. Look for: after the clunk, the picture snows over again with a
   second hiss, a little different from the first, ending in a click-off like a TV switched off
   just as the map comes back.
3. Punch the code and get in the car while a Mannequin is still walking to the breaker. Look
   for: the moment the gate shuts, a feed that's up snows over and the map comes back, and
   nothing from that floor shows on your screen for the rest of the ride. If a friend stays
   behind on the floor, their feed carries on.
4. On a phone, check both hisses are loud enough to notice and not harsh.
Still to decide (my defaults, in place now unless you say otherwise):
1. Its hand rests on the grip 0.6 s before the pull (`Breaker.Grip`); the feed cuts in 2.4 s of
   walk before the throw and stays 1.7 s after; the window grows to about one and a half times
   the map; the dev command `ThrowBreakers` shows no feed (only a Mannequin's own throw does);
   a Mannequin turned away by a light or a sound still shows on camera until the feed runs out
   (8 s at most).
2. With the new static in and out, the quiet static under the picture stays, and so does the
   clunk coming thin through the camera's speaker. Say if you want the picture silent between
   the two bursts instead.
3. A Mannequin stops heading for the breaker on a floor everyone has left (it would cut the
   power for nobody), and one already walking there turns away (seen in Studio Play).

## Now: the halls go dark for a wrong code (S2-04c, built Nov 14, D-163; seen in Play, not heard)

A wrong code now puts every hall light on its floor out for as long as the keypad is dead (3.5,
7, 14 s), instead of turning them all on; the car keeps its own lamp. Seen in Studio Play: all
23 hall lights on floor 3 went out for the alarm and came back; a lit tube stuttered out and its
red eye went grey; the freed Mannequin walked through the dark and caught me standing at the
keypad. Nobody has heard the two new sounds or watched it on a screen.
1. In Studio Play on floor 3 (code 2274 on seed 7), walk down a hall so a few lights are on,
   go back to the keypad and punch 1111. Look for: the bell, then the halls drop to black in a
   ragged stutter under a falling power-down whine, while the car stays lit. When the keypad
   clears, the sensors' red eyes stutter back with a faint flash of each tube and a fluorescent
   flicker's sound. Does the floor going black around the car land as the price of a guess?
2. Listen (my picks from the sound library): the cut is "light power off" played a touch slow;
   the return is "Fluorescent light flickering 1". Too much, too little, or wrong?
3. Decide (my default): the lights come back dark, so only where someone moves do they come on;
   a Mannequin the alarm called keeps walking until a light finds it. The alternative is the
   breaker's way, every light on at once when the power returns, which freezes every Mannequin
   on the floor and makes a guess safe again.

## Now: watch every monster come to a wrong code (S2-04b, built Nov 14, D-160; seen in Play)

A wrong code's alarm now calls every monster awake on the floor, however far, and the ones it
lets out stay quiet behind their doors as they roll up. Seen in Studio Play from where each
monster went (one 142 studs off and three just freed all walked to the keypad); not watched on
screen or heard. Do it with the S2-04a test just below, in the same Play.
1. Punch 1111 once and let the Mannequin from Unit 338 come to the keypad and wander off. When
   it's far away down the halls, punch 1111 again. Look for: it turns and walks back to the
   lobby, and the three new ones come straight there too, not to each other's doors. Does a
   lobby filling up over the next half minute feel like the price of a wrong guess?
2. Look at the keypad once they've arrived: they go to one spot and nothing keeps them apart,
   so they likely stand inside each other (each was 4 to 5 studs from the keypad; I didn't see
   it on screen). Tell me if it reads as wrong; spreading them is on my list.
3. Decide (my defaults): a monster chasing someone it can see keeps chasing when the alarm goes;
   a sleeping monster wakes to the alarm only within its 400 studs (its shut door stops it
   anyway); they walk to the keypad at their "going to look" pace, not a run. The alternatives:
   the alarm pulls a chaser off you (a wrong code as a way out), or they run to it.

## Now: punch a wrong code (S2-04a, built Nov 14, D-159; seen in Play, not heard)

A wrong code now rolls up doors with monsters behind them, by themselves, and the keypad stays
dead longer each time on a floor. Seen in Studio Play from Output and the keypad's state;
nobody has listened to it. The halls now go dark for the alarm (S2-04c, above), so the freed
Mannequins come straight on through the dark.
1. In Studio Play on floor 3 (code 2274 on seed 7), punch 1111 at the keypad. Look for: buzz,
   bell, then about a second later a door somewhere rolls up on its own (Unit 338 on seed 7) and
   its Mannequin comes for the keypad. Is the gap between the alarm and the door right?
2. Punch another wrong code once the keypad clears: three doors roll one after another (307, 327,
   335) and the keypad stays dead 7 seconds, the bell striking twice. A third: 14 seconds, four
   strikes. Does the bell striking again sound like an alarm, or like a mistake? Is 14 seconds
   stuck at the keypad fun-scary or just annoying?
3. Decide (my default): a padlocked door holds against a wrong code, as it holds a pounding
   monster, so the third wrong code on seed 7 opened nothing (only padlocked 305 was left). The
   alternative: a wrong code pops padlocks too, which makes guessing far worse.

## Now: hear the sleepers wake (S2-03, built Nov 14, D-156, D-157; seen in Play, not heard)

Four minutes into a floor (less higher up) doors start pounding: no clock, no words. Seen in
Studio Play from Output and the doors' state; nobody has listened to it yet.
1. In Studio Play, walk floor 3 for a bit, then in the Server's command bar run
   `workspace:SetAttribute("WakeSleepers", true)`. Look for: three doors start banging somewhere
   (on seed 7: 307, 327, 338), each blow denting its door a little more. Can you hear them from
   across the floor, and can you tell roughly where? Is it scary or just noise?
2. Wait 90 seconds: each bursts its door up and comes out looking. About two minutes after the
   first wave, more pound (335, and padlocked 305). 305's padlock holds: one last blow, then
   quiet. Does a padlocked one pounding feel like a scare worth having?
3. Then on a phone, a real climb: does the floor stay smooth with six monsters about?
4. Decide (starting guesses, D-156): the first pounding after four minutes on floors 1 and 2,
   15 seconds sooner each floor above, never under two and a half minutes; three doors at a time
   on floors 1 to 3, one more every three floors, up to five; two minutes between waves on
   floors 1 and 2, closing to 75 seconds higher up; at most six monsters moving on a floor at
   once, for phones. The clock starts when the first of you steps onto the floor.
5. Settle one line: the roadmap said "four minutes on floors 1 and 2 (six above)", but the GDD
   says it starts sooner higher up. It was built sooner. Did "six" mean something else?

## Now: the Mannequin cuts the power (S2-02c, built Nov 14, D-155; seen in Play, not heard)

In a real climb a wandering Mannequin now and then walks to the breaker and throws it; nothing
says it's going. Test the feel with the dev command first, then in a real climb.
1. In Studio Play, stand a Mannequin on the test floor (its "Stand one" post), walk away out of
   its sight, then in the Server's command bar run `workspace:SetAttribute("SendToBreaker",
   true)` (STUDIO.md "The breaker" has the steps). Look for: it walks off somewhere that isn't
   you, then the clunk from behind you and the halls die. Shine your torch on it on its way:
   it should stop dead.
2. Go back and switch it on. Look for: is going back through the dark, toward whatever came to
   look at the clunk, the scary trip the GDD wants?
3. Play a few real floors with a friend. Decide (starting numbers, D-155, D-158): how often it
   happens (the first cut on a floor soon, on half a loose Mannequin's wander picks; after that
   about every three minutes per loose Mannequin on floor 1, every minute and a half by floor
   5, every 48 seconds from floor 12); the 45 seconds of light after the power comes on; the
   clunk calling keepers within 110 studs (a slam's reach) rather than the whole floor.

## Now: sleepers are placed with the floor (S2-01, built Nov 14, D-152; seen in Play)

Nothing new to see yet: it's what lets a monster wake, or be let out, behind a door nobody
opened (the next tickets). About one door in ten still opens on a Mannequin asleep.
1. Decide (starting guesses, D-152): 10 in 100 units hold a sleeper whatever the director's
   mood, 20 in 100 behind a padlock; after a chase (Relief) the extra sleepers replace empty
   units, not finds.

## Now: cash on the results (S1-12, built Nov 14, D-151; the save and the board seen in Play)

The coins you haven't spent when a climb ends become cash, saved at once. Back in your car, the
board shows each friend's cash under their photo; yours counts up from $0 with rising ticks and
lands with a jingle. Seen in Studio Play: 42 coins made $42, the save went from cash 0 to 42 and
read back from the DataStore; the board counted +$0 to +$42 in about 2 s. Not with a friend,
not on a phone, and never after a real lobby climb (the test hall has no car of its own).
1. Climb from a lobby car with a friend, keep some coins, and end it (top or kept). Look for:
   your figure counts up under your photo with ticks and lands with a jingle; your friend's
   counts in silence; the numbers match what your coin counts showed.
2. Rejoin later: nothing shows your total yet (it's in the save; the lobby will show it once cash
   buys something). On a phone: does the board's cash line read from the front of the car?
3. Decide (starting guesses, D-151): one coin is one dollar (`Cash.PerCoin`); leaving a climb
   before it ends makes no cash; cash is shown as dollars ("+$42").

## Now: find the faint mark (S1-11, built Nov 14, D-150; sampled in Play, never seen with a friend)

On one note's door, a small chalk ring with a dot sits on the left side of the door frame,
shown only when your own torch is on it from about three steps. Sampled in Studio Play on
floor 1: hidden with the torch off; fullest (70% solid) from 4 studs straight on and from 4
studs down the hall; part-shown at 7.4; gone with the beam 37 degrees off. Seen on screen once.
To test: start a climb (floor 1 and 2 always have one).
1. Walk the halls with your torch on, sweeping the door frames. Look for: one frame shows a
   faint ring as your beam crosses it close up, and nothing from across the hall or with the
   torch off; it fades in rather than popping. Open that door: a note is inside.
2. On a phone: is it findable when your beam crosses it, and easy to miss otherwise? Does it
   read as that door's (it sits on the jamb beside the neighbour's)? Too faint or too plain?
3. Decide (starting guesses, D-150): floors 1 and 2 always marked, 6 floors in 10 above
   (`Deal.MarkShare`); the mark is a chalk ring with a dot; never on the guarded note. The
   precedent is Phasmophobia's fingerprints under the light you hold (from memory).

## Now: buy at the machine (S1-10c2a-b, built Nov 14, D-148, D-149; real buys seen in Play)

Bolt cutters and a battery bought in Studio Play by pressing E, sampled frame by frame: the coins
left the count one at a time (40 down to 30, never jumping) and reached the slot; the thing
dropped, then flew to the hand; the tool appeared in view only as it arrived; the torch's ring
stayed where it was until the battery reached it, then swept full. Not seen by eye or heard,
and never with a friend. To test: start a climb, earn coins on floor 1, ride up with a friend.
1. As the prices light, look at a button: its Buy names the thing. Press it. Look for: the
   button sinks with a click; your coins leave the count in the corner one by one, the number
   ticking down, and drop into the machine's coin slot with a clink each; the coil turns with a
   whine; the thing drops behind the flap with its clunk; the flap knocks; the thing lifts out
   and flies into your left hand (it's simply there, no swing up), or a battery into your torch,
   which then fills.
2. Your friend watches: same coil, drop and flap, and the thing flies to your hand on their
   screen; your new tool isn't in your hand on their screen until it gets there.
3. With a full torch, the battery buttons show no Buy. Press something you can't afford: one
   dull buzz and its price blinks. Nothing else.
4. Judge the sounds and the pace: does paying read before the drop, and does the flight to your
   hand feel quick enough (about half a second)?

## Now: see the machine's stock (S1-10c1, built Nov 14, D-147; seen staged in Play)

On every ride after the first, the machine is now full: as each row's tube first flashes, its
coils are suddenly holding things (two batteries in each bottom coil; above them three or four
tools, a different lot each ride, one coil empty when there are three), and as the tube catches
its price windows flash 88 and settle on the prices. All of it goes as the gate opens. You can't
buy yet (that's next).
- [ ] **The prices are my guesses; say if any is wrong.** Battery 3, bubble wrap 5, padlock 6,
  air horn 7, saw 8, bolt cutters 10 (the padlock and bolt cutters are the design doc's). A
  player boards the second ride with about 15 to 25 coins. (`Machine.Stock.Prices`)
- [ ] **How much it holds is my guess too:** two batteries in each of the two battery coils (4 a
  ride, one each for a team of four), one of each tool, three or four tools half the time each.
  The ladder isn't sold (it doesn't fit a bay). (`Stock.Batteries`, `Stock.FourShare`)
- [ ] **On a phone, ride from floor 1 to 2:** can you tell the tools apart through the glass
  from the gate? Does the light finding them row by row land, or read as a glitch?

## Now: watch the machine wake (S1-10b2, built Nov 14, D-146; seen lit and dark in Play)

Every floor's car now has the vending machine in its back-right corner. It sleeps on the first
ride (up from the lobby) and wakes on every later one: the tubes tink and flicker on a row at a
time from the bottom, the sign buzzes on, the price windows light (now the prices, S1-10c1), a
hum fills the car and a cold light spills across it. It dies as the gate opens.
- [ ] **Ride from floor 1 to 2** (Workspace's `DevFloorNumber` = 1 before Play): does the wake
  land as a moment after the lurch? Are the tink, the sign's buzz and the hum loud enough over
  the motor, or too loud? (`Machine.Tink`, `Buzz`, `Hum` volumes are first guesses.)
- [ ] **On a phone:** does the lit sign bloom into a blob, and can you read the bays through the
  glass? The bays have no light of their own (a second light blacked out the car).

## Now: ride for 20 seconds (S1-10a, built Nov 14, D-144; the sound loops seen in Play)

The ride between floors now takes about 20 seconds, as the design doc says, so there's time to
use the vending machine coming to the car next. The car grinds up slowly (about a stud a second)
with three cable clanks; the first ride from the lobby looks as before, since its middle is the
teleport's black.
- [ ] **Ride from floor 1 to 2** (Workspace's `DevFloorNumber` = 1 before Play, or a real
  climb): does 20 seconds feel like a tense breath, or dead time before the machine exists? Does
  the shaft creeping past the gate read as a slow old freight car? Is the motor's loop seamless?
- [ ] **Left behind:** you now stand in the dark lobby, frozen, hearing the car grind away for
  about 9 seconds before the black comes down (it used to go black at 4 s). Does it land, or drag?

## Now: take a battery (S1-07b, built Nov 14, D-143; a take seen in Studio Play)

About one unit in ten now has a battery lying on its side in the bulb's light: a chunky D-cell,
black with an amber band, a plus and a lightning bolt on it, a faint glint on its steel end. Once
your torch's ring has lost a tick, it shows a Take button; tap it and the battery hops up end over
end and flies into your torch with a clack and a click, and the ring sweeps round full. While your
ring is still full there's no button for you: it stays for a friend. A dead torch isn't switched
on by it; you press the button and it lights, full. I checked the rules load in Studio and the
art is in the place. In Play I took one (the server logged it, the ring went from 27 seconds
left back to full) but didn't watch its flight. Look sheets: `art/sheets/battery-*.png`.
- [ ] **Take one:** add `DevTorchSeconds` = 60 on Workspace (as below), Play, switch your torch on
  for 10 seconds, then open units until one holds a battery. Does it read as a battery from the
  doorway on a phone-sized window? Does the Take button show? Tap it: does the flight into your
  hand and the clack-click feel like a fresh battery going in? Is the ring full again?
- [ ] **Leave one:** with a full ring (torch never switched on), the same battery shows no button.
  Does that feel natural, or like it's broken?
- [ ] **With a friend:** do you see theirs fly into their hand and hear it from close by?
- [ ] **The rule (my default):** a battery is taken only once your ring has lost a tick (about
  25 seconds of light used). Say if a torch should take one whenever it isn't exactly full.

## Now: the flashlight runs down (S1-09, built Nov 14, D-142; seen in Studio Play)

Your flashlight now runs down while it's on: about five minutes from full, full again at the
start of each climb. A ring of 12 small ticks round its button (bottom right of the screen on a
computer, over the jump button on a phone) goes out one tick at a time; the last ones turn red and
breathe. For its last half minute the beam flickers: one long stutter as it starts, then short
ones far apart that come closer and go darker, with a bulb's buzz in your hand each time, while
the light dims and browns. Then it fades to nothing and clicks off by itself. Pressing it while
it's dead only gives a soft dull click, the torch dips in your hand and the button wobbles. I saw
all of that in Play with a 40-second torch; nobody has heard it yet.
- [ ] **Run it down** (fast): in Edit, select Workspace and add a number attribute
  `DevTorchSeconds` = 40, then Play and switch your torch on (right click). After 10 seconds it
  starts to flicker. Does the first stutter make you look? Does the buzz sound like a dying bulb
  or like noise? Does the end feel like losing your light? Remove the attribute after.
- [ ] **On your phone:** can you read the ring at a glance, and tell red ticks from white ones?
- [ ] **With a friend:** does their beam flicker and buzz when theirs is dying?
- [ ] **The numbers (my defaults, in `Charge.luau`):** five minutes full, half a minute of
  flicker. Say if the flicker should start sooner or later.

## Now: wear a tool out (S1-08, built Nov 14, D-141; passes checks, the break untested in Play)

Tools now wear out, as Minecraft's do: bolt cutters cut 3 padlocks, the saw cuts 2 holes, the air
horn gives 3 blasts. A row of small notches along the foot of the tool's box (and its slot on the
wheel) shows the uses left; the last one turns red and breathes. On the last use the tool breaks
a beat after the job is done: the cutters' jaw cracks just after the padlock snaps off, the
saw's blade snaps just after the panel drops, and the horn's last blast sags and dies, then you
shake the empty can and toss it. The tool jumps out of your hand, bits fly, it clanks on the
floor, lies there a moment and fades. In my Play check the notches and the break's plumbing
were built, but I couldn't get a cut done from the MCP before my session ran out, so you're the
first to see a break.
- [ ] **Break the cutters** (dev floor; bolt cutters lie in Unit 323): cut the padlocks on 305,
  320 and 329. Watch the notches on the box under your thumb go 3, 2, then one red one. On the
  third cut: the padlock snaps off, then the cutters crack, jump out of your hand and clatter on
  the floor with bits flying; your view kicks and the box bursts red and shrinks away. Does it
  feel like losing something, and did the red notch warn you?
- [ ] **Blow a horn dry**: three blasts. Does the last one sag and die like a can running out,
  then the can rattle and get tossed?
- [ ] **Saw two holes** with one saw: the blade snaps a beat after the second panel drops.
- [ ] **With a friend:** do they see your tool break in your hand, its bits, and hear it?
- [ ] **The numbers (the design doc's starting guesses):** cutters 3, saw 2, horn 3. The
  padlock and the bubble wrap are used up whole as they're placed, so they show no notches; the
  ladder never wears.

## Now: cut a padlock (S1-07a, built Nov 14, D-140; seen in Studio Play)

A padlocked unit now always holds a find or a tool, never nothing. About 3 in 10 also have a
Mannequin standing in there with it, asleep (or, now and then, awake and facing the door). Tools
are rarer everywhere: about one unit in twelve, down from one in five. On the dev floor (floor 3,
seed 7) all five padlocked units happen to have a Mannequin; I cut 305 in Play and saw the TV in
the bulb's light with the Mannequin standing right behind it, and a coin.
- [ ] **Cut a padlock** (bolt cutters lie in Unit 323 on the dev floor): cut Unit 305 and open
  it. Is it worth the cutters, and does the Mannequin behind the TV make you stop in the doorway?
  Take the TV past it. Then 320: its Mannequin is awake and comes out at you.
- [ ] **Judge the rarer tools** over a few floors: does a tool now feel like a good find, and do
  you still find bolt cutters often enough to open padlocks? (The machine on the ride, S1-10,
  will sell them.)
- [ ] **Decide (default in place):** the design doc says a padlocked door "always has something
  good" and "the highest chance of a monster". I read that as both at once: the find or tool is
  always there, and a monster sometimes stands with it. The other reading is that the monster is
  instead of the good thing. Say if you meant that.
- [ ] **The numbers (my defaults):** in a padlocked unit a find 7 in 10, a tool 3 in 10; a
  Mannequin with it twice as often as behind an ordinary door (about 3 in 10). Ordinary doors:
  a tool 6 in 100. Finds have no grades yet, so "something great" is just a find for now; it
  gets the better grade when finds have grades.

## Now: judge the gate's pay and keeping (S1-06, built Nov 14, D-138; the screen seen in Play)

As the gate slams with you aboard, a handful of coins clatters, coins burst out over the middle
of your screen and pour into your count, and a gold "+10" shows by it. Any find in your slots
rises out of them on a dark gold-rimmed disc, glints, and flies up off the screen: it's yours,
saved, and the slot is free. Friends see the find in your hand go in a spark. A wrapped friend
gets nothing. I saw the screen's side in Play by sending the message by hand, and a real ride
paying 10 in S1-02 (with no find in a slot).
- [ ] **Ride with a find:** take the teddy from Unit 326 (dev floor), punch the code, board, and
  watch the slam: coins, "+10" (floor 3 pays 14), the teddy rising out of your slot. Then leave
  and rejoin: Output's `[Saving]` line, and `GatePay:` says what you kept.
- [ ] **Judge on your phone:** do the coins and the rising find read over the car's gate, and is
  it too busy with the slam and the ride's sounds?
- [ ] **The numbers (my defaults):** 10 coins on floor 1 and 2 more each floor. The design doc's
  "a quarter more for each trapped monster" and "a harder floor pays more" are not built: say if
  you want either.

## Now: carry a find (S1-05, built Nov 14, D-137; take, drop and catch seen in Play)

A unit's find (the teddy, the TV, the boombox, the skates) now has a Take prompt. One tap puts it
in a slot and in your hand, and it feels heavy: it comes up slower, sags as it lands and sways
as you walk, the TV most.
- [ ] Play floor 3 (seed 7): open Unit 326 (the teddy) and cut Unit 305's padlock (the TV, a
  Mannequin asleep behind it; bolt cutters in 323). Take each on a phone.
  Does the weight read: the TV hauled up and sagging, the teddy light? Is it in the way of the
  hall? Its place in your view was moved lower and further left after one look, and that new
  place hasn't been seen yet.
- [ ] Drop it (Drop button), take it again, and have a friend look at you holding it: it hangs
  from your left hand by its handle or top. Get caught carrying one: it should drop where you
  fell, standing, for a friend to take.
- [ ] Listen to each find's take and drop sound (plastic clack, heavy thud, soft cloth, wheels).
- [ ] **Decide (default in place):** a find doesn't slow you; its weight is only felt in your
  hands. Lethal Company slows you by what you carry. Want carrying the TV to slow you a little?
- [ ] **Decide (default in place):** the TV's name on screen is "TV".

## Now: look at the stuff in units (S1-04b1 and b2, built Nov 14, D-135, D-136; seen in Play)

Some units with nothing to take now show somebody's stuff when the door goes up: an old stained
mattress, a rolled rug, or boxes stacked as a tower, a wall, a heap or a column, pushed into a
back corner.
- [ ] In Studio set Workspace's `DevFloorSeed` to 104 (put it back to 7 after), Play, and open
  units 309 (a heap of boxes), 311 (the mattress), 315 (a wall of boxes), 329 (a tower) and 332
  (a small unit: the rolled rug). Look from the doorway on a phone: does each read at once? Walk
  in and try to squeeze behind the mattress (you shouldn't fit).
- [ ] **Decide (default in place):** half the units with nothing to take hold stuff, half stay
  bare. With today's deal that's about 2 units a floor with stuff and 2 bare. More stuff, fewer
  bare ones? (`Deal.StuffShare`)
- [ ] **Decide (default in place):** the rolled carpet stands on its end against a wall, because
  lying on the floor it read as a thin line from the doorway. Say if you want it lying down.

## Now: judge S1-04a, coins (built Nov 13 and 14, D-132, D-133; the take verified in Studio Play)

Most doors now pay one to three coins lying in the bulb's light with a twinkle on them. Tap
Take: the coins jump, stand up on their edges spinning and are gone with a chink; on your
screen each one flies up to the little count at the right end of the top bar, which ticks up
one at a time and swells. Verified in Studio Play (Nov 14): a pile of two laid in a unit, taken,
both coins flew, the count read 2 and the pile was gone. Not heard by ear: the sounds.
- [ ] **Judge on your phone:** does a pile read from the doorway (the coins look coppery under
  the warm bulb; gold enough)? Is the count's place, right end of the top bar, clear of
  Roblox's buttons and the corner map? Is the take quick and satisfying, or too fast to see?
- [ ] **Listen:** the chink at the pile (a friend up to 30 studs away hears it too), the jingle
  under it for two or three coins, and the ticks rising as each coin lands in your count.

## Now: see the records on the dashboard (S1-02, built Nov 14, D-139; verified in Studio Play)

Nothing shows in the game. Studio sends no records on, so they reach the Creator Dashboard only
from the published game, and Roblox's charts can take a day to fill.
- [ ] Publish, play a climb (open a few units, take coins, ride once), then on the Creator
  Dashboard look under Analytics: Economy shows Coins earned from `pile` and `gate`; Custom
  Events show `doorOpened` (split by `gave`), `firstDoor`, `carLeft`; Funnels show `climb`;
  Progression shows the `climb` path's floors. Say if any is missing.
- [ ] **Decide (default in place):** the wait from joining to the first door is recorded in two
  halves (lobby to car leaving, arriving to first door); carrying the lobby time through the trip
  would make it one number. Say if you want that.

## Now: judge S1-01, saving (built Nov 14, D-134; verified in Studio Play)

Nothing shows on screen; you check it in the server's log. Studio's saves are kept apart, in
`Saves.studio`; live servers use `Saves`.
- [ ] Publish (File > Publish to Roblox), join, press F9 and pick Server: one line,
  `[Saving] made a new save for player_<your id>` the first time, `claimed` after that.
- [ ] Step into a lobby car and ride to floor 1. On your group's server, F9 > Server shows
  `claimed player_<your id>` within about 5 seconds of arriving (the lobby lets go first). Leave;
  join again: `claimed` again, never a kick.

## Decide: coins, whoever taps first (S1-04a, D-132; default in place)

Each unit with coins has one small pile of one to three, and one "Take" button. Whoever taps it
first gets the whole pile, as DOORS' gold goes to whoever grabs it; each player's count is their
own. The other way: everyone who's near when it's taken gets the same coins (no racing friends).
- [ ] **Decide:** first come, first served (the default), or shared?

## Now: judge S1-03, fewer units (built Nov 13, D-131; counts verified in Studio Play)

Each floor now keeps about half its doors: about 30 on floors 1 and 2, about 40 above, with
stretches of plain wall where the rest stood. A hall side's doors go together, so you see blank
wall and then doors side by side. Every wing keeps some doors, the first 8 doors past the lobby
on floors 1 and 2 all stay (the row that teaches sawing between neighbours), and no more than 4
hall pieces in a row go by with no door on either side. Counted in Studio Play (Nov 13): floor 1
laid 29 units, floor 3 laid 40.
- [ ] **Walk a floor on a phone-size view:** does a long stretch of blank wall read as built that
  way, or as doors gone missing? Is a wing with only two or three doors still worth the walk?
  If the walls read as missing, ROADMAP's polish list has dressing for them.
- [ ] **Decide (defaults in place):** (1) about 30 and 40 (`Floor.Plans`, `units`); (2) the
  first 8 doors past the lobby always stay on floors 1 and 2 (`Floor.TeachDoors`); (3) at most 4
  hall pieces in a row with no door (`Floor.BareMost`); (4) a side's doors go together (all
  doors or all wall), never one door alone in a stretch of wall.

## Now: judge L-08e3b, Share and follow (built Nov 13, D-130; the panel seen in Studio)

In Studio Play (Nov 13) the car's panel shows Invite, Share and Go across its bottom, and Share
reaches the server, which asks Roblox for the link; Studio refuses it (HTTP 403), as it does
everywhere but a live server. Everything below needs the published game.

Needs Rojo connected, then File > Publish, and two accounts that are friends (A plays, B waits).
- [ ] **Sent on to your friend:** A rides a car up (their own server), finishes the climb, and is
  back in the car. A taps Invite (it shows there now) and invites B. B taps the invite: B lands
  in a public lobby, then within a few seconds the screen goes black with "Joining" and A's
  name, and opens in A's front office, A's car glowing for B. Tell me how long B saw the public
  lobby before the black, and anything odd in between.
- [ ] **The floor back home:** A and a third account C stand in the same public lobby. A rides
  up alone. C watches the car A left from: "Going up", then once it's back in its bay, "Floor 1",
  "Floor 2" as A climbs (a second or two late), gone when A's climb ends. Does it read?
- [ ] **Share:** in a car, tap Share: Roblox's share sheet (phone) or a "copied" note (computer).
  Open the link on B: B lands in the game (and, from A's own server, is sent on to A).
- [ ] **Decide:** should a friend be able to join a climb under way, stood beside you on your
  floor (ROADMAP L-08e3c)? Hits like DOORS don't allow it. My default: no, they wait in your
  lobby; and an invite sent from a public lobby car before you leave doesn't follow you up yet.


## Now: judge L-08e4a, the carts in the rack (built Nov 12, D-125)

Six orange platform carts now stand nose-in in the rack by the front door, handles to the room,
each a little off square with its front casters turned every which way. Verified in Studio Play
from the spawn and up close (`docs/art/L-08e4a-*.jpg`); a phone is yours. They don't move yet
(the ride is L-08e4b).
- [ ] **Look:** from where you load in, turn to the rack on your phone: do they read as real
  carts you'd want to grab? Walk up: the mat, the grip, the casters.
- [ ] **Bump them:** walk into a cart and step onto its deck: nothing to snag on (the handle
  doesn't block you yet).
- [ ] **Decide (default in place):** the carts' colour, worn safety orange (`art/cart/spec.py`
  `ORANGE`; a rebuild and upload changes it).
## Now: judge L-08e4b1, riding a cart (built Nov 12, D-126)

Walk up to a cart in the rack and tap Ride: you're stood on its deck facing the handle, your view
swinging round to the room. Push forward and it heads where you look, your back leg kicking in
rhythm (a scuff and a dip of your view each kick); let go and it coasts; push back to drag your
foot. A wall or a cart head on: a clank, a jolt and a dead stop; along a wall at a slant, a
scrape. Jump hops you off and the cart rolls on a moment; ride onto a car's yellow stripes and
you're put off there. Verified in Studio Play on a computer: out of the rack and round a curve,
five kicks to 21 studs a second, the rattle rising, a clank at the wall, a turn off it, Jump, the
coast and the park, the stripes. A phone and two players are yours.
- [ ] **The feel, on your phone (Publish first):** the kick's rhythm (one every 0.55 s while you
  hold), the top speed (cruising about 22; a walk is 16), the coast (about 45 studs), and "it
  goes where you look" with the thumbstick in one thumb and turning the view with the other.
  Too slow, too twitchy, too floaty? Name it and I'll tune the numbers (`Cart.Ride`).
- [ ] **Hopping off on a phone:** does the jump button still show while you ride, and hop you
  off? Is the hint ("Hold forward to roll", "Jump to hop off", once a session) readable over the
  tool bar and gone in time?
- [ ] **Two riders:** with a friend, each ride a cart. Do you see their back leg kick, their
  wheels spin and casters swing, and hear their rattle and scuffs? Ride into each other and into
  a friend standing: a clank and a stop, nobody launched.
- [ ] **Decide (defaults in place):** (1) you stand facing the handle and it rolls handle first,
  like a kick scooter (the carts park handles out); (2) it heads where you look, no A and D
  steering; (3) a car's stripes put you off, and until L-08e4b2 the cart waits there; (4) while
  riding your hands hold the torch out, not the handle (goes with whether the torch is out in
  the lobby at all).

## Now: judge L-08e4b2, the cart rolling home (built Nov 13, D-129; verified in Studio Play)

Hop off a cart at a car's yellow stripes and, a moment later, it rolls back to the rack by
itself, casters rattling, curving round to line up and easing nose first into a free slot with
a soft clunk. Facing away from home, it first swings round on the spot. Leave a cart anywhere
else and it goes home after 20 seconds. Stand in its way and it stops short and waits, then
rolls on once you step aside. Verified in Studio Play (Nov 13, one player, from the logs): four
rides to the stripes, each cart off about 1.2 s after you're put off and in its slot about 7 s
later; one left mid-room went home 20 s after it parked; stood in its way, it stopped about 2.4
studs short and rolled on 0.75 s after you stepped aside. A bug found there is fixed: standing
still where you got off held your own cart for 12 s, then it popped into the rack. Left for you:
how it looks and sounds, the swing on the spot, and two riders.
- [ ] **Watch it in Studio Play (Rojo connected):** ride a cart onto a car's stripes. About a
  second and a half after you're put off, the cart sets off. Does it curve smoothly and nose
  into a slot between the hoops without clipping them, and stop with a clunk? Its front casters
  should flip round as it starts. Output should show no "has no way home" line.
- [ ] **Leave one mid-room:** Jump off halfway across. After 20 seconds it rolls home. Leave
  one facing the cars: it swings round on the spot first.
- [ ] **Stand in its way:** it stops a stud or two short of you, waits while you stand there,
  and rolls on about half a second after you step aside. Stand there 12 seconds and it gives up
  and appears in its slot (a jump, but rare).
- [ ] **Two riders at once (with a friend):** both hop off at the stripes. Do both carts get
  home, each to its own slot, without stopping for each other forever?
- [ ] **Decide (defaults in place):** (1) it goes home nose first, the way it already faces
  after a ride out of the rack (the last handoff said handle first; nose first needs no turn
  round in the usual case); (2) 20 seconds before a cart left out goes home (`Home.Wait`);
  (3) it rolls at 7 studs a second, slower than a walk (`Home.Pace`); (4) held up 12 seconds,
  it's put straight in its slot (`Home.GiveUp`); (5) nobody can ride it on the way home.

## Now: judge L-08e2, back in your car (built Nov 12, D-123)

At the end of a climb, "Again" brings your group back standing in the car you left from, in your
old order with the host's choices kept, facing the results on its back wall ("Caught" or "Made it",
the floor and time, everyone's photo with the floor they were lost on), and the count runs 20 s
for another go. Anyone can step out and back in; the results stay on the wall until the car next
leaves. On your group's own server its six cars open at that moment, and your next climb rides
up from there. Verified in Studio, one player: on Studio's own server (ride up from car 3, a wipe,
Again, back in car 3, out and in, ride again) and on a group's own server (`DevTrip` "Arrive":
back in car 1, ride again on that server); a four-friend "Made it" board faked on a car to judge
its look. The place was saved as version 35 so Studio's test teleport ("Send") runs this code.
- [ ] **Alone, live:** join, ride up, lose, press Again. The black lifts on the
  car's back wall: your photo, the floor, the time; the count pops in with the chime. Step out,
  back in, let it go: it rides up to a new floor 1 on the same server.
- [ ] **With friends:** two or three in one car, ride up, end it, Again. You're all back in the same
  car, the host in front, nobody else from the lobby with you, the same Friends only and player
  count on the panel. Is 20 s the right time to take in the wall?
- [ ] **Your phone:** the board from the front row and from the back row (two rows of three: the
  host's row nearer the wall) reads at phone size; the photos and names aren't too small.
- [ ] **Known:** the lobby car's lamp burns very dim in its bay (about a tenth of its brightness,
  cause not found yet), so the car's walls read black round the lit board. It was so before
  L-08e2 too; it's in HANDOFF's Seen list.
- [ ] **Decide (defaults in place):** (1) Again stays as the one button and now leads back to your
  car ("Back in 10" counts down for a friend who hasn't pressed), so there's one press, then the
  car's own count; the other way is no button, everyone back in the car once the results have
  shown. (2) You come back facing the results, so you turn round to step out. (3) After the climb
  your group stays on its own server (its own lobby, the six cars, nobody else): strangers can't
  join you there; a friend you invite from there is sent on to you (L-08e3b, above).

## Now: judge L-08e1c, a server of the group's own (built Nov 12, D-122)

At zero the car's group goes to a server made for them, as DOORS' lobby elevators do: the gate
slams, the car moves off, the screen sinks to black ("Going up"), and it opens on the same ride,
the shaft sliding past, levelling on floor 1 of a building only yours. Verified in Studio, one
player: the ride on Studio's own server as before; the arrival (Workspace `DevTrip` = "Arrive");
the whole trip through Studio's test teleport ("Send"; the place was saved as version 34 for it,
never published); two failed trips ("Fail"), each back in the car with "Teleport failed" and the
count again, then the third ride on the lobby's own server. Live servers, friends and phones are
yours: Publish first (Save alone doesn't change live servers).
- [ ] **The trip, alone:** join, step into a car, Go. The gate slams, the car starts to climb,
  black with "Going up" a beat later, Roblox loading, then you're in a car mid-ride facing the
  gate, the shaft sliding past; the brakes, the bell, the gate opens on floor 1. No front office
  flash as you arrive, no long black (it waits 10 s at most for friends).
- [ ] **With friends (two accounts or a friend):** both in one car, Go. You arrive together in
  the same car (host at the front middle), nobody else from the lobby with you. A second car's
  group, sent at the same time, gets its own server (you never see them).
- [ ] **Someone stays behind:** a third player in the lobby (not in the car) keeps the lobby and
  its cars, and can take another car to a server of their own.
- [ ] **The climb runs on it:** play floor 1 to the code and ride up; at the end, "Again" puts you
  back in your car on the same server (L-08e2, above).
- [ ] **A failed trip** (rare live; Studio's `DevTrip` = "Fail" shows it): back in the car, the
  black lifting, "Teleport failed" in red, the count running again with the same host.
- [ ] **Your phone:** the black comes down evenly, "Going up" readable, the arrival not a long
  stare at black on a phone that loads slowly.
- [ ] **Decide (defaults in place):** (1) someone whose trip failed while friends went goes back
  in the car and the next trip makes a new server: they don't follow their friends (they could:
  reuse the same server for a minute); (2) the group's server waits for everyone or 10 s after
  the first, then goes; a later one is stood on floor 1 in front of the car as it opens; (3) after
  two failed trips in a row a lobby stops sending and rides its groups up on its own server, as
  before; (4) "Going up" under the black (GateClock already says it as a car leaves).


## Now: judge L-08e1b2, the host's panel (built Nov 12, D-121)

The first one into a car hosts, as in DOORS' lobby: a "Host" button inside the car, beside the
gate on the keypad's side, opens the panel: Open or Friends, the player count (1 to 6, its six
seats filling as friends step in), the difficulty (Normal, the only one) and Go. Verified in
Studio on a computer, one player: the panel opens on E, Friends and 2 players land on the car,
the gate shuts and the ride runs to floor 1 with them; Go shuts the gate at once and the ride
runs; a held count (another climb on) greys Go; the greyed view and the "Friends only" headline
checked on this screen alone (shots `docs/art/L-08e1b2-*.jpg`). Two players and a phone are yours.
- [ ] **Host:** step into a car; a "Host" button by the gate's left edge (E, or tap it). The panel
  slides in on the right: "You host", Open / Friends, the count with its seats, Normal, Go. Each
  tap dips its key with a click; the switch's light slides, the count pops. Below those aboard
  the minus does nothing (a dull click); at 6 the plus does nothing. × (or E, or B) closes it.
- [ ] **Go:** with the count running, Go: the panel slides away and the gate slams at once, the
  ride, L to 1, floor 1.
- [ ] **With a friend (Team Test, two players):** the second one in gets "View": the same panel,
  greyed, "<your name> hosts", their taps dull. Change a choice as host: their open panel answers
  at once. Step out as host: they host now (their button says "Host"), your choices kept.
- [ ] **Friends only, a stranger:** host sets Friends; a player who isn't your Roblox friend walks
  in and is set down outside the gate, facing the room, with "Friends only" in red. A real friend
  walks in as normal (asking Roblox takes a moment: they may stand inside a beat first).
- [ ] **Car full:** host sets 2; a third walks in and is set down with "Car full". With 2 aboard
  the count drops to 5.
- [ ] **Your phone:** the "Host" button reachable from anywhere in the car, the panel right of
  the middle and clear of the jump button, every key an easy thumb.
- [ ] **Decide (defaults in place):** (1) the difficulty tiers' names and how many (the GDD's
  auction-board tiers aren't named; the panel shows "Normal" alone till then); (2) the button sits
  inside the car on the keypad's side, as the keypad itself faces the room and can't be reached
  from inside; (3) a stranger turned away is set down outside at once with a headline, as DOORS
  puts you out of a full elevator (untested bet if you remember DOORS differently); (4) the
  choices stay with the car when the host steps out, and go back to Open and 6 once it's empty;
  (5) the host can't set fewer players than are aboard.

## Now: judge L-08e1b1, step in and the count (built Nov 12, D-120)

The lobby's cars are the way into a climb now, as DOORS' lobby elevators are. Verified in Studio
on a computer, one player: you load in facing the cars, stepping into car 3 starts its count,
stepping out stops it, at zero the gate slams, the ride runs and you're on floor 1 of a fresh
climb (shots `docs/art/L-08e1b1-*.jpg`). Friends, a full car and a real phone are yours.
- [ ] **Load in:** Play. You stand just inside the glass door with the six cars ahead and the
  camera looking at them. In Studio the test hall's climb is laid too; its "Test hall" post is by
  the door (E).
- [ ] **Step in:** walk into any car. The chime, and the count pops into the top bar, green, from
  20. The readout on the car's keypad counts with it (the keypad itself doesn't open any more).
  Step out: the count leaves your screen and, with nobody left aboard, the readout goes back to
  dashes. Step in again: 20 again.
- [ ] **The last sprint:** from 10 it's red, the car's lamp blinks and the heartbeat starts; the
  bell on each of the last five. At zero the gate shuts with the climb's slam; the ride, the
  counter going L to 1, and the car opens on floor 1 of a fresh building. Step out within 6 s or
  the gate shuts you in, as on every floor.
- [ ] **With a friend (Team Test, two players):** both into car 3: one count, both clocks. One
  steps out: the count runs on for the other. Both ride and arrive together. A friend in another
  car while you climb: their group forms but their count waits until your climb is over (one
  climb a server, until L-08e1c gives each group a server of its own).
- [ ] **A full car (six players):** the count drops to 5; a seventh is set down outside the gate
  with "Car full" (L-08e1b2).
- [ ] **Your phone:** the count in the top bar and the keypad's readout from the room's middle.
- [ ] **Known, where a climb rides up on the lobby's own server (Studio, or after failed trips):**
  everyone on the server counts in the climb's end, even someone who stayed in the lobby. Since
  L-08e2 "Again" puts the climb's group back in their car and anyone else at the front door.
- [ ] **Decide (defaults in place):** the keypad beside each car stays, its readout the count
  (the host's panel is a button inside, L-08e1b2); 20 s and 5 s (`Boarding`); the car back
  in its bay 12 s after it left; a held count starting again from 20 once a climb ends.

## Now: judge L-08e1a, the front office (built Nov 12, D-119)

The lobby's room, built and laid on every server 600 studs from the test hall: Everkeep's front
office at night, six lit freight cars along the back wall, numbered 1 to 6, their gates folded
open; the counter and shelves to the left of the door, the cart rack to the right (the cars are
the way into a climb since L-08e1b1). Verified in Studio on a computer and
the Galaxy A16 view (shots `docs/art/L-08e1a-*.jpg`); a real phone is yours.
- [ ] **Get there:** you load in there now (L-08e1b1), just inside the glass door. From where
  you land, on your phone too: do the six cars read as "go there" at a glance? Can you read the
  numbers?
- [ ] **Walk it:** the counter and its shelves (boxes on them), the empty cart rack, the striped
  zone before each car, into a car and out. Run into the walls, counter, shelves and rack: nothing
  to fall through or snag on. "Come back" by the door (E) returns you to the test hall.
- [ ] **A real low-end phone:** the frame rate standing at the door looking at all six cars (the
  dev console's Performance tab). The room's real lights: two fills, a porch light outside, the
  six cars' lamps.
- [ ] **Decide (defaults in place):** Everkeep's colours (teal wall panels, the counter's front
  cream; `Lobby.Paint`); the room's size (120 by 48: room for the cart ride, but bare for now; a
  floor plan board, a bench and the like are on the polish list); the hall lights' eyes in the
  office shut (no keeper watches it).

## Now: judge L-16d, the tops at your computer's full frame rate (built Nov 12, D-118)

The jitter's cause: your body moved only with physics, 60 times a second, while a fast screen
draws 120 or 144, so the view held a place for two or three frames, then jumped. Now your body
is placed every drawn frame just before the camera, by that frame's own time. Measured in Studio
at 15 frames a second only (it can't be brought to the front from a script): every frame moves
its share, your eye holds one height lying still, and the server put nobody back crawling flat
out under simulated 4G and bad 3G. The full rate is yours to judge.
- [ ] **On your computer, Studio in front** (or the live game), climb onto the tops and crawl:
  straight, then turning with the mouse, then along a run and round a junction. It should glide
  as walking the hall does, with no stutter. If your screen goes above 60 (Roblox's menu, Max
  Frame Rate), try 120 or 144 too. Still a stutter? Say whether it's while crawling straight, while
  turning, or only climbing the ladder.
- [ ] **On a live server** (published), crawl flat out along a run and back: you should never be
  snapped back a step. A snap means the server's crawl check (`Tops.Slack`, `Tops.LagStuds`)
  needs more room for real lag.

## Now: judge L-17, every button on a phone at once (built Nov 12, D-117)

On the Galaxy A16 in Studio: opening the wheel by a door now makes the door's buttons fade out
under it (they came back as it shut); kept in a unit, the screen holds only the Bang button, the
map and the thumbstick (the empty wheel slides off the bottom, the torch switch goes with the jump
button) and both come back when you're cut free; on a computer, Q at a shut door peeks and leaves
the wheel shut. Shots before and after: `docs/art/L-17-*.jpg`.
- [ ] **On your phone**, at a door, tap the wheel: do the door's buttons fading out read as "the
  wheel has the screen", or would you rather see them dimmed behind it?
- [ ] **Get kept on your phone** (a friend, or the catch in Studio): mash Bang with your thumb.
  Nothing else is near it now; does the empty corner where the torch switch was feel right? Get
  cut free: the wheel should rise back up from the bottom.
- [ ] **On a computer**, at a shut door press Q: you should peek only. Step to an open door and
  press Q: the wheel opens and Close and Slam fade out.
- [ ] **Decide, defaults in place** (D-117): (1) **Kept, your torch can't be switched** on a phone
  (its button goes so a mashed Bang never flicks it; a torch left on stays on). (2) **At a shut
  door Q is Peek's**, not the wheel's; 1, 2, 3 still pick. Say if either should change.

## Now: judge L-20a, the inventory wheel and three slots (built Nov 12, D-116)

Three slots. The round button at the bottom middle shows a dot per slot (lit where a tool is,
bigger for the one in your hand). Tap it and your slots fan out over it with a soft tick each;
tap one and it comes into your hand, the wheel folds and the slot flies into the box beside the
button. Tap the box to put the tool away (out of your hand and view, still yours) or bring it
back up. On a computer: Q opens the wheel and frees the mouse to click; 1, 2, 3 pick straight away,
and pressing your slot's number again puts it away. On a pad: d-pad left and right step round the
slots, up puts away or lifts, down drops. Verified in Studio (one player, a computer and the
Galaxy A16): all of that, the padlock showing Lock only while it's up, Lock then Cut on one door.
Shots: `docs/art/L-20a-*.jpg`.
- [ ] **On your phone** (published, a live server): pick up three tools, tap the button, pick
  each in turn. Does the wheel open fast enough to use with a keeper near, and do the ticks and
  clanks feel right? Tap the box: the tool drops out of view and the box dims; tap again and it
  comes back up. With a horn up, the Blow button (by the jump button) does only its own thing.
- [ ] **On a computer**: Q, then click a slot; and 1, 2, 3, pressing your slot's number twice.
- [ ] **Two players**: put a tool away. Your friend should see it leave your hand, and their Give
  button for you shouldn't change; you can't Give or Drop a tool that's put away.
- [ ] **Decide, defaults in place** (D-116): (1) **Q opens the wheel** on a computer (GTA V uses
  Tab, which is Roblox's player list here). (2) **Your slot's number twice puts the tool away**
  (Rust's hotbar does this); the wheel never does, picking your own slot just shuts it. (3) **The
  ladder can't be put away** (it rides your shoulder; put away it could go through a crawl hole
  with you): the box shakes with a dull click. (4) **A tap anywhere in the world, or 4 seconds
  untouched, shuts the wheel.** Say if any should change.

## Now: judge L-19b, a door's buttons where your hand would go (built Nov 11, D-115)

A shut door: Open on its middle, Peek low by the lift handle. Open: Close and Slam side by side
in the middle. Padlocked: "Padlocked" once over Open, Cut on the latch; Lock on the latch with a
padlock in hand. Each screen keeps the low buttons in view: walk up to a door looking level and
Peek rides up the door to sit just above the wheel's button (on your eye line, Open sits at your
eye); look down at the door and Peek comes down onto the handle. Verified in Studio (one player, a
computer and the Galaxy A16): every state above, Peek (Q) crouching you with Close, Open and Slam
brought down in a row over the gap, Close (F) from the crouch, Cut held with bolt cutters taking
the padlock off, and Slam sliding along the row as the door changes. Shots:
`docs/art/L-19b-*.jpg`.
- [ ] **On your phone** (published, a live server): walk up to a shut door. Peek should never sit
  on the wheel's button, the jump button or the torch button, and never touch Open; look down and it
  settles on the handle. Tap Peek: you crouch and Close, Open and Slam come down above the gap.
  Open a door and tap Close twice fast: the second tap must do nothing (no Open, no Slam).
- [ ] **At a padlocked door on your phone**: Cut sits low right of your gaze, its red "Need bolt
  cutters" stopping short of the torch and jump buttons; turn to face the padlock and Cut slides
  out onto it.
- [ ] **Two players**: both at one door; each screen moves its own buttons, so a friend kneeling
  doesn't bring your row down.
- [ ] **Decide, defaults in place** (D-115): (1) **No more Peek-then-Close on one spot**: Close
  now sits in the row with Open and Slam while you peek, so tapping Peek's spot again does
  nothing. Say if you want the old toggle back (it would put Close down by the handle while you
  kneel, over the view under the door). (2) **The latch's button slides in on a phone**: facing
  the door, Cut and Lock sit between your gaze and the padlock rather than on it, so they stay
  off the torch and jump buttons; they sit on the padlock only when you face it.

## Now: judge L-19a, the new buttons in the world (built Nov 11, D-114)

Every button in the world is now our own: a round key chip with its verb beside it, no grey box.
Verified in Studio (one player, a computer and the Galaxy A16 in the Device Simulator): every
prompt on the test hall and the laid floor uses it; Unit 112 shows E Open and R Cut with
"Padlocked" once above; Open shakes red with "Padlocked" from E and from a real tap on the phone
chip; holding Cut with bolt cutters fills a ring round the chip and cuts the padlock; Pick up
reads "Bolt cutters"; the keypad's Use draws on the phone. Shots: `docs/art/L-19a-*.jpg`
(Studio's captures skip world GUIs, so the shots copy each button onto the screen at its spot).
- [ ] **Look at it on your phone** (published, a live server): walk the test hall and a floor.
  Each button should swell in the moment you're near and vanish as you leave, never a box; the
  chip a clean thumb target (a dot in it) that one tap presses; nothing covering the hall. Tap
  Open on Unit 112: it shakes, goes red with "Padlocked" and a dull tick, then says Open again.
- [ ] **On a computer**: the key in each chip (E, Q, F, G, R) matches the key that presses it; a
  hold (Cut with bolt cutters, Saw with a saw) fills the ring as you hold and empties if you let
  go early; a press pops the chip.
- [ ] **With a controller** (if you have one): each chip shows the pad's button picture.
- [ ] **Two players** (Test > Clients and Servers, 2 players): one presses Open on a padlocked
  door. Only their screen shows "Padlocked"; the other player's button stays as it was (before,
  everyone near saw the refusal).
- [ ] **Decide, defaults in place** (D-114): (1) **Names only where they're news**: doors, the
  ladder, Lean and Drop down show no name now (the number's on the door); Crawl, Saw and Drop in
  still name the unit behind the wall; Pick up names the tool; a padlocked door says "Padlocked".
  (2) **A dull tick on a refusal** (Roblox's UI click, pitched down): say if you'd rather it
  silent or a different sound.

## Now: judge L-16b, landings, the tops and presses on arrival (built Nov 11, D-111, D-113)

Verified in Studio (Play, one player): on the default avatar, a 0.6-stud landing crouch with
straight legs put the feet 0.63 into the floor; with the knees bent, the feet stayed where they
stood. Lying on Unit 101's top, every door button was hidden (Lock too, with a padlock in hand)
and all came back once down. Behind a sawn hole, Climb down and Drop down did nothing, and the
same Drop down from a clear spot dropped you. Running in at full speed, Climb, Saw and Lean each
worked on the first press made the moment the button showed: before, Climb and Saw were dropped
without a word (the server still saw you a few studs back).
- [ ] **A friend lands** (Test > Clients and Servers, 2 players): one drops down off a unit's
  front, then drops in through a sawn top. On the other screen their knees should bend as they
  land, feet on the floor, never sinking into it.
- [ ] **Presses on arrival on your phone** (published, a live server): sprint at a leaned ladder
  and tap Climb the moment it shows; sprint into an open unit and hold Saw at its side wall the
  moment it shows; sprint out of a unit under its closing door and Lock it at once (padlock in
  hand). Each should work first time, never a dead press you have to repeat. A live server sees
  you later than Studio does, so this is the real test.
- [ ] **Two players at once** (Test > Clients and Servers, 2 players): both sprint at the same
  ladder; the first gets Climb, the second "Wait for them". Then both run into one unit and one
  presses Saw: the cut runs its whole time for them.

## Now: judge your Nov 11 fixes: the tops, reaching through doors, the floor (D-110)

Verified in Studio (Play, one player): on a unit top, a quarter turn of the view mid-crawl moved
your eye only where you pushed (0.4 studs sideways over the whole run, the head's soft sway),
4 to 5 studs a second; a tool behind Unit 101's shut door hid its Pick up and the server refused
a forced press, still hidden under a peek, offered and taken once open; Unit 106's floor sits
0.03 over the junction's. Studio was in the background (15 frames a second), so the feel is
yours to judge.
- [ ] **Crawl the tops on your phone**: does it still feel like crawling (the pull's boom, the arms
  for a friend), or now too floaty? The head's dip and sway can come back up (`VIEW_DIP`,
  `VIEW_SWAY` in LadderView) or the surge (`Tops.Surge`).
- [ ] **Units on a real floor** (Walk a floor): open a unit at a hall junction and swing the
  view; the floor near the door should no longer flicker.
- [ ] **Reaching through doors**: a tool in a unit shows no Pick up until the door is half up;
  shut in with one, you can still pick it up.

## Decide: the lobby and the store (your plan, Nov 11, D-112)

Written into the GDD's "The lobby" and "Monetization", ROADMAP L-08e (four tickets) and Phase 2's
store. Defaults are in place; nothing here blocks the tickets before L-08e.
- [ ] **A clerk at the counter?** A character there could be the game's face, as DOORS' Jeff is,
  but it needs a reason to be alive that fits the lore. Default: no clerk, a bell and a sign.
- [ ] **The dolly in the levels** stays a maybe (your note: the climb is an escape, not a haul).
  Nothing builds it until you say. If it comes back, riding an empty one fast but loud would be
  a new, untested bet.
- [ ] **Later, before the game goes public:** watch 5 to 10 kids in the age range play two climbs
  each and note every "how do I get that?"; answer the maturity questionnaire as Mild fear (no
  keeper ever bleeds); set avatars to R15 only; for Kids and Select, 250 plays from highly
  engaged players within 60 days or the refundable 50,000 Robux expedited review.

## Now: judge L-16a, in hand and caught (built Nov 11)

Verified in Studio (Play, one player, D-108): your own right arm raised through the new joint
finder (the old one found none of a player's arm joints, so no friend's torch arm ever rose);
caught 9.6 studs up the ladder and again a second into a crawl (Studio's new `CatchTest`): your
body let go at once, the catch's face, kept in a unit, cut free by a stand-in, then walking 7.2
studs in 0.6 s; G at 102's open door slammed it with the horn still in hand, G with the door shut
dropped it; a click on slot 1 with the horn held blew nothing, one out in the world blew it.
Output at Play is clean but Roblox's own 203785492 lines (not the game's; can't be silenced).
- [ ] **A friend's torch arm** (Test > Clients and Servers, 2 players): one switches their torch
  on and looks up and down. The other should see their right arm come up to point it and follow
  their look, then drop when it goes off. Before tonight it never rose.
- [ ] **The first slam** (Studio closed and opened fresh, then Play): open a door and slam it.
  Does the bang land the instant the door hits, not a beat after? Tonight's Studio couldn't show
  the old lateness either way.
- [ ] **Caught with a friend** (2 players): one gets caught on the ladder, or crawling through a
  hole; the other finds them and cuts them free. The freed one should walk, jump and turn at once,
  and never be pulled back up onto the tops or through the hole.
- [ ] **On the phone**: with a horn held, tap the wheel's button and a slot, then the Blow button.
  Each tap does only its own thing (the wheel opens, a slot switches, Blow blows once).
- [ ] **Decide, defaults in place** (D-108): G at an open door slams it and keeps your tool; G
  anywhere else drops. Say if Drop should get its own key instead.

## Now: judge L-15, keepers hear the rest (built Nov 11)

Verified in Studio (Play, one player, a Mannequin stood two halls off with the lobby's "Stand
one"): a keypad beep 60 studs off didn't reach it; a wrong code did ("heard a wrong code's alarm
69 studs off along the halls; it wakes, turns to it and goes to look"), and it came and caught me
at the keypad. Bolt cutters dropped in the lobby (past 40) left it asleep; dropped 26 studs off
they woke it, and the screen played its new stop: a deep hollow thunk, its weight and a groan as
it wrenched round (alone at 67 studs, only the thunk). The ladder going up 29 studs off woke it
too. Not driven in Studio (Lune only): the saw, a crawl through a hole, a crawl along the tops, a
drop off a top or into a unit, and a sound behind a shut door.
- [ ] **Hear it stop.** Stand a Mannequin, let it roam, then make a noise in its reach out of its
  sight: its limp should break off on one deep thunk (a groan with it if you're close), stand a
  beat, then come your way. Does the stop read as "it heard me"? Is 0.8 s right?
- [ ] **Behind a shut door.** Pull a unit's door down behind you and saw its wall (or drop in
  through its top): a keeper within about 100 studs should come and stand outside your door
  facing it, never get in, then wander off. Lift the door while it's there for the scare. Is half
  the reach right for a shut door?
- [ ] **On the tops.** Crawl along a top near a keeper's hall: it should follow the boom of your
  pulls from below, standing in front of the unit you're on, without stopping at every pull.
- [ ] **With a friend**: one makes noise while the other watches the keeper turn.
- [ ] **Decide, defaults in place** (D-107): (1) **A shut door muffles** a sound inside to half
  its reach, as Lethal Company's shut ship does; before, nothing got through a shut door, so the
  saw, crawl and drop-in were silent with the door down. Say if a shut door should be silence.
  (2) **How far each carries** is what players hear: a beep 30, the chime 60, a wrong code 400
  (the whole floor), a dropped tool 40, the saw 200, a crawl through a hole 35, the ladder going
  up 60, climbing it 30, a crawl on the tops 30, a drop off or into a unit 45. (3) **Its stop**
  on a new sound, 0.8 s; the same noise again within 12 studs doesn't stop it twice. (4) A
  tool dropped as you're caught is heard too (one world).

## Now: judge L-08d, the climb ends (built Nov 11)

Verified in Studio on seed 7, one player: caught by 157's Mannequin, the climb ended ("Caught",
floor 1); floor 3 punched and ridden alone ended in the light ("Made it"); left behind watching two
stand-ins who were then removed ended as "Caught" with your photo on floor 1 and the team on floor
2. "Again" by mouse and by Enter each laid a fresh floor 1 with you in its lobby, everything back
to normal. Frames in `docs/art/L-08d-*.jpg`. What Studio can't tell: two players, a phone, the
sounds, how it feels.
- [ ] **Two players, a wipe.** Both get caught (or one left behind, then the other caught). On the
  last catch the black should hold, the building go quiet, two doors slam far off, then "Caught"
  slams down with a low hit and a jolt, both photos drop in greyed and tilted with the floor each
  was lost on, "Floor N · time", then the warm "Again". Does it feel like a loss? Too long or
  too short? Are the far doors right for "the building's sound"?
- [ ] **Two players, Again.** One presses: on both screens their photo should warm up with a tick,
  their button reads "Waiting", and "Back in 10" counts down. The other presses: it goes at
  once with the elevator's chime and "Going back", a moment of black, then you're back in your
  lobby car as the black lifts (L-08e2). Is one press obvious? Is 10 s right?
- [ ] **On a phone**: the screen and the button at phone size; tap Again.
- [ ] **Decide, defaults in place** (D-106): (1) **There is no top** (S4-01a, D-226): the climb
  goes on until everyone is caught, so "Made it" can't happen now (its screen is kept; see "Climb
  past floor 3"). (2)
  **Where Again leads**: back in your lobby car (L-08e2; the test hall's climb in Studio still
  goes to a fresh floor 1). (3) **Again waits** for
  everyone, or 10 s after the first press. (4) **The Missing board** (GDD: your photo goes up in
  the lobby with the floor you were kept on): the results show the same photos and floors; the
  board waits for your lobby plan. (5) **A wipe ends it** even though a watcher could otherwise
  Cut Free back in: with nobody left climbing there's no floor to cut back into. (6) The words:
  "Caught", "Made it", "Floor 2 · 6:42", "Again", "Waiting", "Back in 10", "Going back".

## Now: judge L-08c, left behind (built Nov 11)

Verified in Studio on seed 7 with two stand-in friends (clones of you) riding while you stayed in
the lobby: three rides, the whole moment logged in real time and held frame by frame
(`docs/art/L-08c-*.jpg`), switching between them, Cut Free into floor 2's lobby, a friend removed
(followed to the other) and both removed (you're let back in). What Studio can't tell: a real
friend, a phone, and how it feels.
- [ ] **Two players, one left on floor 1** (in the lobby or out in the halls when the gate shuts).
  The one left should get, in order: "Left behind" in red with the gate's clang, the screen's top
  and bottom going dark, the car's light drawing away and its motor fading above, a low hit as
  the light goes (you can't move from then), black, a faint bell, then the view lifting behind
  the friend in the new car as its gate opens. Then watch them play a while: does the camera stay
  smooth as they walk, run and turn, never shaking, never stuck in a wall? Drag to swing round
  them. Does it sting? Is anything too long or too short?
- [ ] **Watching on a phone** (Automatic graphics): the bar at the bottom (who, the arrows, "Back
  in when they finish"), the arrows big enough for a thumb, nothing else of the HUD showing, the
  view readable in the dark halls. Studio drew the friend's car black for a while after the
  1000-stud jump under Automatic graphics (as it did for riders in L-08b): does a phone?
- [ ] **Left behind while kept:** get caught on floor 1 and stay kept as the car leaves with your
  friend. You should get the same moment from inside the unit, then watch them. Untested.
- [ ] **Decide, defaults in place** (D-105): (1) Moot since S3-03a1 (D-220): Cut Free's product
  and price are the "Make the Cut Free product" item; bought while left behind, it now stands
  you in the car once it reaches the next floor. (2)
  What you carried when left behind drops and goes with the floor. (3) Moot since S3-01a: the
  bar's "Back in when they finish" line is gone, because you're never out for longer than a ride.

## Now: judge L-08b, the next floor (built Nov 11)

Verified in Studio on seeds 7 and 23: punched floor 1's code, rode, and the gate opened on floor 2's
own lobby (its own layout, teal doors, its own code), floor 1 gone; on floor 2 opened units and
read its notes (237 and 249), woke 224's guard and got caught and kept there, punched floor 2's
code and rode on to floor 3 (81 to 91 units, four notes, ten padlocks). A frame-by-frame log
across the hand-off: the view moved under a hundredth of a stud and didn't turn, the shaft never
jumped. The empty car came back and re-armed. What Studio can't tell: a phone's frame rate at the
move, two players, and how it feels.
- [ ] **Ride from floor 1 to floor 2 on a phone** (graphics on Automatic, as players have it).
  About 6 s into the ride, on the second cable clank, you're moved into floor 2's car (in Studio
  that frame took 0.16 to 0.4 s, and Studio's Automatic graphics then drew the car black for
  10 to 30 s; at a fixed high quality it was lit). Does the view stutter there, the car's light
  flicker or go out, or anything jump? Then walk floor 2: its map in the corner, its doors, its
  notes, its keepers.
- [ ] **With a friend** (two players), both riding: does your friend stay beside you the whole
  ride, or vanish or pop for a moment at the clank? (Left on floor 1 is L-08c's test, below.)
- [ ] **Know:** floors above 1 now have their own layouts and codes per seed (one seed laid floor
  2 as floor 1 again). `lune run scripts/floor-map 7 3` prints the new floor 3; older notes here
  naming seed 7's floor 3 units are out of date.

## Now: judge L-08a, the ride (built Nov 11)

Verified in Studio on seed 7, floor 1: punched 1097, rode from 1 to 2 and again from 2 to 3. A
real-time ride was logged frame by frame (the shaft slid its 16 studs, the lamp dipped as the
brakes let go, every sound started on its moment and the motor followed the car's speed), and
frames were held with Workspace's `DevRideHold` and captured (`docs/art/L-08a-*.jpg`). Standing in
the lobby instead, nothing of the ride played. Nobody here can listen, feel it on a phone, or run
two players: those are yours.
- [ ] **Ride it, headphones on** (one player). Punch the code, step in, wait for the gate. A beat
  after it slams: a heavy clunk, the light dips and flickers, the hall beyond the gate goes black,
  the car sags a hair and pulls up, and a clanky motor winds up. Concrete slides down past the
  gate, a big painted number goes by, two cable clanks knock the car, then the readout over the
  gate (and the plate in the top bar) clicks over to the next floor as the brakes bite. It slows,
  bobs once as it levels with a clunk, the bell rings, the dark lifts off the hall and the gate
  folds open. Does it feel heavy and real? Is anything too slow, too loud, or too soft? Did the
  view ever feel shaky or jittery?
- [ ] **On a phone's speaker:** the same on a real phone. The clanky motor, the clunks and the bell
  are the parts a phone plays; the deep rumble is for headphones. Can you read the floor readout
  over the gate from the middle of the car, and the plate in the top bar?
- [ ] **With a friend** (two players): one rides, one stays in the lobby. The one left should see
  "Left behind" and the car's light draw away and go dark (and, since L-08b, land at the spawn as
  the rider is moved to floor 2). The rider should see and hear the whole ride; the friend, none
  of it.
- [ ] **Decide, defaults in place** (D-103, numbers in `Ride`): (1) the ride's length: 9.6 s to
  level and about 12 s until the gate is open (longer is more breath and dread, shorter keeps the
  climb moving across ten floors); (2) the gate shuts 6 s after it opens on the new floor
  (`Ride.Linger`), with anyone still inside shut in until the next code opens it (it stops
  anyone camping in the car); (3) the shaft is built from Roblox's own concrete and metal, not
  baked in Blender like the car: keep it, or have it built the car's way (a session's work);
  (4) the arrival bell is the keypad's double-ding, lower: keep it, or find a deeper elevator
  gong; (5) the floor readout and the plate are amber, the lamp's colour (the clock stays red and
  green).

## Now: judge L-06c2, the catch (built Nov 11)

Verified in Studio on seed 7, floor 1, caught by 157's guard three times. Frames were held with
Workspace's `DevCatchHold` and captured: the dread (it looms over you in the doorway, its face
faintly lit, the HUD gone), the rush (its arms clawing in low from both sides, its cocked blank
face growing), the landing (its face taller than the screen), the press, the black with "Caught",
the eyes cracked open in the unit. The sting's layers were measured playing on the caught screen
on the rush's first frame and the thunk as it lands; a real-time run logged it frame by frame
(black at 1.0 s, awake by 4.8 s). A stand-in friend's film wind was captured mid-turn. Nobody
here can listen or run two players: the sound by ear, a phone, and a friend's view are untested.
- [ ] **Get caught, headphones on** (one player). Open Unit 157 from (47, 3, -632), stand still
  and let the guard reach you. The chase music and the hall should cut dead the instant it has
  you; your view is wrenched to its face and it holds still for half a second; then it lunges:
  a scream, a huge hit and a rush of air, its face crashing into your eyes, a hollow thunk and a
  hard knock; black. In the black, "Caught" and the film screeching round you; then your eyes
  crack open, drop shut and open, blurred and grey, the hall's sound back. Did it make you
  jump? Is any of it too long, too soft, or too loud?
- [ ] **On a phone's speaker:** the same on a real phone. The scream and the whoosh are the parts
  a phone plays; the big hit is mostly bass. If the moment goes thin, say so. Also judge the
  landing frame on a wide phone: its face should fill the screen's height, cocked over.
- [ ] **A friend watching** (two players): stand a few studs from a friend as they're caught. Its
  face never rushes you; you hear the squeal and see the film climb them from the feet as they
  turn once round, then they're gone. Does it read as being wrapped?
- [ ] **Your maturity answers for fear:** the catch is now a jump scare (a face rushing the camera
  with a scream, no blood). Check the experience's maturity questionnaire answer about fear and
  startling content in Creator Hub before you publish, and update it if it says otherwise.
- [ ] **Decide, defaults in place** (D-102, numbers in `Caught`): (1) the dread before the lunge,
  0.48 s (longer is more dread, shorter more jump); (2) how close its face lands, 1.5 studs then
  pressed to 0.85 (closer shows only its surface); (3) the wake, 2.2 s after 1.25 s of black, the
  whole catch 4.4 s where the GDD said 2: keep the slow wake?; (4) the warm light that comes up on
  its face as it lunges, so its face isn't a black shape: keep it?

## Now: judge L-06c1, the Mannequin's walk (built Nov 10)

Verified in Studio on seed 7, floor 1: 157's guard stepped out and roamed while I watched from 12
studs above the hall, and every sound it made was logged at its body with its distance. It
limped (thump, then a scrape 0.27 s later, a tock 0.47 s after that, then 0.73 s of nothing);
the body's weight under each step came in as it neared (0.09 at 46 studs, 0.36 at 29, 0.61 at
22, 0.88 at 12.6) while the hollow thunk carried to 63 studs; it was silent through each 5 s look;
it creaked on a corner; the door's lift on it answered with a deep thunk and a creak. The poses
were captured on lit copies (`docs/art/L-06c1-gait-front.jpg`, `-side.jpg`). Nobody here can
listen: every sound by ear, and on a phone's speaker, is untested.
- [ ] **By ear, as it comes** (Play, headphones first). Open Unit 157 from (47, 3, -632) and run
  back toward the lobby, then stop round a corner in the dark and listen as it roams. Far off you
  should hear a slow, hollow knocking; as it nears, a heavy thud comes in under each step, its
  dragged foot scrapes between steps, and the beat limps: thump, scrape, tock, pause. It creaks
  at corners and as it turns to you. When it stops, or your torch holds it, nothing at all. Does
  it still sound like a puppet anywhere?
- [ ] **On a phone's speaker:** the same, judged on a real phone. The weight is mostly 190 to 470
  Hz, which a phone only just plays; if the thud vanishes and only the knocking is left, say so.
- [ ] **What you see:** it only walks while no light is on it, so watch it come through the dim
  stretch between two hall lights, torch off, then switch the torch on it. Its left leg stays
  stiff and swings round on its toe, it holds each heavy step and then jerks, and its head lolls
  to one side and lands a beat after its body; caught in your torch it freezes on one of those
  keys, head settled. Does it read as wrong in a frightening way, not as broken animation?
- [ ] **The reveal:** peek Unit 154's sleeper from (47.5, 3, -624): a deep thunk and a creak as the
  curtain clears its feet, before your light finds it.
- [ ] **Decide, defaults in place** (D-101): (1) how near it gets before its steps are heavy (full
  weight within 10 studs, a tenth of it by 40); (2) the levels: thunk 0.55, weight 0.9, scrape
  0.8, creak 0.7 (`KeeperRows`, say "louder" or "quieter" for any); (3) the creak is a rubber
  pedal and a tire's rub pitched down: if it reads as a squeak rather than a stiff plastic body,
  say so; (4) the rush (ROADMAP polish): dead still in the light, then a fast jerky rush across
  the gap when the light leaves it, as SCP-173 does. It means a moment faster than its walk,
  against "nothing outruns you". Want it?

## Now: judge L-07e, the padlock (built Nov 10)

Verified in Studio on seed 7, floor 1, alone, with a 30-second clock (Workspace's
`DevPadlockSeconds`): kept in 123, the warning came with 20 s left and "Padlock in 20" counted
down on my screen once a second; lifting the door hid it and stopped the clock (4.72 s left going
up, 4.72 s left coming back down); the door padlocked on the second, its buttons read Padlocked
with Open and Cut, and my line read Padlocked in red. With the padlock cut off (as bolt cutters
do) Cut free stayed off until the door was up; then a stand-in friend's cut let me out. Kept again
in 111: the hand worked keys in a padlock at the door five times, 5 studs from me, louder toward
the end; with the door open a crack when time ran out, nothing locked for 8 s while the hand kept
at it every 3 s, and the padlock went on 0.25 s after the door closed, with the hit. Dying while
padlocked left the padlock on the empty unit. Kept in 119 and cut free before the warning:
nothing followed. Output clean. Friends' lines (two players) and every sound by ear are
untested; the friends' line was seen as a mock.
- [ ] **The warning, as the one kept** (one player will do: in Play, set Workspace's
  `DevPadlockSeconds` to 30 from the Server, then get kept by the L-07a steps below). Ten seconds
  in, keys work a padlock at your door and "Padlock in 20" comes up high in the middle, beating
  each second, red for the last five; the hand comes closer together and louder. At 0 the bolt
  shoots, the shackle clicks, your view jolts, a low hit sounds and "Padlocked" slams in. Does
  the clock feel like it's running out? Does the click land as dread? Is the hand loud enough
  through the door, or too loud?
- [ ] **The warning, as a friend** (Test > Clients and Servers, two players). While your friend's
  padlock is coming, "Sam: padlock in 12" sits under the top bar; at the click it turns red,
  "Sam: padlocked", and a quieter hit sounds wherever you are. Near their door you hear the hand
  too. Then cut the padlock with bolt cutters (R, held), Open, and Cut free.
- [ ] **Decide, defaults in place** (D-100): (1) the clock is 150 s (two and a half minutes) of
  your door being down, the warning its last 20 s; (2) it stops while your door is going up or
  up (a friend has come) and runs while it's down, open a crack or coming down; (3) one padlock a
  keep: once one has been on and been cut off, it never comes back; (4) a padlock still on when
  the kept player leaves or dies stays on the empty unit; (5) friends hear the hit at the click
  wherever they are; (6) the line doesn't say where your friend is kept: banging still does that
  (D-097). Numbers in `src/shared/Kept.luau`.

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
  and stand still: the Mannequin catches you (its face rushes you, L-06c2 above), and you wake
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

Seed 7, floor 1, as for L-06b3a2 below; Unit 126's Mannequin is dealt asleep now, so use
157's guard. The catch itself is L-06c2's now (above).
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
  the one inside reads "Going up" and rides (L-08a replaced the old fade back to the spawn; judge
  the ride under L-08a); the one outside reads "Left behind" as the car's light draws away. Then swap, and try diving
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
- **Fragile lamps (V5e, D-296), by ear and on a phone:** drop the oil lamp while running and
  set one down standing still. Does the crack (a 0.7 s glass crack over the clank) sound right,
  and does the crack on the chimney read at phone size? Defaults to judge: it cracks at 10
  studs a second or a 4.5 stud fall (`Finds/Chip`), and being caught while running cracks it
  too. A lamp out of your job box doesn't crack yet (waits on the home chain).
