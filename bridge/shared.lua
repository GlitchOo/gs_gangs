-- Framework resolve (VORP | RSG)

local configured = Config.Framework or 'auto'
local resolved

local function resourcePresent(name)
	local state = GetResourceState(name)
	return state == 'started' or state == 'starting'
end

if configured ~= 'auto' then
	resolved = configured
elseif resourcePresent('rsg-core') then
	resolved = 'rsg'
elseif resourcePresent('vorp_core') then
	resolved = 'vorp'
end

if not resolved then
	error('[gs_gangs] No supported framework found. Set Config.Framework to vorp or rsg, or ensure vorp_core / rsg-core is started.')
end

---Resolved framework name after auto-detect (`vorp` or `rsg`)
---@type 'vorp'|'rsg'
Config.Framework = resolved

print(('[gs_gangs] Framework: %s'):format(Config.Framework))

---Default blip color when none is configured.
---@return string
function DefaultColor()
	return 'BLIP_MODIFIER_MP_COLOR_1'
end

---Resolve gang blip color from Config.GangColors or fallback.
---@param name string
---@param fallback? string
---@return string
function ResolveColor(name, fallback)
	if Config.GangColors?[name] then return Config.GangColors[name] end
	return fallback or DefaultColor()
end
