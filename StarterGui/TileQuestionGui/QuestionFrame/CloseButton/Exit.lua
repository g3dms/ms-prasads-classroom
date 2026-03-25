-- @ScriptType: LocalScript
local exit = script.Parent
local frame = exit.Parent

exit.MouseButton1Click:Connect(function()
	frame.Visible = false
end)