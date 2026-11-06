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
  2026-11-05). `rojo build` writes `Lighting.Technology`; live sync can't (plugins can't write
  it), so it's set once in Studio (OWNER.md).

## SurfaceAppearance

- **Overlay** (docs): the part's Color shows wherever the ColorMap's alpha is 0. Its `Color`
  property tints the ColorMap only, never the part's Color.
- Writing AlphaMode and the map properties needs plugin security (docs): the command bar and
  plugins can, game scripts can't.

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
  `StreamingTargetRadius`, `StreamOutBehavior`, `Lighting.Technology`). Check those in the
  Properties panel. It can still require the game's modules, set AlphaMode, destroy a
  PackageLink and set ChangeHistory waypoints.
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
