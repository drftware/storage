# Studio, API and tool notes

What we learned the hard way, so no session relearns it. Mark each note with where it was
verified: a doc page, Studio, or "untested".

## Getting assets into Roblox

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

## SurfaceAppearance

- **Overlay** (docs): the part's Color shows wherever the ColorMap's alpha is 0. Its `Color`
  property tints the ColorMap only, never the part's Color.
- Writing AlphaMode and the map properties needs plugin security (docs): the command bar and
  plugins can, game scripts can't.

## Camera and prompts

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

## The hall's render cost

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
- **Measuring the bulb's click** (L-04b): Pro Sound Effects' "Moviola Toggle Switch Single Clicks
  Sharp 8" (9117028600, 0.74 s) is a sharp tick in its first 0.1 s and a faint release at 0.25 s;
  "Light Bulb Buzz 2" (9112823813) is a 49 s loop. Both preload in Edit.
- **The MCP's clicks don't reach a ScreenGui button in the Device Simulator** (L-11a): neither
  `instance_path` nor coordinates fired the torch button's InputBegan, MouseButton1Down or
  Activated. A gamepad key from `user_keyboard_input` (ButtonR1) does reach ContextActionService;
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
- **Sounds from the audio library** (L-03): `search_asset` with `assetType = "Audio"` finds them;
  Pro Sound Effects' and APM's uploads are Roblox's licensed library and load in any game. Check
  one in Edit with `ContentProvider:PreloadAsync` (status Success, `TimeLength` above 0) before
  relying on it.
- **The command bar caches `require`** (L-11c): after Rojo syncs a module, requiring it from
  `execute_luau` in Edit can still return the old one. Require a clone instead
  (`require(ReplicatedStorage.Shared.Tools:Clone())`), then destroy the clone.
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
  within a frame. Play it once at volume 0 first (`SoundPrimer`). The double-ding 9119642644 is
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
  shows six times at each Play; nothing in the game references it (searched the client), so it's
  Studio's or the avatar's. Ignore it.
  `rbxassetid://87642977759407 failed due to: Asset content representation is being generated`
  showed about thirty times once mid-Play (L-04e, Nov 9); no instance on either side names it
  (searched MeshId, TextureID, the four maps, SoundId, Image). Same verdict.
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

