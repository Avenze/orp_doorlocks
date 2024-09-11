-----------------------------------------------------
-- /*/ Variables
-----------------------------------------------------

local PermissionList = {}
local CachedDoorList = Config.DoorList

-----------------------------------------------------
-- /*/ Function Definitions
-----------------------------------------------------

-- Rounds the provided number to the nearest whole number
-- @param Number (float): The number to round
-- @return float: The rounded number
local RoundNumber = function(Number)
	return Number % 1 >= 0.5 and math.ceil(Number) or math.floor(Number)
end

-- Checks the player permissions for the provided AuthorizedRoles
-- @param AuthorizedRoles (table/string): A table or string containing the role/roles that are authorized to access the door.
-- @return boolean: State determining the permission.
local CheckPermissionsFromDoor = function(AuthorizedRoles)
	local PermissionState = false
	if type(AuthorizedRoles) == "table" then
		for Index, Role in pairs(AuthorizedRoles) do
			if PermissionList[Role] == true then
				PermissionState = true
				break;
			end
		end
	else
		if PermissionList[AuthorizedRoles] == true then
			PermissionState = true
		end
	end

	return PermissionState
end

-- Returns the distance between the player and the provided entity
-- @param OPTIONAL: Entity (int): The entity to calculate the distance to.
-- @param OPTIONAL: Coordinates (vector3): The coordinates to calculate the distance to.
-- @return float: The distance between the player and the entity.
local GetDistanceToPoint = function(Entity, Coordinates)
	local PlayerCoords = GetEntityCoords(PlayerPedId())
	local SpecifiedCoordinates = GetEntityCoords(Entity)
	if Entity and type(Entity) == "number" then
		SpecifiedCoordinates = GetEntityCoords(Entity)
	elseif Coordinates and type(Coordinates) == "vector3" then
		SpecifiedCoordinates = Coordinates
	end
	return #(PlayerCoords - SpecifiedCoordinates)
end

-- Updates all of the door entities in the provided DoorList
-- @param DoorList (table): A table containing all of the doordata structs
local RefreshAllDoorEntities = function(DoorList)
	for Index, DoorData in pairs(DoorList) do 
		local Distance = GetDistanceToPoint(DoorData.textCoords)
		if Distance < 50 then
			if DoorData.doors and type(DoorData.doors) == "table" then
				for Index, Door in pairs(DoorData.doors) do
					Door.object = GetClosestObjectOfType(Door.objCoords, 1.0, Door.objHash, false, false, false)
					if Door.object and DoesEntityExist(Door.object) then
						FreezeEntityPosition(Door.object, DoorData.locked)
					end
					if DoorData.locked and Door.objHeading and RoundNumber(GetEntityHeading(Door.object)) ~= Door.objHeading then
						SetEntityHeading(Door.object, Door.objHeading)
					end
				end
			else
				warn("Invalid structure in Config.DoorList, expected 'doors' to be a table, got: " .. type(DoorData.doors))
			end
		end
	end
end

-----------------------------------------------------
-- /*/ Networking Definitions
-----------------------------------------------------

RegisterNetEvent("orp_doorlocks:Client:ReturnPermissions")
AddEventHandler("orp_doorlocks:Client:ReturnPermissions", function(Permissions)
	PermissionList = Permissions
end)

RegisterNetEvent("orp_doorlocks:Client:GetDoorStates")
AddEventHandler("orp_doorlocks:Client:GetDoorStates", function(DoorStates)
	for Index, State in pairs(DoorStates) do
		CachedDoorList[Index].locked = State
	end
end)

RegisterNetEvent("orp_doorlocks:Client:SetDoorState")
AddEventHandler("orp_doorlocks:Client:SetDoorState", function(Index, State) 
	CachedDoorList[Index].locked = State
end)

-----------------------------------------------------
-- /*/ Thread
-----------------------------------------------------

Citizen.CreateThread(function()

	-- /*/ Trigger a serversided sync
	TriggerServerEvent("orp_doorlocks:Server:GetPermissions")
	TriggerServerEvent("orp_doorlocks:Server:GetDoorStates")

	-- /*/ Register all ox_target boxzones for interaction
	for Index, DoorData in pairs(CachedDoorList) do

		if not CheckPermissionsFromDoor(DoorData.authorizedRoles) then return end

		exports.ox_target:addBoxZone({
			coords = DoorData.textCoords,
			size = vector3(3.0, 3.0, 3.0),
			options = {
				label = "Lock/Unlock This Door"
				icon = "fa-solid fa-lock",
				onSelect = function()
					TriggerServerEvent('orp_doorlocks:Server:AttemptStateChange', Index, not DoorData.locked);
				end
			}
		})

	end
end)