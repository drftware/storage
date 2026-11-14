# The faint mark

A small, hasty chalk ring with a dot in it, scrawled on the steel jamb beside one note's door
(S1-11, D-150; GDD "At most one faint mark on a floor"). Numbers: `spec.py`. The game shows it
only in your own torch's beam from a few steps (`src/shared/FaintMark.luau`, FaintMarkView).

    scripts/art.sh mark            textures, FBX, look sheet (seconds)
    scripts/art.sh mark export     just the FBX

- **textures**: the ring is drawn straight into `out/textures/FaintMark_Color.png` with numpy:
  one stroke stamped along a tilted, wobbling oval that runs on past its start and spirals in a
  little, swelling and dragging thin at its end; the chalk caught only the steel's high points,
  in fine specks and in streaks along the stroke (the alpha). A flat 16-texel roughness map.
- **export**: `out/FaintMark.fbx`, one plane 0.44 studs square, its drawn face toward Blender -Y
  (Roblox front), the colour's alpha wired into the BSDF's so it imports in AlphaMode
  Transparency. No Specs module: the game reads only the part.
- **renders**: `art/sheets/mark.png`, flat on in a soft light, then from about three steps in a
  torch's beam.

## Into Studio

`lune run scripts/upload_art FaintMark`, then in Edit `InsertService:LoadAsset(id)` (the ID is in
`assets.json`): the MeshPart is two Models deep. Move it to `ReplicatedStorage.Props.FaintMark`,
CFrame identity, Anchored, CanCollide, CanQuery, CanTouch and CastShadow off, Transparency 1.
FloorBuilder clones it onto the marked unit's jamb as the floor is laid.
