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

## Now: judge the haze (P0-02i and P0-02j, built Nov 7)

- [ ] **Judge the phone shots:** `docs/art/P0-02j-phone.jpg` is a Galaxy A16's screen, landscape:
  graphics Level01 (left, where the cheapest phones play), Level08 (middle), full quality (right).
  Top row from the spawn, bottom row under the near lit tube. Look for: grey air you'd notice
  round a lit tube without it reading as smoke or fire, about as thick at all three, the far doors
  still showing through. From the spawn it's only a faint glow round the far tube at phone size;
  say if it should be thicker (`HallLight.HazeTransparency`). The bigger Studio-size shots are
  `docs/art/P0-02i-haze.jpg`. Known: at low graphics the cloud's top can show a faint straight
  edge near the ceiling.
- [ ] **Feel it yourself:** set File > Studio Settings > Rendering > Quality Level to 1, Play,
  walk from the spawn to the far tube and stand under it; then again at 21, and put it back to
  Automatic. Look for: the dust drifting slowly, never popping in or out, as thick at 1 as at 21
  (before this fix Level 1 had almost none), and nothing hazy in a dark stretch.
  `docs/art/P0-02i-inside-105.jpg` checks a shut unit is still dark at low graphics.
