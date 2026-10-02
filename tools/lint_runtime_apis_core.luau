--!strict

export type Hit = {
	line: number,
	api: string,
	message: string?,
}

local RuntimeApis = {}

local function hasWord(line: string, word: string): boolean
	local start = 1
	while true do
		local first, last = line:find(word, start, true)
		if not first then
			return false
		end
		local before = if first > 1 then line:sub(first - 1, first - 1) else ""
		local after = if last < #line then line:sub(last + 1, last + 1) else ""
		if not before:match("[%w_]") and not after:match("[%w_]") then
			return true
		end
		start = last + 1
	end
end

local function getsService(line: string, service: string): boolean
	local doubleQuoted = ':GetService%s*%(%s*"' .. service .. '"%s*%)'
	local singleQuoted = ":GetService%s*%(%s*'" .. service .. "'%s*%)"
	return line:find(doubleQuoted) ~= nil or line:find(singleQuoted) ~= nil
end

local function writesToCoreGui(line: string): boolean
	for _, quote in { '"', "'" } do
		local pattern = "game%s*:%s*GetService%s*%(%s*" .. quote .. "CoreGui" .. quote .. "%s*%)()"
		local afterCall = line:match(pattern)
		if afterCall then
			local tail = line:sub(afterCall)
			local _, equals = tail:find("^%s*[%.%[].-=")
			if equals and tail:sub(equals + 1, equals + 1) ~= "=" then
				return true
			end
		end
	end
	return false
end

local function isStarterPlayerScriptsPath(path: string): boolean
	local normalized = path:gsub("\\", "/")
	for _, prefix in
		{
			"game/src/StarterPlayer/StarterPlayerScripts/",
			"src/StarterPlayer/StarterPlayerScripts/",
		}
	do
		if normalized:sub(1, #prefix) == prefix or normalized:find("/" .. prefix, 1, true) then
			return true
		end
	end
	return false
end

local function directParentRequire(line: string): string?
	local child = line:match("require%s*%(%s*script%s*%.%s*Parent%s*%.%s*([%a_][%w_]*)%s*%)")
	if not child then
		child = line:match('require%s*%(%s*script%s*%.%s*Parent%s*%[%s*"([%a_][%w_]*)"%s*%]%s*%)')
	end
	if not child then
		child = line:match("require%s*%(%s*script%s*%.%s*Parent%s*%[%s*'([%a_][%w_]*)'%s*%]%s*%)")
	end
	if child then
		return "require(script.Parent." .. child .. ")"
	end
	return nil
end

function RuntimeApis.matchLine(line: string): { string }
	if line:match("^%s*%-%-") then
		return {}
	end

	local hits = {}
	if line:find("%f[%w_]settings%s*%(") then
		table.insert(hits, "settings()")
	end
	local _, technologyEquals = line:find("%.%s*Technology%s*=")
	if technologyEquals and line:sub(technologyEquals + 1, technologyEquals + 1) ~= "=" then
		table.insert(hits, "Lighting.Technology")
	end
	for _, service in { "StudioService", "PluginGuiService", "ChangeHistoryService" } do
		if hasWord(line, service) then
			table.insert(hits, service)
		end
	end
	if getsService(line, "Selection") then
		table.insert(hits, "Selection")
	end
	if line:find("%f[%w_]plugin%s*[%.:]") then
		table.insert(hits, "plugin")
	end
	if hasWord(line, "TakeScreenshot") then
		table.insert(hits, "TakeScreenshot")
	end
	if writesToCoreGui(line) then
		table.insert(hits, "CoreGui")
	end
	return hits
end

function RuntimeApis.scanSource(source: string, path: string?): { Hit }
	local hits = {}
	local lineNumber = 0
	local checkParentRequires = path ~= nil and isStarterPlayerScriptsPath(path)
	for line in (source .. "\n"):gmatch("(.-)\n") do
		lineNumber += 1
		line = line:gsub("\r$", "")
		for _, api in RuntimeApis.matchLine(line) do
			table.insert(hits, { line = lineNumber, api = api })
		end
		if checkParentRequires and not line:match("^%s*%-%-") then
			local parentRequire = directParentRequire(line)
			if parentRequire then
				table.insert(hits, {
					line = lineNumber,
					api = parentRequire,
					message = parentRequire .. " must use WaitForChild",
				})
			end
		end
	end
	return hits
end

return RuntimeApis
