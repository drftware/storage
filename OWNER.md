# Owner

Everything waiting on you, in order. Work down and tick boxes. Agents add new items here and
nowhere else.

## Now

- [ ] **Each session: click Connect** in Studio's Rojo plugin when it says `rojo serve` is running.
- [ ] **A home for the code:** the repository has no remote, so "push" had nowhere to go; the work
  is now on a local `main` (`storage-unit` renamed, `third-person-walls` deleted, Nov 6). Say if
  you want a private GitHub repository created and `main` pushed to it.

## Now: judge P0-02g (built Nov 6)

- [ ] **Reconnect Rojo once** (Disconnect, then Connect; or restart `rojo serve`): Lighting still
  has no colour correction called `Grade` in Studio (checked Nov 6). After the reconnect, Lighting
  has a `Grade` with Saturation -0.15.
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
- [ ] **The low-graphics hall still looks flat:** `docs/art/P0-02g-hall.jpg` is the hall from the
  spawn at low graphics (left) and full quality (right). Nothing changed there this session;
  that's P0-02h. Say if anything beyond the white facades and the lit doors between fixtures bothers
  you.
