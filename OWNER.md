# Owner

Everything waiting on you, in order. Work down and tick boxes. Agents add new items here and
nowhere else.

## Now

- [ ] **Judge the storage unit's look.** Open `art/sheets/unit-contact-sheet.png`, then
  `art/sheets/door-hall.mp4` and `door-mechanism.mp4`. Say yes, or what to change. It sets the
  look for every asset after it: worn, real materials under cold corridor light (D-007).
- [ ] **Before the next session (P0-02): Studio open on this game's place, ready to be driven.**
  1. In Studio, keep only this game's place open (right now a second window is open too, and it's
     unknown which one the session would talk to). Publish it to its experience first if it isn't
     yet: the unit's import uploads meshes and textures, and they should belong to the game's owner.
  2. Keep Studio's MCP option on, as it is for Game1, and the Rojo plugin installed. The session
     starts `rojo serve` and may ask you to click Connect.
  3. Start a new session here. If it asks to approve the `Roblox_Studio` server, approve it. If no
     Studio tools appear, run this in this folder, then start again:
     `claude mcp add Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`
  4. The 3D Importer is a dialog. If the session can't run it, it will ask you to do just that one
     import with the settings in `art/unit/README.md` ("Into Studio"), and do the rest itself.
- [ ] **Branches:** everything so far is on `storage-unit`; `main` has no commits yet. Say if you
  want `storage-unit` to become `main`.
