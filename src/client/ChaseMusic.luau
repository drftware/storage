--!strict
--[[
	ChaseMusic: the sting and the chase bed on the hunted player's own screen (L-06b4b1). The
	server tells only them how many keepers hunt them, once each time that changes
	(Remotes.Hunted, from Keepers); `Chase` decides whether a rise is a fresh sighting (the sting)
	and how loud the bed is. Both play from SoundService, the same wherever you stand: it's your
	music, not a sound in the hall, and friends never hear it. A catch (Remotes.Caught) cuts both
	at once: the black is silent.

	It steps only while the bed is playing or about to.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Brix = require(ReplicatedStorage.Brix)
local Caught = require(ReplicatedStorage.Shared.Caught)
local Chase = require(ReplicatedStorage.Shared.Chase)
local SoundPrimer = require(script.Parent.SoundPrimer)

local function makeSound(name: string, clip: Chase.Clip, looped: boolean): Sound
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = clip.id
	s.Volume = clip.volume
	s.Looped = looped
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(clip.from, clip.to)
	if looped then
		s.LoopRegion = NumberRange.new(clip.from, clip.to)
	end
	s.Parent = SoundService -- no place in the world: your own music
	return s
end

local ChaseMusic = {}

function ChaseMusic.new(): Brix.System
	local music = Chase.new()
	local sting: Sound? = nil
	local bed: Sound? = nil
	local running = false
	local stepping = false
	local connections: { RBXScriptConnection } = {}

	-- Brings the bed to where `Chase` says at `now`: started from the top of its loop as it rises
	-- out of silence, stopped once it's faded out.
	local function sync(now: number)
		local s = bed
		if not s then
			return
		end
		local loud = Chase.bed(music, now)
		if loud > 0 then
			if not s.IsPlaying then
				s.TimePosition = Chase.Bed.from
				s:Play()
			end
			s.Volume = Chase.Bed.volume * loud
		elseif s.IsPlaying then
			s:Stop()
		end
		stepping = not Chase.quiet(music) or s.IsPlaying
	end

	-- unknown: a remote's argument; the server sends one whole number
	local function onHunted(count: unknown)
		if
			typeof(count) ~= "number"
			or count ~= math.floor(count)
			or count < 0
			or count > Chase.MostHunters
		then
			return
		end
		local now = os.clock()
		if Chase.hunted(music, count, now) and sting then
			sting.TimePosition = Chase.Sting.from
			sting:Play()
		end
		sync(now)
	end

	local function onCaught()
		Chase.caught(music, os.clock())
		if sting then
			sting:Stop()
		end
		if bed then
			bed:Stop()
		end
		stepping = not Chase.quiet(music)
	end

	local function listen(name: string, handler: (...unknown) -> ())
		task.spawn(function()
			local folder = ReplicatedStorage:WaitForChild(Chase.RemoteFolder, 30)
			local remote = folder and folder:WaitForChild(name, 30)
			if running and remote and remote:IsA("RemoteEvent") then
				table.insert(connections, remote.OnClientEvent:Connect(handler))
			end
		end)
	end

	return {
		name = "ChaseMusic",
		start = function(_: any, _context: Brix.Context)
			running = true
			sting = makeSound("ChaseSting", Chase.Sting, false)
			bed = makeSound("ChaseBed", Chase.Bed, true)
			task.spawn(SoundPrimer.prime, { Chase.Sting.id, Chase.Bed.id })
			listen(Chase.Remote, onHunted)
			listen(Caught.Remote, onCaught)
		end,
		step = function(_: any, _dt: number)
			if stepping then
				sync(os.clock())
			end
		end,
		stop = function(_: any)
			running = false
			stepping = false
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			if sting then
				sting:Destroy()
				sting = nil
			end
			if bed then
				bed:Destroy()
				bed = nil
			end
		end,
	}
end

return ChaseMusic
