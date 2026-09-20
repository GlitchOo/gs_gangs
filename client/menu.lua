local ExternalMenus = {}
local InviteToken = 0

---Add Item To Menu (legacy API for other resources).
---@param resource string
---@param item table
function AddItemToMenu(resource, item)
	ExternalMenus[resource] = ExternalMenus[resource] or {}
	table.insert(ExternalMenus[resource], item)
end

---Clear active invite prompts.
---@param acceptPrompt table|nil
---@param declinePrompt table|nil
local function ClearInvitePrompts(acceptPrompt, declinePrompt)
	if acceptPrompt then acceptPrompt:DeletePrompt() end
	if declinePrompt then declinePrompt:DeletePrompt() end
end

---Event triggered when the player receives an invitation to join a gang.
---@param gangName string
---@param player number
RegisterNetEvent('gs_gangs:client:recruit', function(gangName, player)
	DevPrint('gs_gangs:client:recruit', gangName, player)

	local gang = Config.Gangs[gangName]
	if not gang then return end

	InviteToken = InviteToken + 1
	local token = InviteToken
	local label = _('invite_subtext', gang.label)
	local timeoutMs = (Config.InvitePromptTimeout or 30) * 1000

	local group = U.Prompts:SetupPromptGroup()
	-- E accept, Backspace / cancel decline
	local acceptPrompt = group:RegisterPrompt(_('accept'), 0xCEFD9220)
	local declinePrompt = group:RegisterPrompt(_('decline'), 0x156F7119)

	CreateThread(function()
		local endsAt = GetGameTimer() + timeoutMs

		while token == InviteToken do
			if GetGameTimer() >= endsAt then
				TriggerServerEvent('gs_gangs:server:recruitResponse', false, player)
				break
			end

			group:ShowGroup(label)

			if acceptPrompt:HasCompleted() then
				TriggerServerEvent('gs_gangs:server:recruitResponse', true, player)
				break
			end

			if declinePrompt:HasCompleted() then
				TriggerServerEvent('gs_gangs:server:recruitResponse', false, player)
				break
			end

			Wait(0)
		end

		ClearInvitePrompts(acceptPrompt, declinePrompt)
	end)
end)

---Members refresh while the book is open.
---@param members table
RegisterNetEvent('gs_gangs:client:members', function(members)
	for i = 1, #members do
		if type(members[i].gang) == 'string' then
			members[i].gang = json.decode(members[i].gang)
		end
	end

	TriggerServerEvent('gs_gangs:server:refreshBook')
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		InviteToken = InviteToken + 1
	end
	ExternalMenus[resource] = nil
end)
