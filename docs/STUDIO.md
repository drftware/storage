# Studio, API and tool notes

What we learned the hard way, so no session relearns it. Mark each note with where it was
verified: a doc page, Studio, or "untested".

## Getting assets into Roblox

- **Nobody can stand on a unit's top** (L-13b2d3a, 2026-11-09): the halls' ceiling
  (`Colliders.Ceiling`) is at 14 studs and a unit's steel top at 10.14, so there are 3.86 studs
  up there; a standing body needs about 5.2 and its view sits 4.8 up. A move played on the tops
  has to stay lying or tipped (the first Drop in stood you up and put the view at 15.07).
- **A prompt right under a first-person view falls off the top of the screen** (L-13b2d3a): lying
  at a sawn hole's edge and looking at the floor ten studs below, a button at the steel's face in
  the hole's middle is about 45 degrees above where you look; three studs down the hole it's in
  view. `screen_capture` showed no prompt either way (two captures with it enabled and in view),
  though F from `user_keyboard_input` triggered it, so judge a prompt's look by eye, not by capture.
- **The MCP's `require` in Edit can hand back stale modules** (L-13b2b, 2026-11-09): after Rojo
  re-synced the generated unit specs, `require(ReplicatedStorage.Shared.StorageUnit)` from
  `execute_luau` still returned the old `Specs` (no S at all, the M with its old colliders), so
  `UnitKit.prepare` failed on S and gave the M stale colliders. Editing a module's Source doesn't
  clear Studio's cache. Clone `ReplicatedStorage.Shared` into a scratch folder, require from the
  clone, then destroy it. After preparing a template, check its `Colliders` match the spec.

- **With a PrimaryPart set, a write to `Model.WorldPivot` doesn't move the pivot** (L-08e4a,
  Studio Edit, 2026-11-12): `model.PrimaryPart = body; model.WorldPivot = CFrame.identity` left
  the model's pivot at the body's middle, so `PivotTo` a floor point sank every cart 1.69 studs.
  Set the PrimaryPart's own `PivotOffset` instead (`Cart.prepare`).
- **The FBX recipe** (create.roblox.com/docs/art/blender, read 2026-11-05): Blender Unit System
  None; FBX export "FBX Unit Scale", Forward Z, Up Y, Path Mode Copy, Embed Textures. In Studio's
  3D Importer: Import as model, Scale Unit Stud, World Forward Front, World Up Top. With Forward Z,
  Blender's -Y becomes Roblox's front (-Z, the LookVector) and Blender +X becomes Roblox -X.
- **PBR comes in by itself** (docs, untested here): a Principled BSDF with an image in Base
  Color, Metallic and Roughness, and a Normal Map node into Normal, becomes a SurfaceAppearance
  when the model is imported whole. Normal maps are OpenGL (Blender's default bake).
- **Limits** (docs): 20,000 triangles per mesh; one material per MeshPart. The docs disagree on
  the texture cap (1024 vs 4096); we ship 1024.
- **Instancing** (docs): MeshParts with the same mesh and identical SurfaceAppearance draw in one
  call, so clone one imported part rather than importing copies.
- **What an Open Cloud FBX upload of the unit becomes** (Studio, P0-02, 2026-11-05): a Model of
  20 MeshParts as direct children, unanchored, named as in Blender, at the right size (12.2 x 10.1
  x 12.2 studs: 1 FBX unit is 1 stud). Each part keeps its Blender origin as its pivot (a
  PivotOffset; the rig doesn't care). Every SurfaceAppearance arrives in **AlphaMode Overlay**.
  `insert_asset` drops it in as a **package** at an arbitrary turn about Y; destroy the
  PackageLink before preparing. Upload: `scripts/upload_art.luau` (D-010).
- **Open Cloud Assets API** (porch-pirates' STUDIO.md, used here 2026-11-05): `POST
  assets/v1/assets`, multipart `request` JSON and `fileContent` (`model/fbx`); poll the operation
  until `done`. Only an FBX updates in place (`PATCH`, same ID). The unit's 8.5 MB FBX took under
  a minute.
- **Rojo can't live-sync imported meshes** (Rojo's sync docs and DevForum, read 2026-11-05):
  `MeshPart.MeshId` isn't writable by plugins, so a `.rbxm` of MeshParts in the served tree
  arrives blank. Hence D-009: templates live in the place.
- **Rojo 7.7.1 project files take comments and trailing commas** (tested with `rojo build`,
  2026-11-05).
- **`Lighting.Technology` is gone** (Lighting docs and Studio, 2026-11-05): deprecated, read-only,
  RobloxScript only, and missing from the Properties panel. A place opened in this Studio carries
  the attribute `RBX_LightingTechnologyUnifiedMigration`. Its replacements are
  **`LightingStyle`** (Realistic or Soft) and **`PrioritizeLightingQuality`** (keep shadows and
  shaders or view distance when quality drops); both are ordinary settings that Rojo live-syncs.

- **A 2D picture from the Studio MCP** (Nov 14, D-158): `upload_image` takes http URLs only.
  Serve the folder with `python3 -m http.server 8765 --bind 127.0.0.1` and pass
  `http://localhost:8765/<file>.png` (the `127.0.0.1` spelling answered "Unable to read file");
  it returns an `rbxassetid` that an ImageLabel loads at once in Play (`IsLoaded` true). Stop the
  server after. Record the ID in the art's `assets.json`.
- **A ViewportFrame draws soft** (Nov 14): the coin count's 3D coin looked fuzzy beside its
  number on every screen. For a small, still icon use a rendered picture; keep viewports for
  things that move.

## SurfaceAppearance

- **Overlay** (docs): the part's Color shows wherever the ColorMap's alpha is 0. Its `Color`
  property tints the ColorMap only, never the part's Color.
- Writing AlphaMode and the map properties needs plugin security (docs): the command bar and
  plugins can, game scripts can't.
- **AlphaMode Transparency cuts unless the part is a hair transparent** (L-07b, Play,
  2026-11-10): the kept wrap's colour map carries alpha 0.4 to 1. On a MeshPart at Transparency
  0 it drew as hard-edged white shreds with the body plain between (the alpha cut at about half);
  at Transparency 0.02 the same map blended as cloudy film. Roblox also blends it lighter than
  Cycles renders it: alpha 0.28 for one layer of film left a face plain to read; 0.46 reads as
  cloudy. Judge alpha in Studio, not the Blender sheets.
- **An FBX whose material wires the colour image's alpha into the BSDF's Alpha imports in
  AlphaMode Transparency** (L-07b, Open Cloud upload, 2026-11-10); without that link it arrives in
  Overlay, as every earlier import did.

## Camera and prompts

- **A door's middle point holds three buttons** (S1-04a2, Play, 2026-11-14): `DoorMiddle` has
  Open, Close and Slam, each a child named `ProximityPrompt`, so `DoorMiddle.ProximityPrompt`
  returns whichever comes first, usually a switched-off one, and presses on it do nothing. Pick
  the button by `ActionText` (or `DoorAction`).
- **Testing a coin take** (S1-04a2, Play): floor 3 in the DevCorridor (seed 2000013). From the
  Server pivot the character to (0, 3, -618) facing +X; from the Client set the camera to
  Scriptable, point it at Unit301's Open, wait 1.2 s, `InputHoldBegin`/`End` on it: the server
  lays a pile of 2 (`Floor3.Straight2.Coins`). Pivot to (6.5, 3, -617.1) and press the pile's
  Take the same way. Sample the coins' Y and `PlayerGui.CoinCount` children (`Flying`) every
  0.08 s to see the jump, the vanish and the flights; the number read 2 at 0.75 s.
- **The real coin in a ViewportFrame reads gold** (S1-04a2): with Ambient (190, 175, 150),
  LightColor (255, 244, 222) and the light from the front, top left, the PBR coin showed its
  keyhole and rim in a 40-point square at the top bar. On the unit's floor under the bulb the
  same coin reads coppery, the bulb's warm light on gold.

- **What stops Roblox's camera** (the PlayerModule's `Popper`, read in Studio, 2026-11-05): its
  ray uses `RespectCanCollide` and the Default collision group, and it stops only at a part that is
  CanCollide with total transparency under 0.25. Invisible colliders and non-colliding meshes let
  it straight through, so a unit as prepared today stops nothing (the reason for D-011's first
  person).
- **A prompt shows only when on screen and in sight of the camera** (seen in Play, 2026-11-05):
  with the camera inside the unit across the hall, 101's prompts hid; with it in the hall, all five
  showed. Default Exclusivity is OnePerButton: one prompt per key at a time.
- **First person** (Play, 2026-11-06): `StarterPlayer.CameraMode` `LockFirstPerson` (Rojo writes
  the string as enum 1) puts the camera half a stud behind the head's centre and hides your own
  body. Vertical field of view is 70°, so a point more than 35° below your gaze is off screen: a
  prompt at chest height 1.5 studs out from a door vanished when you walked up to it. Put prompt
  points on the object at about eye height (4 for a standing player, eyes at about 4.4).
- **A prompt's sight line is blocked by invisible colliders** (Play, 2026-11-06): Lift, 0.5 behind
  a shut door, in reach and on screen, stayed hidden from the hall because the ray from the camera
  hit the transparent DoorCollider. A shut door hides what's behind it without extra rules.
- **Prompts on one point stack** (Play, 2026-11-06): the default UI is a `Prompt` BillboardGui per
  prompt in PlayerGui, 138×72 on touch, with no offset, so prompts sharing an attachment draw on
  top of each other. Space them with `ProximityPrompt.UIOffset` or give each its own point.
- **Custom prompts** (L-19a, verified in Play 2026-11-11): with `Style` Custom Roblox draws
  nothing but still decides showing (reach, sight, one per key) and fires `ProximityPromptService`
  `PromptShown(prompt, inputType)`, `PromptHidden`, `PromptButtonHoldBegan/Ended` and
  `PromptTriggered` as before. A BillboardGui under a ScreenGui in PlayerGui draws in the world;
  a tap on a button in it needs the BillboardGui's `Active` on. `UIOffset` is ours to honour:
  `SizeOffset = UIOffset / Size` (in points). `UserInputService:GetStringForKeyCode(E)` gives
  "E"; `GetImageForKeyCode(ButtonX)` gives
  `rbxasset://textures/ui/Controls/DefaultController/ButtonX@2x.png` (loads); Roblox's ring
  picture `rbxasset://textures/ui/Controls/RadialFill.png` loads. "UI Bright Click"
  15675059323 (Roblox's) loads, 0.37 s.
- **A spot moved on one screen** (L-19b, Play): a client writing its copy of a server Attachment's
  `WorldPosition` moves that screen's ProximityPrompt (its on-screen check and reach) and the
  BillboardGui adorned to it; the server's copy and every other screen keep theirs, until the
  server writes the Attachment again. An Attachment's `WorldCFrame` set before it has a parent is
  kept relative to the parent it gets later: parent it first.
- **The Galaxy A16's screen, measured** (Device Simulator, L-19b): `ViewportSize` says 685x338
  but `WorldToViewportPoint` of a point dead ahead is (342.5, 179.5): the 3D view's middle sits
  10 points under the middle of the reported viewport. The tool slots span y 267 to 328 (x 280
  to 402), the jump button x 590 to 660, y 248 to 318, the torch's switch x 599 to 651, y 186 to
  238, the thumbstick the bottom left.
- **The wheel on the A16** (L-20a): the button spans viewport y 270 to 326 (x 314 to 371), the
  box 273 to 323 lifted, Drop beside it; the open wheel's top slot reaches y 190. Peek's middle at
  a shut door sits at 233 to 235 from 1.5 to 4 studs.
- **Every button at once on the A16** (L-17): the Bang button (kept) spans gui x 558 to 654,
  y 153 to 249 (viewport y 211 to 307), the torch's switch gui x 599 to 651, y 128 to 180: they
  overlapped, so the switch now goes while you're kept. An open door's Close and Slam sit at
  viewport y about 158 to 216, a shut door's Open/Peek at about 158 and 204 to 233, the open
  wheel's slots from 190 down: they overlapped, so the world's buttons step aside while the wheel
  is open. A padlocked door's Cut chip sits on the held torch's head and reads.
- **A keyboard press hides the Device Simulator's touch controls** (L-17): after a
  `user_keyboard_input` (E to pick up, 2 to switch) Roblox takes the last input as a keyboard,
  hides the thumbstick and jump button, and the screens that follow the jump (torch switch, Use
  button) go with it; captures then miss them. One `user_mouse_input` click on an empty spot
  (e.g. (420, 120)) brings them all back.
- **A screen following the jump button can miss its hide** (L-17, seen once): at a catch the
  jump hid but FlashlightView's and HornView's screens, which follow its `Visible` change, stayed
  on; setting the jump's Visible by hand afterwards made both follow. Cause unknown; anything
  that must go with the jump in a given state should also watch that state (they now watch
  `Kept`).
- **A Client `execute_luau` has its own module cache** (L-20a): `require` of a shared module there
  returns a different table from the one the game's LocalScripts hold, so setting a number on it
  (to stretch `Wheel.Linger` for a shot) changes nothing in the game. Batch the input and the
  capture instead, or change the source.
- **`user_mouse_input` with `instance_path` clicks a ScreenGui button on a computer** (L-20a,
  Play) even while first person pins the mouse to the middle: the wheel's button, a slot, the box
  and Drop all fired `Activated`. Each MCP call takes a few seconds, so open the wheel and pick in
  one batch (it folds itself after 4 s).
- **Don't teleport past the corridor's walls** (L-20a): the DevCorridor's floor is narrow; a test
  teleport to z 5 by the tools fell through to the void and respawned the player, dropping the
  tools at the world's middle with no Pick up (HANDOFF's Seen). Stand at z 0 to 0.6 and aim at a
  tool by the wall.
- **A scripted Pick up can miss** (L-19b, Play): `InputHoldBegin`/`End` on a shown "Pick up"
  twice did nothing on the server (its slots stayed empty, no error) where `user_keyboard_input`
  E took it at once. Check the player's `ToolSlot1` after a scripted pick-up; use the key if
  it's empty.
- **Aiming the first-person camera from a Client `execute_luau`** (L-19b): with `CameraType`
  Custom, set `Camera.CFrame` once and the camera module carries on from that look; Scriptable
  holds any view but ignores `Humanoid.CameraOffset` (so KneelView's crouch only shows in Custom).
- **Seeing a BillboardGui in a capture** (L-19a): captures draw no BillboardGuis, so mirror
  them: for each, clone its contents into a frame of its size in a temporary ScreenGui at
  `Camera:WorldToViewportPoint` of its adornee plus `SizeOffset` times its size (y flipped),
  capture, then destroy it. The clone shows exactly what the billboard draws at that moment.
- **Clicking on the Galaxy A16 with `user_mouse_input`** (Device Simulator, L-19a): a click
  arrives as a Touch at (x - 47, y) in input space, which starts below the 58-point top inset,
  so a viewport point (X, Y) from `WorldToViewportPoint` is clicked at (X + 47, Y - 58).
  Calibrate with a full-screen TextButton logging `InputBegan` positions if it seems off.
- **Driving a ProximityPrompt from a Client `execute_luau`** (L-12b2): `prompt:InputHoldBegin()`
  then `InputHoldEnd()` presses it as the player would (a hold prompt runs its HoldDuration, the
  server gets HoldBegan, Triggered and HoldEnded), but only while the prompt is shown: in first
  person it isn't unless its point is on screen. Set `CurrentCamera.CameraType` to Scriptable and
  point it at the prompt first; the Assistant puts the camera back to Custom after the call. A
  `screen_capture` lands about 0.5 s after the call returns, so return early to catch a hold
  mid-way.
- **Reading the stick: the PlayerModule no longer gives it out** (L-13b2c, 2026-11-09): the
  PlayerModule is at `StarterPlayer.PlayerModule` (see below), not in PlayerScripts, and
  requiring it returns only `{ ControlModule = { Enabled } }`: no `GetControls()`, no
  `GetMoveVector()`. Input now runs on Roblox's Input Action System: the stick is
  `PlayerModule.InputContexts.CharacterContext.MoveAction` (Direction2D, screen-relative).
  `Humanoid.MoveDirection` is the easy read (camera-relative, flat) and keeps following the keys
  while the Humanoid is PlatformStand: holding A read (1, 0, 0) with the camera looking +Z.
- **Aiming the Custom camera from a script sticks** (L-13b2c): a Client `execute_luau` setting
  `CurrentCamera.CFrame` in Custom mode keeps that rotation (first person) until the mouse moves
  it, so a test can point the view, then hold W with `user_keyboard_input` to crawl that way.
- **No Device Simulator from a script:** `game:GetService("StudioDeviceEmulatorService")` is nil
  in an Edit `execute_luau` (L-12b2), so a phone view needs the Device Simulator set by hand.
- **Avatar joints are AnimationConstraints** (Play, L-12b3): a player's R15 shoulders here
  (`RightUpperArm.RightShoulder`) are `AnimationConstraint`s, not `Motor6D`s (Roblox's newer avatar
  joints). Both have `Transform`, and a write in `PreSimulation` holds through physics; code that
  looks only for a `Motor6D` finds nothing (FlashlightView's old `motor()` did). The elbows and
  wrists are AnimationConstraints too. Find and turn them with the client's `Joints` (L-16a);
  Luau can't index `Transform` through the two classes' union, so it goes through one `any`.
- **First person's camera spot** (Play, L-12b3, LockFirstPerson): 1.5 studs above the root and
  half a stud back along the look (the closest zoom). A Scriptable camera handed back to Custom at
  exactly that spot carries on with no jump and keeps its look.
- **Moving your own body by script** (Play, L-12b3): the owner's screen sets the root's CFrame
  (velocities zeroed) in `PreSimulation`, with `Humanoid.PlatformStand` on (Animate stops its
  tracks) and the parts in a server-registered collision group that collides with nothing: the
  body holds the path (lying at 0.77 for 0.8: one step of gravity) and stands up cleanly after.
  To tune a pose without restarting Play, hold the body there from a Client `execute_luau` the
  same way, set the joints there, and read the parts' positions in the hole's frame.
- **Sounds measured for the crawl** (L-12b3; 0.1 s bins at half speed): "Body Fall Master 28"
  9113475819 hits at 0 s (-6 dB) and rolls to 0.5 s; "Sand Bag Slide 6" 9118767703 slides at
  0.6 to 1.0 s (-30 to -18 dB) and 1.4 to 1.8 s, hits at 1.8 and 2.4 s; "Metal Scrapes 1"
  9116818437 is one steady hollow drag, -12 to -6 dB, from 0.1 to 5.5 s; "Metal Impacts And
  Scrapes 8" 9116709512 is a hit at 0 s, not a scrape; "Slide By Books Across Table 5" 9119195573
  is a soft hiss peaking at 0.5 s.
- **Phone in the Device Simulator:** set the device in Edit first, then the orientation (it errors
  with no phone active), then Play. Touch is on: the dynamic thumbstick is the left part of the
  screen (`PlayerGui.TouchGui`), and `user_mouse_input` drags drive it and the look. A
  `screen_capture` right after a teleport can come back black; take it again.
- **A thin mesh gets a bad decomposition:** the unit's Facade (0.001 thick, doorway cut out) given
  PreciseConvexDecomposition at runtime got a hull across the doorway (a ray down the doorway's
  middle hit it). `CollisionFidelity` is writable in Edit (a read in the same script can still show
  the old value; it settles) but **a client's writes are ignored** (Play, 2026-11-06): set it in
  `UnitKit.prepare`, never at runtime on a client.
- **The camera rests a little past what stops it** (Play, 2026-11-06): up to about 0.08 studs
  behind the surface it hit. A prompt's line of sight starts at the camera, so behind a flat panel
  or a thin sheet the sight line crosses it and every prompt in view hides. Inside a box at least
  0.2 deep it's harmless, because a ray that starts inside a part doesn't hit that part. A default
  raycast does hit the invisible DoorCollider (CanQuery). Built and verified on the parked branch
  `third-person-walls` (D-011 passed on that approach).
- **The shut curtain's collision shapes** (Edit, rays, 2026-11-06): Box is 0.96 deep at every
  height because its top curls back toward the drum, and as a client-side solid it nudged a player
  shut inside 0.36 studs away from the door as it landed. Default and Precise follow the sheet,
  0.07 thick below the header; Hull is a wedge, 0.1 deep at the floor to 0.6 at head height.
- **Arms through a shut door** (Play, 2026-11-06, the owner's R15 avatar, walking straight into
  101's shut door and holding W): the run animation keeps playing against the door, so the hands
  swing through it the whole time, not just on the last stride. Furthest reach past the curtain,
  by the hand's bounding box (its centre in brackets): 0.4-deep collider, from inside 1.25 (0.57);
  1.2-deep, from inside 0.79 (0.10), from the hall 0.79 (0.13). The body stops 1.17 to 1.23
  studs from the curtain at 1.2 deep. Why `BehindDoors` exists (D-013).
- **Hiding a character's name** (owner's two-player test, then docs and Play, 2026-11-06): with
  every part and decal at `LocalTransparencyModifier` 1, the player's name still floated over the
  shut door from the hall, because the name display is the Humanoid's, not the parts'. Setting that
  Humanoid's `DisplayDistanceType` to None hides its name and health bar "under any circumstances"
  (create.roblox.com, Character name/health display), and a client's write stays on that client:
  set on the client in Play, the server still read Viewer. `NameOcclusion` (default OccludeAll) is
  no help here: an object more transparent than 0.99 never occludes, so the invisible collider
  doesn't count, and the thin curtain didn't catch it in the owner's test.
- **Freeing the mouse in first person** (create.roblox.com GuiButton.Modal, and Play, 2026-11-06):
  "If true while the GUI element is visible, the mouse will not be locked unless the right mouse
  button is down." The engine applies it on its own: the PlayerModule still writes
  `MouseBehavior = LockCenter` every frame (`BaseCamera:UpdateMouseBehavior`), so the property keeps
  reading LockCenter with the button showing, and setting it to Default yourself is undone the next
  frame. The camera turns from the `MouseDelta` binding in `PlayerModule.InputContexts`, which an
  unlocked mouse doesn't feed. Studio doesn't lock the mouse while its window is out of focus, and
  the MCP's mouse moves are absolute, so neither the lock nor its release shows up from the MCP.
- **Hiding the cursor in first person** (Play and Roblox's core scripts, 2026-11-06): first person
  draws the arrow in the middle of the screen while the mouse only turns the view.
  `UserInputService.MouseIconEnabled` hides it, and the PlayerModule never writes it (it only swaps
  `Mouse.Icon` for shift lock and the toggle camera), so the game owns it. Roblox's menu still gets
  a cursor: its SettingsHub sets `OverrideMouseIconBehavior` to ForceShow while open
  (Roblox/Core-Scripts on GitHub, archived; the property is core-script only, so a game script
  can't even read it). While the menu is open, Left Alt arrives as processed input.
- **The PlayerModule now lives at `StarterPlayer.PlayerModule`** (Play, 2026-11-06), not in
  PlayerScripts. Its ControlModule moves the character with `self.moveFunction(player, worldVector,
  false)` on most paths, but some flag-gated paths skip it. `Humanoid.MoveDirection` read in a
  later render step still lags the input by a frame, so a guard built on it misses.
- Right after the hall streamed back in, the first capture rendered black; a few seconds later it
  was lit. Watch for that flash after a teleport.

- **The MCP's keys only tap** (L-11c, 2026-11-08): `user_keyboard_input` keyDown then keyUp
  never starts a held prompt (no `PromptButtonHoldBegan`). Hold one from the Client with the
  prompt's own `InputHoldBegin()` / `InputHoldEnd()`, as a custom prompt UI does; set its
  `HoldDuration` long on that screen only to catch a shot mid-hold. A door's buttons hide while
  their point (eye height on the door) is off screen, so aim level at the door, not at the latch.
- **A screen's own prompt reach sticks** (L-11c): a client setting `MaxActivationDistance` on a
  server's prompt keeps it until the server writes that property again; Doors never does, so
  ToolView hides Lock that way.
- **Loose parts a screen makes fall on that screen** (L-11c): a client's unanchored clone is
  simulated there. One cloned into the corner of a door, its wall and the floor is wedged in all
  three and never moves: start it clear (DoorView's cut padlock starts out and up, colliding after
  0.08 s). It lands in a tenth of a second: sample it as it's made, or it looks frozen.
- **Same-key prompts close together** (L-08e1a, Play): with "Walk a floor" and "Go far" 3 studs
  either side of a new post, all on E, an E press went to "Walk a floor". Roblox gives a key to
  the prompt nearest the middle of the view, so a dev post that stands among others gets its own
  key (`travelPost`'s `key`, `pad`). Before pressing a key from the MCP, turn the camera to the
  prompt: in Play the camera is first person and a `PivotTo` keeps its old look, so it may face
  away. A Client camera `CFrame` set in Play keeps only its look (the position stays at the
  head): to shoot a view, move the character there.

## Lighting and captures

- **Graphics quality decides the hall's look** (Play, 2026-11-06, a plate held under a tube):
  `settings().Rendering.QualityLevel` at Level08 and on Automatic, the tube cast no shadow, ignored
  its cone and lit a shut unit's inside through the 0.001-thick facade; at Level10 a faint, blurry
  shadow; at Level12 and up, sharp shadows, the cone holds and units stay dark. Forum reports put
  Realistic (Future) lighting at graphics quality about 4 of 10 and up, falling back on weaker
  devices ([Android rollout thread](https://devforum.roblox.com/t/future-is-bright-on-android-is-fully-rolled-out-client-beta/3235808?page=4)).
  Studio sat on Automatic, which here gave the fallback. **Automatic also switches levels by
  itself during Play** as the frame rate moves (the owner saw an open unit flip between lit and
  black, Nov 6; `docs/art/P0-02g-open-101.jpg`), so judge looks at a fixed Quality Level. A session can set `QualityLevel` from the
  MCP (Client); Play resets it to Automatic. Put it back to Automatic when done.
- **Low graphics ignores geometry entirely** (Play at Level08, 2026-11-06): a 2-stud concrete
  slab over a unit and a 2-stud block in front of its door changed nothing inside; switching the
  tubes off made it black. Only the lights themselves steer that look, so scale them per client
  (D-016). Range does steer it once it stops short of what it lit (2026-11-07): 15 against 22
  looked the same, but a 14-stud tube left an open unit's back wall dark at low graphics.
- **Low graphics against full quality, measured** (2026-11-07, `scripts/brightness.py` on the
  spawn view): floors come out the same at both; upright walls, facades and a unit's insides
  are 2 to 3 times brighter at low graphics. `ExposureCompensation` moves both levels alike, and
  doubling a light's brightness doubled both (low graphics doesn't cap it). A light level with
  the walls (a fill at door height) narrows the gap; see D-017. A light fades to nothing at its
  Range at full quality, so a fill must reach a little past what it should light.
- **A spotlight lights nothing close at low graphics** (Play, L-11a, 2026-11-08): the torch's
  SpotLight (54 degrees, 42 studs) 2.7 studs from a wall lit it at Level21 but not at Level08 or on
  Automatic; down a dark hall at Level08 it washed walls and floor warm, ignoring its cone. Low
  graphics works light out in 4-stud blocks, and a narrow cone that close catches none. A
  PointLight in the same place lit the wall at Level08, on a part or on an Attachment. Lights on
  Attachments, and on parts under `Workspace.CurrentCamera`, render at both levels.
- **Moving the camera from the MCP** (Play, L-11a): set the character's root with `CFrame.lookAt`,
  then `workspace.CurrentCamera.CFrame`; first person keeps the new look. A teleport wakes the
  hall's motion lights: stand still about 8 s for a dark hall.
- **Particles in the hall** (Play, 2026-11-07, P0-02i): a ParticleEmitter at LightInfluence 1
  is lit by local lights at both Level08 and Level21 and goes dark when they switch off, but low
  graphics lights it about twice as brightly. At low graphics a puff that cuts into the ceiling
  or a wall shows a hard straight edge (full quality fades it softly), so keep puffs clear of
  geometry. `Emit` called on the server shows on clients already watching. Compare looks with a
  fresh burst: a steady emitter's puffs are at different ages from one capture to the next.
- **Roblox thins an emitter's Rate at lower graphics, never `Emit`** (Play, 2026-11-07, P0-02j):
  puffs emitted over 2 s at Rate 20 came to about (level ÷ 21) of the rate: Level01 7%, Level04
  17%, Level08 35%, Level12 55%, Level16 69%, Level21 92% (the rest is frame timing). Ten
  `Emit(1)` calls gave ten puffs at every level. So a steady emitter that looks right at full
  quality is nearly empty on a cheap phone, and a fresh burst hides it: judge particles in their
  steady state, or emit them yourself (the haze does, D-019). Count puffs on screen with
  `Stats.RenderBreakdown.Particles` (two triangles a puff).
- **Neon blooms into blobs at low graphics:** a neon strip brighter than about 150 grey smeared
  into round blotches at Level08 (Lighting's Bloom, Threshold 2). Keep small glowing details at
  mid grey; Neon still reads white.
- **Saving captures:** `screen_capture` images land in the session's `tool-results` folder (the
  path comes back with each image); compose them with ffmpeg `hstack`. In zsh, write ffmpeg's
  options out rather than in a variable: zsh doesn't split it into words.
- **A light on a wall only grazes it** (P0-03c, 2026-11-07): the exit sign's PointLight at the
  sign's middle, 0.1 off the dead end, lit the walls beside it bright red and left the wall it hung
  on dark, so the end read as a dark opening. Hung on an Attachment 1.5 out and 1 below the sign,
  it washes the wall it's on. Pale walls (the facade paint) take far more of a light than dark
  concrete did, so a light tuned beside concrete needs retuning beside them.
- **A point light's shadows are hard, even from thin wires** (L-04b, 2026-11-07): a PointLight in a
  caged bulb, with the guard's 0.026-stud wires casting, threw six black bands a stud wide across
  a unit's walls and floor at Level21 (`docs/art/L-04b-guard-shadows.jpg`). A real bulb's are soft;
  Roblox draws no penumbra. Lights inside a model: the parts round them cast no shadow.
- **A unit's bulb, tuned** (L-04b, Galaxy A16): Brightness 1 and Range 12 lit an M unit to its
  corners; 0.6 and 11 left the back corners dark with the boxes plain. Level01 looked close to
  Level21 (walls a little brighter), and lit the facades either side of the open door through
  the wall, which reads as light spilling out.
- **A unit's contents read only behind its bulb** (Play, L-04c2, Galaxy A16): the bulb hangs at
  the unit's middle, so a find standing between it and the door shows the doorway its unlit side:
  the TV read as a black box and the boombox as a dark lump at Level21, metalness map or not. Two
  studs deeper, behind the bulb, all four read at Level01 and 21. The hall's light doesn't help.
- **Roblox lights barely fade inside their Range**, and a SurfaceLight's `Angle` is a hard edge
  (Blender's area-light spread fades softly), so a cone a little wider than the sheets' (130° for
  105°) catches the facade above each door.
- **The environment light is negligible indoors here:** with every tube off, the hall stayed near
  black at EnvironmentDiffuseScale 0.15 and EnvironmentSpecularScale 0.3.
- **A light change can take a frame or more to show:** wait a second or two before a capture, or
  you get the old lighting.
- **Capturing from the look sheets' camera spots:** pin the camera with a `BindToRenderStep` that
  sets `Scriptable`, the CFrame and the FOV every frame (the PlayerModule resets a one-off
  `CameraType`). Blender to Studio for the hero unit 105: (x, y, z) → (x + 6, z, −4 − y). Blender's
  lens is horizontal on a 36 mm sensor; Roblox's FOV is vertical: 20 mm → 53.7°, 17 mm → 61.5°,
  22 mm → 49.4° at 16:9. Studio's view is wider than 16:9 (1430×515 here), so crop its middle.
  ffmpeg composes the side by side (no PIL or ImageMagick on this Mac).
- **Check Studio has your code before a Play test** (L-08e4b2, 2026-11-13): if the Rojo plugin
  isn't connected (`rojo serve` restarted, or nobody clicked Connect), Studio silently runs the
  old scripts. In Edit, `execute_luau` a find in a changed script's `Source` first. The MCP
  can't sync around it: Studio's Assistant refuses HTTP to localhost or 127.0.0.1 ("not in the
  Assistant HTTP allowlist"), so only the owner's Connect click fixes it.
- **Rojo may not push a project-file change to Studio** (2026-11-06): a new Lighting child in
  `default.project.json` built fine with `rojo build` but never showed in Studio over a running
  `rojo serve`. Reconnect, or restart `rojo serve`, after editing the project file.

- **In Play, take the player's own view, not a placed camera** (L-05a2, 2026-11-08):
  `screen_capture` with a `camera_position` in Play kept returning the same frame after the car's
  lamp was switched off on the client. Turning the client's camera instead (Client view:
  `workspace.CurrentCamera.CFrame = CFrame.lookAt(itsPosition, target)`; first person keeps the
  new heading) and capturing with no camera gave the live view, the lobby black with the lamp off.
- **A SurfaceGui draws on an invisible part, and in captures** (L-05a2): a Transparency 1 card
  shows its text. But the first note made in the session drew no digits until its SurfaceGui was
  switched off and on (Kalam's first use, Edit); later notes drew at once.
- **A ViewportFrame draws a mesh's SurfaceAppearance but no SurfaceGui** (Play, L-05b1d): the
  note's paper showed its colour map (thumb smudge and all) and its curl, but the SurfaceGui
  writing on its card drew nothing; write over it with screen labels. A parent's `Rotation` turns
  a ViewportFrame and the labels with it, and a transparent ViewportFrame floats over the world.
- **Kalam (bold) metrics** (`TextService:GetTextBoundsAsync`, L-05b1d): the line is exactly the
  TextSize tall; widths over TextSize are "0" 0.325, "7" 0.30, "8" 0.375, "_" 0.39, and
  "_ 7 _ _" 2.21. TextScaled sizes each label on its own, so a "_" and a "7" side by side need one
  computed TextSize.
- **The MCP's touch doesn't reach a ProximityPrompt's button** (Galaxy A16, L-05b1d): a tap
  dead on the shown prompt arrived with `gameProcessedEvent` false and didn't trigger it, while
  taps on ScreenGui buttons work. Trigger prompts with `InputHoldBegin`/`End`; a real tap on a
  prompt is the owner's to check. `user_keyboard_input` with E, `ButtonX` and `ButtonB` does reach
  ContextActionService bindings and a prompt's keyboard key.
- **Paper sounds** (Play, L-05b1d, by `PlaybackLoudness` every 25 ms): Pro Sound Effects' "File
  Folder Movement 5" (9114409576, 1.75 s) is near silent but one sharp flap at 0.78 to 0.88 s;
  "Rip Perforated Computer Paper Paper Rustle 3" (9118184346) is a loud quarter second at 0.1 s,
  the rip.
- **A note's digit at phone size** (L-05b1b, Galaxy A16, 668x308 captures): Kalam's digits on
  the art's note stand 0.107 studs tall (a sixth of the note), about 5 rows of the capture from a
  small unit's doorway: a speck. At the note's 1.6 scale, the "5" of `5 _ _ _` read plainly from
  6 studs. A unit's walls show grey or warm brown in captures a few seconds apart (its bulb's
  stutter and the shadows settling); judge colour after standing 10 s.
- **The first Play after Rojo syncs new code is slow** (L-05b1b): floor 3's laying peaked at
  168 ms in one frame, then 25.6 ms on the next Play with nothing changed. Measure on the second.
  `Model:ScaleTo` grows a note's SurfaceGui writing with its card (TextScaled); a note with its
  scale costs 0.43 ms to lay.
- **Kalam's line is tall for its digits** (L-05a2): `TextScaled` in a short box comes out
  height-limited and small; with no top or bottom padding the width sets the size.
- **A lamp's shadows settle after a few seconds** (L-05a2, owner's test): the keypad, on the
  lobby's face of the wall the lamp hangs behind, showed lit just after a teleport and went black
  once the shadows settled, at Level 21. Judge light after standing still 10 s or more. At
  Level 01 there are no shadows, so the lamp lit the wall through it and the keypad stayed lit.
- **The car's lamp lights the lobby only through the opening** (L-05a2): with Shadows on, the
  lattice gate prints on the lobby floor; the light fans wide (the lamp hangs 5.2 behind the
  threshold), so the lobby's side walls catch it from about 5 studs in front of the back wall.

- **The tops are black on screen** (Play, L-13a, 2026-11-09): Lighting's Brightness is 0 and the
  Grade colour correction darkens everything, so a shot of the unit tops shows nothing. To judge
  geometry from the MCP, on the Client set `Lighting.Brightness = 1`, `Ambient` to about
  (90, 90, 90), disable the ColorCorrection, DepthOfField and Bloom effects and set the
  Atmosphere's Density to 0; Play discards it all on stop. Move the player near first: the floor
  600 studs off isn't streamed in at the spawn and shots of it come back empty sky.
- **Test physics with probes one direction at a time** (Server, L-13a): several unanchored parts
  spawned on one spot fling each other apart (twelve "fell" in the first sweep). Spawn them apart,
  or one per round, frictionless (`PhysicalProperties.new(1, 0, 0, 100, 1)`) so each slides until
  something stops it.
- **A standing avatar on a unit's top wedges** (Play, L-13a): 3.9 studs to the deck's collider
  (the joists, 2.8 up, don't collide) is too little for a 5-stud avatar; teleported onto a lid it
  stuck at root height 11.9 and `MoveTo` couldn't move it. It didn't fall either.

- **A held tool shows black in a capture once the hall's light times out** (L-14b1): the motion
  light over your hall piece goes out a few seconds after you stop, and your view's tool and torch
  are lit only by the world. Walk a few studs (`character_navigation`) to trip it, point the
  camera, and capture at once. A Scriptable camera set from `execute_luau` is put back to Custom
  by the Assistant after the call; Custom keeps the `CFrame` you set in first person.
- **Roblox's Glass from a lit room shows black** (L-08e1a, Galaxy A16 and computer): the front
  office's panes at Glass 0.6 (and 0.8, lighter) showed nothing of the lit concrete outside;
  SmoothPlastic at 0.82 shows the night sky and the porch light's pool. From outside, Glass showed
  the room fine.

## The hall's render cost

- **Testing a server system from the MCP** (L-06b2a, 2026-11-09): the Host's systems live inside
  `init.server` and can't be reached from `execute_luau`. Drive them as a player would: move the
  character next to the walked floor from the Server (it's 600 studs off and not streamed at the
  spawn), then press its dev post or a door's button from the Client (`InputHoldBegin`, above),
  and read what happened off attributes (`KeeperState`, `DoorMotion`) and Output. A Server
  `execute_luau` can sample a keeper's pivot every 0.1 s for a path; the pure modules
  (`Floor.generate` with the dev floor's seed, `KeeperMap`) rebuild the same map to check against.
- **Driving a tool from the MCP** (S1-08, 2026-11-14): the dev floor (`Workspace.DevCorridor.
  Floor3`) is about 1300 studs from where you spawn, so on the Client its units don't exist until
  you pivot your character near them and call `RequestStreamAroundAsync`; units on another
  straight need the same before each. A lying tool's Pick up prompt isn't inside the tool's
  model: find it by its `ObjectText` ("Bolt cutters"). A Client `InputHoldBegin` on it placed 3
  studs above it didn't take it (untried: standing beside it, or waiting longer for the server to
  see you there). Pro Sound Effects' "Spray Paint 3" 9119523840 (1.47 s): hits at 0.12 and
  0.21 s near -5 dB, a rattle to 0.7 s, quiet after (AudioAnalyzer, 50 ms bins, half speed).
- **Pressing a screen button from the MCP** (S1-09, 2026-11-14): `ContextActionService:
  CallFunction` is refused from the MCP's Client code (it needs RobloxScript), but
  `user_mouse_input` with `instance_path` "LocalPlayer.PlayerGui.Flashlight.Switch", a moveTo then
  a left click, fires the button's `InputBegan` as a real click. A `task.spawn`ed sampler writing
  into a `StringValue` under the player keeps logging between calls; read it back after a
  `task.wait`. `Workspace`'s `DevTorchSeconds` (set in Edit before Play) makes a full torch 40 s,
  so its flicker starts 10 s after you switch it on.
- **The bulb's buzz, measured** (S1-09, 2026-11-14; Edit, AudioPlayer at half speed to
  AudioAnalyzer, 0.2 s bins): Pro Sound Effects' "Light Bulb Buzz 2" 9116267264 (2.66 s, a 60 W
  bulb) has an onset to 0.2 s, holds steady near -39 dB peak from 0.25 to 1.55 s (the loop), then
  fades out. At an `AudioPlayer.Volume` of 0.001 the analyzer reads silence: measure at 1.
- **Opening a unit so it deals, from the MCP** (S1-07a, 2026-11-14): `RollUpDoor.play(unit,
  "Open")` from the Server moves the door but never deals it (`Deals` hears only the Doors
  system's own acts), so press the door's Open prompt from the Client. `setLocked(unit, false)`
  from the Server is a cut, and closing it again (`"Close"`) leaves it undealt. Stand on the
  hall side: `FloorBuilder.face(unit)` is a CFrame, and `unit:GetPivot()` doesn't say which way
  the hall is; the Open prompt's Attachment (`DoorOrigin.DoorMiddle`) sits on the hall side of
  the `DoorCollider`. From inside, a raycast to it hits the collider and no prompt shows. 4.5
  studs out along the DoorOrigin's LookVector, on the side with a clear ray to the attachment,
  works; the prompt's reach is 8. The Client can pivot its own character between presses, so a
  single Client `execute_luau` opens several units. The dev floor's units today: floor 3, seed 7
  (2000013): padlocks on 305, 320, 329, 330 and 336; since S2-01 (D-152) sleepers in 305 (with
  its find), 307, 327, 335 and 338, and what other doors deal moved (323's bolt cutters and 326's
  teddy unchecked since). Streaming: a unit far off isn't on the Client, so pivot the character
  to its door from the Server first (4.5 studs along `DoorOrigin`'s LookVector is the hall side
  for 307), then press from the Client with the camera pointed at `DoorMiddle`.
- **The awake Mannequin moved to Unit 157** (L-06b5a, 2026-11-10): on seed 7, floor 1 the guard
  of the note in 157 holds the floor's one awake place, so 126's (and 112's, 154's) Mannequin
  deals asleep and the recipes below that open 126 for an awake one need 157 (or trap 157's guard
  first). 157's door face is (52, 0, -632) looking -X into the hall; its guard stands 6.1 in at
  (58.1, 0, -634.5). Stand at (47, 3, -632), point the camera at its `DoorButtons` and tap Open: it
  sees you 11 studs off and catches you in about 3.5 s (6.6 s once, L-14e, when it froze in the
  hall light on the way). It stays 157 through L-14e (D-098: the guard is drawn before the bag);
  `lune run scripts/floor-deal <seed> <floor>` names any floor's guarded note. A door's face from
  a Server `execute_luau` in Play: `require(ServerScriptService.Server.FloorBuilder).face(unit)`.
  `screen_capture` with `camera_position` in Play draws the Client's view from there: a camera
  at (45.5, 0.9, -632.3) shows the guard's feet under a peek, where a standing eye 4.5 up sees
  only a stud or two in (the peek's kneel, L-06b5b, now drops your eye to 1.0).
- **Two Unit109s** (L-07b, 2026-11-10): the dev corridor's own short hall has units 109 to 114,
  and so does a floor. `workspace:FindFirstChild("Unit109", true)` found the corridor's, so a
  Server `RollUpDoor.play` opened the wrong door and the kept player stayed kept. Look the kept
  unit up under `Workspace.DevCorridor.Floor1`. To see a kept body as a friend would (your own
  screen never draws it): on the Client clone your character (`Archivable` on, then off), strip
  its scripts, anchor its root, set every part's `LocalTransparencyModifier` to 0; set the door's
  `CurtainClosed`, `Slat_A`/`B`/`C`, `BottomBar`, `LatchBolt` and `Padlock` to 1 on that screen
  only; raise `Lighting.Ambient`; `screen_capture` from 4.5 studs outside the door face.
- **Testing getting kept from the MCP** (L-07a, 2026-11-10; rechecked L-14e): seed 7, floor 1.
  Pivot the character to (47, 3, -632) looking +X, point the camera at Unit 157's
  `DoorOrigin.DoorButtons` (an Attachment: `WorldPosition`) and tap Open from the Client: caught in
  2.5 to 7 s (it freezes while the hall light is lit), Output names the unit you're kept in (at
  random). Look the floor's units up under `Workspace.DevCorridor.Floor1` (Two Unit109s, above).
  To lift your door alone, from a Server
  `execute_luau`: `require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor).play(unit, "Open")`;
  Doors hears the door's motion attribute change, so `changed` fires as from a press. Since
  L-07d that no longer lets you out: a cut does ("Testing Cut free from the MCP", below). The
  roaming Mannequin catches you again if you stand 6 studs in front of it (`Keeper` tag, its
  pivot's look). Dropped tools lie in `Workspace.Tools`; a tool's "Pick up" prompt sits on an
  Attachment outside its model (find the nearest prompt to the tool).
- **Testing banging from the MCP** (L-07c, 2026-11-10): get kept by the steps above (seed 7,
  floor 1, 157's Mannequin). `user_keyboard_input` Space taps reach the Bang action (each tap a
  press); a Client loop calling `Remotes.Bang:FireServer()` is the spam test. Read each bang off
  the unit's `DoorMotion` ("Bang|...") and the floor's `KeptBangs` from a Server `GetAttribute
  ChangedSignal` logging into `_G`. The Mannequin roams floor 1's upper halls (z -600 to -648)
  for minutes at a time, out of the 70 studs a bang carries to units on the bottom hall
  (z -700); bang every 0.65 s from a Client loop while a Server sampler watches `KeeperState`
  for Going, and it comes (about 2.5 minutes in, from 54 studs). An anchored server Part tagged
  `TripsLights`, moved by CFrame in the hall, trips the motion light there.
- **Testing a catch anywhere from the MCP** (L-16a, 2026-11-11): `ServerStorage.CatchTest:
  Invoke(player)` (Studio only) has the standing keeper nearest you catch you through the real
  catch, wherever you are: on the ladder, mid-crawl. It needs a keeper standing: on floor 1 move
  to (-6, 3.5, -591) on the Client so the "Stand one" post (`Floor1.StandMannequin`) streams in,
  then aim and press its prompt. One player kept ends the climb (ClimbEnds' wipe) as soon as the
  screen is black, so first put a stand-in friend in the world (the left-behind recipe's clone,
  tagged `StandInFriend`, anywhere). Floor 1's units sit under its hall pieces
  (`Floor1.Straight18.Unit155`); `CrawlHole.saw(Unit155, Unit153)` and `RollUpDoor.play(unit,
  "Open")` from the Server make a crawl ready, and 155's `CrawlButton` prompt is pressed from
  (55.8, 3, -621.8). The ladder at the spawn: pick it up, Lean at `Unit102`'s `LeanButton` from
  2.5 studs out, then the Climb prompt under `Workspace.Ladders`. A Client sampler (PlatformStand,
  root `Anchored`, `CameraType`, `Kept`, the move's tag) spawned from a call that returns at once
  reads the run; invoke the catch from the Server 2.4 to 2.6 s after arming it. Then the kept
  unit is the player's `KeptIn.Value`; Cut free as below, and `Humanoid:MoveTo` 8 studs ahead
  checks you walk.
- **A click on a button, from the MCP** (L-16a): `user_mouse_input` to an `instance_path` lands a
  click whose `InputObject.Position` (below the top bar's inset) goes straight into
  `PlayerGui:GetGuiObjectsAtPosition`, which skips buttons under a hidden frame (the keypad's).
  Left Alt from `user_keyboard_input` frees the cursor first (FreeCursor). A ProximityPrompt's key
  and a ContextActionService binding on the same key (G) both get it; with the binding passing,
  the prompt still fired.
- **Testing Cut free from the MCP** (L-07d, 2026-11-10): get kept (above; `KeptIn.Value` is the
  unit) and lift its door from the Server. One player can't cut themselves free, so a stand-in
  friend: on the Server set your character's `Archivable` on, clone it, set it back off, strip
  the clone's scripts, prompts, `KeptWrap` and `CutFree`, anchor its root, parent it to
  Workspace, pivot it where a friend would stand, then
  `ServerStorage.CutFreeTest:Invoke(player, clone, heldSeconds)`: it returns the refusal
  (`Kept.CutRefusal`) or "Cut" and frees you as a real cut does (Studio only, server side).
  Your own trigger goes through the real button: on the Client set
  `ProximityPromptService.Enabled` true (your screen hides prompts while kept), point a
  Scriptable camera at your root's `CutFree` attachment from 3 studs in front, wait a second,
  `InputHoldBegin`, 1.15 s, `InputHoldEnd`: Output says it was refused (Self). A friend's hold
  (the strain) needs two players; set the wrap's `KeptPull` to 1 from the Server to hear it.
  Your own screen can't show your film before the tear (CaughtView hides it), so judge its
  look on a client-side copy of `Props.KeptWrap` posed by `Kept.tearPose`. The Mannequin often
  catches you again within seconds of the cut: re-read `KeptIn` before the next step.
- **Testing the padlock from the MCP** (L-07e, 2026-11-10): in Play, set Workspace's
  `DevPadlockSeconds` (Studio only) from the Server before getting kept; 30 gives a 10 s wait,
  then the 20 s warning. Get kept (above). Log the player's `KeptWarn` (subtract
  `GetServerTimeNow()` for the seconds left), `KeptPadlocked` and the unit's `DoorLocked` from a
  Server `GetAttributeChangedSignal` into `_G`; the kept screen's line is
  `PlayerGui.Padlock[<your name>]`; each handling is a "PadlockHand" Attachment added to Terrain
  (ChildAdded on the Client). The door from the Server: `RollUpDoor.play(unit, "Open")` stops the
  clock, `"Close"` or `"Peek"` keep it running; `RollUpDoor.setLocked(unit, false)` is what a
  Cut with bolt cutters does to it (Doors hears the attribute, so KeptPlayers clears
  `KeptPadlocked`). Setting the Server's attribute in Play leaves Edit's untouched. Friends'
  lines need two players; one can be mocked by adding a TextLabel to
  `PlayerGui.PadlockLines.Lines`.
- **A game script can't read `SurfaceAppearance.ColorMap`** (L-07d, 2026-11-10, checked from a
  LocalScript in Play): "The current thread cannot read 'ColorMap' (lacking capability
  Plugin)". The command bar can, so a check from `execute_luau` passes and misleads. Its
  `ColorMapContent` (a `Content`) reads fine: `.Uri` is "rbxassetid://...". A colour map's first
  use as an image (a ParticleEmitter's `Texture`) printed "Asset content representation is being
  generated" three times in one session, then loaded (`PreloadAsync` Success) and never again.
- **`screen_capture` draws no BillboardGuis** (L-07c, 2026-11-10): not ours, nor a plain red
  80-point square on an Attachment in Terrain or on the head, `AlwaysOnTop`, while ScreenGuis
  draw. Check a billboard by its state (Enabled, Adornee, `WorldToViewportPoint` on screen) and
  leave its look to the owner.
- **A SurfaceGui on a part's Top face** (L-07c, 2026-11-10): the canvas's x runs along the part's
  Z (its size across, at `PixelsPerStud`, gives it away: 32 by 160 for a 1.6-deep, 8-wide part),
  starting at the part's +Z end; a UIGradient at Rotation 180 starts at its -Z end.
- **A UIPadding pads every child** (L-07c): a label placed "under" a padded TextButton at
  `UDim2.new(0.5, 0, 1, 6)` lands inside it. Put the button and its label side by side in a
  plain holder Frame.
- **A script's `Humanoid:Move` on the Client barely moves you** (2026-11-10): the PlayerModule
  sets the move from your (empty) input every frame, so `Move` from an `execute_luau` gets a
  frame or so (a stud a second). `character_navigation` walks for real. This was the "couldn't
  move after a catch" in the Queue: not a bug in the game.
- **`ProximityPromptService.Enabled`** (read in Studio, 2026-11-10): exists (true by default);
  set false on a client, it hides every prompt on that screen only. The server must still refuse.
- **First person turns the body to the camera** (L-07a, 2026-11-10): with `LockFirstPerson`,
  `Humanoid.AutoRotate` turns your root on your own screen to wherever the camera points, even
  over a server pivot of an anchored root, so a camera turned "the way the body faces" chases its
  own tail. Turn `AutoRotate` off first, then aim the camera along the root's look.
- **Testing the peek's kneel from the MCP** (L-06b5b, 2026-11-10): seed 7, floor 1. From the
  Server pivot the character to (48.5, 3, -632) looking +X (157, the guard) or (47.5, 3, -624)
  looking -X (154, a sleeper). In one Client script point the camera at the unit's
  `DoorButtons`, wait a second, `InputHoldBegin`/`End` on the prompt whose `DoorAction` is
  `Peek`, wait 1.2 s, then set the camera level along the door's normal; `Humanoid.CameraOffset`
  reads -3.5 and the camera's Y 1.01. A capture then draws your kneeling view; one came back all
  black once (a retake was fine). To see a friend's kneel: clone your kneeling character
  (`Archivable` on, then off): the clone keeps the server's `Kneeling` tag, so KneelView poses
  it as any friend's; strip its scripts, anchor its root, set every part's
  `LocalTransparencyModifier` to 0. The halls are too dark to judge a body: raise
  `Lighting.Ambient` from the Client (the halls' is 0.03, 0.03, 0.035) and set it back by value;
  a PointLight beside it didn't show, and the value kept in `_G` didn't come back. The rustle's
  stretch was found by sampling `Sound.PlaybackLoudness` every 0.1 s (small numbers in Studio,
  but they show where the sound is).
- **Testing a chase from the MCP** (L-06b3a2, 2026-11-09): on seed 7, floor 1, Unit 126's door is
  at world (90, 0, -700) facing +Z (the floor's origin is (0, 0, -600)). Set the character's root
  at (90, 3, -696) from the Server, then press 126's Open prompt from the Client (camera pointed
  at it, above): the awake Mannequin comes out at you. `character_navigation` walks the character
  at its run, so it makes a real chase (west to (2, 3, -696), then (0, 3, -676) round the
  junction); a Server loop sampling the body's pivot and `KeeperState` every 0.25 s into `_G`
  shows it. Teleporting the root off the floor (the spawn, (-32, 3, 0)) loses it. Rebuilding
  `KeeperMap` from `Floor.generate(1, Brix.Random.new({seed = 7}))` in a Server `execute_luau`
  finds spots it can or can't see (`KeeperMap.clear`).
- **What a frame draws, and when** (Play, Client, L-06b4a, tested): in one frame the simulation's
  steps (Heartbeat) and replicated changes come first, then every `BindToRenderStep` function (any
  priority), then `RenderStepped` connections (the client Host steps there), then `PreRender`
  connections, then the render. So a probe of what's drawn goes on `PreRender`; one bound with
  `BindToRenderStep` reads the frame before. A Motor6D's `Transform` written in RenderStepped, with
  no Animator and an anchored root, poses the parts: every Mannequin part stood within 0.0001
  studs of `Pose.solve`.
- **Studio drew 15 frames a second from the MCP** (L-06b4a): with its window in the background,
  the Client drew a frame each 0.067 s while Heartbeat ran four times a frame. Judge smoothness by
  speed per drawn frame, not by frame count.
- **Pressing 126's Open from the Client** (L-06b4a): point the camera, then wait about a second
  before `InputHoldBegin`; after 0.3 s the press did nothing, after a second it triggered.
- **Watching a keeper unseen** (L-06b4a): teleporting the player to the spawn streams floor 1's
  keeper out of the client. Anchor the player's root 12 studs over the keeper's hall from the
  Server instead (above its sight's 8): it stays streamed in and never sees you.
- **Testing the light freeze from the MCP** (L-06b3b, 2026-11-09): every `execute_luau` that sets
  the camera Scriptable has it put back to Custom when it returns, and in first person the camera
  then turns your character back to where it looks; so do the turn in the same Client script,
  with the camera Scriptable and `Humanoid.AutoRotate` off, and set the root's CFrame to face the
  keeper. Firing `Remotes.Flashlight` from the Client doesn't hold: the torch's own view sends its
  state back within 0.4 s (`Torch.Resend`); switch it as a player does, a right-click through
  `user_mouse_input`. To chase in the dark, take the `TripsLights` tag off your root on the
  Server: no light wakes for you; put it back to test the hall lights. Fixtures' pivots stand on
  the floor (y 0 on floor 1), 24 apart down the hall.
- **The server sees a player's turn late and eased** (L-06b4b3, 2026-11-10, measured in Studio
  at a 1 ms ping): a snap turn of your root on the client starts to show in the server's
  `HumanoidRootPart.CFrame` 0.06 to 0.13 s later and is eased in over another 0.15 to 0.4 s
  (Roblox smooths a client-owned character). Anything the server judges from where a player
  looks should take the client's own word, as the torch's heading does (D-084).
  `Player:GetNetworkPing()` read 0.001 in Studio.
- **Testing the torch's freeze on your screen from the MCP** (L-06b4b3, 2026-11-10): seed 7,
  floor 1. Server: `TripsLights` off, character at (47, 3, -632) facing +X; right-click the torch
  on. One Client script: turn the camera from `BindToRenderStep` at `Camera.Value + 1` (where
  Roblox's camera turns it, before the Host's step; turned on `PreRender`, KeeperView sees it a
  frame late), Scriptable with `AutoRotate` off, looking at 157's `DoorButtons`; tap Open, face
  -X; 0.25 s after the first walking `Hunting` record turn to the drawn body, and log each
  `PreRender` (the body's pivot, its `RightHip` Transform X: 6 is the pass-right key). Output's
  `KeeperView:` lines say when your beam held it, when the server's stop came and how far on, and
  when the light let go. A shut door: stand at (50.5, 3, -638.5), tap Open, tap Slam 2.15 s later
  (the guard, going out to look, is trapped), then stand at (46, 3, -632) facing +X.
- **Testing the keeper's tell from the MCP** (L-06b4b2, 2026-11-10): seed 7, floor 1. Log from
  the Client with a `task.spawn`ed `RenderStepped` poll over each keeper body's root: a Sound
  named `Keeper*` that is playing with a `TimePosition` lower than last frame's (or newly
  playing) was just played; read `RightHip`'s and `LeftHip`'s `Transform` X angle then to see
  the pose it landed (since L-06c1's limp: step right R28 L-24, pass right R4 L-8, step left
  R-22 L22, pass left R26 L2, slack R8 L0), and keep the lines on a LocalPlayer attribute. Peek 157's guard from (48.5,
  3, -632) and 154's sleeper from (47.5, 3, -624) as the kneel recipe does. **After a Peek pressed
  with `InputHoldBegin`, that door's other buttons stop answering** (shown, but no `Triggered`
  reaches the server, by `InputHoldBegin` or a key press): pivot the character out of reach
  (20 studs) and back from the Server, wait a second, then press. After 157's catch the guard
  roams the halls at its walk for a long log from the lobby.
- **Testing the chase music from the MCP** (L-06b4b1, 2026-11-10): seed 7, floor 1. The guard
  recipe (157, standing at (47, 3, -632)) sees you as its door gets all the way up, 2.07 s after
  the tap, and catches you 0.5 s later: enough for the sting and the catch's cut. To see the
  fade, move yourself from the Client (it owns your character): set your root's CFrame to the
  spawn (-32, 3, 0) 0.3 s after `Remotes.Hunted` says 1. For a long chase, read the roaming
  keeper's `KeeperMotion` on the Server (state, server time, feet x y z in the world, facing x z,
  pace, studs left to its stop, studs walked) and pivot the player `left - 2` studs (at most 34)
  along its facing, looking back at it: it sees you at once along its own path. A keeper far
  from you isn't streamed to your client, so do that on the Server. A sampler spawned with
  `task.spawn` from a Client `execute_luau` keeps running after the call returns; a LocalPlayer
  attribute carries its log back to a later call.
- **Testing the catch from the MCP** (L-06b3c, 2026-11-10; L-06c2, 2026-11-11): seed 7, floor 1.
  126's Mannequin is dealt asleep now (it won't come); 157's guard is awake. On the Server take
  the `TripsLights` tag off your root and pivot the character to (47, 3, -632) facing +X (wait for
  `Unit157` on the Client: it streams in late); on the Client point the camera at 157's
  `DoorButtons` WorldPosition from a `BindToRenderStep`, wait 1.2 s, then `InputHoldBegin`/`End`
  on its Open prompt. The guard steps out, sees you 11 studs off and catches you about 2.2 s
  after the open; you're kept in a unit nearby (154, 145, 109). To look at one frame of the
  catch set Workspace's `DevCatchHold` (seconds after the catch; set it on the Client and only
  that screen holds) before the open: the lunge, the black and the wake all stop there; set it
  to a later time to step on, clear it to run on. Frames judged: 0.3 the dread, 0.72 and 0.775
  the rush, 0.8 the landing, 0.86 the press, 1.6 the black, 2.66 the eyes cracked open. A
  `PreRender` logger into `_G`, armed from a call that returns at once (the open in a
  `task.spawn`), reads the real-time run. For a friend's view from one client, build a stand-in:
  a template Mannequin clone (tags removed) with a `Props.KeptWrap` clone welded to its root,
  tagged `KeptWrap` and stamped `KeptWound` = `GetServerTimeNow()`, parented last; hold it with
  `DevCatchHold`. For the torch half, right-click once before opening: the body's `Flashlight`
  model's `On` attribute says it's lit; it then hunts frozen.
- **execute_luau puts the camera back** (L-06c2): a call during which the camera's type changed
  (the catch's lunge makes it Scriptable) ends with Studio's assistant setting it back to Custom
  ("The execute_luau changed camera type. Resetting..."). Arm a real-time test from a call that
  returns before the catch, as above.
- **Testing the trap from the MCP** (L-06b3d1, 2026-11-10): seed 7, floor 1. The Mannequin in
  126 stands 9.6 studs inside and crosses the door line about 0.9 s after the door is all the way
  up, so the slam has to land in that window. Stand beside the door, out of its sight through the
  doorway: pivot the character to (96.5, 3, -698.5) from the Server (TripsLights tag off). In one
  Client script: point the camera at 126's `DoorButtons` attachment, wait 1.2 s, tap Open
  (`InputHoldBegin`/`End`), read the Open motion's start from `DoorMotion`, and tap Slam once
  `GetServerTimeNow()` passes start + 2.1. Slam is offered from the moment the door starts up (an
  opening door offers Close and Slam), but a tap in its first 0.1 s did nothing; one before the
  door is all the way up would be a lowered door, not a trap. Padlock it from the Server with the
  unit's `DoorLocked` attribute once the slam has settled: Doors reads it at its next refresh,
  which the next blow's `Doors.move` makes. A sampler logging `KeeperState` and the door's motion
  kind every 0.05 s into `_G` reads the run back; waits of 50 s per `execute_luau` stayed safe.
- **Testing the hole trap from the MCP** (L-12c, 2026-11-10): seed 7, floor 1; 157, 155 and 153
  stand in a row on the hall's east side (doors at z -632, -624, -616, facing -X), the junction
  at (48, -648). Server: `TripsLights` off, `CrawlHole.saw(Unit155, Unit153)`, and a sampler
  writing the guard's state and pivot to a `workspace` attribute every 0.05 s (a Client script
  reads it to time its steps; a keeper far off isn't streamed to you). One Client script, moving
  with `Humanoid:MoveTo` (it walks at the full run from a Client `execute_luau`): open 155 from
  (49, 3, -624) and 153 from (49, 3, -616) (the guard behind 157's shut door hears neither);
  open 157 from (50.5, 3, -638.5) and wait for the guard's `Waiting` at its front; open 133 from
  (54, 3, -648.5) and step to (49, 3, -622): it walks to 133's front (54, -649); then open 156
  from (47.5, 3, -630) and walk to 155's front (49, 3, -623): it comes up from the junction and
  sees you 24 studs off. Walk to (55.8, 3, -621.8), press 155's `CrawlButton` prompt once
  `PromptShown` fires, wait out the `Crawling` tag, walk to (49.5, 3, -616.5) then (49.5, 3,
  -622.5) and press Slam on `PromptShown`: about 0.9 s from the crawl's end; it stands its 5 s.
  A `screen_capture` mid-run took 16 s, long enough for it to roam off: capture in a run of its
  own. Hook the prompts' `Triggered` on the Server to log where it saw you when each press came.
- **A press made the moment you arrive** (L-12c, 2026-11-10; L-16b2, 2026-11-11): the server
  sees a run late, so a prompt pressed as you reach it reaches the server while it still sees you
  a few studs back (3.5 to 4.3 at a full run of 16, 0.22 to 0.27 s: Climb seen 9.2 off when
  pressed at 5.8, Saw seen out in the hall when pressed just inside). Every server check of where
  you stand for a press goes through `Arrival` (D-113). To measure one: on the Server connect
  `ProximityPromptService.PromptButtonHoldBegan` and `PromptTriggered` and log the root's place,
  velocity and distance to the prompt; on the Client pivot the character 15 to 20 studs off,
  hold the camera on the prompt each frame (`BindToRenderStep`, Scriptable), `Humanoid:MoveTo`
  the spot, and `InputHoldBegin()` on the first frame `PromptShown` has fired for it. A crawler's
  `AssemblyLinearVelocity` reads 0 on the server (the crawl sets the body's place each frame). After being
  caught, setting your root's CFrame from the Client did nothing; pivot from the Server.
- **Shots of a door in the hall** (L-06b3d2, 2026-11-10): the hall's motion light wakes only for a
  real walk (`character_navigation`; a pivot or `Humanoid:MoveTo` from the Server didn't) and goes
  dark again after some 20 s standing still, so walk, aim the camera and capture at once. In
  first person, setting `workspace.CurrentCamera.CFrame` from the Client and capturing with no
  camera gave the live view. Setting `settings().Rendering.QualityLevel` from the Client dropped
  that Client's MCP connection once (the next call worked). Studio's Automatic quality drew the
  dent flat; Level21 showed it.
- **An Edit session keeps old requires** (L-06b3d2): a module required earlier in the open Edit
  session stays cached after Rojo syncs new Source (`RollUpDoor.prepareDent` was nil; the cached
  `Specs` had no S). Require a fresh clone (`m:Clone()`, parented beside it, required, destroyed);
  a cached table can be patched for the call. Play always starts fresh.
- **Dented doors measured** (L-06b3d2): a bowed rib is about 450 triangles; the worst step shows 16
  of them in place of plain ones, about 8k triangles for a dented door against a plain door's
  1.5k merged curtain.
- **Holding the player still** (L-06b3c, tested 2026-11-10): from a Client `execute_luau`,
  neither `require(StarterPlayer.PlayerModule).ControlModule.Enabled = false` (the plugin's
  require may get its own copy) nor `PlayerModule.InputContexts.CharacterContext.Enabled = false`
  stopped W walking (4 studs in 0.8 s either way). The Humanoid's `WalkSpeed` 0 and `JumpHeight`
  0, set on the Client, held it: 0.000 studs with W held and Space pressed. `CaughtView` does
  that and gives them back only if still 0 (the server's Slots sets a heavy tool's pace).
- **Counting what replicates** (L-06b4a): on the Server, `GetAttributeChangedSignal` on a body and
  `GetPropertyChangedSignal("CFrame")` and `("C0")` on its root and joints count every write.
- **Reading the counts from the MCP** (2026-11-07): in Play, `execute_luau` on the Client can read
  `Stats.RenderBreakdown`'s items (`Opaque`, `Transparent`, `Particles`, `UI` and the rest), each
  a string like "17936 tris, 11 draws" for the main view, and `Stats.FrameRateManager.Batches`
  for the draw calls of every pass together, shadow maps included. Studio's `PerformanceStats.GPU`
  reads near 0 on this Mac, so GPU time on a phone can't be judged here.
- **The test hall, measured** (P0-02j, Galaxy A16 viewport, 685x338; nine units, two lit tubes):
  | View | Main view | Every pass |
  |---|---|---|
  | Spawn, haze off | 60,996 tris, 25 draws | 30 at Level08, 73 at Level21 |
  | Spawn, haze on (12 puffs) | 61,044 tris, 28 draws | 33 at Level08, 76 at Level21 |
  | Under a tube, haze off | 43,352 tris, 21 draws | 26 / 63 |
  | Under a tube, haze on (6 puffs) | 43,376 tris, 23 draws | 28 / 65 |
  The main view's counts are the same at Level08 and Level21; full quality's extra draw calls
  are its shadow passes. The haze costs one particle draw call plus two in the see-through pass;
  its real cost on a phone is the screen area its see-through puffs cover, which Studio can't
  show. The units are almost all of the 61,000 triangles.
- **With the corridor kit** (P0-03a, same viewport, Level21, haze on, from the new spawn at
  x = -32): 65,436 triangles in 18 opaque draw calls, 33 in the main view with UI and haze, 82
  over every pass. The three straight pieces add about 5,000 triangles of steel ceiling, and
  their identical meshes instance, so the main view has fewer draw calls than the old plain hall.
- **With the fixtures, plain walls and dead ends** (P0-03c, same viewport and spot, Level21):
  73,844 triangles in 28 opaque draw calls (P0-03b's fixtures made it 71,400 in 21), 39 in the
  main view with UI and haze, 105 over every pass. A plain wall is 556 triangles and a dead end
  958; each kind draws its three parts in three calls however many stand.
- **A laid floor** (L-01c, floor 3 of seed 7, 67 units; Studio's full window, 1430x761, Quality
  Automatic, not the phone viewport): from the lobby facing the hall, 96,344 triangles in 43
  opaque draw calls, 55 over every pass; at the first T looking down a 96-stud aisle, 111,758 in
  43, 55. All 67 units were streamed in on the client at once (a floor fits the target radius),
  and most of those triangles are units behind walls. Measure it on the phone viewport next.
- **Laying a floor in Play** (L-01c): the first Play frames are slow (Studio is loading the
  client), so a floor laid at start takes about 1.4 s by the clock for 65 ms of work; judge
  laying by its work per frame (`FloorBuilder`'s `Laid`), not by the clock. `execute_luau` on the
  Server can require `FloorBuilder` and lay a test floor (it yields fine), then `:Destroy()` it.

## Importing kit pieces

- **The corridor piece arrives whole** (Studio, P0-03a, 2026-11-07): `insert_asset` of an Open
  Cloud FBX of two MeshParts gives a Model with both parts at the right size, every part's pivot
  at the Blender origin, both SurfaceAppearances in AlphaMode Overlay, and a 45° turn about Y.
  `CorridorKit.frame` reads the floor's own box, so the turn doesn't matter.
- **An untextured part imports with no SurfaceAppearance** (Studio, P0-03b, 2026-11-07): the
  fixture's lens and eye, each a Principled BSDF with only a base colour, came in as plain
  MeshParts, so `Material = Neon` and `Color` work on them straight away. The insert also left
  every part's local Y up (a 135° turn about Y), so a SurfaceLight on the lens's Bottom face points
  down. `prepare` still strips any SurfaceAppearance from the two, in case a later export adds one.
- **A small red Neon dome doesn't bloom into a blob** (Studio, P0-03b): the fixture's eye (0.36
  across) at full red (255, 40, 24) stayed a clean dot at Level01 and Level21. The blob warning
  above is for bright, near-white strips.
- **An FBX's hash changes on every export** (Blender stamps the time), so `upload_art` sends a
  rebuilt piece again even when nothing changed. It updates the same asset in place.
- **After setting `QualityLevel` from the MCP, wait several seconds before a capture.** At Level01
  the first capture 2.5 s after the switch was black but for the tubes; the next, 20 s later, was
  lit normally.
- **CollisionFidelity does take from the MCP in Edit** (Studio, L-04c2, 2026-11-07): written by
  `execute_luau`, directly or through `Finds.prepare`, it reads back `Default` in the same call
  and the value set in the next. L-04a's "doesn't take" was that read; the boxes were set all along.
- **A re-uploaded FBX keeps its texture IDs** (Studio, L-04c2): the rebuilt Bedroom FBX (only the
  skates' placing changed) inserted with the same ColorMap `rbxassetid` as the first upload, so
  templates from two uploads still share one texture set.
- **The hall light doesn't reach into an open unit** (Studio, L-04a): with the door up and the
  nearest fixture lit, unit 101's floor and back wall stayed black on the Galaxy A16 view; only the
  facades either side of the doorway lit. Its contents showed only in a stand-in torch's beam (a
  client SpotLight at the camera, `docs/art/L-04a-unit-torch.jpg`).
- **The bulb arrived like the fixture** (L-04b): two MeshParts, the textured one with a
  SurfaceAppearance in Overlay, the plain one without, both with local Y up; every part casts
  shadows until `prepare` says otherwise.
- **Blender: an emission-only mesh blocks the light inside it** (L-04b): a point light inside the
  bulb's glowing glass lit nothing until the glass's `visible_shadow` was off.
- **A re-upload with new textures gets new texture IDs** (Studio, S1-04b1, Nov 14): the rebuilt
  Stuff FBX (only its bake changed) inserted with a new ColorMap `rbxassetid`, so replace every
  template from the new insert; the note above (IDs kept) holds when the textures didn't change.
- **A unit template's pivot is turned -90° about X** (Edit, S1-04b1): `Units.S:PivotTo(CFrame.new(p))`
  laid the unit on its back. Keep its turn: `PivotTo(CFrame.new(p) * template:GetPivot().Rotation)`;
  then its door is at local z 0 facing -Z, the inside runs to +Z. Part `.Position`s of imported
  MeshParts are their Blender origins, so read a part's box from its CFrame and Size instead.
- **The breaker arrived unturned, but its box's pivot was turned** (Edit, S2-02a, Nov 14):
  `InsertService:LoadAsset` gave three MeshParts at their spec centres with no turn, yet the
  box's `PivotOffset` carried a 90-degree turn about X (the unit's), so `Model:PivotTo` through it
  as PrimaryPart laid the box on its back. Set each part's `PivotOffset` to `CFrame.new(-centre)`.
  CollisionFidelity written to a part of the unparented `LoadAsset` result didn't take; written
  again once the template was in ReplicatedStorage, it read Box in the next call.
- **Judging a wall piece in Edit** (S2-02a): `CorridorKit.place("Straight", CFrame.new(p), f)`
  and `CorridorKit.wall("Wall", CFrame.lookAt(face, face - n), paint, f)` at ±4 across build a
  hall from the templates; the place's Edit lighting is dark (ambient 0.03), so an anchored
  invisible part with a SpotLight (Angle 50, Range 40, Brightness 3) beside the capture's camera
  stands in for a torch. Destroy it all after.
- **When the MCP's `insert_asset` fails, InsertService doesn't** (S1-10b2, Nov 14): right after
  the upload, `insert_asset` of the machine answered "Failed to load package asset: Request
  Failed" three times over half an hour; `InsertService:LoadAsset(id)` from an Edit
  `execute_luau` loaded it at once, a Model wrapping the asset's Model, every part unturned with
  its pivot on the FBX origin. Prepare the inner Model.
- **Roblox's username lookup can be down** (Nov 14): `users.roblox.com` and the Open Cloud
  assets API both answered 503 for about 20 minutes. `upload_art` takes a numeric
  `ROBLOX_CREATOR_ID` from the shell over the file's (`game.CreatorId` in Studio).
- **A SurfaceLight shone into a closed cabinet blacks out the frame** (Play, S1-10b2): on the
  machine's glass, a SurfaceLight on its Back face (into the bays, Range 3) turned every other
  lit thing in view black (the car's walls under its lamp), leaving only Neon and GUI. The one
  on its Front face (into the car) alone was fine. Not understood; avoid it.
- **The machine's sounds, measured** (Edit, AudioAnalyzer): "Toggle Switches Moviola Editing
  Machine 17" 9120089728 is 0.36 s, a snap at -11 dB gone by 0.1 s; "Light Bulb Buzz 3"
  9116270244 holds near -22 dB from 0.23 s; "Transformer Hum 1" 9112889082 holds near -29 dB
  for all of its 36 s.
- **Judging a prop in a lit unit without Play** (S1-04b1): clone `Units.S` or `.M` into the Edit
  workspace as above, destroy its door's parts (`CurtainClosed`, the slats, `BottomBar`,
  `Padlock`, `LatchBolt`, `DoorCollider`), hang an invisible part with a PointLight at
  `UnitLight`'s colour, brightness, range and shadows 0.7 under the top's middle, and capture from
  the doorway at eye height (4.6). Destroy it all after.
- **Sampling a buy on the Client** (S1-10c2b, Play): an execute can `task.spawn` a loop on
  `RenderStepped` that keeps the camera aimed (Scriptable, set every frame, so the MCP's reset
  doesn't matter) and writes a line a frame into `shared.someTable`; press E with
  `user_keyboard_input`, then read the table in a later execute. A ring tick reads lit when its
  `BackgroundTransparency` is under 0.2.
- **Attribute signals in one batch fire before the next frame, in the server's order** (S1-10c2b,
  Play): the Player's charge (written first) fired before the machine's `Stock`. A screen that
  must react to two changes together reads them in its frame step, not in either signal.
- **Staging a buy** (S1-10c2a, Play): stage the ride as below, then from the Server set
  Workspace `DevCoins` (every count in a climb) and stand the player's root about 2.4 studs in
  front of a button. On the Client set the camera Scriptable and `CFrame.lookAt(head, button)`,
  then press E with `user_keyboard_input`: that's a real buy. The MCP resets the camera to Custom
  after each execute, so aim and press close together; `ProximityPromptService.PromptShown` on
  the Client says which bay is up. A battery needs a torch that isn't full: Workspace
  `DevTorchSeconds` 600 makes the 300 s in it read as half a torch.
- **ProximityPrompt choice among close buttons** (Play, S1-10c2a): with six prompts 1-2 studs
  apart, Roblox showed the one the camera aimed at each time it was asked, but once showed a
  neighbour; name each prompt for its thing so the player sees what they'd press.
- **Staging the machine's stock** (S1-10c1, Play, the test hall's floor 3 car): from the Server
  set Workspace's `DevRideHold` to 8, then the car's `Ride` to `Ride.encode(now, 3, 4)` and its
  `Aboard` to `Departure.encodeAboard(now, { userId })`: Machines deals the stock at once. Step
  the reveal on the Client alone by setting its own Workspace `DevRideHold` (1.3 the bottom row
  there, 1.75 its 88, 2.0 its price, 19.7 all gone). A chosen stock: set the machine's `Stock`
  attribute from the Server (Machines rewrites it only when the car's ride changes). The
  first-person torch is the Client's `Workspace.YourFlashlight`; move it out before a capture.
  A capture right after a camera jump came out black until the Client's QualityLevel was Level12.
- **`scripts/art.sh machine export` rewrites `Machine.fbx` with new bytes** (same size, same
  geometry: a timestamp). When only the Specs needed regenerating, restore the FBX from git so
  it still matches the uploaded asset.
- **Blender: small geometric bevels starve the atlas** (S1-10b1, `art/machine/`): 0.02-0.03
  bevels with two segments made strips under a texel wide at 45 texels a stud, so their middles
  missed the bake (397 faces) and their islands' margins ate the pack (35% used). Dropping them
  for the bake's Bevel node, a 4-texel margin, and shrinking the UVs of what's only seen through
  glass (`thin`) before `pack_islands(shape_method="CONCAVE")` gave 43% and 54 faces.
- **Blender: one atlas for unlike pieces** (S1-04b1): smart-project both meshes together in
  multi-object edit mode, then `uv.pack_islands(rotate=True, margin_method="FRACTION",
  shape_method="CONCAVE")`: 70% of the atlas used, against about 35% for a square per piece.
- **Lune: loading a generated Specs module** (S1-04b1): Specs that build `Vector3`, `Vector2` or
  `CFrame` fail under `require` in Lune. Load them with
  `luau.load(fs.readFile(path), { environment = { Vector3 = roblox.Vector3, ... } })()`
  (`tests/stuff.spec.luau`).
- **A full FBX of props arrives as one Model of MeshParts** (Studio, L-04a): `Boxes.fbx` gave five
  MeshParts at their real sizes, each pivot at its Blender origin (the bottom's middle), each
  turned 135° about Y with the model, each with a SurfaceAppearance in Overlay and no MetalnessMap.

- **The elevator arrived like the kit** (L-05a2): 24 MeshParts, every pivot on the threshold
  (the gate's parts and the note too, as built at the FBX origin), a 45° turn, SurfaceAppearances
  in Overlay; `LampGlass`, `KeypadReadout` and `KeypadLight` came plain. Each part's centre sat
  within 0.0005 of `Specs.Parts`.

- **The flashlight arrived like the finds** (L-11a): two MeshParts at the right size, the torch with
  its SurfaceAppearance (Overlay), the lens plain, a 178-degree turn about Y, each pivot at the
  Blender origin (the grip). `Flashlight.prepare` squares them to the world.
- **Rigs turn the grip attachment differently** (Play, L-11a): Studio's own avatar's
  `RightGripAttachment` sits near the hand's middle (its hand 0.75 x 0.89 x 0.77) turned so its
  look runs down the arm. Weld a held thing from the attachment's Position and turn it from the
  hand itself, or it points the wrong way on some avatars.

- **`insert_asset` turns the whole model** (L-12b1): the crawl hole's kit came in turned 178.1°
  about Y, every part alike. Square a kit by one part's own `CFrame` (its frame is the FBX's):
  `CFrame.new(specCentre) * anchor.CFrame:ToObjectSpace(part.CFrame)` for each part
  (`CrawlHole.prepare`); moving it by position alone leaves it turned.
- **Thin strips in an atlas** (L-12b1, Blender): faces built as separate quads are each their own
  UV island (376 for the hole's edge, most of the atlas margin); share their points. Smart
  project's margin is per island, so long 3-texel strips with 6 texels of margin each side fill a
  quarter of the atlas at best: a 2-texel margin and `uv.pack_islands(shape_method="CONCAVE")`
  after it (works headless with `use_uv_select_sync`) got the edge to 123 texels a stud at 512².
- **A bulb lights through a hole** (L-12b1, Galaxy A16): with a crawl hole between them, a lit
  unit's bulb lights the shut neighbour's floor by the hole, as it should; nothing else of a
  shut unit lights.
- **The Packrat arrived like the Mannequin** (Edit, S2-06a2, Nov 14): `insert_asset` worked
  first time and gave a Model of fifteen MeshParts turned -94.2 degrees about Y, local Y up,
  every pivot on the floor between its feet, one SurfaceAppearance (Overlay) on each, a
  PackageLink and an `Assistant:` tag on the model (`Packrat.prepare` removes both).
- **Measuring a gap on a posed body with rays** (Edit, S2-06a2): parts are `CanQuery`, so a
  `workspace:Raycast` with an Include filter of one part (the UpperTorso from in front, then the
  forearms out from the chest) gives each surface; read the hits in the chest's own frame
  (`UpperTorso.CFrame:PointToObjectSpace`). That's how the carry point was put between them.
- **An asset updated in place inserts as its new version at once** (L-08e1a): after
  `upload_art` PATCHed the lobby's FBX (same ID), `insert_asset` brought the new size. And an
  **Edit** `execute_luau` keeps the first copy of a module it required, as a Client one does: a
  `prepare` after Rojo synced a change ran the old code. Check the template's values after, or
  set the changed ones by hand.

## Tools

- **Driving Studio from a session:** `.mcp.json` starts Studio's own MCP server
  (`/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`, the same one the owner's Game1
  folder uses). A session only loads MCP servers when it starts, so a server added mid-session
  needs a new session. Studio must be open on this game's place; with two places open it's
  unknown which one the server talks to. Search for its tools with ToolSearch (try `studio`,
  `run_code`, `Roblox_Studio`) before concluding Studio can't be driven.
- **What the MCP can do** (P0-02): `execute_luau` in Edit, Server or Client; `insert_asset` by
  ID; `start_stop_play` (one player only, so two-client tests are the owner's); `screen_capture`
  with a camera position; `http_get` on create.roblox.com docs (`.md` URLs). This Studio build has
  **no `open_cloud_invoke`**, so uploads go through `scripts/upload_art.luau`.
- **`execute_luau` isn't a full plugin:** members gated to PluginOrOpenCloud or RobloxScript read
  as "not a valid member" or "lacking capability" (`Workspace.StreamingMinRadius`,
  `StreamingTargetRadius`, `StreamOutBehavior`). `inspect_instance` returns no properties for
  Workspace or Lighting either. Check those in the Properties panel. It can still require the game's modules, set AlphaMode, destroy a
  PackageLink and set ChangeHistory waypoints.
- **Playtesting through the MCP** (P0-02b): `user_keyboard_input` key presses trigger
  ProximityPrompts; `character_navigation` walks the character there; setting
  `workspace.CurrentCamera.CFrame` on the client turns the Custom camera. `screen_capture` with no
  camera position shows the player's view, with one it moves the camera; CoreGui (prompts) never
  shows in captures, so read `prompt.ObjectText` on the server for refusals, and track shown prompts
  with `ProximityPromptService.PromptShown` and `PromptHidden`. A capture with a camera position
  far from the player (the laid floor, 600 studs off) showed only sky (L-01d): most likely
  streaming hadn't sent that area to the client, so move the character there first ("Walk a
  floor") or check by numbers on the server. With Studio in the background the
  client ran at about 15 fps, so time feel by the clock, not by frames.
- **Luau's negative zero:** `-j * 2` with `j = 0` is -0, equal to 0 but printed "-0", so a text
  key like `` `{x},{z}` `` misses its match. Write `0 - j * 2` (Floor's grid, L-01a).
- **`require` in Edit is cached:** after Rojo syncs a change, `execute_luau`'s `require` still
  returns the module from the first call. Require a `:Clone()` of the module tree for fresh code.
- **A folder module requiring by string** (S1-07b, Nov 14): in `src/shared/Battery/init.luau`,
  `require("./Flashlight/Charge")` finds `Shared.Flashlight.Charge` in both Lune and Studio: an
  `init.luau`'s `./` is the folder's own siblings (the ModuleScript's parent's children), not its
  children. `../` would go one level too far. Checked in Edit by requiring a clone of `Shared`.
- **Measuring the bulb's click** (L-04b): Pro Sound Effects' "Moviola Toggle Switch Single Clicks
  Sharp 8" (9117028600, 0.74 s) is a sharp tick in its first 0.1 s and a faint release at 0.25 s;
  "Light Bulb Buzz 2" (9112823813) is a 49 s loop. Both preload in Edit.
- **The MCP's clicks on a ScreenGui button in the Device Simulator** (L-11a; corrected L-20a):
  `instance_path` doesn't fire it, but coordinates do with the A16 mapping below: click at
  (AbsolutePosition X + 47, AbsolutePosition Y) of the button's middle (a ScreenGui's Y is the
  viewport's minus the 58-point inset). The wheel's button, a slot and the box all took taps so. A gamepad key from `user_keyboard_input` (ButtonR1) does reach ContextActionService;
  it also hides Roblox's touch controls, as a real gamepad does.
- **The flashlight's clicks, measured** (L-11a; 10 ms bins at PlaybackSpeed 0.25, AudioAnalyzer in
  Edit): Pro Sound Effects' "Flashlight On Off Clicks 13" 9114480271 is one click at 0.40 s, about
  60 ms, -20 dB, 1.17 s long; "15" 9114480269 one click at 0.12 s, -22 dB, 1.06 s long.
- **The Device Simulator from the MCP** (2026-11-07, skill `rbx-device-simulator-lua`): set the
  device in Edit before Play (its setters fail in Play's server view), then the orientation:
  `SetOrientationAsync` before a phone is active fails ("only on mobile devices"). The Galaxy
  A16 (`samsung_galaxy_a16`, 780x360) is the list's mid-range Android; `screen_capture` then
  returns 668x308 with the touch thumbstick and jump button drawn. `StopSimulationAsync` when
  done; the scaling mode (ScaleToPhysicalSize here) persists, so leave it alone.
- **The importer keeps each part's FBX axes** (P0-03d, 2026-11-07): an inserted MeshPart's own
  frame is the FBX's, turned with the model: its local X is Blender's -x, Y Blender's z, Z
  Blender's y (the export's `axis_forward="Z"`, `axis_up="Y"`). The fixture's eye, at Blender +x,
  sits at the Diffuser's local -X. So a square part's own `CFrame` still tells its turn, which
  is how `CorridorKit.frame` reads a junction's.
- **`screen_capture` can stop answering mid-Play** (P0-03d): after about ten captures with camera
  positions, each later one timed out and `Stats.RenderBreakdown` stopped changing. Take the shots
  that matter first; measure the render cost early in a session.
- **`start_stop_play` with Play already running** answers "Game Started" and changes nothing: stop
  first, or new code never loads.
- **Tagged templates sit in ReplicatedStorage:** `CollectionService:GetTagged` and its added
  signal return the unit template (`ReplicatedStorage.Units.M`, at the origin) along with the
  placed units. Filter to `IsDescendantOf(Workspace)`. Missing it, BehindDoors took the template
  for a shut unit in mid-hall and darkened the hall as you walked through (fixed Nov 7).
- `insert_asset` tags what it inserts `Assistant:<guid>`; remove the tag before keeping the model.
- **Triggering a prompt and judging low graphics from the MCP** (L-03, 2026-11-07): a key press
  from `user_keyboard_input` reaches a prompt only while it's shown, and it shows only with the
  camera facing it; then `prompt:InputHoldBegin()` and `InputHoldEnd()` in the Client view trigger
  it. `settings().Rendering.QualityLevel` can be set from the Client view mid-Play (Level01 for a
  low-graphics phone); put it back to Automatic.
- **Coin sounds measured** (S1-04a1, Nov 13; Edit, AudioPlayer to AudioAnalyzer at a quarter
  speed, `PeakLevel` in 50 ms bins): Pro Sound Effects' "Coins In Pocket 2" 9113849162 (1.49 s) is
  quiet but for one bright chink at 1.13 to 1.35 s (peak 0.17); "Coins In Pocket 1" 9113849100
  (1.22 s) is a low jingle from 0.25 to 1.0 s. User uploads ("coin clink" and the like) were
  skipped: only the licensed library is sure to load in any game.
- **Sounds from the audio library** (L-03): `search_asset` with `assetType = "Audio"` finds them;
  Pro Sound Effects' and APM's uploads are Roblox's licensed library and load in any game. Check
  one in Edit with `ContentProvider:PreloadAsync` (status Success, `TimeLength` above 0) before
  relying on it.
- **Sounds measured for the chase** (L-06b4b1, 2026-11-10; Edit, AudioPlayer to AudioAnalyzer):
  an unparented `Sound` reads `TimeLength` 0 even after a Success preload; an `AudioPlayer` in
  SoundService reads it once `IsReady`. With `SpectrumEnabled` on, `AudioAnalyzer:GetSpectrum()`
  gives 512 bins up to 24 kHz: sum their squares over a few seconds for where a sound's energy
  sits. APM's stings, 0.1 s bins: "Rising Fear Hit 1" 1841353894 (7.55 s) full by 0.1 s, loud to
  0.8 s, gone by 7 s, centroid 1.35 kHz; "Brute Force Sting 3" 1837950656 loud 0 to 1.2 s, mostly
  under 150 Hz; "Shock (A)" 1840489046 silent to 0.3 s; "Evil Mind 9" 1846887425 peaks 0.2 to
  0.6 s; "Midnight Horror - Sting" 92700004957359 a flat texture, no hit. APM's beds are steady
  for two minutes, and seven of eight ("Rhythm Drone 44" and "50", "Tension Repeat Drones" 10,
  23, 28, 29, "No Escape A") keep 60 to 96% of their energy under 150 Hz, which a phone speaker
  barely plays; "Tension Repeat Drones 39" 1843739491 (128.6 s) keeps 82% at 150 to 500 Hz,
  swells about every 5 s and fades out from about 120 s.
- **The command bar caches `require`** (L-11c): after Rojo syncs a module, requiring it from
  `execute_luau` in Edit can still return the old one. Require a clone instead
  (`require(ReplicatedStorage.Shared.Tools:Clone())`), then destroy the clone.
- **Sounds measured for the catch** (L-06c2, 2026-11-11; Edit, AudioPlayer to AudioAnalyzer with
  `SpectrumEnabled`, 50 ms bins and the share of the first 1.5 s under 190 Hz / 190 to 470 / 470
  to 2k / 2 to 6k / over 6k; then a quarter speed and 20 ms bins for the attacks). Chosen: "Creature
  Screech Pterodactyl Vocals Screams 1" 9125474229 (0.92 s) up within 60 ms, 0/4/48/47/1, centroid
  2.2 kHz (6 9125474505 and 7 9125474511 are quieter, 1.7 to 2 kHz); APM "Razormorph K" 1846681042
  (6.5 s) full in 20 ms at about -6 dB RMS, rings for seconds, 50/21/20/8/1; "Whoosh Fast Swish By
  5" 9120714365 (1.1 s) rises from 0 to its peak at 0.36 to 0.5 s, 9/35/49/7. Passed over: Daily
  Sounds' "Horror Stinger" 130018094603454 (builds to a peak at 0.65 s), APM "Shock Chord"
  1845391028 (ramps over 0.3 s), "Rising Fear Hit 3" 1841353939 (sharp, but 67% under 190 Hz),
  "Supernaturalizer Hit 2", "Beautiful Horror - Stinger" 1 to 3, "Ghosting The Machine Tonal
  Stab", "Showdown At The Docks 18" (55 to 87% under 190 Hz), "Shock (A)" (silent to 0.4 s),
  "Piano Strings Attack 3", "Whoosh Fast Swish By 4". In Play, the caught screen's
  `PlaybackLoudness` peaks: Razormorph 748 at volume 1.1, the screech 286 at 1.6 (raised to 2.4
  over Razormorph's 0.9 for phones), the whoosh 284, the Lunge beat's scrape 188 and creak 64, the
  Catch beat's weight 488 and thunk 303. The library's search turns up mostly re-uploads of other
  games' jump scares (FNaF, Doors, Spooky's): never those.
- **Sounds measured for the ride** (L-08a, 2026-11-11; AudioPlayer to AudioAnalyzer with
  `SpectrumEnabled`, 0.5 s bins and the share under 190 Hz / 190 to 470 / 470 to 2k / 2 to 6k /
  over 6k; then 20 ms bins at a fifth or a tenth of speed for the hits). Pro Sound Effects'
  "Freight Elevator" set is quiet and mostly bass: "Freight Elevator 3" 9114533164 (19.6 s) has a
  brake-release clunk at 1.13 s (6/32/47/12/3) and a stop clunk at 15.15 s (8/17/53/15/8, the
  loudest thing in it), its run between nine tenths under 190 Hz; "Freight Elevator 2"
  9114533808 (45.9 s) runs steady from 15 to 24.5 s, three quarters under 190 Hz; "1" 9114533169
  and 9114533605 are quiet start-stop clatter. A phone barely plays any of their runs, so the
  motor is "Conveyor Belt 5" 9113910297 (13.7 s): a hard knock at 0.24 s, then a clanky motor
  steady from 0.5 to 13 s at about -25 dB (at volume 0.3), 40 to 59% at 190 to 470 Hz and 30 to
  40% at 470 Hz to 2 kHz, stopping at 13 s. "Conveyor Belt 2" 9113910179 is similar and rougher.
  The library has no single elevator arrival ding from a licensed creator; the ride reuses the
  right code's double-ding 9119642644. In Play the ride's sounds read in order on the rider's
  screen (release, motor and rumble from 0.9 s, clanks, the tick at 7.2 s, the stop and brake
  from 9 s, the bell at 9.75 s) and on no other screen.
- **`PlaybackLoudness` reads the recording, not the Sound's `Volume`** (Play, L-08a): the ride's
  motor faded to Volume 0 still read 30 to 50, so compare loudness at equal volumes or multiply.
- **Testing the ride from the MCP** (L-08a, 2026-11-11): seed 7, floor 1, the elevator at (0, 0,
  -588), the car toward +Z. From the Server pivot your character to (-7.8, 3, -591.5) facing the
  keypad; from the Client fire `ReplicatedStorage.Remotes.Keypad:FireServer(elevator, digit)` for
  1, 0, 9, 7, 0.45 s apart; then pivot to (0, 3, -581) facing -Z (aboard). The gate shuts about
  31 s later. MCP calls and captures took 3 to 5 s each in Play, slower than the ride, so to look
  at a frame set Workspace's `DevRideHold` (Studio only) to the seconds into the ride you want,
  from the Server before the car leaves or while it rides: the car never arrives while it's set,
  and every screen draws that moment (shaft, sway, lamp, readouts). Clearing it fast-forwards: the
  car arrives, opens and is armed again at once. Turn the Client's camera to the gate
  (`CFrame.lookAt(pos, pos + Vector3.new(0, 0.1, -1))`) before capturing. A real-time ride is best
  logged from a `task.spawn`ed RenderStepped loop that the call leaves running (`_G` for results).
- **A Sound's LoopRegion inside its PlaybackRegion works** (S1-10a, 2026-11-14, Play): with
  `PlaybackRegionsEnabled`, `PlaybackRegion` 0.45 to 12.4 and `Looped` with `LoopRegion` 2 to
  12.4, the ride's motor played straight from 0.45, then went round 2 to 12.4 (TimePosition
  12.0 then 2.7 a second later), no stop between. The rumble (15 to 24.5, loop from 16) alike.
- **The dev floor's ride ends the climb** (S1-10a, 2026-11-14): on seed 7, floor 3, code 2274,
  the climb's top is floor 3, so its ride goes to the results (`ClimbEnds: ... (Top)`) and your
  character is gone after it. To watch a ride arrive on a next floor, start lower (Workspace's
  `DevFloorNumber`). The S1-07b recipe also worked: `Floor.generate` and `Deal.new` with
  `Climb.seedOf(7, 3)` from an Edit `execute_luau` name the units with batteries (309, 314);
  open 309 from 4.5 studs out on its +LookVector side and take the battery
  (`Straight18.Battery.Take.ProximityPrompt`) standing beside it.
- **Testing the climb from the MCP** (L-08b, 2026-11-11): a climb starting on floor f lays floor n
  with its lobby's middle at (0, 0, -600 - 1000 (n - f)), its elevator 12 studs behind it (the
  first at (0, 0, -588)); added to that pivot, the keypad spot is (-7.8, 3, -3.5) and aboard
  is (0, 3, 7). Punch the code from the Client (`Remotes.Keypad`, as above): the next floor lays
  then (Output prints its map, code and notes). Board and wait about 27 s for the gate; the move
  lands 6.1 s into the ride ("rode up to floor n" in Output). `DevRideHold` holds the hand-off
  too: the takeover waits for 5.6 s and the move for 6.1 s on the held clock. Unit doors open by
  their Open prompt (`DoorAction`) as in "Driving a ProximityPrompt"; a door face is
  `FloorBuilder.face(unit)` from the Server (require `ServerScriptService.Server.FloorBuilder`).
  Caught and kept with nobody to cut you free, `Player:LoadCharacter()` from the Server lets you
  out and "Walk a floor" (it names the climb's floor) takes you back. Seeds used: 7 (codes 1097,
  0566, 4275 from floor 1) and 23 (1631, 8468, 4050).
- **Testing left behind from the MCP** (L-08c, 2026-11-11): one player can't ride and stay, so
  stand-in friends ride: on the Server clone your character (as in the Cut free recipe), strip
  its scripts, anchor its root, name it (the bar shows the name), tag it `StandInFriend`
  (`Left.StandInTag`) and pivot it into floor 1's car facing the gate (`(±2.3, 3, -581.5)` for
  the first floor at -600); two of them to test switching. Punch the code, step back into the
  lobby (`(0.5, 3, -597)`), and when the gate shuts you're left: stand-ins in the car count as
  riders (Climbs) and are carried into the next car at the move. `DevRideHold` holds the sting
  with the ride (WatchView reads `RideClock`): 0.75 for the title, 2.6 for the bars and the HUD
  gone. The move waits on the held clock for the takeover's moment plus `Climb.Lead`: held at 2.6
  then raised to 12, the takeover lands at 12 and the move wants 12.5, so raise it to 13 to see
  the watch. Clearing it fast-forwards the arrival, the open and the re-arm in one go, so see the
  gate open on you in real time: a Server call that waits until 9.4 s after `LeftBehind` and
  returns, then a capture, lands on the lift; another lands on the open gate. `Remotes.Watch`
  takes "Next", "Back" and "CutFree" from the Client. Set the Client's
  `settings().Rendering.QualityLevel` to Level12 first (the Edit setting doesn't carry into
  Play), or the car draws black after the 1000-stud move.
- **Testing the end from the MCP** (L-08d, 2026-11-11): one player, no stand-ins. A wipe: the
  catch recipe above (seed 7, floor 1, 157's guard) ends the climb about 1 s after you're kept
  (Output: "ClimbEnds: the climb ended (Kept)"). The top: set Workspace's `DevFloorNumber` to 3 in
  Edit, Play, punch floor 3's code (seed 7: 4275) and step aboard as in the climb recipe; the
  gate shuts about 31 s later and the end is set as the car leaves (white from 6.1 s). Left
  behind into a wipe: the left-behind recipe, then destroy the stand-ins on the Server once
  you're watching. To look at one frame, set `DevRideHold` on the **Client** (only that screen
  holds; EndView runs on `RideClock`): 3.64 the title slamming, 4.14 a photo landing, 12 all of
  it. Press Again with `user_mouse_input` (moveTo `LocalPlayer.PlayerGui.ClimbEnd.Content.Again`,
  then a left click) or `user_keyboard_input` Return. For phone size, set the Client's
  `PlayerGui.ClimbEnd.Content.Size` to `UDim2.fromOffset(750, 360)` (a landscape iPhone's safe
  area) and capture; set it back to `fromScale(1, 1)`.
- **Testing a wipe mid-carry** (S3-01b, 2026-11-14): one player and two stand-ins, no captures.
  In Edit set Workspace's `DevFloorNumber` to 2 (seed 7; clear it after: nil is floor 3), Play;
  Output names the code ("floor 2's code is 9199" on Nov 14). Stand-ins as in "Testing left
  behind" at (±2.3, 3, -581.5) facing -Z; you at (-7.8, 3, -593.2) facing the keypad; from the
  Client fire `Remotes.Keypad` with `Workspace.DevCorridor.Floor2.Lobby.Elevator` and each digit,
  0.45 s apart; then from the Server pivot to (0.5, 3, -597) and, in the same call, wait for your
  `CarriedAt` (set as the car arrives on floor 3, about 39 s later, left behind at 20 s), destroy
  the stand-ins and watch for Workspace's `ClimbEnd` (1.1 s later) and your `ClimbFate`
  (`Kept|3`). Again from the Client: `Remotes.Again:FireServer()`.
- **A locked Mac stops Studio drawing** (2026-11-11): with the screen locked, the Client's
  `RenderStepped` fired 0 times a second, so the client Host (stepped on it) stood still and
  `screen_capture` timed out, while Heartbeat ran on. `caffeinate -u` woke the display for 30 s
  only; `caffeinate -d -u -t 2400` kept it on, and Studio drew at about 15 frames a second behind
  the lock screen. Check with a one-second count of `RenderStepped` before trusting a log.
- **Scaled text stops at 100 px** (L-08d): a `TextScaled` label never draws past 100 px, so a
  `UIScale` over it grew its box but not its text on a big screen. A title that has to grow
  (EndView's slam) takes a fixed `TextSize` from the screen's height instead.
- **Quality set in Play stays after Stop** (L-08d): `settings().Rendering.QualityLevel` set to
  Level12 on the Client in Play was still Level12 in Edit after Stop; set it back to Automatic.
- **A character taken away stays away** (2026-11-11): `player.Character = nil` then
  `character:Destroy()` on the server left the player with no character for minutes with
  `CharacterAutoLoads` on (only a death respawns); `player:LoadCharacter()` brings one back.
  `ReplicationFocus` set to another model's root streamed the world round it to that player with
  no character of their own, and an ObjectValue pointing at that model read nil on their screen
  until it streamed in, then the model.
- **execute_luau's camera reset bites a watcher** (L-08c): a Client call made while watching
  (camera Scriptable) that lets you back in ends with the assistant setting the camera back to
  Scriptable after WatchView set Custom, so the next sting logged a still camera. Fire Cut Free
  from a call that returns at once (WatchView turns the camera Custom after it ends), not one
  that waits for your new character.
- **`screen_capture` with a camera position leaves the camera Scriptable** (Play, 2026-11-11), and
  `execute_luau` puts back whatever camera type it found when the call began, so a later call
  setting Custom is undone ("Resetting from Custom back to Scriptable"). A ride then logs the
  camera standing where the capture left it. Put it back with `task.delay(1, ...)` setting
  `CameraSubject` and Custom, which runs after the call, and capture without a camera position
  while testing anything that moves the character.
- **Studio stops drawing when the Mac's display sleeps or locks** (2026-11-11, overnight):
  `RenderStepped` stops (0 frames a second) and every `screen_capture` times out while scripts
  still run. `caffeinate -u -t 1800` in a background shell woke it and kept it drawing (`-d` alone
  didn't); it ends on its own.
- **A 1000-stud move under Automatic graphics quality** (Play, 2026-11-11): after the hand-off's
  move the car drew black (only the readouts and plates, which light themselves) for 10 to 30 s,
  the torch's view model hidden too, though its lamp was on at full brightness; the move's long
  frame drops Automatic's level and it climbs back slowly. At a fixed `QualityLevel` Level12 the
  same move drew the car lit at the first capture, 4 s later. Fix the level before judging a
  far move's look. `Player:RequestStreamAroundAsync(position, timeOut)` (verified on
  create.roblox.com: yields; temporary, no guarantee) streamed the new lobby in, but a 20 s
  `DevRideHold` let it go again: ask again right before moving anyone.
- **The kept wrap's squeal, measured** (L-07b, 2026-11-10; Edit, AudioPlayer at half speed to
  AudioAnalyzer, 0.1 s bins, spectral centroid per bin): nothing in the library is titled
  stretch film; a tape screeching off a roll is the same sound. Pro Sound Effects' "Duct Tape
  Richard Epilates Himself 2" 9114200236 (3.0 s) holds a steady peel from 0.6 to 2.6 s at -24 to
  -12 dB, centroid 1 to 2 kHz (the one used); "... 3" 9114200240 (2.25 s) is short bursts;
  Daily Sounds' "Tape Pull" 91534288572394 (1.16 s) one loud pull at 0.4 s; "Plastic Bag
  Handling Crunchy Cellophane 8" 9117409739 crunches 0.2 to 1.5 s, centroid near 1 kHz.
- **Sounds measured for cutting free** (L-07d, 2026-11-10; Edit, AudioPlayer at half speed to
  AudioAnalyzer, 50 ms bins, then a quarter speed and 20 ms for the chosen): Pro Sound Effects'
  "Plastic Sheet Impacts Rips Paper Tears" 1 to 9 (9117624452, 4545, 4703, 4721, 4735, 4959,
  4995, 4991, 9117625280): 2 is one snap at -4 dB gone by 0.15 s; 5 and 6 a steady 0.35 s tear
  near 3 kHz at -15; 7 a long build with a hit at 1.75 s; 9 (the one used) silent to 0.31 s,
  then a hard tear (peak -5 dB at 0.36 s) with bursts to 1.1 s at -10 to -25 dB RMS, centred 1
  to 2 kHz. "Cloth Rip Zippy" 4 and 8 and "Cloth Rip Rapid 2" are nylon zips, 2 to 4 kHz.
  "Plastic Bag Handling Crunchy Cellophane 8" 9117409739 crunches from 0.36 s at only -30 to -35
  dB RMS (the heap's crunch, turned up).
- **Sounds measured for the padlock's warning** (L-07e, 2026-11-10; Edit, AudioPlayer at half
  speed to AudioAnalyzer, 50 ms bins of 6 dB): Pro Sound Effects' "Keys In Padlock" (keys in a
  padlock on a cage, clinking) 1 to 5: 1 9116175991 (0.68 s) one clink at 0.1 s near -27 dB;
  2 9116176107 (4.13 s) a steady working from 0.25 to 2.45 s at -24 to -36 dB, more to 3.25;
  3 9116176070 (2.23 s) quiet, 0.5 to 1.6 s; 4 9116176269 (3.35 s) a clank at 0.35 s (-12 to -18)
  then a long jangle to 2.6 s; 5 9116176337 (2.44 s) a hard clank at 0.4 s (-6 to -12) then the
  shackle worked to 1.6 s. "Chain Rattle Glassy Metal Rattle" 3 9113763590 and 4 9113763639 are
  loud (-6 to -12) small-chain rattles, glassy. APM's stings, 0.1 s bins with the spectrum:
  "Evil Mind 9" 1846887425 (5.12 s) -12 to -18 dB from 0.1 s to 0.8 s, dying by 3 s, 76% of its
  energy above 150 Hz, centroid 0.4 to 1.1 kHz (the padlock's click); "Shock (A)" 1840489046
  silent to 0.3 s then a long -18 to -30 dB bed, 85% above 150 Hz; "Brute Force Sting 3"
  1837950656 loud 0 to 1 s, only 42% above 150 Hz (a phone loses most of it).
- **Bubble wrap's sounds, measured** (L-14b1, 2026-11-10; Edit, AudioPlayer at half speed to
  AudioAnalyzer, 50 ms bins): Pro Sound Effects' "Plastic Bubble Wrap Short Fluttering
  Movements" 12 9125745465 (2.2 s) starts at 0.2 s, crinkles at 0.25 and rustles to about 1 s; 11
  9125745466 (2.5 s) has a sharp crackle at 0.30 to 0.40 s (-12 to -6 dB), then rustle at -24 to
  -36 dB to 1.6 s; 9 9125745458 (3.5 s) hits hardest at 0.35 to 0.40; 13 and 16 are soft
  throughout. "Bubble Wrap Light Crinkling Plastic" 1 and 2 run 10 to 35 s (beds, not hits).
- **The air horns, measured** (L-14a2, 2026-11-10; Edit, AudioPlayer to AudioAnalyzer, 0.1 s bins
  at half speed, then 20 ms at a quarter): Pro Sound Effects' "Air Horn Various Lengths" 1 to 14
  (9113071755, 9113071764, 9113071895, 9113071891, 9113071885, 9113072082, 9113072098,
  9113072084, 9113072258, 9113072263...) are stadium canned horns, most silent for about 0.9 s
  first. "4" 9113071891 (3.4 s) blasts from 0.94 s to about 2.05 s near -2 dB, -19 dB by 2.1,
  -40 by 2.4; "1" 9113071755 blasts at once (0.25 to 1.0 s, 0 dB). The "Various Lengths And
  Pitches" set is whining blasts; "Diesel Truck Horn" and "Tugboat Horn" are vehicles.
- **Pressing a tool's use from the MCP** (L-14a2): `user_mouse_input` with a left
  `mouseButtonClick` on the Client reaches a `ContextActionService` binding on MouseButton1, so it
  presses Blow as a player would. To see a blast's keeper from the Server, sample the body's
  `KeeperState` and pivot each second into `_G` from a spawned loop, and wait on the horn's
  `Blown` attribute to pivot the player away the moment it's blown (a keeper that comes to the
  spot and finds you there hunts you).
- **Sounds measured for the saw** (L-12b2; 50 ms bins at half speed, 0.5 s bins at 4x for long
  ones): "Metal Blade Grind 1" 9116524165 is silent to 0.15 s, spins up to -18 dB by 0.3 s, full
  (-12 to -6 dB, steady) from 0.8 s to about 14 s. "Cold Saw Humming Whir 2" 9113851035 (36.5 s)
  grinds loudest at 8 to 11.5 s and steadiest at 16.5 to 20 s (-12 dB). "Metal Lid Drop Hard Lid
  Close Drops 12" 9116737135 is silent to 0.40 s, one flat hit and rattle at -12 dB to 1.05 s,
  gone by 1.35 s. "Sheet Metal 2" and "5" (9119068619, 9119068827) are handling and flexing, many
  bangs: no single clang.
- **Sounds measured for the keeper's tell** (L-06b4b2, 2026-11-10; Edit, an `AudioPlayer` at half
  speed wired to an `AudioAnalyzer`, `PeakLevel` binned by `TimePosition` in 25 ms; at half
  speed a spectrum bin's frequency is half the real one, so double it): "Wood Drop Light 4"
  9120864768 (4.8 s) is quiet to 1.45 s, one flat clack to 1.53 (-16 dB by then), a bounce at
  1.725; "Wood Drop Light 2" 9120864539 clacks at 0.975, -29 dB by 1.125, a second clack at
  1.15: both about 860 Hz. "Knock Slap Plastic" 9 9116201805 and 7 9116201611 (0.7 s, 0.8 s): one
  knock each at 0.15 s, -22 dB by 0.225, room tone near -35 dB; about 700 to 760 Hz, -5.5 dBFS,
  4 dB under the boards. Also measured: "Plastic Impact Hard Dropping Hollow Hits" 1 to 4 (two
  or more hits each, mostly under 450 Hz), "Foot Stomp" 1 and 7 (a dull thud on carpet, -12
  dBFS), "Pole Drops 6" 9117734474 (a hollow wood hit at 0.025, a bounce at 0.5, about 850 Hz).
- **Sounds measured for the Packrat** (S2-06e, 2026-11-14; Edit, AudioPlayers in parallel to
  AudioAnalyzers, 50 ms bins at half speed, then 10 ms at a quarter; band shares under 190 Hz /
  190 to 470 / 470 to 2k / over 2k). "Foot Stomp" 1 to 7 (9114523161, ...351, ...345, ...358,
  ...636, ...612, ...629; a stomp on hard carpet): one hit each at 0.00, -12 dB, gone by 0.08;
  1, 4, 7 mostly 190 to 470 (56/67/53%), 2 and 3 more 470 to 2k. "Duct Tape ... 3" 9114200240: a
  burst at 0.05 (-16 dB), crackle after. "Bag Drop Bag Bumping Wall 2" 9113244443 (1.44 s): bumps
  at 0.04, 0.16, 0.28, 0.46 (-12 dB), contents jingling throughout, centroid 2.3 kHz. "Ammo Box
  Movement 2" 9113103014: one rattle 0.25 to 0.47 (-12 dB), later ones far quieter. "Chair Impact
  12" 9113771767: plastic clatter in four runs from 0.03 to 0.9. "Body Impact 2" 9113524237 hits
  at 0.02, peak 0.04 to 0.06. Passed over: "Jacket 2" (a cloth throw, -21 dB peak, too quiet),
  "Vehicle Seat 3" (one -18 dB thud), "Robot Footsteps ... Metal Body Rattle 1" (a robot),
  "Slide By Books 5", "Prop Dirt Drag 11" (a long tumble).
- **Hearing a keeper from the MCP** (S2-06e2, Nov 14): first keep Studio drawing frames (the
  `caffeinate` pulse in "Getting frames back"). The client steps every monster's walk on
  RenderStepped, so at 0 frames the server walks a keeper while the client shows it standing and
  plays nothing: that is what made S2-06e think the Packrat was silent. Then, on the Client,
  anchor your own root and each RenderStepped set it 14 studs above the keeper's root and 6
  behind it (the server keeps your character where it was, so the keeper never sees you; the
  real camera follows, so the real listener is close), and log its root's `Keeper*` Sounds: a
  play is one newly `IsPlaying` or whose `TimePosition` fell since last frame; note `IsLoaded`
  at its start. A Packrat: `StandPackrat` (it fetches the boombox, so both sets come in 45 s).
  A Mannequin: `WakeSleepers` with your root on the floor; three wake shut in, and the first
  bursts out a minute or so later. Woken Mannequins pounding their doors draw the Packrat to look, and it
  never fetches: test it in a Play without waking them.
- **Sounds measured for the keeper's walk** (L-06c1, 2026-11-10; Edit, AudioPlayer at half speed
  to AudioAnalyzer with `SpectrumEnabled`, 50 then 25 ms bins and the share of the hit's energy
  under 190 Hz / 190 to 470 / 470 to 2k / over 2k; then a quarter speed and 10 ms bins for the
  cuts). Weight: "Plastic Cooler 6" 9117451558 hits at 0.06, -30 dB by 0.23, a second hit at 0.46,
  20/62/12/4 (centroid 456 Hz); "Body Impact 2" 9113524237 at 0.03, gone by 0.33, 55/22/19/2;
  "Wood Drop Wood Log 2" 9120871246 (a railroad tie on pavement) at 0.49, a second strike at
  0.73, 9/53/35/0. Thunk: "Plastic Impacts Dish Shaped Planter" 5 9117557254 (0.63, 89% at 190 to
  470), 23 9117570260 (0.09), 27 9117571208 (0.57), 22 9117570079 (0.16, a bounce at 0.26): one
  hit each, -30 dB within 0.06 s. Drag: "Rock Scrape On Concrete Constant Dragging Dry 2"
  9125883658, strokes at 0.16 to 0.48, 0.78 on, 1.75 to 2.13, centroid 200 to 380 Hz (pitched up
  for phones). Creak: "Gas Pedal Cu Slow Pressing Movements Squeezing 1" 9125571873, a ratchet
  of pulses every 75 ms from 1.10 (centroid 564); "Tire Squeak Cu Creak Rub Together Rubber 1"
  9120078794, steady from 0.2, centroid 1 to 2.4 kHz. Passed over: "Body Impact 10", "Deep
  Impacts 7" and "Body Falls 1" (87 to 90% under 190 Hz: a phone plays none of it); the "Body
  Fall Concrete" set (long scuffles, several hits); "Wood Creak 1" (86% over 2 kHz, a squeal);
  "Rope Stress 3" (-29 dB); "Metal Scrape Dragging Drain Pipe" (metal).
- **A unit's `DoorButtons` is an Attachment** (L-06c1): aim the camera at its `WorldPosition`;
  its `Position` is the offset in the door's frame, and a camera pointed there misses the prompt
  (the press then does nothing).
- **Watching a keeper roam, from the MCP** (L-06c1, seed 7, floor 1): from the Server, spawn a
  thread that waits on Unit157's `DoorMotion` changing, then 0.5 s later anchors your root and
  pivots you to (47, 15, -632); stand at (47, 3, -632) and tap 157's Open from the Client. The
  guard steps out to look, never sees you 12 studs up, and roams the halls; a Client
  `RenderStepped` logger over the body's `Keeper*` Sounds (a play is one newly playing or with a
  `TimePosition` lower than last frame's) gives each beat, its volume, pitch and distance.
- **Testing what keepers hear, from the MCP** (L-15, Play): press the walked floor's "Stand one"
  (`StandMannequin` in its lobby, -9, -591) for an asleep Mannequin 60 studs along the halls. A
  Server `PivotTo` onto a spot the client hasn't streamed drops you through the floor (to -500 and
  dead, which ends the climb): anchor the root, `RequestStreamAroundAsync`, wait 2.5 s, unanchor.
  The lobby floor is round (0, -600); (-9, -586) is off it. Fire `Remotes.Keypad` with
  (elevator, key) from 3 studs off the keypad; `ToolDrop` drops what's in hand. A woken keeper
  comes to the noise and catches you if you're there: set your root's CFrame away on the Client
  right after (the camera can stay, Scriptable, to hear it). A Client logger that errors every
  frame (a floor gone at "Again") floods Output past what `get_console_output` returns: guard it
  with `FindFirstChild`.
- **Sounds measured for the ladder** (L-13b1; 50 ms bins at half speed): "Metal Ladder Bang
  Slams Against Body 1" 9116717868 (1.08 s) bangs at 0 s near 0 dB, rattles to 0.85 s; "Metal
  Ladder Drop 1" 9116718698 is only 0.66 s, a soft hit then a loud one at 0.25 s; "Metal Ladder
  Impact 1" 9116719494 is silent to 0.55 s, creaks, hits hard at 0.70 s, bounces to 1.45 s;
  "Metal Ladder Hits 1" 9116718918 is a bang at 0 s and a long decay. The store's durations
  run longer than `TimeLength`.
- **The script deals what Studio deals** (L-14e; L-13b1 found them apart): until L-14e
  `scripts/floor-deal` drew the deal from its own Random (seed + 1000000) while `DevCorridor`
  carries on the layout's, so the code, notes, guard and contents all differed. Now they match:
  opening floor 1's 104 to 125, 101 to 103, then 157 on seed 7 dealt in Play exactly what the
  script prints. Only which tool comes out depends on the order doors first lift, so open them in
  another order and the tools move between the tool units; nothing else moves. To judge a tool
  where the deal puts it, lay one with DealSpot's spot and Slots' `resting` from the server
  (Tools, DealSpot, FloorBuilder.face), as Deals does.
- **`Deals` hears a press, not a door** (L-14e): a Server `RollUpDoor.play(unit, "Open")` lifts the
  door but deals nothing (`Deals` listens to `Doors.acted`, which only a press or `Doors:move`
  fires; `KeptPlayers` listens to `changed`, so the let-out recipe still works). To deal a row of
  units, press Open from one Client `execute_luau`: for each, pivot your character 3.5 studs out
  from the door (the `DoorOrigin` part's look, flattened, points out to the hall; check it against
  `DoorButtons`), wait for the unit to stream in, aim a Scriptable camera with `AutoRotate` off at
  its `DoorButtons`, wait 1.3 s, then `InputHoldBegin`/`End` on the prompt whose `DoorAction` is
  Open. 26 doors took about a minute. Once, the first three presses straight after Play started
  didn't take (pressed again later they did); waiting 5 s after Play before the first, all did.
- **Your own body's shadow falls on your view's tool** (L-13b1): your character is hidden in
  first person but still casts shadows, so a view model held close to the body (the ladder, 0.7
  ahead) reads black when the light is behind you; moved off the body it's lit. The saw and
  cutters sit 1.3 to 2 studs out, mostly clear of it.
- **Seeing your own character carry something** (Play, one player): set the LocalPlayer's
  `CameraMode` to Classic and both zoom distances to 14, then `screen_capture` with a
  `camera_position`; set them back to LockFirstPerson and 0.5 after. `user_keyboard_input` key
  presses reach ContextActionService (1, 2, G); the slot bar's `Name` label keeps the last line
  it said (its Text stays after it fades).
- **Climbing a TrussPart** (Play, L-13b2a): a TrussPart's X and Z are always 2, its Y any
  length. Real key input (W from `user_keyboard_input`, with the first-person camera turned to
  face the truss) climbs a vertical one at about 11 studs a second; `Humanoid:Move` from a script
  walked into it but never climbed. Leaned 14 degrees off vertical, the climber flicked between
  Climbing, Running and Freefall on the way up: don't build a leaned climb on Roblox's own.
- **The first-person camera lying down** (Play, L-13b2a): Roblox's camera follows the root's
  CFrame turned by its head offset (1.5 up in the root's own frame), so a body held flat on its
  belly by script puts the view at its head, looking wherever the player turns it, with no
  camera script of our own.
- **Sounds measured for the ladder's lean and climb** (L-13b2a; 0.1 s bins at half speed):
  "Chain Movement On Aluminum Ladder 13" 9113761047 (3.19 s) is a steady drag from 0.3 to 2.7 s;
  "Fire Escape 2" 9114437085 (4.14 s), a grab and climb up a metal ladder, is loud at 0.2 to
  0.4 s and 1.0 to 1.2 s with rattles between; "Chain- Link Fence Impacts Metal Rattle 1"
  9113755181 (4.25 s) is silent to 0.3 s, hits at 0.3 to 0.7 s and rattles out by 1.6 s;
  "Chain Movement On Aluminum Ladder 10" 9113760919 drags loud almost all through.
- **Sounds measured for the padlock** (L-11c; 50 ms bins at half speed): "Scissors Snap 28"
  9118829487 is one snap at 0 s, about -15 dB, 0.47 s long; "Padlock Open Lock Pick Up Throw Down
  1" 9117185722 opens at 0.05 s, locks at 0.40 s, then its pick-up and throw-down run together
  from 0.65 to 1.2 s (too blurred to cut apart).
- **Measuring a sound** (Edit, P0-04, 2026-11-07): nobody here can listen, so find a recording's
  events by its loudness. An `AudioPlayer` wired (`Wire`) to an `AudioAnalyzer` plays in Edit with
  no output attached, silently; sample the analyzer's `PeakLevel` each frame against the player's
  `TimePosition` and bin it (50 ms bins as a digit per bin of 6 dB). At `PlaybackSpeed` 0.25 the
  bins resolve onsets to about 5 ms. Several players run at once.
- **Playing a stretch of a recording** (Play, P0-04): a classic `Sound` with
  `PlaybackRegionsEnabled`, `PlaybackRegion` and (looped) `LoopRegion` plays only that stretch;
  set `TimePosition` to the region's start before `Play`. A fresh Sound with a preloaded id starts
  at its region on its very first play. Fade the end with a delayed `TweenInfo` on `Volume`.
- **The keypad's sounds, measured** (L-05b1a, 2026-11-08; 50 ms bins, one AudioAnalyzer each,
  all six at once in Edit): beep 9114642536 is one blip, loud 0 to 0.2 s of 0.46; buzzer
  9113085665 a burst 0 to 0.4 s of 0.98; the elevator alarm bell 9125544264 rings up from 0.2 s,
  loudest 0.6 to 1.2 s, then decays over its 7.9 s; the double-ding 9119642644 is about 30 dB
  under the others (play it loud); the fold 9117907728 is silent to 0.6 s, then a ratchet that
  builds to its slam at about 2.2 s and dies by 3.3 s; the latch 9117910424 jiggles 0.2 to 0.8 s.
- **A recording's first play is late** (Play, L-05b1c, 2026-11-08): the first `Play` of a
  library recording in a session starts 0.26 to 0.35 s late (its `TimePosition` sits still),
  even after `ContentProvider:PreloadAsync`; every play after, even from a new `Sound`, starts
  within a frame. Play it once at volume 0 first (`SoundPrimer`). On Nov 11 (L-16a) even
  recordings the game never plays, preloaded only, were 0.15 s in after 0.15 s on their first
  play: not seen again, maybe Studio's cache. Every system primes its recordings anyway. The double-ding 9119642644 is
  5.2 s long, loudest to 1 s, down 18 dB by 2.6 s.
- **The gate clock's sounds, measured** (L-05b2, 2026-11-08; 50 ms bins, AudioAnalyzer in Edit, all
  at volume 0.3): APM's "Heartbeat 01" 9043365727 is a clean lub-dub about every 0.77 s (78 a
  minute, though its title says 96 BPM), peaks -11 dB, 60 s, loops; Pro Sound Effects' "Elevator
  Bell Synth Chimes 11" 9114302479 rings two tones by 0.35 s, -21 dB, gone by 1.5 s; the
  double-ding 9119642644 is one strike at -43 dB ringing down slowly (play it at 5 or more).
- **A UIAspectRatioConstraint can't make width from nothing** (L-05b2): a frame sized
  `fromScale(0, h)` with `DominantAxis.Height` comes out 0 by 0 (the constraint fits inside the
  size it's given). Give it the width to fit in, or size it in offsets.
- **`GuiService.TopbarInset`** (read in Play on the Galaxy A16, 2026-11-08): a Rect of the top
  bar's free stretch, right of Roblox's buttons: 208 to 685 across, 58 tall. A ScreenGui with
  `ScreenInsets.TopbarSafeInsets` is laid in that stretch (its middle is then not the screen's);
  `IgnoreGuiInset` plus offsets from TopbarInset centres a thing on the screen within the row.
- **A client's `SetAttribute` on a replicated instance fires its changed signal locally**
  (L-05b2): a quick way to preview what a screen does with a server value (a headline, a lamp)
  without running the whole loop; the server's next write replaces it.
- **Studio runs about 15 frames a second under the Device Simulator with the MCP driving**
  (L-05b2): a per-frame probe logged the clock's seconds 0.07 s late. Judge timing from the
  server's clock values, not a probe's frame times.
- **Driving the phone's touch from the MCP** (L-05b1c, Galaxy A16): `user_mouse_input` lands taps
  at about 0.9 of the x you give (and of an `instance_path`'s x); y lands true. Give x divided by
  0.902 of the button's `AbsolutePosition` middle, and check where it landed with a
  `UserInputService.InputBegan` listener kept in `_G` (an `execute_luau` that waits blocks the
  input call until it returns). `ProximityPrompt:InputHoldBegin()` then `InputHoldEnd()` in the
  Client view triggers a prompt as a tap would.
- **Types don't pass through a table** (luau-lsp, L-05b1c): `local Keypad = Elevator.Keypad` gives
  the module's values but not its types (`Keypad.State` is unknown); require the module itself.
- **Testing a remote from the MCP** (L-05b1a): `execute_luau` in the Client view can
  `FireServer` as the player, bad payloads and all, and read the replicated attributes back; the
  server's prints show in `get_console_output`. Move the character first (Server view,
  `PivotTo`), since the server checks range.
- **Deferred events miss the first play:** a `Played` handler connected inside `DescendantAdded`
  connects after the game's code has already called `Play` (Roblox defers events). A probe polls
  `IsPlaying` each frame instead.
- **String requires work for the game's own modules** (Play, P0-04): `require("./Motion")` from
  `StorageUnit/DoorSound` loads its sibling in Roblox, and the same file runs under Lune and passes
  luau-lsp, as Brix's modules do.
- **One asset ID serves every branch:** after uploading the unit from one branch, re-upload from
  the branch you return to (set its `sha256` in `art/unit/assets.json` to anything and run the
  script; it writes the same hash back).
- `ProximityPromptService.PromptShown` misses prompts already showing when you connect (the spawn
  is within reach of 101's): step away first.
- **Teleporting doesn't wake a motion light** (L-01b, 2026-11-07): after `PivotTo` the hall stayed
  dark; walk a few studs with `Humanoid:MoveTo` (and wait for `MoveToFinished`) and capture within
  a second or two, before the light's hold runs out. In LockFirstPerson the character turns to the
  camera, so set `CurrentCamera.CFrame` after moving, then trigger prompts or capture.
- **Rojo connects through the owner:** start `rojo serve` in the background; the owner clicks
  Connect in Studio's Rojo plugin. Rojo keeps the place's own children (Baseplate,
  `ReplicatedStorage.Units`) because no node there has a `$path`.
- `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type`
  shows six times at each Play, three and three. It's Roblox's audio "Pop Close Sound" (by
  Zyleak; `MarketplaceService:GetProductInfo`), asked for as some other type by something outside
  the game: no instance names it in Edit, on the Server or on the Client (CoreGui included, about
  18,000 searched, every content property and attribute, L-16a), nor the repo nor Brix. Studio's
  or a plugin's; the game can't silence it. Ignore it.
  120448020095820 ("content representation is being generated", seen Nov 11) is
  `ReplicatedStorage.Props.KeptWrap`'s `SurfaceAppearance.ColorMap` in the place: Roblox still
  processing it after its upload; it didn't show in L-16a's Plays.
  `rbxassetid://87642977759407 failed due to: Asset content representation is being generated`
  showed about thirty times once mid-Play (L-04e, Nov 9); no instance on either side names it
  (searched MeshId, TextureID, the four maps, SoundId, Image). Same verdict.
  It came back as the kept wrap first drew after each fresh upload (L-07b, Nov 10: 99219113961263,
  then 122882625024859 after a re-upload, never the wrap's own IDs): Roblox still processing a
  new upload. Check it's gone a while after.
- **Lune can't require a generated Specs that builds Vector3s** (the unit's, the tools', the
  finds'): read the numbers from the file's text, as `tests/dealspot.spec.luau` and
  `tests/deal.spec.luau` do. The Mannequin's and the Elevator's Specs use plain lists and load.
- **Shots and prompts from the MCP, a recipe** (L-04e): set `CurrentCamera.CameraType` to
  Scriptable on the Client before aiming (the default camera takes the CFrame back next frame),
  aim for about a second, then `InputHoldBegin`, wait the prompt's `HoldDuration` plus a little,
  `InputHoldEnd`; put the camera back to Custom after. A hall shot taken after standing still a
  while comes back black for a different reason: the motion light went out. Move, then shoot.

- **Blender 5.2 headless:** assigning `hide_render` while iterating `collection.all_objects`
  doesn't stick; wrap it in `list(...)`. The volume node is `ShaderNodeVolumePrincipled`. A camera
  made this frame has a stale `matrix_world` until `view_layer.update()`. GPU bakes vary by at
  most 1/255 between runs, so texture hashes aren't stable.
- **Smart project packs a moved part differently** (L-01b, 2026-11-07): the S's hardware, the same
  shapes as the M's only shifted sideways, landed up to 0.7 of the atlas away from the M's, so it
  would have worn the wrong texels of the M's bake. A shared bake needs the same pack: copy the
  UVs face for face (`bake.copy_atlas`).
- **`bpy.data.libraries.load` swaps the names in the list you assign** for the loaded datablocks,
  in place; assign a copy (`dst.meshes = list(want)`) to keep the names.
- **A Python error in `blender -b -P` still exits 0**, and `art.sh` filters the output, so a
  failed rebuild used to leave the last `unit.blend` for the next stage to export. `art.sh` now
  deletes it first for sizes other than M.
- **luau-lsp 1.70.1 strict:** locals bound from a multi-return widen string-literal unions to
  `string`; annotate them (`local kind: Motion.Kind, from: number = Motion.decode(...)`).
- **Lune** runs a spec with `lune run tests/<name>.spec` from the repo root; specs require
  modules by relative path.
- **Lune 0.10.5 can mis-compare inside a loop** (L-06b1, 2026-11-09): `math.abs(a - b) <= f(c) * 10`
  in a spec's loop failed with "attempt to compare number <= nil" (or string, or function) though
  every part was a number; the same line alone, or in a closure, ran fine. Put the right side in a
  local first (`local slack = f(c) * 10`). Not seen in Studio.
- **`vector` is 32-bit floats** (Luau's native type, and Roblox's): a few hundred studs from the
  origin a position is good to about 3e-5 studs, so a spec comparing distances between vectors
  needs a tolerance near 1e-4, not 1e-9 (`tests/keepermap.spec.luau`).
- **Captures miss the prompts** (L-02, 2026-11-07): `screen_capture` draws the 3D view only, not
  Roblox's ProximityPrompt overlay. To check buttons on screen, listen to
  `ProximityPromptService.PromptShown`/`PromptHidden` in the Client view and project each shown
  prompt's attachment with `Camera:WorldToViewportPoint`, adding its `UIOffset`. Phone shots of
  prompts are the owner's (the Device Simulator).
- **Union string types across modules** (L-02): a function declared to return a string union
  (`Door.State`) reads as plain `string` at the call site unless the local is annotated
  (`local state: Door.State = Door.stateOf(...)`); the same for a loop over a `{ Door.Side }`
  (`for _, point: Door.Side in Door.Sides`). A table typed `{ [Union]: T }` rejects `t.Key`; give
  it a record type (`{ BoltCutters: boolean, Padlock: boolean }`) or index with a typed local.

- **R15's rig, by name** (Humanoid docs, `BuildRigFromAttachments`, read 2026-11-08; built and
  posed in Studio, L-06a): a Motor6D's name is its attachments' name less "RigAttachment"
  (`NeckRigAttachment` in UpperTorso and in Head make `Neck`), it sits in Part1, C0 is Part0's
  attachment's CFrame and C1 Part1's. Animations find parts by these names and joints, so custom
  rigid meshes named as R15's parts animate as R15 (docs; not played here). The fifteen joints:
  Root, Waist, Neck, Left/Right Shoulder, Elbow, Wrist, Hip, Knee, Ankle.
- **An imported part's pivot carries the FBX's Z-up turn** (Studio, L-06a): the Mannequin built
  from `LowerTorso:GetPivot()` lay on its back. The pivot's position is the Blender origin, but
  its orientation isn't the part's; take the position from the pivot and the turn from the part's
  own CFrame (whose axes are the figure's, as the importer note above says).
- **Motor6D C0 posing, verified** (Play, server, L-06a): with the root anchored, setting each
  `C0 = RigAttachment.CFrame * turn` put all fifteen parts within 0.0001 studs of the pure
  `Pose.solve`. Whether Edit moves parts when C0 changes wasn't tested: `Mannequin.pose` places
  them itself when the game isn't running.
- **A capture into an open unit timed out twice** (Play, L-06a): a capture with a camera position
  in 101's doorway never answered, while the next, down the hall, did.

- **The command bar keeps the old tool list** (Edit, L-14a1): after Rojo synced a new `Catalog`
  row, `require(ReplicatedStorage.Shared.Tools)` in an Edit `execute_luau` still returned the old
  one (a module is cached for the Edit session), so `Tools.prepare` said "no catalog row".
  Require a clone (`Shared.Tools:Clone()`, parented beside it, destroyed after) to read the new.
- **The prompt you face wins** (Play, L-14a1): with two tools' Pick up prompts in reach,
  `InputHoldBegin` on the one not shown does nothing, and E takes the one the camera faces. Point
  the camera at the tool first (set `CurrentCamera.CFrame` on the Client), then press E.
- **Move your own character from the Client** (Play, L-14a1, no catch): a Server `PivotTo` moved
  it for the server only; the Client still stood at the spawn, and the next replication undid
  it. A Client `PivotTo` stuck. In the test hall, z 5 by x -26 is past the hall's floor: the
  character fell and respawned.

### Blender traps met building the elevator (Nov 8, `art/elevator/`)
- The finds' unwrap (each object in its own square of the atlas) wastes most of it on long
  strips: the elevator's trim filled 31%. `bpy.ops.uv.pack_islands` over all of a set's objects
  at once (multi-object edit, `use_uv_select_sync` on, `shape_method="AABB"`, cardinal turns,
  `scale=True`) keeps one texel density and packed 42%; past that, the limit is real surface.
- A FONT object's `matrix_world` is stale after setting its `location` and `scale` until the view
  layer updates: compose its matrix from `location` and `scale` before moving it elsewhere.

### Blender traps met building the finds (Nov 7, `art/finds/`)
- `bmesh.ops.create_uvsphere` numbers its points differently from run to run. Anything whose
  UVs are saved and worn later must build its spheres point by point (`build.py` `ellipsoid`).
- Smart project over several objects at once can fold one object's islands over each other (the
  teddy's, among three others; alone it was clean). Unwrap each object alone and place it.
- Smart project packs differently each run: save the bake's UVs and wear them in later stages,
  after the same trip through edit mode (it renumbers some faces' corners).
- Baking several objects into one image: each object's margin paints over the others' island
  edges, whole small islands included. Bake with margin 0, bake a coverage pass, pad afterwards.
- **luau-lsp and lists of words** (L-04d): a list annotated `{ Kind }` (Kind a union of string
  words) hands its loop variable back as plain strings, so indexing a `{ [Kind]: number }` table
  or assigning to a `Kind` local from it fails strict checks. `Deal` keys its odds tables by
  `string` and casts the one assignment (`k :: Kind`); `Door` gets away with `:: { Action }`
  because it never indexes a table by the loop variable.
- **The Device Simulator's calls** (L-11b, so the 10k-token skill needn't be loaded again):
  `local svc = game:GetService("StudioDeviceSimulatorService")`, in Edit before Play:
  `svc:SetDeviceAsync("samsung_galaxy_a16")`, `task.wait(0.3)`,
  `svc:SetOrientationAsync(Enum.ScreenOrientation.LandscapeLeft)`; after Play is stopped,
  `svc:StopSimulationAsync()`; `svc:GetDeviceAsync()` says which ("default" when off). Every call
  yields; wrap in pcall. Setters fail in Play's server view. The A16's viewport is 685x338.
- **The MCP's E reaches ProximityPrompts** (Play, L-11b): `user_keyboard_input` E (and ButtonX on a
  pad) triggers the prompt Roblox shows for that key, but with two E prompts in reach only one
  shows (Exclusivity OnePerButton): by the spawn E took "Walk a floor" over a tool's "Pick up"
  and sent the player to the floor. Stand away from the posts (10 studs) when testing a prompt.
  Prompts don't show in `screen_capture`.
- **Setting `workspace.CurrentCamera.CFrame` on the client turns a first-person view** (Play,
  L-11b): with LockFirstPerson the camera keeps the new look, so a shot can be aimed from the MCP.

- **A unit's inside is pitch dark in Play** (L-13b2d2a, 2026-11-09): its bulb is off until its
  door opens. To judge art inside or under a top, light it on your own client from the MCP:
  `unit.Bulb.Glass.PointLight` Enabled, Brightness 1.5, Range 18 (it stays until Play stops).
  An uploaded set whose textures match ones already up (the TopHole kit's Partition set) arrives
  with the same `rbxassetid`s as the first upload's.

- **The test hall and the walked floor share unit names** (Play, L-12a, 2026-11-09): both lay
  `Unit101` and on under `Workspace.DevCorridor`; the floor's are 600 studs off, so pick them by
  `GetPivot().Position.Z < -300` (and their `DoorButtons` attachment by `WorldPosition.Z`).
- **A Client `execute_luau` has its own `require`** (Play, L-12a): changing a module's table from
  the MCP (a Catalog row's `hold`) never reaches the game's scripts, which hold their own copy.
  Edit the source, let Rojo sync, and Play again.
- **`screen_capture` with a camera position works in Play** (L-12a, Galaxy A16): it aims the
  client's camera for the shot, and the held tool and torch follow it (ToolView draws from the
  camera each frame), so a level first-person shot needs no Scriptable camera. The MCP sets
  `CameraType` back to Custom after every `execute_luau` that changed it.
- **Walk a step before a shot** (L-12a): a capture after a teleport came back black twice; a
  `Humanoid:MoveTo` a few studs out and back woke the motion light and the next capture was lit.

- **Held things in first person** (L-13b2c2, 2026-11-09, checked in Studio): the camera's near
  plane is 0.1 studs (`Camera.NearPlaneZ` = -0.1); standing flush to a wall your first-person eye
  is 1.45 studs from it. `Model:ScaleTo` scales parts and attachments' places but leaves a light's
  `Range` alone. `execute_luau` (the MCP) sets the camera back to its own type after each call, so
  a test view must be held by a `BindToRenderStep` at `Camera.Value + 1` (unbind it after).

- **Measuring a held body's legs from the MCP** (Play, L-16b1, 2026-11-11): to hold your
  character in a pose, set `PlatformStand`, then in a `PreSimulation` binding set the root's
  CFrame *and zero its velocities* every frame, or gravity drags it a stud lower between frames
  and every measurement is off. Joint `Transform`s written there hold (the default avatar's legs
  are `AnimationConstraint`s, hip to knee 0.96, knee to ankle 0.57 by its rig attachments). Judge a
  knee's bend by the knee's rig attachment ahead of the hip's, not by part centres, which move
  forward together in a crouch.
- **Picking up one tool from the MCP** (L-16b2): the test hall's tools lie close together, so
  the nearest Pick up can be another one (the air horn beside the saw). Press the prompt inside
  that tool's own model. The ladder starts in `Workspace.YourTool`, not `Workspace.Tools`.
- **Testing a server's reach from further than the screen's** (L-16b2): set the prompt's
  `MaxActivationDistance` higher on the Client for the press, then back. The client shows it
  and fires it; the server still judges its own reach, so a press ignored there is the server's
  check, not the screen's. Pair each "ignored" with the same press from a clear spot that goes.
- **Getting a player up on the tops from the MCP** (Play, L-13b2d2b, 2026-11-09): every press is
  the prompt's own `InputHoldBegin()`/`InputHoldEnd()` on the Client, on the *nearest* prompt of
  that name (the test hall and the walked floor both have a Unit 101), with the camera aimed at it
  first (`CurrentCamera.CFrame = CFrame.lookAt(...)`): a prompt off screen never fires, and Lean
  sits up at the front's top edge. Order: pick up the ladder (it takes both hands, so the saw
  can't come first), aim and press Lean at Unit 101 from 2.5 studs out, pick up the saw, stand
  2.5 studs from Climb and press it; four seconds later you're lying on the top. To catch a held
  Saw mid-cut in a shot, set that prompt's `HoldDuration` long on the client; the server drops the
  cut a second after its time, so press again with 4 to go through.
- **Placing a crawler exactly from the MCP** (Play, L-13b2d2c): once up on the tops, set the
  character's `TopsFix` attribute to a lying CFrame on the Client (`origin * CFrame.new(x, y, z) *
  CFrame.Angles(0, yaw, 0) * CFrame.Angles(-math.pi / 2, 0, 0)`, the map's frame); LadderView
  takes it as the server's put-back and moves you there, and the server's check accepts it as a
  crawl if it's a few studs off; much further (23 studs, L-16d) and the server puts you back where
  it last saw you, so crawl most of the way first. To crawl a way, hold the view with a `BindToRenderStep` and hold
  W with `user_keyboard_input`. The torch's R1 from `user_keyboard_input` doesn't reach its
  ContextActionService binding; for a shot, enable the beam's SpotLight on the Client.
- **Measuring the crawl's view frame by frame** (Play, L-16c, 2026-11-11): record in a
  `BindToRenderStep` just after `Enum.RenderPriority.Camera` and read `CurrentCamera.Focus` (the
  eye the camera follows: root plus 1.5 up the body plus `CameraOffset`), not
  `CurrentCamera.CFrame.Position`, which sits half a stud behind the eye along the look and so
  swings whenever the view turns. To turn the view mid-crawl, set the camera's rotation in a
  binding just before `Camera` each frame and hold W with `user_keyboard_input`. With Studio not
  focused it draws about 15 frames a second while `PreSimulation` keeps stepping several times
  per drawn frame, so a render sampler sees several crawl steps at once (that looked like physics
  moving the body; it wasn't). Judge smoothness by eye only with Studio focused, or on a device.
  To compare runs, take each frame's horizontal eye step over its own `dt` and compare it with its
  neighbours' (L-16d): a frame that moved whole physics steps whatever its length stands out.
- **Physics steps on its own clock, not per drawn frame** (L-16d, 2026-11-12): measured in Play,
  `PreSimulation` and `PostSimulation` ran 60.1 times a second while Studio drew 14.9, four to a
  frame and now and then two. So above 60 drawn frames a second some frames get no physics step at
  all: anything the camera follows that's moved in `PreSimulation` shows one place for two or three
  frames, then jumps. Move it in a `BindToRenderStep` just before `Camera` and hold it, velocity
  zeroed, in `PreSimulation` (LadderView's "LadderViewPlace"); physics also sags an unanchored
  body between the two, so the camera there sees exactly what you placed. Roblox's BindToSimulation
  and UseFixedSimulation (DevForum, Apr 29, 2026) put more of the engine on that fixed clock; a
  script can't read `workspace.UseFixedSimulation` ("not a valid member"), so where it's set is
  unknown here.
- **Studio can't be brought to the front from a script** (L-16d): `osascript ... activate`, `open
  -a RobloxStudio` and System Events' `frontmost` all leave Claude in front (macOS refuses the
  switch; System Events has no accessibility permission), so Studio draws at 15 frames a second
  and anything about feel at a computer's full rate is the owner's to judge.
- **The network simulator from the MCP** (L-16d): `settings().Network`'s six numbers,
  `InboundNetworkMinDelayMs`, `InboundNetworkJitterMs`, `InboundNetworkLossPercent` and the three
  `Outbound` ones, set from a Client `execute_luau`, shape Play's connection at once (loss is a
  percent, at most 0.5). They persist across Studio restarts and places, so read them first and
  put them back (they were all 0). Roblox's presets: 4G 45/20/0.4 in and 55/30/0.5 out; bad 3G
  150/70/0.5 in and 180/90/0.5 out. The Roblox_Studio MCP's `rbx-network-simulator` skill has the
  rest (its text is too long to load whole: grep the saved file).
- **The lobby's floor slab was 7 studs into the cars** (Nov 14, D-158): in `Props.Lobby` the
  `Floor` MeshPart sat at z -29 from the model's pivot where its spec says -36 (every other part
  matched), so it ran under each car's floor at height 0 and flickered. Check a template against
  its Specs from the Edit command bar: `WorldPivot:ToObjectSpace(part.CFrame)` against
  `Specs.Parts[name].Centre`.
- **Two floors at one height flicker** (L-16c): a hall junction's concrete (`T.Floor`, top at 0)
  runs on under the front of the units round it, where the unit's own floor also sits at 0, so
  the two drew over each other as the view moved (only on real floors: the test hall has no
  junctions). Find such pairs from a Server `execute_luau` by testing every visible part's box
  against a unit's floor; `GetPartBoundsInBox` misses them (the art's meshes aren't queryable).
- **A unit's bulb and its top at Studio's Automatic graphics** (Play, L-13b2d2c): a lit bulb
  lit the whole steel top above it and the deck from below, through the steel; at Level21 only
  the sawn hole glowed and the deck above it caught a patch. Judge light through a top at a fixed
  high level, and on a phone for what most players see.

- **Testing the deal from the MCP** (Play, L-13b2d3b, 2026-11-09): the test hall's units are never
  dealt; only the walked floor's are (600 studs off, under `DevCorridor.Floor1`), and Output says
  "Deals: Unit102 held ..." as each is. The ladder and saw lie only in the test hall, and the
  ladder takes both hands: pick up the ladder, set your root's CFrame to the floor's hall, Lean,
  go back for the saw, return and Climb. A door's state is attributes, so on the Server
  `require(RollUpDoor).setLocked(unit, true)` padlocks a door for a test though the MCP's
  `require` is its own copy. A unit's door face from the MCP: origin at its `DoorButtons` side
  of the wall on the floor, +Z toward its `LiftButton`.
- **Which way you face can't be judged with the camera held** (first person, L-13b2d3b): the
  character turns with the camera, so a `BindToRenderStep` look used to press a prompt also
  turns the body. Read a move's facing from its own numbers, not from the root after.
- **A re-uploaded FBX with changed textures gets new texture IDs** (Studio, Nov 10, the softer
  bubbles): unlike a mesh-only change (L-04c2, above), `upload_art` updates the model in place
  but its SurfaceAppearances arrive with new ColorMap, NormalMap and RoughnessMap IDs (the
  MetalnessMap, unchanged, kept its). Insert the asset, clone its SurfaceAppearance onto each
  template's MeshPart in place of the old one (keep the old one's AlphaMode), then destroy the
  insert. Right after the upload Output may say "Asset content representation is being
  generated" for a minute.
- **Some runs no prompt shows to the MCP at all** (Play, Nov 10): standing over the test hall's
  roll with the Scriptable camera pointed at it, `PromptShown` never fired, so neither
  `InputHoldBegin`/`End` (after a 1.2 s wait) nor `user_keyboard_input` E picked it up. Cause
  unknown (perhaps the viewport unfocused). Test what follows a pick-up from the Server instead:
  the shared module required there, a template laid and tagged as the system would.
- **The server reads a player's facing as their client holds it:** a Server `PivotTo` turning
  the character is undone within 0.3 s by the client (it owns the character), so a server check
  of facing after a teleport sees the client's way, not the pivot's.
- **Bubble wrap's pops, measured** (L-14b2b, 2026-11-10; Edit, AudioPlayer to AudioAnalyzer, 50 ms
  bins at half speed, then 10 ms at a quarter): Pro Sound Effects' "Plastic Bubble Wrap Short
  Fluttering Movements" 2 9125745015 (7.75 s) is the loudest of the set: a crackle from 3.38 s
  (onsets 3.38, 3.45, 3.61, about -17 dB) building to one sharp pop at 3.94 s (-6 dB), then
  rustle to 4.4. 20 9125745994 (3.3 s) hits -14 dB at 0.38 s; 15 9125745716 crackles -15 to
  -20 dB from 0.1 to 1.5 s; 1, 6 and 14 stay under -17 dB. "Elastic Twist Bubble Wrap Prop Turn
  2" 9114234244 is quiet (-28 dB). Build2Inspire's user upload "Pop Bubble Wrap Sound Effect"
  7158013361 is one lone pop at 1.2 s (-5 dB) and nothing else.
- **`SurfaceAppearance.Color`** (Edit, Nov 10): exists and reads white (a tint on its ColorMap).
  A LocalScript can set it in Play (verified Nov 10: the spent bubble wrap's grey).
- **`AbsolutePosition` skips the top bar** (Play, Nov 10, the minimap): in a ScreenGui with
  `IgnoreGuiInset` true, a frame placed at y 68 (58 under `GuiService.TopbarInset`'s row, plus
  10) reads `AbsolutePosition.Y` 10: it's measured from under the inset. Place by `TopbarInset`
  and check by eye, not by `AbsolutePosition`.
- **"✓" draws in Builder Sans Bold** (Play, Nov 10): from a fallback font, thin; at 6 points it
  doesn't read, so the minimap's opened units go green as well.
- **Teleports right after Play starts can skip frames** (Nov 10): a client walked by `PivotTo` 3
  studs every 0.08 s as Play began skipped the minimap's junction (slow first frames); walked
  again later, it filled in. Wait a few seconds after Play before stepping a character along.
- **A server-made model can reach a screen before its parts** (Play, Nov 10, the laid bubble
  wrap): with StreamingEnabled and the model's `ModelStreamingMode` Default, a client's
  `CollectionService` added handler can find the model with no part yet, and code that gives up
  there never sees it (the bubble wrap's pops were silent on screen while the server popped it).
  It didn't happen with the same model cloned and tagged from the MCP. Make such a model
  `Atomic` on the server (its parts arrive with it) and wait for a missing part on the client.
- **The roll's prompt did show to the MCP** (Play, Nov 10, on the third try): every other prompt
  under `Workspace.Tools` disabled on the Client, the character stood 2.5 studs off, the camera
  Scriptable and pointed at the prompt from 4 up and 4 out, a 1.5 s wait: `PromptShown` fired and
  `InputHoldBegin`/`InputHoldEnd` picked it up. `ToolUse:FireServer()` then presses the tool.
- **Picking a tool up from the MCP** (Play, Nov 10, again): `user_keyboard_input` E does press a
  prompt, but the one Roblox picks among those in reach (a padlock, then the saw, beside the test
  hall's roll). With every other prompt disabled on the Client, the roll's prompt (2.8 studs off,
  enabled, no line of sight needed) never showed (`PromptShown` silent, even after walking off
  and back) and neither E nor `InputHoldBegin` triggered it. Cause unknown. Next try: pick the
  roll up first, before any other tool, or carry it in from a unit on the walked floor.
- **Never key a weak table by an Instance** (L-16b2): Roblox lets go of a weakly held Instance's
  entry while the Instance is still in the world. 163 prompts put in a `__mode = "k"` table were
  all gone after a garbage pass (20,000 small tables made a few times over 1.5 s), so
  `ButtonReach` lost each button's reach and took it again as 0. Keep plain tables and clear an
  entry on `AncestryChanged` (out of the world) or `Destroying`.
- **A tool carried off the test hall's open end is lost** (Studio only, L-16b2): the hall's west
  end (x about -34) has no floor; walking off it, the body and the welded ladder fall below the
  world and Roblox destroys their parts before `Died` drops the tool, leaving an empty `Ladder`
  model and no button to pick it up. Stop and start Play to get it back. Real floors are closed.
- **The lobby is black for a few seconds after Play starts** (L-08e1b1, Nov 12): a screen capture
  taken at once shows only the signs and the hall lights' tubes; three seconds later the room,
  its textures and the cars' lamps are all there. Wait before judging a first frame.
- **A cross-folder string require's types can fail to reach a caller** (luau-lsp, L-08e1b1): a
  client calling `Boarding.readout`, whose return type names `Readout.Tone` through
  `require("../Elevator/Readout")`, saw the tone as `string`; so did `if pick then pick(x) else x`
  over an optional function field (`{Player} | {Player}`, "Cannot call"). Annotating the caller's
  locals (`local char: string, tone: Boarding.Tone = ...`) or an if statement fixed both; the
  module now spells the four tones out itself.
- **Testing a lobby car from the MCP** (L-08e1b2, Nov 12): the cars' tag is `Elevator.Tag`
  ("FreightElevator"), not "Elevator". After a ride up from the lobby the client streams the
  lobby out: teleport back first and loop on `GetTagged` until the car (and its `CarPanel`
  attachment) are there, then step in. A choice on the panel: `user_mouse_input` with
  `instance_path` "LocalPlayer.PlayerGui.CarPanel.Panel.Body.Go" (or `.Switch.Friends`,
  `.Minus`, `.Plus`) clicks it on a computer. A second player's view on one screen: set the car's
  `Group`, `FriendsOnly` and `Players` from a Client `execute_luau` (local only, never
  replicated; the server's next publish overwrites them). A headline that pops and fades within
  2 s: send it (a Server `FireClient`) and capture in the very next call, not after a wait.
- **Teleports, read Nov 12 (L-08e1c, create.roblox.com's TeleportService, TeleportOptions,
  TeleportAsyncResult and "Teleport between places")**: `TeleportService:TeleportAsync(placeId,
  players, options)` is the one way, server only, up to 50 players, yields, can throw (wrap it in
  `pcall`). A reserved server: `options.ReservedServerId = HttpService:GenerateGUID(false)`; the
  first teleport with a new id makes it, the same id again lands on it. `ReserveServer`,
  `ReserveServerAsync`, `ShouldReserveServer` and `ReservedServerAccessCode` are deprecated, and
  only one routing field may be set. `options:SetTeleportData(t)` sends value types only; read it
  with `Player:GetJoinData().TeleportData` (server) or `GetLocalPlayerTeleportData` (client). It
  passes through the client: never trust it. `TeleportInitFailed(player, result, message,
  placeId, options)` fires on server and client when a teleport that started can't go; retry
  `Failure` and `Flooded` (the docs wait 1 s and 15 s), report the rest. A custom screen:
  `SetTeleportGui(gui)` on the client before the teleport (once per teleport); on arrival
  `GetArrivingTeleportGui()` from a ReplicatedFirst LocalScript, parented to PlayerGui, or Roblox
  drops it once the place loads. On a reserved server `game.PrivateServerId ~= ""` and
  `game.PrivateServerOwnerId == 0` (a VIP server has an owner).
- **Invites and share links, read Nov 12 (L-08e3, create.roblox.com's SocialService, "Player
  invite prompts", Creator Rewards)**: `SocialService:CanSendGameInviteAsync(player, recipientId?)`
  yields (wrap it in `pcall`) and says whether the player may invite at all; call it before
  `PromptGameInvite(player, options?)`, which opens Roblox's friend sheet (client). Options are an
  `ExperienceInviteOptions` instance: `PromptMessage` (dropped if too long to fit), `InviteUser`
  (one friend), `InviteMessageId` (a Notification string from the Creator Dashboard), `LaunchData`
  (at most 200 characters; the joiner's server reads it from `Player:GetJoinData().LaunchData`,
  which can take a few seconds to arrive, so poll it). `GameInvitePromptClosed(player,
  recipientIds)`: recipientIds is no longer filled in, so you can't tell whether anyone was
  invited. The docs don't say what joining an invite from a reserved server does; a friend can't
  follow into one. `PromptLinkSharingAsync(player, options)` is server only: an expiring share
  link (`ExpirationSeconds`, default a day; `PreviewTitle`, `PreviewDescription`,
  `PreviewAssetId`, `LaunchData`, `FallbackLinkId`) on Roblox's share sheet or the clipboard,
  returning an `Enum.PromptLinkSharingResult`; `ShareSheetClosed` fires on the server.
  Audience Expansion pays 35% of a new or returning user's first $100 of purchases (60 days) when
  they come by the experience's share link (or a direct link) and play 10+ minutes that day, the
  experience averaging 100+ DAU.
- **Share links, messaging and names, read Nov 13 (L-08e3b, create.roblox.com's SocialService,
  MessagingService)**: `SocialService:PromptLinkSharingAsync(player, options?)` is server only and
  yields; `options` is a plain dictionary (luau-lsp's `LinkSharingOptions`: `FallbackLinkId`,
  `ExpirationSeconds`, `PreviewTitle`, `PreviewDescription`, `PreviewAssetId`, `LaunchData`); it
  returns an `Enum.PromptLinkSharingResult` (`Success`, `PlayerLeft`, `InvalidLaunchData`); an
  expired link goes to `FallbackLinkId` (default the game's join link). MessagingService: topics
  1 to 80 characters, messages 1 kB, best effort (usually 1 to 2 s, not guaranteed); per server
  600 + 240 per player sends a minute and 20 + 8 per player subscriptions; per topic 40 + 80 per
  server received a minute. `SubscribeAsync(topic, fn)` yields and gives a connection; the
  message is a table with `Data` and `Sent`. `UserService:GetUserInfosByUserIdsAsync({ ids })`
  (server) gives `{ Id, Username, DisplayName }` rows. Unverified: what `game.JobId` is in Studio
  (LobbyCars subscribes only when it reads as a GUID).
- **Invites in Studio** (Nov 12, verified with the MCP): `CanSendGameInviteAsync` returns true in
  Play and `PromptGameInvite` opens the real sheet with your real friends
  (`CoreGui.GameInvite.GameInviteModal`; `screen_capture` doesn't show CoreGui, so read its
  `TextLabel`s from a Client `execute_luau`). Never press a friend's Invite there: it sends a real
  invite. Stop Play to close it. `game.PrivateServerId` can't be read on the client (it warns and
  gives ""): read Workspace's `OwnServer` instead.
- **Opening a lobby car's panel from the MCP** (Nov 12): its count is 20 s, so do it in quick
  calls: Server pivot into the car (`car:GetPivot() * CFrame.new(1, 3, 5)`, facing the gate),
  Client `CurrentCamera.CFrame = CFrame.lookAt(pos, car:GetPivot() * CFrame.new(-5.75, 4,
  1.6))` (the button is off screen otherwise and E does nothing), keyboard E, capture.
  `ProximityPrompt:InputHoldBegin()` from a script didn't trigger it.
- **Studio can test teleports now** (Nov 12, verified with the MCP): a `TeleportAsync` in Play
  opens the destination as a new test server and the Studio session switches to it (the
  executing client call ends with "Target is closed"; Client and Server then mean the new
  server). That server loads the place **as last saved to Roblox**, not this Edit session: save
  first, and attributes set in Edit (`DevTrip`) aren't there. Its `PrivateServerId` and `JobId`
  are empty even for a reserved server. `GetArrivingTeleportGui()` came back nil there.
- **`rojo serve` reads its project's tree only at start** (Nov 12): a new top-level entry in
  `default.project.json` (`ReplicatedFirst`, L-08e1c) didn't sync to a server already running;
  files under existing entries do. Restart it (and Connect) after such a change.
- **Testing the trip from the MCP** (L-08e1c): set Workspace's `DevTrip` in Edit ("Arrive",
  "Send" or "Fail"), Play, pivot the character into a lobby car (`car:GetPivot() * CFrame.new(0,
  3, 6)`), and from the Client `ReplicatedStorage.Remotes.CarPanel:FireServer(car, "Go", true)`
  as its host. Clear `DevTrip` before saving. On "Arrive" the arrival is over about a second
  after the client starts: probe from the server, not by waiting for the cover.
- **The game is first person, and the body turns to the camera** (L-08e2, Nov 12): Studio's
  `CameraMode` is `LockFirstPerson`. A new character keeps the camera's old look, and within a
  frame or two the client turns the body to face it, so "turn the camera the way the body faces"
  turns it the way the camera already looked. Turn it to where the server stood you (a value the
  server writes, `ClimbEnd.StoodAttribute`), after the camera's own update.
- **The lobby streams out during a climb** (L-08e2): back in a lobby car, a screen lifted at once
  opens on a dark, half-there car for a few seconds. `RequestStreamAroundAsync` at each player's
  new spot before the screens lift fixes it (ClimbEnds' `load`).
- **Testing back in your car from the MCP** (L-08e2): end a climb as a wipe by setting the
  player's `Kept` attribute on the Server (nobody climbing ends it about a second later), then
  clear it by hand after the end (KeptPlayers lets out only those it kept); press Again with
  `Remotes.Again:FireServer()` from the Client. Each MCP call takes several seconds, so a 20 s
  count runs out between a few of them: press Again and probe the camera and car in one Client
  call, and capture straight after it. A lobby car's results board can be faked on any car by
  setting its `Results` attribute on the Server (`"Top|3|402|<id>:Out:3,1:Kept:2"`).
- **A lobby car's lamp is dim in its bay** (seen L-08e2, cause not found): car 3's lamp
  `PointLight` read Brightness 0.14 of `Elevator.Lamp`'s 1.2 on the client while its count ran,
  so in first person its walls read black. ElevatorView's `lampAt`/`showLamp` set it; the riding
  car in a climb is lit.
- **There's no PlayerModule in PlayerScripts here** (Play, L-08e4b1, Nov 12): PlayerScripts held
  only `Client` and `RbxCharacterSounds`, so `require(PlayerScripts.PlayerModule)` fails ("not a
  valid member") and its `GetControls():GetMoveVector()` can't be read (WatchView's lookup of it
  fails quietly too). `Humanoid.MoveDirection` (the stick or keys turned by your view, on the
  floor) still updates while you stand on a plain Seat: read that.
- **`Seat:Sit` from the server moved the cart to the player** (Play, L-08e4b1): with the cart
  freed first, the character's root was the pair's root and the cart jumped and turned round
  them. Now the cart's body has `RootPriority` 1 and the character is stood on the seat's spot
  (`PivotTo`) before `Sit`, then the SeatWeld's C0/C1 set to hold it there. A Seat with
  `CanTouch` off still seats by `Sit`, and never by someone walking into it. Jump while seated
  hops you off as usual; a client setting its own `Humanoid.Sit = false` does too.
- **`Workspace:Blockcast` can't see what it starts inside** (Play, L-08e4b1): a cart turned at a
  wall left a corner a hair in it, the next kick's sweep found nothing and carried cart and rider
  out through the wall (the server's room check took the cart back). Sweep from a pose known to
  be clear and check turns with a box a hair bigger than the swept one.
- **The torch poses your arms after any other pose** (Play, L-08e4b1): a cart rider's shoulders
  set in `PreSimulation` read back as set, yet the arms held the torch out level (FlashlightView
  holds it, after). Pose a body's arms only with FlashlightView's say.
- **Seeing your own body in first person for a capture** (L-08e4b1): bind a render step at
  `Camera + 5` that sets every part's `LocalTransparencyModifier` to 0 and the camera's CFrame to
  the shot (following the subject if it moves), capture, then unbind. A plain `execute_luau`
  camera change is undone when the call ends.
- **Sounds measured for the cart** (L-08e4b1; AudioPlayer to AudioAnalyzer in Edit): Pro Sound
  Effects' "Gurney Rolling 1" 9114736569 (19.5 s) a steady metal-wheel rattle about -24 dB from
  1 to 15 s, 85% in 470 Hz to 2 kHz (a phone plays it; "Skateboard Start Constant Rolling"
  9125955680 is 92% hiss over 2 kHz); "Shopping Cart 5" 9119083245 (7.8 s) rolls up from 1.6 s
  and hits a curb at 4.0 s (-13 dB), rattling to 4.5; "Paint Canvas 21" 9117188688 (0.37 s) one
  dry-brush stroke peaking at 0.2 s, a sole's scuff pitched down; "Paint Canvas 5" 9117187117
  steady from 0.75 to 1.0 s; "Skateboard Tail Grinds Scrapes 1" 9125957009 (1.2 s) about -33 dB
  throughout; "Rubber Mat Hits Drops Impacts 9" 9118733086 one thud in its first 0.2 s. The
  library's skateboard push takes (9125954198) bury the pushes under rolling: no clean kick.
- **Testing a cart ride from the MCP** (L-08e4b1): Cart1's slot is (-19.5, 0, 554.85), its Ride
  button over the handle at about (-19.5, 3.5, 557); walk to (-19.5, 3, 561), turn the camera to
  the handle, press E, then turn the camera the way to go and hold W (`user_keyboard_input`
  keyDown, wait, keyUp; Space to hop off). Log from a client Heartbeat connection that writes a
  Workspace attribute when done, read it from a later call. The lobby's left wall is at x -60;
  the cars' band edge at z 596.8.
- **Watching a cart go home from the MCP** (L-08e4b2, Nov 13): the server never moves a homing
  cart; it writes `HomeRun` (from, speed, to) and `HomeAt` and puts it in its slot at the end,
  so a Server log of its pivot jumps. Every screen rolls it: log the pivot from a Client
  Heartbeat into a Workspace attribute. A run of `0/0/length` is a start, not a halt; a halt's
  `to` is short of the way's length. Riding to the stripes with W held 3 s from the rack puts you
  off in the car (the car's count then takes you up within about 20 s); W 1.8 s leaves you
  standing on the cart's handle end. To stand in a homing cart's way, `require` the shared
  `Cart.Home` on the Server, rebuild the way from `HomeFrom`, `HomeTo`, `HomeShape` and the run,
  and `PivotTo` the character a few studs ahead of `Home.at`.
- **Opening a lobby car's panel from the MCP** (Nov 13): E from `user_keyboard_input` and
  `InputHoldBegin` both do nothing until the panel's button is shown, and a prompt shows only
  while on screen: in one Client call, `PivotTo` into the car, wait for the `CarPanel`
  attachment's prompt to be `Enabled`, point the camera at the attachment for a few frames, then
  `InputHoldBegin`/`End`. One player alone, the car's count leaves in about 20 s, so open it
  in the same call that steps in. Share then reaches the server, and Studio refuses the link:
  "share sheet didn't open: HTTP 403 (Forbidden)". Share links work only on a live server.

## DataStores (S1-01, Nov 14)

- The Storage place reaches DataStores in Play (Studio API access is on), but a DataStore call
  from the Edit datamodel (the command bar, the MCP's `execute_luau` in Edit) fails with
  `502: API Services rejected request with error. Error code: 0 Reason: Access forbidden.` Check
  saves from the Server datamodel during Play: `GetAsync` of `player_<UserId>` in `Saves.studio`
  shows the record (`version`, `data`, `lease`) and `KeyInfo:GetUserIds()` the UserId.
- Brix's Saves may change the record its store hands `change` in place (a claim rewrites the
  lease on it), so a store wrapper that compares before and after must read what it needs from
  the old record before calling `change`.
- Play's Stop lets go of each save in BindToClose, and its `[Saving] let go of` line reaches
  Output; the next Play claims it within a second. Empty maps come back from the DataStore as
  JSON `[]`, which load as empty tables.


## Stuff in units (S1-04b2, Nov 14)

- **The open box is bigger than its Specs say.** `Boxes/Specs.luau` gives every box its body
  (the open one 1.8 x 1.6 x 1.8), but the open box's flaps lean out past its walls: its template
  is 2.464 x 2.497 x 2.440 with its pivot 0.222 to +X and 0.102 to +Z of its middle, so it reaches
  1.454 to -X, 1.010 to +X, 1.322 to the front and 1.118 to the back. Closed boxes bow out by about
  their `bulge` each side (a large one is 1.857 across). `art/stuff/spec.py`'s `box_reach` measures
  stacks with both; a stack laid with the body sizes put the heap's flap into the back wall.
- **Seeing the stuff in Play:** Workspace `DevFloorSeed` 104 lays floor 3 (seed 2000110, 38 units,
  code 4687) with a heap in 309, the mattress in 311, a wall of boxes in 315, a tower in 329 and
  the rolled rug in small unit 332 (drawn a column, which doesn't fit). Open them from one Client
  `execute_luau` as "`Deals` hears a press" says (the Open prompt is on `DoorOrigin.DoorMiddle`);
  `Deals:` lines in Output name what stood. Measure each thing from its parts' boxes, their
  corners put into `FloorBuilder.face(unit)`'s frame (the back wall's middle line is the unit's
  depth, the side walls' half its width). Put `DevFloorSeed` back to 7 after.
- **Sounds measured for the finds** (S1-05, Nov 14; Edit, eight AudioPlayers to AudioAnalyzers at
  once, `PeakLevel` in about 50 ms bins): Pro Sound Effects' "Switch Portable Plastic Radio Tape
  Player 9" 9119728830 (1.46 s) one clack at 0.2 s (peak 0.35); "Shield Impacts 15" 9119075637
  (1.31 s) hits at once (0.39) and again at 0.3 s; "Shield Impacts 19" 9119075967 (2.07 s) a big
  hit at 0.2 s (0.87); "Pillow Blanket 1" 9117373366 (1.87 s) one grab at 0.45 s (0.73), the
  "2" 9117373365 loud and violent from 0.15 s; "Roller Skate 10" 9118697756 (1.75 s) wheels and
  impacts from 0.35 to 1.1 s (about 0.6); "Rubber Mat Hits Drops Impacts 9" too quiet (0.03);
  "Plastic Ice Chest 25" 9117544893 quiet (0.12 at 0.15 s).
- **The finds' art** (S1-05): each find's MeshPart in `Props.Finds` has its pivot at the middle of
  its bottom with its box centred over it (PivotOffset straight down by half its height), so a
  find's box middle from its grip is `(0, Size.Y / 2, 0) - grip` (`Tools.bounds`). Their collision
  boxes (Box, Hull) hide the shapes from rays: the skates' standing collar is near (-0.1, 0.9,
  0.42) from the pivot, the teddy's head top 1.42 at z 0.05.
- **Testing a find in Play** (S1-05): on the default dev floor (seed 7, floor 3) Unit 301 holds the
  teddy, 317 and 330 skates, 327 the TV (`lune` on `Deal.open` for `Climb.seedOf(7, 3)`). Pivot to
  (0, 3, -618) facing +X, aim the Client camera at 301's Open (`ActionText`), press it; the teddy
  stands at about (14.2, 0.66, -615.9) in `Workspace.Tools`. Stand at (9.5, 3, -616), aim at its
  Take and press: `ToolSlot1` reads Teddy. `Remotes.ToolDrop:FireServer()` from the Client drops it.
- **Coin pour sounds measured** (S1-06, Nov 14; Edit, AudioPlayer at half speed to AudioAnalyzer,
  0.1 s bins of the recording): Pro Sound Effects' "Coin Throws 3" 9113849651 (1.38 s) one dense
  burst 0 to 0.6 s (0.66 peak) and a tail to 0.9 s, the pay's pour; "Coin Throws 2" 9113849583
  (2.21 s) two throws, 0 to 0.5 s and 0.9 to 1.3 s.
- **Testing the pay on screen from the MCP** (S1-06): in Play, from the Server
  `Remotes.GatePay:FireClient(player, 22, { "Teddy", "Boombox" })` inside a `task.delay`, then
  raise the `Coins` attribute; from the Client sample `PlayerGui.CoinCount` (`Flying` frames,
  `Count.Number`, `Plus`) and `PlayerGui.KeptFinds` (skip its Sounds) in one call. Seen: 12
  coins for 22, the count up by 22 as they land, "+22" in at 0.6 s and gone by 3.6 s; the teddy
  from the box (70 points) to 147 at (498, 412) and the boombox beside it, gone by 2.4 s.
- **AnalyticsService in Studio Play** (S1-02, Nov 14): every call it takes prints
  `AnalyticsService: LogCustomEvent event fired.` (or LogEconomyEvent, LogFunnelStepEvent,
  LogProgressionStartEvent...) in Output, and nothing reaches the dashboard. `Recording` prints its
  own line after each, naming the record.
- **A full climb from the MCP, quickly** (S1-02, Nov 14): Play; from the Server pivot into
  `workspace.FrontOffice.Car3` (`car:GetPivot() * CFrame.new(0, 3, 6)`); from the Client
  `Remotes.CarPanel:FireServer(car, "Go", true)`. About 17 s later the car leaves and the climb's
  floor 1 is `workspace.LobbyClimb.Floor1`, its lobby at x = -1600 (elevator (-1600, 0, -588)),
  units 101 and 102 facing each other across the hall at z = -616. Doors open by their Open
  prompt from the Client; a pile's `Take` prompt is found by `ActionText` within 14 studs.
  To end the climb without a keeper, set the player's `Kept.Attribute` true from the Server for
  about 10 s: ClimbEnds ends it (Kept) its usual way; then `Remotes.Again:FireServer()`.

## The faint mark (S1-11, Nov 14)

- **A one-plane FBX imports as a MeshPart 0.001 thick, DoubleSided true** (`InsertService:LoadAsset`
  in Edit): a Model wrapping a Model named for the asset, wrapping the MeshPart of the same name,
  so `FindFirstChild(name, true)` finds the inner Model first. Its alpha wired into the BSDF's
  gave AlphaMode Transparency, as the kept wrap's did. Its front (-Z) is the Blender plane's -Y face.
- **Sampling what your beam sees: move the character, aim the camera from its head each frame.**
  Moving only a Scriptable camera was unreliable in Play (once the eye stayed at the character,
  once at the camera). Put the character more than about 8 studs out from a door and it landed
  past the hall's far side, fell out of the world and respawned with its torch off; the mark
  streamed out with it. `DevFloorNumber` 1 on Workspace (Edit) lays floor 1, which always has a
  mark; clear it after.


## Cash at the climb's end (S1-12, Nov 14)

- **Testing the cash-out from the MCP** (Play, one player): from the Server, wait for the
  player's `Coins` attribute, set Workspace's `DevCoins` (say 42), then set the player's `Kept`
  attribute true. About a second later Output shows `CashOut: <name>'s 42 coins made $42, now
  $<total>` and `[Saving] saved player_<id> (... cash <total> ...)`; the player's `CashEarned`
  reads 42. Clear `Kept` by hand. The Studio store reads back with
  `DataStoreService:GetDataStore("Saves.studio"):GetAsync("player_<id>")` (the cash is inside
  Brix's record). The coin count leaves the player at the cover (about 6 s).
- **Seeing a lobby car's board in Play:** the test hall's climb has no lobby car, so fake one:
  move the character into a car from the Server (car 6's pivot is (-45, 0, 600), the board at
  (-45, 5.6, 611.9)) so it streams in (StreamingEnabled follows the character, not the camera;
  `RequestStreamAroundAsync` alone lets it go again), then clear and set that car's `Results`
  attribute (`"Top|3|402|<id>:Out:3:42,1:Kept:2:12,2:Left:1:0"`). The board rebuilds and counts.
  The first-person camera takes the view back each frame; a capture through the character's own
  eyes from the front row frames the whole board.

## The breaker (S2-02b, Nov 14)

- **Throwing it in Play:** the dev floor (`Workspace.DevCorridor.Floor3`) has its box at
  (-100, 0, -702), facing +X. From the Server's command bar, `workspace:SetAttribute(
  "ThrowBreakers", true)` throws every box (Studio only; it resets itself). Read the hall lights'
  `Light` attribute under the floor: all `Blind` once thrown. Stand the character 3.5 studs in
  front of the grip from the Server, then from the Client point a Scriptable camera at
  `Breaker.PrimaryPart.BreakerGrip` and `InputHoldBegin`, wait 1.2 s, `InputHoldEnd` (the
  prompt recipe above). The box's `PowerOn` turns true and every light reads `Lit`.
- **Studio's eye adapts to the dark** (S2-02b): a lone light in a black hall looks brighter in
  each capture for several seconds after it comes on, so judge a light's look only after about
  8 seconds, and keep a light meant to stay local short-ranged (range 6 washed a whole hall red
  once adapted; range 4 kept it on the box). A PointLight right on a surface only grazes it:
  hang it a stud or two out in front.
- **Sending the Mannequin to the box in Play** (S2-02c): move your character to (-6, 3.5, -591)
  from the Server, press the "Stand one" post's prompt from the Client (`InputHoldBegin`, then
  `InputHoldEnd`), then park your root anchored at (0, 400, 0) so you trip no light and are seen
  by nobody, and wait about 9 s for the lights to time out. Then from the Server
  `workspace:SetAttribute("SendToBreaker", true)` (Studio only, resets itself): every loose
  Mannequin picks the box now, a hall-stood sleeper woken for it. Sample the body's pivot,
  `KeeperState` and the box's `PowerOn` every 0.5 s; Output says "heads for the breaker", then
  "threw the breaker". It walked 110 studs in 21 s.
- **A door moved by `RollUpDoor.play` from a Server `execute_luau` isn't heard by keepers**
  (S2-02c): the door's motion attribute changed and the door moved, but no keeper heard it (no
  `Keepers:` line). Wake one with a real press from the Client, or the dev command above.
- **`screen_capture` in Play shows your character's view**, not the camera you pass: with the
  root parked high over the lobby it showed sky. Capture the floor in Edit, or move the
  character and its Scriptable camera there first.
- **Testing sleepers waking** (S2-03b, 2026-11-14): on the dev floor the waking clock starts at
  spawn (the spawn is on floor 3's level, so "the team is on floor 3" prints at once). In Play,
  a Server `workspace:SetAttribute("WakeSleepers", true)` skips to the first wave (225 s on floor
  3). Seed 7: the first wave woke 307, 327 and 338, the second (335 s) 335 and padlocked 305;
  each unpadlocked one burst at 90 s, 305 gave "one last blow" and held. Read the bangs off the
  unit's `DoorMotion` ("Bang|...") and `DoorDent` attributes; a `LogService.MessageOut` filter in
  a Server `execute_luau` keeps the Output you read small.

- **`WakeSleepers` needs someone on the floor first** (S2-07a2): set at Play start it does nothing
  (the floor's clock hasn't started). Pivot the character to the keypad, wait 2 s ("the team is
  on floor 3" prints), then set it. Floor 3 allows two loose: the first wave's third prints "is
  held in" at once.
- **Spread at the keypad without pounding** (S2-07a2): from a fresh Play, two wrong codes 4.2 s
  apart (one Client call) free four monsters, hushed, with no pounding door to pull them off the
  alarm. Park the root anchored high, then sample bodies within 25 studs of the pad every 0.5 s.

## Testing a wrong code (S2-04a, Nov 14)

- **A far floor isn't on the client.** With StreamingEnabled, a client script at spawn can't
  reach `DevCorridor.Floor3` (WaitForChild just waits). Pivot the character to the keypad first
  (`CFrame.new(-7.8, 3, -593.2)` on the dev floor), WaitForChild the elevator, fire
  `Remotes.Keypad` four times 0.15 s apart, and pivot back to spawn so a freed Mannequin doesn't
  end the climb. A keypad press counts within `Keypad.Reach` (9 studs) of its face.
- **Wait for the pivot before pressing** (S2-04b). Pressing in the same moment as the pivot
  can reach the server before the character's new place does, and the press is out of reach and
  ignored. `task.wait(0.6)` after `PivotTo` made every wrong code count.
- **Read Output small.** `get_console_output` returns the whole log, with about 50 texture
  permission lines at every Play start. Instead, at Play start run a server script that hooks
  `LogService.MessageOut`, keeps lines starting `Keepers:` plus warnings and errors in a
  `ServerStorage` StringValue, and read that; a second loop writing each keeper body's distance
  from the keypad every 2 s shows who turned.
- **A timed-out `execute_luau` keeps running.** The tool gave up ("Request timeout") but the
  script went on waiting and pressed later, so the keypad saw an extra wrong code. Keep each call
  short (one wrong code a call) and time long things with a server-side watcher that writes a
  Workspace attribute.
- **The keypad's bell recording** (`rbxassetid://9125544264`) is 7.9 s long but is one clang:
  loud at 0.6 to 1 s, about 20 times quieter by 2.5 s. Measured with an `AudioPlayer` wired to
  an `AudioAnalyzer` in Edit (`RmsLevel` every 0.2 s). Don't loop it; strike it again.
- **Unchecked Output line:** `ContentId: rbxassetid://89260803894903 failed due to: No asset
  content representation found` (27 times) as the first wrong code's unit was dealt and rolled
  up. The ID isn't in the repo or in any MeshId, Texture or Image in Workspace or
  ReplicatedStorage on either side. Traced in S2-07b2 (D-174): the owner's TexturePack from the coin's
  import, named by no property; three coins cloned in Play didn't bring it.

## The machine's menu (S1-10d1, Nov 14)

- **An Edit `require` keeps the module it first loaded** (S1-10d2): after Rojo synced the new
  `Machine.Specs` (its Source read 1.8 deep), `require(RS.Shared.Machine.Specs)` in an Edit
  `execute_luau` still gave 2.4. Clone the module (`RS.Shared.Machine:Clone()`, parented beside
  it so its own `script.X` requires resolve), require the clone, use it, destroy it. Play
  starts fresh, so this is only for Edit work such as `Machine.prepare`.
- **Studio drew frames again** (S1-10d2): the Client's RenderStepped fired 30 times in half a
  second, so client-side Play checks worked; the frameless session below is the exception.

- **Studio drew no frames at all** with its window hidden (S1-10d1): the Client's
  `RenderStepped` fired 0 times in half a second while Heartbeat fired 30, so the client Host
  (stepped from RenderStepped) never stepped and no client system moved; `screen_capture` timed
  out. Check that count first (a `task.wait(0.5)` with both connected) before trusting any
  client-side Play result. Server paths and remotes still work: a Client `FireServer` is sent.
- **A pick staged from the Client** (S1-10d1): `Remotes.MachinePick:FireServer(machine, bay)`
  after staging the ride as above; `Remotes.MachineBuy.OnClientEvent` says the sale came back.
- **luau-lsp widened a string-singleton alias returned by a frozen module** (S1-10d1): `Buy.tile`
  is typed `: Tile`, yet a client field typed `Buy.Tile` got "string" from it. Store it as
  `string` with a comment rather than casting.
- **A prompt made on a client needs an anchor that never moves**: the machine has no
  PrimaryPart and its first BasePart was a coil, which turns as it vends; the button hangs on
  `Glass`.


## The alarm's lights out (S2-04c, Nov 14)

- **Other creators' free Creator Store audio loaded here.** Eight sounds from `search_asset`
  (users' uploads, not Pro Sound Effects or APM) all preloaded with status Success and a
  `TimeLength` in Play. To judge one unheard, wire an `AudioPlayer` to an `AudioAnalyzer` with
  `SpectrumEnabled` and log `RmsLevel` (dB) and the spectrum's centroid every 0.2 s: "light power
  off" 106554188841955 reads -5 dB at once and a centroid falling 4.4 kHz to 500 Hz in 1.6 s, a
  power-down sweep.
- **luau-lsp narrowed a singleton wrongly across `elseif`s.** After `elseif state == "Out" and
  was ~= "Blind" then`, a later `elseif was == "Out"` failed with `Type "Blind" cannot be
  compared with "Out"`. Take the comparisons into locals first (`local wasOut = was == "Out"`).
- **Testing it from the MCP:** the S2-04a recipe above; a Client RenderStepped loop logging a
  lit fixture's `Diffuser` material, its SurfaceLight's brightness and its `Eye` colour shows
  the stutter; the dev floor has 23 fixtures and none inside a car.
- **The halls' pieces don't answer queries** (S2-02d1, Nov 14): the corridor kit's meshes have
  CanQuery off, so `GetPartBoundsInBox` found none of them and a ray passes through them; a ray
  stops only at their invisible collision boxes (Transparency 1), so never skip a hit for being
  see-through when measuring a hall. To copy what's in view, walk the floor's parts once and test
  each against the lens (FeedView: a floor in a millisecond or two, 46 parts in view).
- **AbsolutePosition ignores IgnoreGuiInset** (S2-02d1): the corner map, placed at the top bar's
  bottom plus 10 (68 in Studio) in a ScreenGui with IgnoreGuiInset, reports AbsolutePosition Y
  10. To line something up with another gui, parent it into that gui and copy its UDim2 Position
  instead of converting. The map's screen layers its children by one ZIndex for all: a child
  added there needs ZIndex above the map's (FeedView uses 10 and up) or its background hides
  its own children.
- **Studio in the background draws no frames** (S2-02d2, Nov 14): `RunService.RenderStepped`
  fired 0 times a second (Heartbeat 60), so every client system stepped on it (`init.client`'s
  frames: KeeperView, FeedView's follow) stood still. A body then shows each standing record only
  when the next one arrives (one late), walking bodies glide unposed, and scripted
  `InputHoldBegin` on a prompt does nothing (it's never shown). Count RenderStepped first; to
  get a loose Mannequin without the prompt, `workspace:SetAttribute("WakeSleepers", true)` and
  wait 90 s for the unpadlocked ones to burst out, then "SendToBreaker" (sounds call them off
  often: send again). The body's state is in its `KeeperMotion` attribute's first word
  (Reaching, Pulling at the box).
- **Getting frames back when Studio draws none** (Nov 14, afternoon): with the owner away the
  display idles and RenderStepped drops to 0. `caffeinate -u -t 1` (declares the user active)
  brought it to 7-15 a second at once; it fell back to 0 within minutes, so pulse it in a
  background loop (`caffeinate -u -t 1; sleep 4`, repeated). Bringing the app forward
  (`osascript ... activate`) alone did nothing. `screen_capture` with no frames hangs for minutes
  before it times out: count RenderStepped right before every capture.
- **`WakeSleepers` does nothing until someone has stood on the floor** (Nov 14): the floor's
  sleeper clock starts only when a player is on it, and a root parked under the lobby at
  (-6, -12, -591) from the start doesn't count. Stand the root at (-6, 3.5, -591) for 2 s (Output:
  "its sleepers' clock starts"), set `WakeSleepers`, then park. The bursts come 90 s later.
  `SendToBreaker` then had a Mannequin throw the box within a minute, before a watch loop on
  `KeeperMotion` started: start that loop in the same call that sends it.
- **A new Sound starts late, primed or not** (S2-02d4, Nov 14, Play at 15 frames a second): a
  `Sound` made and played at once reads `IsLoaded` false and its `TimePosition` sits still for
  about 0.28 s, even for a recording `SoundPrimer` played and the game played before. One made
  ahead (wait for `IsLoaded`) and replayed starts within a frame, and with
  `PlaybackRegionsEnabled` it stops by itself at its region's end. Sounds that must land on a
  beat are made once at start and replayed (FeedView). A tween with a delay may start a frame or
  two late: end a region a little past a fade.
- **The feed's static, measured** (S2-02d4; Edit, AudioPlayer at a quarter speed to an
  AudioAnalyzer): Pro Sound Effects' "Television Static On Change Stations Constant 1"
  9126097386 (2.87 s) is silent with a click at 0.3 s, then from 0.745 s full hiss (about -22 dB
  RMS, -16 at the edge) within 5 ms, to a hard stop at 2.15 s. "...Constant Off 2" 9126097099
  (6.84 s): a click at 0.6 s, steady hiss 1.0 to 5.56 s, then the set switched off (down 30 dB in
  60 ms). "Off 4" 9126097283 and "Off 3" 9126097291 are the same, longer; "On 3" 9126097362
  changes channel at 5.2 s and hums quietly after 8.9 s.
- **A feed up as your gate shuts, in Play** (S2-02d4): punch the code (2274 on the dev floor,
  seed 7) at (-7.8, 3, -593.2), then from the Client hold the "Stand one" post's prompt
  (`StandMannequin`, Scriptable camera on it), park anchored under the car at (0, -12, -581),
  and from the Server set `SendToBreaker` when the elevator's `Departs` is 20.5 s off and pivot
  aboard at (0, 3, -581) 1.5 s before it. The stood Mannequin walked 110 studs and reached the
  box just after the gate hit its post (about 1.1 s after `Departs`); the feed cut in 2.6 s
  before. On the dev floor the shut ends the climb (Top). `WakeSleepers` is worse for this:
  later waves pound and call the errands off.
- **Testing the camera feed in Play** (S2-02d1): the "Sending the Mannequin to the box" recipe,
  but park your root anchored under the lobby at (-6, -12, -591), not up at 400: the feed goes
  only to players on the floor (40 studs up or down). The feed is `PlayerGui.Minimap.Feed`;
  sample its `Picture` (children: Camera, Halls, the copies) and `Picture.Ambient` (drops at the
  throw). A staged feed: from the Server, `ReplicatedStorage.Feed:FireClient(player, "Show", id,
  cameraCFrame, 7, { box, body }, floor)` shows for 8 s; capture 0.6 s later, once the map has
  finished sliding in and the floor has streamed.
- **Staging feeds at a walking monster** (S2-07a1): stand one from the "Stand one" post (put a
  Scriptable camera 4 studs off the post and wait for `PromptShown` first, or the hold does
  nothing), park, set `SendToBreaker`, and from the same Server call `task.spawn` a schedule of
  `Show`/`Cut` fires (the watch list can be `{}`: the floor's monsters are followed anyway) so the
  Client call that samples `Picture.Mannequin`'s pivot every 0.25 s runs while they land. A
  camera 5 back and 4.5 up along the body's `LookVector`, aimed 3 ahead of it, keeps it in shot;
  one aimed back at it from ahead loses it in a second. A capture can take seconds: fire the
  feed, read the picture and capture in one parallel batch.

## Testing the tap (S2-05a, Nov 14)

- **Press a door's button from the Client with the camera in the hall.** The door's frame has +Z
  into the unit, so the hall is `at - RollUpDoor.frame(unit).ZVector * 6`; a camera put on the
  other side (`LookVector * -6`) sits inside the unit and `InputHoldBegin` does nothing at all.
  Pivot the character to `frame * CFrame.new(0, 3, -3)` first; a far unit needs a pivot near it
  before `WaitForChild` finds it (streaming).
- **Drive the tap from the same Client call:** connect to `Remotes.ShutTap.OnClientEvent` before
  pressing Close to catch "Open" (start, zone), wait for `start + Lead + (zone + width/2) * Sweep`
  on `GetServerTimeNow`, then `FireServer(unit, GetServerTimeNow())`. Dev floor (seed of Nov 14
  evening): sleepers in 305, 307, 327, 335, 338; 307's hit settled from 1.05 studs, 327 with no
  tap answered at 1.78 s and its door read `Drop` then `Bang` 1.22 s later.
- **A test can't press keys** (S2-05b): `VirtualInputManager:SendKeyEvent` from a Client
  `execute_luau` fails ("lacking capability RobloxScript"), so a screen's own `InputBegan` path
  (TapView's tap) can't be driven; send the remote instead and say the input path is untested.
  A failed call stops the script mid-run: an open bar then runs out as a miss.
- **A door button shows only with a clear sight line from the camera** (S2-05b): a Scriptable
  camera straight behind the character, looking at the door's middle, ran its line through the
  head and Open never showed, so `InputHoldBegin` did nothing. Put the camera off to the side,
  `frame * CFrame.new(3.5, 7, -9)` looking at `frame * CFrame.new(0, 3, 0)`, and wait for
  `ProximityPromptService.PromptShown` on the button before pressing it.
- **A staged bar** (S2-05b): from the Server, `Remotes.ShutTap:FireClient(player, "Open", unit,
  GetServerTimeNow() - 0.3, 0.6)` puts the bar up on that screen with no window on the server
  (its taps are ignored); `FireClient(player, "Done", unit, false)` a second later shows the
  miss. A `screen_capture` right after the Open caught the bar still in its lead.
- **The warning tick, measured** (Edit, AudioPlayer at a quarter speed to an AudioAnalyzer):
  9120089728 is 0.36 s, its click at 0.015 s (-10 dB peak), down 30 dB by 0.07 s, a faint ring to
  the end. 9117028600 ("Moviola ... Sharp 8") is two clicks, 0.03 and 0.28 s.

## The player's three (S2-07b1, Nov 14)

- **The dev floor's keypad is under no hall light.** It sits in `Floor3.Lobby` at about
  (-7.8, 4, -588); the nearest fixture (`Straight2.Fixture`, at (0, 0, -624), its hall along Z)
  is 36 studs off. To watch a light come back over a still player: punch the wrong code at the
  keypad, then pivot to (0, 3, -624) within the dead span and stand; a server watcher on the
  fixture's `MotionLightState` shows Out, then Lit as the alarm ends.
- **Setting `Kept` by hand ends a one-player climb.** With nobody left free, the climb is lost
  and the character goes (the end screen); restart Play after. Clear it in the same call.
- **The torch button from the MCP:** `ContextActionService:CallFunction` is refused ("lacking
  capability RobloxScript"); `user_mouse_input` with a right click in the viewport presses it.
  Your own torch is `Workspace.YourFlashlight` on the client (its SpotLight and PointLight).
- **Testing a screen's battery rule without opening a unit:** a client-made Part tagged
  `Battery` with a `Take` attachment, a ProximityPrompt and a `Unit` ObjectValue, and the
  Player's `Charge` set low on the client, is picked up by BatteryView like a real one.

## The screen's three (S2-07b2, Nov 14)

- **Which asset a load line means:** `ContentProvider:GetAssetFetchStatus(id)` on the Client
  gives each content id's state without loading it (Success, None for never asked, Failure).
  The server answers None for everything (it renders nothing). `PreloadAsync` with id strings
  answered Failure for nearly all 458, loaded or not: useless for this.
- **What an id is:** `MarketplaceService:GetProductInfo(id)` on the Server gives its name, type
  (`AssetTypeId`; 63 is a TexturePack, which the 3D Importer makes beside a mesh) and creation
  time; match the time against other imports' meshes to find which import made it.
- **A load failure is printed once a session:** reloading the character or cloning the thing
  again brings no new line, so a test of "does X cause it" needs a fresh Play.
- **Standing in a friend's beam for a client view:** require the view's module from
  `PlayerScripts.Client`, make a second instance with a fake `Beam` whose `friends()` returns your
  own sight table, and call its `step` by hand; the real instance leaves an unlit mark alone.

## Pressing a prompt from a test (S2-06b2a, Nov 14)

- Through the Studio MCP, neither a key sent with `user_keyboard_input` nor the client calling
  `ProximityPrompt:InputHoldBegin()` / `InputHoldEnd()` fired the dev floor's post (R, hold 0,
  the player standing at it). A dev post a test must press also listens for a Workspace
  attribute in Studio (`StandPackrat`), as `SendToBreaker` and `WakeSleepers` do.
- **Testing a drop in front of a hunting Packrat from the MCP** (S2-06c2, Nov 14): `GiveFind`
  gives nothing until your root stands on the floor (pivot it to (-6, 3.5, -591) first), and
  setting the value it already holds fires nothing: set it to "" then "Teddy". The held find is
  the character's `HeldTool` model. Then one Client call does the rest: wait for the Packrat's
  `KeeperState` to be Roaming with 19 clear studs ahead of it (a raycast), pivot your character 16
  studs ahead facing it, and the moment `KeeperState` reads Hunting fire `ToolDrop`
  (`ReplicatedStorage:FindFirstChild("ToolDrop", true)`). Fire it at once: the server is a few
  studs ahead of what the client shows, and 0.2 s later it has already reached you. Output: "turns
  off drftware for the find in its path", then "takes a find and heads home with it". Placed only
  12 studs off with your back to it, it sees you at 7 and robs you before a scripted drop.
- **Baiting the Packrat into a unit from the MCP** (S2-06d, Nov 14): lay the bait before standing
  it, or the loud open draws it and it catches you. Server: pivot your root to (-6, 3.5, -591),
  wait for `Floor3.StandPackrat` and 2.5 s, `GiveFind` "" then "Teddy", pivot to the hall at
  (-48, 3, -594) facing +X. Client: point a Scriptable camera at Unit308's Open, wait 1.2 s,
  `InputHoldBegin`/`End` (Unit308's inside runs toward +X from its door at X -44.15). Pivot to
  (-36, 3, -594) facing +X and fire `ToolDrop`: the teddy lies at X -33.4. Then stand on Unit308's
  roof (bounding box top + 3): the Packrat never sees the tops. Server: `StandPackrat` true (a
  number does nothing). Client: aim the camera at Slam, watch the Packrat's `KeeperState` (the raw
  state: reaching reads "Waiting") and when it's Waiting inside (X > -43), pivot to (-47.5, 3,
  -594), wait 0.25 s, press Slam. It laid the boombox, walked in at about 39 s and was trapped.
- **Anchoring your root on the Client hides where you went from the server**: a client
  `PivotTo` followed by `Anchored = true` in the same frame never reached the server, which still
  had the player where they stood before, and the Packrat came at that spot and caught them. Park
  a player somewhere it can't see (a unit's roof) instead of anchoring.

- **Testing a screen's answer to a server mark from the Client alone** (S3-01a, 2026-11-14):
  `LocalPlayer:SetAttribute(...)` on the Client fires that attribute's changed signals there
  (it never reaches the server), so one Client call can set the marks and sample the screen in
  step with it. Two calls (Server sets, Client samples) land seconds apart, past a short moment.
  The carried wake: set `BroughtAt` to `workspace:GetServerTimeNow()` and `Kept` to true, sample
  the `Caught` ScreenGui's full-screen frame, then clear both.
