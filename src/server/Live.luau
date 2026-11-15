--!strict
--[[
	The live config (S3-02b): values the owner changes on every running server without an update,
	a system. Nothing on screen. What it buys is a switch per product: an offer that misbehaves is
	off everywhere within a minute, with no new version of the game.

	Built on Brix's LiveConfig: the defaults are every product's switch, on (`Products.switches`), and
	each must be true or false, so a mistyped value is refused and the last good values stay. The
	values come from Roblox's experience configs (Creator Hub > the experience > Configs, or Studio's
	File > Open Configs), read through `Brix.Roblox.ConfigSource.configService` and kept current by
	`Brix.Roblox.ConfigRefresher`: once at start, at once when Roblox says a newer version was
	published (15 seconds to a minute), and every minute in case that notice never came. Until the
	first read lands, and whenever configs can't be read, every switch keeps its default (on), with
	one warning while the problem lasts.

	To try a value on one running server without publishing, a server command line runs
	`game:GetService("ConfigService"):SetTestingValue("sellTestPurchase", false)` (and
	`ClearTestingValue` to take it back).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local Products = require(ReplicatedStorage.Shared.Products)

-- The config's values: each product's switch by its key.
export type Values = { [string]: boolean }

export type LiveSystem = Brix.System & {
	-- The live values now: the last good ones read, or the defaults before any read. Never yields.
	current: (self: any) -> Values,
}

local Live = {}

function Live.new(): LiveSystem
	local defaults = Products.switches()
	local fields: { [string]: Brix.Schema } = {}
	for key in defaults do
		fields[key] = Brix.Schema.boolean()
	end
	local config: Brix.LiveConfig<Values>? = nil
	local source: Brix.ConfigServiceSource? = nil
	local refresher: Brix.ConfigRefresher? = nil

	local system = { name = "Live" }

	function system.start(_: any, _context: Brix.Context)
		local from = Brix.Roblox.ConfigSource.configService()
		local made = Brix.LiveConfig.new({
			schema = Brix.Schema.shape(fields),
			defaults = defaults,
			source = from,
		})
		local keeper = Brix.Roblox.ConfigRefresher.new({
			config = made,
			source = from,
			onProblem = function(problem: string)
				warn(`[Live] {problem}; every switch keeps its last good value`)
			end,
		})
		source, config, refresher = from, made, keeper
		keeper:start()
	end

	function system.stop(_: any)
		if refresher then
			refresher:stop()
			refresher = nil
		end
		if source then
			source:destroy()
			source = nil
		end
	end

	function system.current(_: any): Values
		return if config then config:current() else defaults
	end

	return system
end

return Live
