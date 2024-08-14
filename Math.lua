local API = {}

local basic = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kiprov/Forbidden-API/main/stdfunctions.lua"))()

type RaycastSettings = {range: number, SeeThroughTransparentParts: boolean, filterTable: {}}
API.LineOfSight = function(Object1: Instance, Object2: Instance, raycastSettings: RaycastSettings, ERROROVERRIDE: boolean): any

	if Object1 == nil then warn("Object1 was nil!") return false end
	if Object2 == nil then warn("Object2 was nil!") return false end

	raycastSettings = raycastSettings or {}
	ERROROVERRIDE = ERROROVERRIDE or false

	local _LoS_Settings = {

		range = 50, -- length of raycast, DO NOT RAISE TO AN ABSURD VALUE
		SeeThroughTransparentParts = false,
		filterTable = "default" -- get descendants to ignore

	}


	for setting, v in pairs(raycastSettings) do
		_LoS_Settings[setting] = v
	end

	local i = 0
	local hitboxes = {}
	local targetModelMode = false
	local parentModel = nil

	local function findBasePart(obj: Instance, Type: string) -- verify the entered selection is supported

		i+=1
		if Type == "Player" then -- gets the character and allows for type == "Model" to run.
			obj = obj.Character
			if obj == nil then warn("character does not exist") return false end -- protection
			Type = "Model"
		end
		if Type == "Part" then hitboxes[i] = obj return end 
		if Type == "Model" then

			if i == 2 then targetModelMode = true parentModel = obj end

			if obj.PrimaryPart ~= nil then hitboxes[i] = obj.PrimaryPart return end

			if obj:FindFirstChild("Humanoid") then 
				local hitbox = obj:FindFirstChild("HumanoidRootPart")
				if hitbox then targetModelMode = false parentModel = nil end
				if hitbox ~= nil then hitboxes[i] = hitbox return end
			end

			hitboxes[i] = obj:GetChildren()[1]
		end
	end

	local type1 = basic.GetType(Object1) -- use the API to get type
	local type2 = basic.GetType(Object2)

	local temp1 = findBasePart(Object1,type1) -- call findBasePart, if there is a return there is an error
	local temp2 = findBasePart(Object2,type2)

	if not ERROROVERRIDE then -- error
		if temp1 ~= nil then warn(temp1) return temp1 end
		if temp2 ~= nil then warn(temp2) return temp2 end
	end

	-- Get Hitboxes
	local hitbox1 = hitboxes[1]
	local hitbox2 = hitboxes[2]
	local direction = (hitbox2.Position - hitbox1.Position).Unit

	-- Raycast Params
	local raycastParams = RaycastParams.new()
	local filtertable = {hitbox1}
	if type1 == "Model" then
		filtertable = {Object1}
	end
	if _LoS_Settings["filterTable"] ~= "default" then
		raycastParams.FilterDescendantsInstances = _LoS_Settings["filterTable"]
	else
		raycastParams.FilterDescendantsInstances = filtertable
	end

	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result: RaycastResult = nil

	local function raycast() -- cast ray

		result = nil
		result = workspace:Raycast(hitbox1.Position, direction*_LoS_Settings["range"], raycastParams)

		if result then
			--	print(hitbox1)
			--	print(hitbox2)
			if result.Instance == hitbox2 then -- checks to see if part is detected
				return true
			end

			if targetModelMode then -- test for descendants, useful if the part is in a character.

				for i, v in pairs(parentModel:GetDescendants()) do -- search given model for target name

					if v == result.Instance then
						return true
					end
				end
			end

			  --print(result.Instance)
			return false
		end

		if result == nil or not result then -- If out of range
			return false
		end
	end

	if not _LoS_Settings["SeeThroughTransparentParts"] or _LoS_Settings["SeeThroughTransparentParts"] == nil then
		local restest = raycast()
		--print(restest)
		return restest
	end

	if _LoS_Settings["SeeThroughTransparentParts"] then

		local foundEnd = false
		local maxIterations = 15  -- Limit the number of iterations to prevent infinite loop
		local iterationCount = 0

		while not foundEnd and iterationCount < maxIterations do
			iterationCount = iterationCount + 1

			local F_result = raycast()

			if not F_result then
				local transparency = 0

				if not result then return false end
				if result.Instance == nil then return false end

				local success, err = pcall(function() transparency = result.Instance.Transparency end)

				if transparency > 0 then
					table.insert(filtertable, result.Instance)
				end

				if not (transparency > 0) then
					foundEnd = true
					return F_result
				end
			end

			if F_result then
				foundEnd = true
				return true
			end
		end

		if iterationCount >= maxIterations then
			--print(Object1)
			--print(Object2)
			--print(parentModel)
			warn("Exceeded maximum iterations in LineOfSight function.") -- means no solid object was hit.
			return false
		end
	end
end

API.Round = function(Variable: any)

	local Type = basic.GetType(Variable)

	if Type == "Vector3" then

		local v3 = Vector3.new(math.round(Variable.X), 
			math.round(Variable.X), 
			math.round(Variable.Z))

		return v3
	end

	if Type == "Number" then

		return math.round(Variable)
	end

	if Type == "Integer" then

		return Variable
	end

	if Type == "CFrame" then

		Variable.X = math.round(Variable.X)
		Variable.Y = math.round(Variable.Y)
		Variable.Z = math.round(Variable.Z)

		return Variable
	end
end

-- For Players
API.IsOnScreen = function(PartToCheck: BasePart, doRaycast: boolean): boolean

	local losCamera = false
	local losCharacter = true

	local player = game.Players.LocalPlayer
	local camera = game.Workspace.CurrentCamera
	local final = PartToCheck

	if PartToCheck:IsA("Model") then
		if PartToCheck.PrimaryPart ~= nil then
			final = PartToCheck.PrimaryPart
		end
	end

	-- In viewport check
	local vector, inViewport = camera:WorldToViewportPoint(PartToCheck.Position)

	-- Check if the part is hidden
	local ray = camera:ViewportPointToRay(vector.X, vector.Y, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {player.Character}
	local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)

	if raycastResult == nil then return false end

	if raycastResult.Instance == PartToCheck then
		losCamera = true
	end

	if doRaycast then
		losCharacter = API.LineOfSight(player.Character, PartToCheck, {range = 100, SeeThroughTransparentParts = true, filterTable = {player.Character}})
	end

	-- Check if all values are correct
	local isVisible = inViewport and losCamera and losCharacter
	if isVisible then
		return true
	end

	return false
end

-- For Any Humanoid
API.IsInView = function(FromCharacter: Model, TargetOther: Instance, detectionFOV: number, doRaycast: boolean, raycastSets: RaycastSettings): boolean

	-- Defaults
	if detectionFOV == nil then detectionFOV = 70 end
	if doRaycast == nil then doRaycast = false end

	-- Error Protection
	if detectionFOV < 0 then detectionFOV = 0 end
	if detectionFOV > 180 then detectionFOV = 180 end

	-- Get HRT
	local hrt = FromCharacter:FindFirstChild("HumanoidRootPart")
	if hrt == nil then error("[Forbidden.Math.InPlayerView] The NPC provided does not contain a HumanoidRootPart!") end

	-- Make sure these components are not nil.
	if raycastSets == nil then raycastSets = {} end
	if raycastSets.filterTable == nil then
		raycastSets.filterTable = {FromCharacter}
	end

	local actualOther = nil

	-- Decides the best part to act as the IsInSight part.
	local function getBase()
		if TargetOther:IsA("Model") then

			local hrt_target = TargetOther:FindFirstChild("HumanoidRootPart")
			if hrt_target then
				actualOther = hrt_target
				return
			end


			if TargetOther.PrimaryPart then
				actualOther = TargetOther.PrimaryPart
				return
			else
				local children = TargetOther:GetChildren()
				if #children > 0 then
					actualOther = children[1]
					return
				else
					error("[Forbidden.Math.IsInView] No objects in the model!")
				end
			end
		end

		if TargetOther:IsA("BasePart") then
			actualOther = TargetOther
		end
	end

	-- Get the target part, filter extraneous parts in the model or character. 
	getBase()
	if actualOther == nil then error("[Forbidden.Math.IsInView] Could not decide best base part for the IsInView check") end
	if TargetOther:IsA("Model") then
		for i, v in TargetOther:GetChildren() do
			if not v:IsA("BasePart") and not v:IsA("Accessory") then continue end
			if v ~= actualOther then -- Imagine this was a character, this would filter everything except the HumanoidRootPart
				table.insert(raycastSets.filterTable, v)
			end
		end
	end

	-- Raycast
	local losResult = true
	if doRaycast then
		losResult = API.LineOfSight(hrt, actualOther, raycastSets)
	end

	-- Viewport
	if losResult then
		local isInfront = false
		local isNextTo = false
		local angle = math.acos(hrt.CFrame.LookVector:Dot((actualOther.Position-hrt.Position).Unit))
		local isInFOVAngle = angle < detectionFOV * (math.pi / 180) -- 0: Ahead  PI: Behind 	(symmetrical on left and right sides of AI)
		if isInFOVAngle then
			return true
		end
	end

	return false
end

return API
