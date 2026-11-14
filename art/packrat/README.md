# The Packrat

The second monster (GDD "The Packrat collects things, not people"): a tall, faceless bundle of
grey moving blankets bound with packing tape, two long bare arms out of it. It carries the
floor's finds home one at a time, so its look has one job: full arms read apart from empty arms
from the far end of a hall on a phone. The arms are the only pale thing on it.

| | |
|---|---|
| ![lineup](../sheets/packrat-lineup.png) | ![hall](../sheets/packrat-hall.png) |

Sheets in `art/sheets/`: `packrat-lineup` (asleep, walking empty, walking full, full from the
side), `-close` (the hug), `-hall` (empty and full 30 studs off, at a phone's size).

## Numbers

| | |
|---|---|
| Height | 7.3 studs at rest (`spec.HEIGHT`); 8 clears a door |
| Triangles | 7,020 |
| Texture set | Packrat, 1024² (colour, normal, roughness, metalness), 103 texels a stud |
| Parts | 15 MeshParts named as R15's body parts; `prepare` adds the root (S2-06a2) |
| Carry | where a find's middle sits on the UpperTorso: `spec.CARRY`, `Specs.Carry` |

## How it's made

```
art/packrat/spec.py    every number: the parts' stations, the joints, the tape bands, the
                       quilting, the blankets' edges and greys, the hood's hollow, the capsules
art/packrat/build.py   stages textures | export | renders (scripts/art.sh packrat, about a minute)
scripts/packrat-poses.luau  writes out/poses.json from src/shared/Packrat/Pose.luau
```

The Mannequin's way (`art/mannequin/README.md`): lofted parts in one frame, the finds' bake.
Its own: a blanket part's loft is creased (three waves round and down it) and pulled in where a
tape band crosses it, so the recipe's tape sits in a real pinch; the hood's front is pushed in
and painted near black. The recipe: quilted diamonds puffed between their stitches, a dark
binding where one blanket's edge crosses another, dull tan tape wrinkled across with pale
lifting edges, grime low down; the skin pale and mottled, darker at the elbows and knuckles,
grimed at the fingertips.

## Into Studio

Not yet (ROADMAP S2-06a2): `lune run scripts/upload_art Packrat`, insert, prepare, and the
template at `ReplicatedStorage.Keepers.Packrat`.
