local Log = LOG_FACTORY:GetLog("BP_Handler");
local BP_Handler = {};


function BP_Handler.OnSlashCommand( ... )
	if( ... == nil or #... == 0) then
		SCENE_MANAGER:Toggle("backpack");
		return;
	end 

	-- local args = ...;
	-- if(args and #args > 0) then
	-- 	local cmd = args[1];
	-- 	if(cmd == group) then
	-- 		if(#args > 1) then
	-- 			if(args[2] == "list") then
	-- 				for i, group in Backpack.groups do
	-- 					Log:I(i..": "..group.Name);
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- 	if(cmd) then
	-- 		cmd.handler(args);
	-- 	end
	-- end
end

function BP_Handler.OnAddonLoaded(eventCode, addOnName)
	if(addOnName == BACKPACK.ADDON_NAME) then
		SLASH_COMMANDS["/bp"] = function( ... ) BP_Handler.OnSlashCommand( ... ); end
		SLASH_COMMANDS["/backpack"] = function( ... ) BP_Handler.OnSlashCommand( ... ); end
		SLASH_COMMANDS["/rl"] = function( ... ) ReloadUI(); end
		SLASH_COMMANDS["/reload"] = function( ... ) ReloadUI(); end


		BACKPACK:OnLoad();
	end
end


EVENT_MANAGER:RegisterForEvent(BACKPACK.ADDON_NAME, EVENT_ADD_ON_LOADED, function(...) BP_Handler.OnAddonLoaded(...) end);
