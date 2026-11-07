# Owner

Everything waiting on you, in order. Work down and tick boxes. Agents add new items here and
nowhere else.

## Now

- [ ] **Each session: click Connect** in Studio's Rojo plugin when it says `rojo serve` is running.
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
