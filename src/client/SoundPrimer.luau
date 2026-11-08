--!strict
--[[
	SoundPrimer: gets recordings ready so their first play is on time. A recording's first play in
	a session starts a quarter to a third of a second late even after ContentProvider has loaded
	it; every play after starts at once (docs/STUDIO.md, "A recording's first play is late"). So
	this loads each one, then plays it once, silently, and lets it go.
]]
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

-- Seconds the silent plays run: past the measured delay, with room to spare.
local PRIMING_SECONDS = 1

local SoundPrimer = {}

-- Loads and primes each recording in `ids` (rbxassetid strings). Yields; call it in its own thread.
function SoundPrimer.prime(ids: { string })
	local sounds: { Sound } = {}
	local list: { Instance } = {} -- the same sounds, as PreloadAsync takes them
	local seen: { [string]: true } = {}
	for _, id in ids do
		if not seen[id] then
			seen[id] = true
			local s = Instance.new("Sound")
			s.Name = "Priming"
			s.SoundId = id
			s.Volume = 0
			table.insert(sounds, s)
			table.insert(list, s)
		end
	end
	ContentProvider:PreloadAsync(list)
	for _, s in sounds do
		s.Parent = SoundService
		s:Play()
	end
	task.wait(PRIMING_SECONDS)
	for _, s in sounds do
		s:Destroy()
	end
end

return SoundPrimer
