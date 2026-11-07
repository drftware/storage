# Owner

Everything waiting on you, in order. Work down and tick boxes. Agents add new items here and
nowhere else.

## Now

- [ ] **Each session: click Connect** in Studio's Rojo plugin when it says `rojo serve` is running.
- [ ] **Save the place** (File > Save to Roblox) after this session (Nov 7): the hall's templates
  now live in it at `ReplicatedStorage.Corridor`: `Straight` (last session) and `Fixture` (the
  new hall light). Unsaved, the next open loses them and the test hall falls back to plain blocks
  and bare tubes (Output says so).
- [ ] **A home for the code:** the repository has no remote, so "push" had nowhere to go; the work
  is now on a local `main` (`storage-unit` renamed, `third-person-walls` deleted, Nov 6). Say if
  you want a private GitHub repository created and `main` pushed to it.

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
  lights never dropping and no white line on the floor. Then walk into 101, shut it on yourself
  (the steps under "Now: judge P0-02g"), and check the dark and the line under the door still
  come, and go again when it lifts.

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
  three fixtures (a weak one by the spawn, the lit one, a dead one past the last units) hanging
  straight between the joists, nothing floating or poking through the deck; and from last
  session, no line where two floor pieces meet (x = -12 and 12) and footsteps that sound like
  concrete. The dead fixture's eye is hard to see in the exit sign's red; that end gets the dead
  end piece (P0-03c).
- [ ] **Decide later (the ladder):** the ceiling's lowest steel is now 12.8, so standing on a
  unit's wire top (10) leaves 2.8 studs overhead, and an avatar is about 5. Before the ladder is
  built: crawl-only up there (the default), or taller floors.
