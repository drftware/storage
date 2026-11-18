# The next-floor cards' faces

On the ride up, three cards light on the car's panel, each a version of the floor you're riding to
(`NextFloor.Versions`, ROADMAP S4-03). Each card's face is a picture of that floor, with no words:
you read it at a glance on a phone, as Hades shows each door's reward before you pick.

| Version | The picture | Its light |
|---|---|---|
| PowerOut | the hall's caged bulb, dead, hanging in front of a cold pool on the wall | cold blue |
| TwicePadlocks | two padlocks hanging on a steel door, the right one swung as if just hung | warm bulb |
| TwiceMonsters | two Mannequins standing as they're found at the end of a dark hall | sick green |
| CaughtToLobby | looking down the shaft at the car far below, its cables running down to it | emergency red |

Each card has its own colour of light, so the three on a panel tell apart before you've read a
picture.

## How it's made

```
art/cards/spec.py    every number: the face's size, each scene's camera, lights and exposure
art/cards/build.py   stages: faces (out/<Version>.png) | sheet (art/sheets/cards-phone.png)
scripts/art.sh cards both stages, under a minute
```

Each scene is staged from the game's own exported models (`art/padlock/out/Padlock.fbx`, the
Mannequin's FBX stood in its `Still` pose from `poses.json`, the corridor's caged bulb, the freight
elevator), so the faces match what players meet on the floor. They're lit and rendered with the
unit's render kit (`art/unit/render.py`: Cycles, AgX). Build those models first.

The faces are 512 by 640 pixels (4 wide to 5 tall): a card is about 130 points wide on a Galaxy A16,
about 340 pixels, so they stay sharp. Judge them on `art/sheets/cards-phone.png`, which shows the
four at that size.

## Into the game

`lune run scripts/upload_art PowerOut` (and each other version's name) uploads a face through Open
Cloud and records its ID in `assets.json`. That ID is a Decal's, not the picture's: from Studio's
Server, `InsertService:LoadAsset(id)` gives a Model holding a Decal whose `Texture` is the image's
`rbxassetid://`, and that goes into the version's `face` in `src/shared/NextFloor.luau` by hand.
A re-rendered face uploads as a new Decal (an image is never updated in place).

Nov 17: the four images fetched with `AssetFetchStatus.Success` in Play straight after upload.
