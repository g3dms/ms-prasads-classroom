-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local tileQuestionGui = script.Parent
local questionFrame = tileQuestionGui:WaitForChild("QuestionFrame")
local questionImage = questionFrame:WaitForChild("QuestionImage")
local closeButton = questionFrame:WaitForChild("CloseButton")

local FRAME_BG_TRANSPARENCY = 1.0

local currentAnimationConnection = nil
local currentResizeConnection = nil
local currentFrame = 1
local totalFrames = 0
local columns = 1
local rows = 1
local frameWidth = 0
local frameHeight = 0
local framerate = 30
local lastTick = 0

local function stopAnimation()
	if currentAnimationConnection then
		currentAnimationConnection:Disconnect()
		currentAnimationConnection = nil
	end
	if currentResizeConnection then
		currentResizeConnection:Disconnect()
		currentResizeConnection = nil
	end
end

local function scaleImageToFit()
	if frameWidth == 0 or frameHeight == 0 then return end
	local containerSize = questionFrame.AbsoluteSize
	if containerSize.X <= 0 or containerSize.Y <= 0 then return end

	local frameAspect = frameWidth / frameHeight
	local containerAspect = containerSize.X / containerSize.Y

	local scale
	if frameAspect > containerAspect then
		scale = containerSize.X / frameWidth
	else
		scale = containerSize.Y / frameHeight
	end

	local newWidth = frameWidth * scale
	local newHeight = frameHeight * scale
	questionImage.Size = UDim2.new(0, newWidth, 0, newHeight)
	questionImage.AnchorPoint = Vector2.new(0.5, 0.5)
	questionImage.Position = UDim2.new(0.5, 0, 0.5, 0)

	print(string.format("Debug: Scaled image to %.0f x %.0f (scale=%.3f)", newWidth, newHeight, scale))
end

local function updateFrameOffset()
	local col = (currentFrame - 1) % columns + 1
	local row = math.floor((currentFrame - 1) / columns) + 1
	local x = (col - 1) * frameWidth
	local y = (row - 1) * frameHeight
	questionImage.ImageRectOffset = Vector2.new(x, y)

	print(string.format("Debug: Frame %d → col=%d, row=%d, offset=(%d, %d)", 
		currentFrame, col, row, x, y))
end

local function onPromptTriggered(prompt: ProximityPrompt)
	local tile = prompt.Parent
	if not tile then return end

	stopAnimation()

	questionImage.Image = ""
	questionImage.Visible = false
	questionImage.ScaleType = Enum.ScaleType.Fit
	questionImage.ImageRectOffset = Vector2.new(0, 0)
	questionImage.ImageRectSize = Vector2.new(0, 0)
	questionImage.Size = UDim2.new(1, 0, 1, 0)
	questionImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	questionImage.AnchorPoint = Vector2.new(0.5, 0.5)

	local topic = tile:GetAttribute("Topic") or ""
	local imageIdRaw = tile:GetAttribute("ImageId") or ""
	local spriteCols = tonumber(tile:GetAttribute("SpriteSheetColumns") or 0)
	local spriteRows = tonumber(tile:GetAttribute("SpriteSheetRows") or 0)
	local spriteFPS = tonumber(tile:GetAttribute("SpriteSheetFramerate") or 12)
	local sWidth = tonumber(tile:GetAttribute("SpriteSheetFrameWidth") or 0)
	local sHeight = tonumber(tile:GetAttribute("SpriteSheetFrameHeight") or 0)


	if imageIdRaw ~= "" then
		local imageId = imageIdRaw
		if not imageId:find("^rbxassetid://") then
			imageId = "rbxassetid://" .. imageId
		end

		ContentProvider:PreloadAsync({imageId})

		if spriteCols > 0 and spriteRows > 0 and sWidth > 0 and sHeight > 0 then
			columns = spriteCols
			rows = spriteRows
			frameWidth = sWidth
			frameHeight = sHeight
			totalFrames = columns * rows
			framerate = spriteFPS
			currentFrame = 1
			lastTick = tick()

			questionImage.ImageRectSize = Vector2.new(frameWidth, frameHeight)
			questionImage.ImageRectOffset = Vector2.new(0, 0) 
			print(string.format("Debug: ImageRectSize set to %d x %d", frameWidth, frameHeight))

			scaleImageToFit()

			currentResizeConnection = questionFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(scaleImageToFit)

			updateFrameOffset()  

			currentAnimationConnection = RunService.RenderStepped:Connect(function()
				local now = tick()
				local delta = now - lastTick
				if delta >= (1 / framerate) then
					lastTick = now
					currentFrame = currentFrame + 1
					if currentFrame > totalFrames then currentFrame = 1 end
					updateFrameOffset()
				end
			end)

			questionImage.Image = imageId
			questionImage.ImageTransparency = 0
			questionImage.Visible = true

			print("Debug: Sprite sheet animation started – total frames:", totalFrames, "fps:", framerate)

		else
			questionImage.ScaleType = Enum.ScaleType.Fit
			questionImage.Size = UDim2.new(1, 0, 1, 0)
			questionImage.Position = UDim2.new(0, 0, 0, 0)
			questionImage.AnchorPoint = Vector2.new(0, 0)
			questionImage.Image = imageId
			questionImage.ImageTransparency = 0
			questionImage.Visible = true
			print("Debug: Static image loaded →", imageId)
		end

	else
		questionImage.Visible = false
		print("Debug: No ImageId attribute found – showing text only")
	end

	questionFrame.Visible = true
	print("Debug: QuestionFrame visible")
end

closeButton.Activated:Connect(function()
	stopAnimation()
	questionFrame.Visible = false
	print("Debug: Frame closed, animation stopped")
end)

local connectedPrompts = {}
ProximityPromptService.PromptShown:Connect(function(prompt)
	if not connectedPrompts[prompt] then
		connectedPrompts[prompt] = true
		prompt.Triggered:Connect(function()
			onPromptTriggered(prompt)
		end)
	end
end)

tileQuestionGui.ResetOnSpawn = false
tileQuestionGui.IgnoreGuiInset = true

questionFrame.Size = UDim2.new(1, 0, 1, 0)
questionFrame.Position = UDim2.new(0, 0, 0, 0)
questionFrame.BackgroundTransparency = FRAME_BG_TRANSPARENCY
questionFrame.BackgroundColor3 = Color3.new(0, 0, 0)
questionFrame.ZIndex = 1

closeButton.ZIndex = 2

questionFrame.Visible = false
questionImage.Visible = false

print("Debug: Ready-- full‑screen frame with sprite sheet support")