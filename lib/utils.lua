local utils = {}

local NOTE_NAMES = {"C", "c", "D", "d", "E", "F", "f", "G", "g", "A", "a", "B"}
local NOTE_VALS = {C = 0, c = 1, D = 2, d = 3, E = 4, F = 5, f = 6, G = 7, g = 8, A = 9, a = 10, B = 11}

utils.note_num_to_name = function(note_num, include_octave)
  local name = NOTE_NAMES[note_num % 12 + 1]
  if include_octave then name =  name .. math.floor(note_num / 12 - 2) end
  return name
end

utils.note_name_to_num = function(note_str)
  local data = {}
  for i in string.gmatch(note_str, "(.)") do data[#data + 1 ] = i end
  local note = NOTE_VALS[data[1]] or 0
  local oct = tonumber(data[2]) or 3
  return note + ( oct * 12 ) + 24
end

utils.join = function(a, b)
  for i=2,#b do
    table.insert(a, b[i])
  end
end

utils.startswith(text, prefix)
  return text:find(prefix, 1, true) == 1
end

utils.endswith(text, suffix)
  return text:sub(-string.len(suffix)) == suffix
end

utils.tostring = function (lst, f)
  if type(lst) ~= 'table' then return tostring(lst) end
  local str = {}
  for _, a in ipairs(lst) do
      table.insert(str, utils.tostring(a))
  end
  if f then
    return string.format("(%s)", table.concat(str, " "))
  else
    return string.format("%s", table.concat(str, " "))
  end
end

utils.log = function(self, st)
  if #self.output > 500 then local h,o = 1,{}
      for i = 492, 500 do o[h] = self.output[i]
      h = h + 1 end self.output = o
  end
  local str = utils.tostring(st)
  local limit = 10
  local s = tostring(str):gsub("^%s*(.-)%s*$", "%1")
  if string.len(s) == 0  then return false
  elseif string.len(s) > 33 then
      local b = string.sub(str, 31)
      self.output[#self.output] =  s
      self.output[#self.output + 1] = b
      if string.len(b) > 33 then utils.log(self, string.sub(b, 31)) end
    else
      if s ~= self.output[#self.output] then
          self.output[#self.output + 1] =  s
      end
    end
end

utils.update_offset = function(val, y, length, bounds, offset)
  if y  > val + (9 - offset)  then
    val = util.clamp( val + 1, 0, length - bounds)
  elseif y < bounds + ( val - (8 - offset))  then
    val = util.clamp( val - 1, 0, length - bounds)
  end
  return val
end


utils.tab_key = function (t, e)
  local index={}
  for k, v in pairs(t) do
    if v == e then
      return k
    end
  end
end


return utils
