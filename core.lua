ConstructionHorse = ConstructionHorse or {}
ConstructionHorse.obj = ConstructionHorse.obj or {}

ConstructionHorse.gobj = ConstructionHorse.gobj or {}
ConstructionHorse.npc = ConstructionHorse.npc or {}

ConstructionHorse.objects = {}
ConstructionHorse.nearby = {}
ConstructionHorse.other = {}

function ConstructionHorse.gobj.add(id)
   ConstructionHorse.command('.gobject add %d', id)
end

function ConstructionHorse.npc.add(id)
   ConstructionHorse.command('.npc add %d', id)
end

function ConstructionHorse.gobj.delete(guid)
   ConstructionHorse.command('.gobject delete %d', guid)
end

function ConstructionHorse.npc.delete(guid)
   ConstructionHorse.command('.npc delete %d', guid)
end

function ConstructionHorse.obj:new(id, name, guid, x, y, z, type)
   self.__index = self
   
   if type == nil then
      type = ConstructionHorse.gobj
   end
   
   return setmetatable({
         id=id,
         name=name,
         guid=guid,
         x=x,
         y=y,
         z=z,
         type=type
   }, self)
end

function ConstructionHorse.command(format, ...)
   msg = string.format(format, ...)
   if ConstructionHorse.debug then
      print(string.format('[ConstructionHorse.command] %s', msg))
      
   end
   SendChatMessage(msg, 'say', nil, nil) 
end

function ConstructionHorse.obj:delete()
   self.type.delete(self.guid)
end

function ConstructionHorse.obj:move(x, y, z)
   x = x or self.x
   y = y or self.y
   z = z or self.z
   
   ConstructionHorse.command('.gobject move %d %f %f %f', self.guid, x, y, z)
end

function ConstructionHorse.obj:activate(value)
   ConstructionHorse.command('.gobject activate %d %d', self.guid, value)
end

function ConstructionHorse.obj:move_right(amount)
   self.x = self.x + amount
   self:move(self.x, self.y, self.z)
end

function ConstructionHorse.obj:move_left(amount)
   return self:move_right(-amount)
end

function ConstructionHorse.obj:move_up(amount)
   self.y = self.y + amount
   self:move(self.x, self.y, self.z)
end

function ConstructionHorse.obj:move_down(amount)
   return self:move_up(-amount)
end

function ConstructionHorse.obj:turn(orientation)
   ConstructionHorse.command('.gobject turn %d %f', self.guid, orientation)
end

function ConstructionHorse.obj:flash()
   self:move_right(0)
end

local gobject_add_regex = 'Add Game Object \'([0-9]+)\' %(([a-zA-Z0-9, %(%)%!%-\'%[%]]+)%) %(GUID: ([0-9]+)%) added at \'(.+) (.+) (.+)\''

local gobject_removed_regex = 'Game Object %(GUID: ([0-9]+)%) removed'

local gobject_nearby_regex = '([0-9]+) %(Entry: ([0-9]+)%) .*%[([a-zA-Z0-9 _,%!%(%)%-\'%[%]]*) X:(.*) Y:(.*) Z:(.*) Map'

ConstructionHorse.frame = CreateFrame('frame')
ConstructionHorse.frame:RegisterEvent('CHAT_MSG_SYSTEM')

local on_nearby_end = nil

local last_nearby_lookup = time()
ConstructionHorse.last_added_id = nil

function ConstructionHorse.handle_event(self, event, msg)   
   if msg:find('Found near gameobjects %(distance ') and on_nearby_end then
      on_nearby_end()
      on_nearby_end = nil
   end
   
   local id, name, guid, x, y, z = string.match(msg, gobject_add_regex)
   if not (id == nil or name == nil or guid == nil) then
      table.insert(ConstructionHorse.objects, ConstructionHorse.obj:new(id, name, guid, tonumber(x), tonumber(y), tonumber(z)))
      ConstructionHorse.last_added_id = id
      return
   end
   
   local guid = string.match(msg, gobject_removed_regex)
   if guid ~= nil then
      for i, obj in ipairs(ConstructionHorse.objects) do
         if obj.guid == guid then
            table.remove(ConstructionHorse.objects, i)
            print('Removed object (' .. obj.guid .. '): ' .. obj.name)
         end
      end
   end
   
   local guid, id, name, x, y, z = msg:match(gobject_nearby_regex)
   if not (guid == nil or id == nil or name == nil or x == nil or y == nil or z == nil) then
      table.insert(ConstructionHorse.nearby, ConstructionHorse.obj:new(id, name, guid, tonumber(x), tonumber(y), tonumber(z)))
   end
end

ConstructionHorse.frame:SetScript('OnEvent', ConstructionHorse.handle_event)

function ConstructionHorse.add(obj)
   if type(obj) == 'table' then
      obj.type.add(obj.id)
   else
      ConstructionHorse.command('.gobject add %d', obj)
   end
end

function ConstructionHorse.delete_all()
   for _, v in ipairs(ConstructionHorse.objects) do
      v:delete()
   end
end

function ConstructionHorse.flash_all()
   for _, v in ipairs(ConstructionHorse.objects) do
      v:flash()
   end
end

ConstructionHorse.select = ConstructionHorse.select or {}
ConstructionHorse.select.i = nil

ConstructionHorse.selection = nil

local function readjust_selection()
   ConstructionHorse.select.i = ConstructionHorse.select.i or #ConstructionHorse.objects
   if ConstructionHorse.select.i > #ConstructionHorse.objects then
      ConstructionHorse.select.i = #ConstructionHorse.objects
   end
   
   if ConstructionHorse.select.i < 1 then
      ConstructionHorse.select.i = 1
   end
end

function ConstructionHorse.select.current()   
   readjust_selection()
   local obj = ConstructionHorse.objects[ConstructionHorse.select.i]
   if obj == nil then print('nil') return end
   
   ConstructionHorse.selection = obj
   obj:flash()
end

function ConstructionHorse.select.attach(radius)
	print('[ConstructionHorse.select.attach(radius)] Error, no nearby objects. Try running ConstructionHorse.select.nearby(10) first')
	if radius == nil or #ConstructionHorse.nearby == 0 then
		return
	end
	
	ConstructionHorse.objects = ConstructionHorse.nearby
	print('[ConstructionHorse] Attached to '.. #ConstructionHorse.objects ..' nearby objects')
end

function ConstructionHorse.select.prev()
   ConstructionHorse.select.i = ConstructionHorse.select.i or #ConstructionHorse.objects
   if ConstructionHorse.select.i > #ConstructionHorse.objects then return end
   ConstructionHorse.select.i = ConstructionHorse.select.i + 1
   
   ConstructionHorse.select.current()
end

function ConstructionHorse.select.next()
   ConstructionHorse.select.i = ConstructionHorse.select.i or #ConstructionHorse.objects
   if ConstructionHorse.select.i < 1 then return end
   ConstructionHorse.select.i = ConstructionHorse.select.i - 1
   
   ConstructionHorse.select.current()
end

function ConstructionHorse.select.nearby(radius)
   ConstructionHorse.nearby = {}
   
   if radius == nil then radius = 10 end
   now = time()
   
   if now - last_nearby_lookup > 0.1 then
      last_nearby_lookup = now
      ConstructionHorse.command('.gobject near %d', radius)
   end
   
   on_nearby_end = function()
      for _, obj in ipairs(ConstructionHorse.nearby) do
         obj:flash()
      end
   end
end

function ConstructionHorse.last()
   return ConstructionHorse.objects[#ConstructionHorse.objects]
end

function ConstructionHorse.again()
   ConstructionHorse.add(ConstructionHorse.last_added_id)
end

function ConstructionHorse.undo()
   local last_obj = ConstructionHorse.last()
   if last_obj then
      last_obj:delete()
   end
end
