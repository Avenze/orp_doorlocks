-----------------------------------------------------
-- /*/ Variables
-----------------------------------------------------

local DoorStates = {}
local Permissions = {}

-----------------------------------------------------
-- /*/ Function Definitions
-----------------------------------------------------

-- Checks the player permissions for the provided AuthorizedRoles
-- @param Player (int): The player to check the permissions for.
-- @param AuthorizedRoles (table/string): A table or string containing the role/roles that are authorized to access the door.
-- @return boolean: State determining the permission.
local CheckPermissionsFromDoor = function(Player, AuthorizedRoles)
	local PermissionState = false
	local PlayerPermissions = Permissions[Player]
	if type(AuthorizedRoles) == "table" then
		for Index, Role in pairs(AuthorizedRoles) do
			if PlayerPermissions[Role] == true then
				PermissionState = true
				break;
			end
		end
	else
		if PlayerPermissions[AuthorizedRoles] == true then
			PermissionState = true
		end
	end

	return PermissionState
end

-----------------------------------------------------
-- /*/ Networking Definitions
-----------------------------------------------------

RegisterNetEvent("orp_doorlocks:Server:GetPermissions")
AddEventHandler("orp_doorlocks:Server:GetPermissions", function() 
	local Player = source
	local ReturnedPermissions = {}

	for RoleName, Permission in pairs(Config.Roles) do
		if IsPlayerAceAllowed(Player, Permission) then
			ReturnedPermissions[RoleName] = true
		end
	end

	Permissions[Player] = ReturnedPermissions
	TriggerClientEvent("orp_doorlocks:Client:ReturnPermissions", Player, ReturnedPermissions)
end)

RegisterNetEvent("orp_doorlocks:Server:GetDoorStates")
AddEventHandler("orp_doorlocks:Server:GetDoorStates", function() 
	TriggerClientEvent("orp_doorlocks:Client:GetDoorStates", DoorStates)
end)

RegisterNetEvent("orp_doorlocks:Server:AttemptStateChange")
AddEventHandler("orp_doorlocks:Server:AttemptStateChange", function(Index, State) 
	local Player = source

	if not type(Index) == "number" then return end 
	if not type(State) == "boolean" then return end
	if not Config.DoorList[doorIndex] then return end
	if not CheckPermissionsFromDoor(Player, Config.DoorList[Index].authorizedRoles) then return end

	DoorStates[Index] = State
	TriggerClientEvent("orp_doorlocks:Client:SetDoorState", -1, Index, State)
end)

AddEventHandler('playerDropped', function() 
	Permissions[source] = nil
end)
