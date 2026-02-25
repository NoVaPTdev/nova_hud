local interface = {}
local debug = require("modules.utils.shared").debug

local isVisible = false

---@param msgType string The NUI message type
---@param data any The data to send (will be merged with type)
interface.message = function(msgType, data)
	local msg = {}
	if type(data) == "table" then
		for k, v in pairs(data) do
			msg[k] = v
		end
	end
	msg.type = msgType
	SendNUIMessage(msg)
end

---@param shouldShow boolean|nil Whether to show the frame (nil = toggle)
interface.toggle = function(shouldShow)
	if shouldShow == nil then
		-- Toggle
		isVisible = not isVisible
	else
		isVisible = shouldShow and true or false
	end

	if isVisible then
		SendNUIMessage({ type = "showHUD" })
	else
		SendNUIMessage({ type = "hideHUD" })
	end

	debug("(interface:toggle) HUD visibility: ", isVisible)
end

---@return boolean
interface.isVisible = function()
	return isVisible
end

return interface
