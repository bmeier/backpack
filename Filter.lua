local Log = LOG_FACTORY:GetLog("Filter");

FILTER_TYPES = {
	Or = 0,
	And = 1,
	ItemType = 2,
	EmptySlot = 3,
	FilterType = 4,
};

Filter = ZO_Object:Subclass();
Filter.Type = nil;
Filter.Name = "Default";

function Filter:New( type )
	local r = ZO_Object.New(self);
	r.Type = type;
	return r;
end 

function Filter:Matches( item )
	--Log:T("Filter:Matches(item)")
	return true;
end

local EmptyFilter = Filter:Subclass();
function EmptyFilter:New( )
	local r = ZO_Object.New(self);
	r.Type = FILTER_TYPES.EmptySlot;
	return r;
end 

function EmptyFilter:Matches( slot )
	--Log:T("EmptyFilter:Matches(item)")
	return slot.itemInfo == nil;
end

local OrFilter = Filter:Subclass();
function OrFilter:New()
	local r = ZO_Object:New(self);
	self.Filter = {};
	self.Type = FILTER_TYPES.Or;
	return r;
end

function OrFilter:Add(filter)
	table.insert(self.Filter, filter);
end

function OrFilter:Matches(item)
	for _, f in ipairs(self.Filter) do
		if(f:Matches(item)) then
			return true;
		end
	end
	return false;
end

AndFilter = ZO_Object:Subclass();
function AndFilter:New()
	local r = ZO_Object:New(self);
	self.Filter = {};
	self.Type = FILTER_TYPES.And;
	return r;
end

function AndFilter:Add(filter)
	table.insert(self.Filter, filter);
end

function AndFilter:Matches(item)
	for _, f in pairs(self.Filter) do
		if(not f:Matches(item)) then
			return false;
		end
	end
	return true;
end

GenericFilter = ZO_Object:Subclass();
function GenericFilter:New( filter ) 
	local r = ZO_Object:New(self);
	r.func = filter;
	return r;
end

function GenericFilter:Matches(item)
	return self.func(item);
end

ItemNameFilter = ZO_Object:Subclass();
function ItemNameFilter:New( name )
	local r = ZO_Object.New(self);
	self.ItemName = name;
		return r;
end

function ItemNameFilter:Matches(item)
	--TRACE("In ItemTypeFilter:Pass(item)");

	--TRACE("bagId:"..bagId..", slotIdx: "..slotIdx);
	return string.gfind(item.Name, self.ItemName)() ~= nil;
end

ItemTypeFilter = Filter:Subclass();
function ItemTypeFilter:New( item_type )
	local r = ZO_Object.New(self);
	r.itemType = item_type;
	r.Type = FILTER_TYPES.ItemType;
	return r;
end

function ItemTypeFilter:Matches(slot)
	if(not slot) then return false; end
	if(not slot.itemInfo) then return false; end
	return (slot.itemInfo.type == self.itemType);
end



FilterTypeFilter = Filter:Subclass();
FilterTypeFilter.filter = -1;
function FilterTypeFilter:New( filter )
	local r = ZO_Object.New(self);
	r.filter = filter;
	r.Type = FILTER_TYPES.FilterType;
	return r;
end

function FilterTypeFilter:Matches(slot)
	if(not slot) then return false; end
	if(not slot.itemInfo) then return false; end
	return (slot.itemInfo.filter == self.filter);
end


function filter(items, n, f)
	DEBUG("Filtering items...");

	local itemCount = 0;
	local r = {};
	for i=1,n do
		if(f:Matches(items[i])) then
			TRACE("Item '"..items[i].Name.."' passed filter.");
			itemCount = itemCount + 1;
			r[itemCount] = items[i];
		end
	end 
	DEBUG(itemCount.." items passed the filter.");
	return itemCount, r;
end 

local FILTER = {};
FILTER[FILTER_TYPES.ItemType] = function( ... ) return ItemTypeFilter:New( ... ) end;

function CreateFilter(filterType, ...) 
	local filter = nil;
	if(filterType == FILTER_TYPES.And) then
		filter = AndFilter:New( ... );
	elseif(filterType == FILTER_TYPES.ItemType) then
		filter = ItemTypeFilter:New( ... );
	elseif(filterType == FILTER_TYPES.EmptySlot) then
		filter = EmptyFilter:New(...);
	elseif(filterType == FILTER_TYPES.FilterType) then
		filter = FilterTypeFilter:New(...)
	end

	return filter;
end