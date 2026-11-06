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
  PackageLink before preparing. Upload: `scripts/upload_unit.luau` (D-010).
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

## Lighting and captures

- **Graphics quality decides the hall's look** (Play, 2026-11-06, a plate held under a tube):
  `settings().Rendering.QualityLevel` at Level08 and on Automatic, the tube cast no shadow, ignored
  its cone and lit a shut unit's inside through the 0.001-thick facade; at Level10 a faint, blurry
  shadow; at Level12 and up, sharp shadows, the cone holds and units stay dark. Forum reports put
  Realistic (Future) lighting at graphics quality about 4 of 10 and up, falling back on weaker
  devices ([Android rollout thread](https://devforum.roblox.com/t/future-is-bright-on-android-is-fully-rolled-out-client-beta/3235808?page=4)).
  Studio sat on Automatic, which here gave the fallback. A session can set `QualityLevel` from the
  MCP (Client); Play resets it to Automatic. Put it back to Automatic when done.
- **Low graphics ignores geometry entirely** (Play at Level08, 2026-11-06): a 2-stud concrete
  slab over a unit and a 2-stud block in front of its door changed nothing inside; switching the
  tubes off made it black. Range barely matters there either (15 against 22 looked the same): the
  light spreads coarsely past it. Only the lights themselves (brightness, on or off) steer that
  look, so scale them per client (D-016).
- **Neon blooms into blobs at low graphics:** a neon strip brighter than about 150 grey smeared
  into round blotches at Level08 (Lighting's Bloom, Threshold 2). Keep small glowing details at
  mid grey; Neon still reads white.
- **Saving captures:** `screen_capture` images land in the session's `tool-results` folder (the
  path comes back with each image); compose them with ffmpeg `hstack`. In zsh, write ffmpeg's
  options out rather than in a variable: zsh doesn't split it into words.
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
  **no `open_cloud_invoke`**, so uploads go through `scripts/upload_unit.luau`.
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
  with `ProximityPromptService.PromptShown` and `PromptHidden`. With Studio in the background the
  client ran at about 15 fps, so time feel by the clock, not by frames.
- **`require` in Edit is cached:** after Rojo syncs a change, `execute_luau`'s `require` still
  returns the module from the first call. Require a `:Clone()` of the module tree for fresh code.
- `insert_asset` tags what it inserts `Assistant:<guid>`; remove the tag before keeping the model.
- **One asset ID serves every branch:** after uploading the unit from one branch, re-upload from
  the branch you return to (set its `sha256` in `art/unit/assets.json` to anything and run the
  script; it writes the same hash back).
- `ProximityPromptService.PromptShown` misses prompts already showing when you connect (the spawn
  is within reach of 101's): step away first.
- **Rojo connects through the owner:** start `rojo serve` in the background; the owner clicks
  Connect in Studio's Rojo plugin. Rojo keeps the place's own children (Baseplate,
  `ReplicatedStorage.Units`) because no node there has a `$path`.
- `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type`
  shows six times at each Play; nothing in the game references it (searched the client), so it's
  Studio's or the avatar's. Ignore it.

- **Blender 5.2 headless:** assigning `hide_render` while iterating `collection.all_objects`
  doesn't stick; wrap it in `list(...)`. The volume node is `ShaderNodeVolumePrincipled`. A camera
  made this frame has a stale `matrix_world` until `view_layer.update()`. GPU bakes vary by at
  most 1/255 between runs, so texture hashes aren't stable.
- **luau-lsp 1.70.1 strict:** locals bound from a multi-return widen string-literal unions to
  `string`; annotate them (`local kind: Motion.Kind, from: number = Motion.decode(...)`).
- **Lune** runs a spec with `lune run tests/<name>.spec` from the repo root; specs require
  modules by relative path.
