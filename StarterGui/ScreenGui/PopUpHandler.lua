-- @ScriptType: LocalScript
local players = game:GetService("Players")
local player = players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")

local showResultRe = rs:WaitForChild("ShowRollResult")

local resultFrame = script.Parent:WaitForChild("ResultFrame")
local resultText = resultFrame:WaitForChild("ResultText")

print("Dice script loaded") 

resultFrame.Visible = false

local function showPopUp(rollNumber)
	print("Showing pop-up for roll: " .. rollNumber)

	resultText.Text = "🎲 You rolled a " .. rollNumber .. "! 🎲"

	resultFrame.Visible = true

	wait(2)

	resultFrame.Visible = false
end

showResultRe.OnClientEvent:Connect(showPopUp)
