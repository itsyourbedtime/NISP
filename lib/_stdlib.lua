-- 
-- standart library
-- @its_your_bedtime
--

local stdlib = {}
local utils = include('lib/utils')


stdlib['#t'] = true

stdlib['#f'] = function () return false end
--- math
stdlib['+'] = function(...) local r = 0 for i=1,select("#",...) do r = r + select(i,...) end return r end

stdlib['-'] = function(...) local r = 0 for i=1,select("#",...) do r = r - select(i,...) end return r end

stdlib['*'] = function(...) local r = 1 for i=1,select("#",...) do r = r * select(i,...) end return r end

stdlib['/'] = function(...) local r = 1 for i=1,select("#",...) do r = r / select(i,...) end return r end

stdlib['%'] = function(...) local r for i=1,(select("#",...) - 1) do r = select(i,...) % select(i + 1,...) end return r end

stdlib['^'] = function(...) local r for i=1,(select("#",...) - 1) do r = select(i,...) ^ select(i + 1,...) end return r end
-- lists
stdlib['append'] = function(a,b) return  end -- to do

stdlib['apply'] = function(a,b) return a(table.unpack(b)) end

stdlib['begin'] = function(...) local a = {...}; return a[#a] end

stdlib['car'] = function(lst) return lst[1] end

stdlib['cdr'] = function(lst) return table.move(lst, 2, #lst, 1, {}) end

stdlib['cons'] = function(a, lst) return table.move( lst, 1, #lst, 2, { a }) end

stdlib['eq'] = function(a, b) return a == b end

stdlib['='] = function(a, b) return a == b end

stdlib['>'] = function(a, b) return a > b end

stdlib['<'] = function(a, b) return a < b end

stdlib['<='] = function(a, b) return a <= b end

stdlib['>='] = function(a, b) return a >= b end

stdlib['list'] = function(...) return {...} end

stdlib['list?'] = function(a) return type(a) == 'table' end

stdlib['len'] = function(a) return type(a) == 'table' and #a or string.len(a) end

stdlib['get'] = function(a, b) return type(a) == 'table' and a[b]  end

stdlib['put'] = function (a, b) return type(a) == 'table' and table.insert(a, b) or (type(a) == 'table' and type(b) == 'table') and join(a, b) end

stdlib['concat'] = function(...) local r for i=1,(select("#",...) - 1) do r = tostring(select(i,...)):gsub('"','')..tostring(select(i + 1,...)):gsub('"','') end return r end

stdlib['nil?'] = function(a) return a == nil or #a == 0 end

stdlib['print'] = function(...) return utils.tostring(..., true) end

stdlib['num?'] = function(a) return tonumber(a) ~= nil end

stdlib['map'] = function(fn, a) local v = {}; for i = 1,#a do v[i] = fn(a[i]) end; return v end

stdlib['rnd'] = function(a, b) return((not a and not b) and math.random(0, 99) or (a and not b) and math.random(a) 
or math.random(a, b)) end

return stdlib