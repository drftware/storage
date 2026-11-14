# The security camera feed's pictures (S2-02d)

When a monster does something the team should see, every player on that floor watches it on a
security camera in the corner of the screen (`FeedView`). Two tiling pictures make it read as an
old camera rather than the game's own view:

- **FeedGrain** (128x128): white specks of every strength on clear, every other row a faint dark
  scanline. Laid over the picture and moved by whole pixels each time the picture updates, so the
  grain crawls while the lines hold still.
- **FeedSnow** (128x128): a dead channel's snow with a few torn bright bands, shown as the feed
  cuts in and out.

Made by `build.py` (seeded; plain Python, so `scripts/art.sh feed` or `python3 art/feed/build.py`).
Uploaded with the Studio MCP's `upload_image` (docs/STUDIO.md "A 2D picture from the Studio MCP");
the ids are in `assets.json` and in `src/shared/Feed.luau`.
