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
  looks only for a `Motor6D` finds nothing (FlashlightView's `motor()` does). Luau can't index
  `Transform` through the two classes' union, so CrawlView sets it through one `any`.
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

## The hall's render cost

- **Testing a server system from the MCP** (L-06b2a, 2026-11-09): the Host's systems live inside
  `init.server` and can't be reached from `execute_luau`. Drive them as a player would: move the
  character next to the walked floor from the Server (it's 600 studs off and not streamed at the
  spawn), then press its dev post or a door's button from the Client (`InputHoldBegin`, above),
  and read what happened off attributes (`KeeperState`, `DoorMotion`) and Output. A Server
  `execute_luau` can sample a keeper's pivot every 0.1 s for a path; the pure modules
  (`Floor.generate` with the dev floor's seed, `KeeperMap`) rebuild the same map to check against.
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
- **A press made the moment you arrive** (L-12c, 2026-11-10): the server sees a run late, so a
  prompt pressed as you reach it reaches the server while it still sees you a few studs back
  (4 studs at a full run: the Crawl button 6.8 studs off, you still in the doorway). Any server
  check of where you stand for a press must allow for it (`Crawling.counts`: where it sees you
  or 0.4 s on at your speed, D-085). A door's Slam pressed the same way landed. After being
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
  crawl if it's a few studs off. To crawl a way, hold the view with a `BindToRenderStep` and hold
  W with `user_keyboard_input`. The torch's R1 from `user_keyboard_input` doesn't reach its
  ContextActionService binding; for a shot, enable the beam's SpotLight on the Client.
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
