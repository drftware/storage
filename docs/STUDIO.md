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
- Right after the hall streamed back in, the first capture rendered black; a few seconds later it
  was lit. Watch for that flash after a teleport.

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
