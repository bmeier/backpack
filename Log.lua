LOG_PREFIXES = { "Trace", "Debug", "Info ", "Warn ", "Error", "Fatal" }
LOG_LEVEL = { FATAL=6, ERROR=5, WARN=4, INFO=3, DEBUG=2, TRACE=1, OFF=0 }

local LOG_LEVEL_COLORS= { "333333", "cccccc", "006400 ", "ffa500", "ff0000", "ff0000" }
local Log = ZO_Object:Subclass();
Log.Level = LOG_LEVEL.ERROR;
Log.name = "";

local function Log_GetColoredLogPrefix(level)
	return "|c"..LOG_LEVEL_COLORS[level]..LOG_PREFIXES[level].."|r"
end

function Log.LevelFromColoredPrefix(coloredPrefix) 
	local prefix = string.match(coloredPrefix, "\|c(.*){6}(\w+)\s*\|r")
	if prefix then
		return LOG_LEVEL[zo_strupper(prefix)]
	end
	return nil
end


function Log:New( name )
	local log = ZO_Object.New(self)
	log.name = name
	return log
end

function Log:L( level, ... )
	if(level >= self.Level) then
		local msg = "";
		if(self.name ~= nil) then
			msg = msg..self.name.." : ";
		end
		msg = msg..Log_GetColoredLogPrefix(level).." - ";
		if ...  then
			for i=1, select('#', ...) do
				msg = msg .. Log.SafeToString(select(i, ...))
			end
		end
		CHAT_SYSTEM:AddMessage(msg);
	end
end

function Log:T( ... )
	self:L(LOG_LEVEL.TRACE, ...);
end

function Log:D( ... )
	self:L(LOG_LEVEL.DEBUG, ...);
end

function Log:I( ... )
	self:L(LOG_LEVEL.INFO, ...);
end

function Log:W( ... )
	self:L(LOG_LEVEL.WARN, ...);
end

function Log:E( ... )
	self:L(LOG_LEVEL.ERROR, ...);
end

function Log:F( ... )
	self:L(LOG_LEVEL.FATAL, ...);
end

function Log.SafeToString( obj )
	if(obj == nil) then
		return "<nil>";
	elseif( type(obj) == "string" ) then
		return obj;
	elseif( type(obj) == "number" ) then
		return ""..obj;
	elseif(type(obj) == "function") then
		return "function";
	elseif(type(obj) == "table") then
		return "table"
	end
	return "<unkown>"

end


local Factory = ZO_Object:Subclass();
Factory.logs = {}

function Factory:New()
	local factory = ZO_Object.New(self);
	return factory;
end

function Factory:SetLevel( level )
	if level then
		if level < LOG_LEVEL.FATAL then
			for _, log in pairs(self.logs) do
				log.Level = level
			end
		end
	end
end

function Factory:SetStrLevel( val )
	if not val then
		return
	end

	local level = nil;
    for i, prefix in ipairs(LOG_PREFIXES) do
    	if prefix == val then
    		level = i
    		break
    	end
    end
    self:SetLevel(level)
 end

function Factory:GetLog( name )
	local log = self.logs[name]
	if not log then
		log = Log:New(name)
		self.logs[name] = log;
	end
	return log;
end
LOG_FACTORY = Factory:New();



