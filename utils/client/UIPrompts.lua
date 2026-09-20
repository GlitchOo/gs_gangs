U.Prompts = {}

---Creates a new prompt group.
---@return table
function U.Prompts:SetupPromptGroup()
	local UIPromptGroup = {}
	UIPromptGroup.PromptGroup = GetRandomIntInRange(0, 0xffffff)

	---Shows the prompt group this frame.
	---@param label string|nil
	function UIPromptGroup:ShowGroup(label)
		PromptSetActiveGroupThisFrame(self.PromptGroup, CreateVarString(10, 'LITERAL_STRING', label or 'Interact'), 1, 0, 0, 0)
	end

	---Registers a click prompt on this group.
	---@param title string
	---@param button number
	---@return table
	function UIPromptGroup:RegisterPrompt(title, button)
		local UIPrompt = {}
		UIPrompt.Prompt = PromptRegisterBegin()

		PromptSetControlAction(UIPrompt.Prompt, button)
		PromptSetText(UIPrompt.Prompt, CreateVarString(10, 'LITERAL_STRING', title or 'Option'))
		PromptSetEnabled(UIPrompt.Prompt, true)
		PromptSetVisible(UIPrompt.Prompt, true)
		PromptSetStandardMode(UIPrompt.Prompt, true)
		PromptSetGroup(UIPrompt.Prompt, self.PromptGroup, 0)
		PromptRegisterEnd(UIPrompt.Prompt)

		function UIPrompt:HasCompleted()
			return PromptHasStandardModeCompleted(self.Prompt)
		end

		function UIPrompt:DeletePrompt()
			PromptDelete(self.Prompt)
		end

		return UIPrompt
	end

	return UIPromptGroup
end
