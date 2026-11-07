--!strict
-- Open Cloud asset uploads shared by the art uploaders (see scripts/upload_art.luau): the key from the git-ignored
-- .config/.env, the creator's user ID, and one file sent and polled until its import is done.
-- Never prints the key.

local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")
local task = require("@lune/task")

local API = "https://apis.roblox.com/assets/v1/"
-- Open Cloud imports take a few seconds for an image and up to a minute for a skinned FBX.
local POLL_SECONDS = 2
local POLL_TRIES = 90

export type Kind = { assetType: string, contentType: string }
export type Session = { key: string, creator: number }

local OpenCloud = {}

local function fail(message: string): never
	print("opencloud: " .. message)
	return process.exit(1)
end

local function readEnv(): { [string]: string }
	local path = ".config/.env"
	if not fs.isFile(path) then
		fail(path .. " is missing (see scripts/upload_art.luau)")
	end
	local env = {}
	for line in string.gmatch(fs.readFile(path), "[^\r\n]+") do
		local key, value = string.match(line, "^%s*([%w_]+)%s*=%s*(.-)%s*$")
		if key and value then
			env[key] = string.gsub(value, "^[\"'](.*)[\"']$", "%1")
		end
	end
	return env
end

local function creatorId(creatorValue: string): number
	local numeric = tonumber(creatorValue)
	if numeric then
		return numeric
	end
	local params: net.FetchParams = {
		url = "https://users.roblox.com/v1/usernames/users",
		method = "POST",
		headers = { ["content-type"] = "application/json" } :: net.HttpHeaderMap,
		body = serde.encode("json", { usernames = { creatorValue }, excludeBannedUsers = true }),
	}
	local response = net.request(params)
	local data = if response.ok then serde.decode("json", response.body).data else nil
	return if data and data[1] then data[1].id else fail("ROBLOX_CREATOR_ID matches no Roblox user")
end

-- Reads ROBLOX_API_KEY (Assets read and write) and ROBLOX_CREATOR_ID (the key owner's user ID or
-- username) from .config/.env. Called only when something goes up, so dry runs need neither.
function OpenCloud.session(): Session
	local env = readEnv()
	local key = env.ROBLOX_API_KEY or fail("ROBLOX_API_KEY is not set in .config/.env")
	local creator = env.ROBLOX_CREATOR_ID or fail("ROBLOX_CREATOR_ID is not set in .config/.env")
	return { key = key, creator = creatorId(creator) }
end

local function multipart(
	request: { [string]: any },
	path: string,
	contentType: string
): (string, string)
	local file = string.match(path, "[^/]+$") or path
	local boundary = "----StorageHorror" .. serde.hash("md5", file .. os.clock())
	local body = table.concat({
		"--" .. boundary,
		'Content-Disposition: form-data; name="request"',
		"Content-Type: application/json",
		"",
		serde.encode("json", request),
		"--" .. boundary,
		`Content-Disposition: form-data; name="fileContent"; filename="{file}"`,
		"Content-Type: " .. contentType,
		"",
		fs.readFile(path),
		"--" .. boundary .. "--",
		"",
	}, "\r\n")
	return body, "multipart/form-data; boundary=" .. boundary
end

-- Sends the file at path and waits for its import; returns the asset ID. With existing, a model
-- updates in place (PATCH keeps the ID); nothing else can be updated.
function OpenCloud.upload(
	session: Session,
	path: string,
	kind: Kind,
	existing: number?,
	description: string
): number
	local file = string.match(path, "[^/]+$") or path
	local request: { [string]: any } = {
		assetType = kind.assetType,
		displayName = string.gsub(string.gsub(file, "%.%w+$", ""), "_", " "),
		description = description,
		creationContext = { creator = { userId = tostring(session.creator) } },
	}
	local url = API .. "assets"
	local method: net.HttpMethod = "POST"
	if existing then
		request.assetId = tostring(existing)
		request.creationContext.expectedPrice = 0
		url ..= "/" .. tostring(existing)
		method = "PATCH"
	end
	local body, contentType = multipart(request, path, kind.contentType)
	local params: net.FetchParams = {
		url = url,
		method = method,
		headers = { ["x-api-key"] = session.key, ["content-type"] = contentType } :: net.HttpHeaderMap,
		body = body,
	}
	local response = net.request(params)
	if not response.ok then
		fail(`{file}: {response.statusCode} {response.body}`)
	end
	local operation = serde.decode("json", response.body).path
	for _ = 1, POLL_TRIES do
		task.wait(POLL_SECONDS)
		local pollParams: net.FetchParams = {
			url = API .. operation,
			headers = { ["x-api-key"] = session.key } :: net.HttpHeaderMap,
		}
		local poll = net.request(pollParams)
		local state = if poll.ok then serde.decode("json", poll.body) else nil
		if state and state.done then
			if state.error or not (state.response and state.response.assetId) then
				fail(`{file}: import failed: {poll.body}`)
			end
			local moderation = state.response.moderationResult
			if moderation and moderation.moderationState == "Rejected" then
				print(`  {file}: rejected by moderation`)
			end
			return tonumber(state.response.assetId) :: number
		end
	end
	return fail(`{file}: import still running after {POLL_SECONDS * POLL_TRIES} s`)
end

return OpenCloud
