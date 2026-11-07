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

## Now: judge P0-02h (built Nov 7)

- [ ] **Judge the shots:** `docs/art/P0-02h-hall.jpg` is the hall from the spawn, top row before,
  bottom row now, low graphics left and full quality right. `P0-02h-open-101.jpg` is the same
  layout looking into open unit 101. Look for: the bottom pair much closer than the top pair, a
  pool of light under the far tube, and 101's walls dimly readable at both (it was black at full
  quality). Known: low graphics is still about 1.7x brighter, and the facades near the spawn still
  read near white there. `P0-02h-inside-105.jpg` checks a shut unit is still dark at low graphics.
- [ ] **Feel it yourself:** Play on Automatic, walk the hall from the spawn, open 101 (E) and look
  in. Look for: when Studio switches quality by itself, a small dimming, not a different hall.
  Say if you want them closer still (more of the light from the fill, at some cost to the pools).
- [ ] **The light budget:** each lit fixture is now two real lights (the tube and its fill), so the
  6-light default (D-015) means three lit fixtures awake at once on a phone (D-017). Say if motion
  lights (L-03) should allow more.
