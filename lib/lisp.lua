--
-- lisp core
-- @its_your_bedtime
--

local keyboard = require 'core/keyboard'
local stdlib = include('lib/_stdlib')
local utils = include('lib/utils')
local repl = include('lib/repl')
local engines = include('lib/_engines')
local tracker = include('lib/tracker')
local beatclock = require('beatclock')

local lisp = {
   output = {''}, metro = beatclock.new(),
   core = include('lib/_corelib'), std = nil, log = utils.log,
   buf = {}, blink = false, bpm =  110, live = false,
   tracker = true, pat = {[0] = {}}, help = '',
   pos = 1, subpos = { 1, 1, 1, 1 }, length = 16,
   mute ={ false, false, false, false },
   cycle = { 1, 1, 1, 1 }, div = { 1, 1, 1, 1 },
   tr_now = 1, pos_now = 1,
}

local is_mute_shortcut = false
function lisp.kb_code(c, val)
  is_mute_shortcut = false
  if lisp.live then repl:kb()
  elseif lisp.tracker then
    tracker.kb_code(c, val, lisp.pat, lisp.length)
    local code = utils.tab_key(keyboard.codes, c)
    if val > 0 and keyboard.shift() and (code <= 5 and code >= 2) then
      is_mute_shortcut = true
      lisp.mute[code - 1] = not lisp.mute[code - 1]
    end
  end
  if keyboard.state.ENTER then
    if lisp.live then
      repl.evaluate(lisp)
    end
  end
  if keyboard.shift() and keyboard.ctrl() then
    if lisp.metro.playing then
      lisp.metro:stop() lisp:log('> stopped.')
    else lisp.metro:start() lisp:log('> running..') end
  end
end

function lisp.kb_char(k)
  if lisp.live then repl:buildword(k)
  elseif lisp.tracker then
    tracker.kb_char(k)
    if keyboard.ctrl() then
      if k == 'x' then
        tracker:copy(lisp.pat[tracker.pos.y][tracker.pos.x])
        lisp.pat[tracker.pos.y][tracker.pos.x] = nil
      elseif k == 'c' then
        tracker:copy(lisp.pat[tracker.pos.y][tracker.pos.x])
      elseif k == 'v' then
        lisp.pat[tracker.pos.y][tracker.pos.x] = tracker:paste()
      end
    elseif is_mute_shortcut then
      -- pass
    else
      tracker:buildword(k, lisp.pat)
    end
  end
end

lisp.enc = function(self, n, d)
   if self.live then repl:enc(n, d, lisp) else end
end

lisp.init = function()
    local blinks = metro.init( function() lisp.blink = not lisp.blink end, 0.7)
    blinks:start()
    lisp.metro:add_clock_params()
    lisp.metro.on_step = function() tracker.exec(lisp) end
    engines.init()
   -- init environment
    lisp.std = lisp.Env({}, {}, {_find_= function() return nil end }) -- outer table doesn't exists
    for k,_ in pairs(lisp.core) do lisp.help = lisp.help ..' '.. k end
    for k,v in pairs(stdlib) do lisp.std[k] = v lisp.help = lisp.help ..' '.. k  end -- functions
    for k = 1, 99 do lisp.pat[k] = {} end

    lisp:log('welcome to nisp')
end

----------

-- Prepare table for environment
lisp.Env = function (pars, args, outer)
   local dict = { outer = outer }
   for i = 1, #pars do dict[pars[i]] = args[i] end
   -- check existance of symbol
   dict._find_ = function (self, v) return self[v] and self or self.outer:_find_(v) end
   return dict
end

lisp.collect = function(t,s,e)
   local args = {}
   for i = s, #t do
      local v = lisp.eval(t[i], e )
      if v then
        args[#args + 1] = v
      end
   end
   return args
end

-- Expression evaluation
lisp.eval = function (x, env)
   env = env or lisp.std
   if type(x) ~= 'table' then
      local elt = env:_find_(x)
      if elt then return elt[x] end                 -- is symbol
      if tonumber(x) then return tonumber(x) end    -- is number
      if x == nil then return false end
      if string.find(x, '".*"') then return x end   -- is string ("" must be used)
      lisp:log('Undefined: ' .. utils.tostring(x))
      --lisp.err('unknown: ' .. utils.tostring(x))
      return nil
   else
      if lisp.core[x[1]] then
         return lisp.core[x[1]](lisp, x, env)
      elseif env:_find_(x[1]) then
            local proc = lisp.eval(x[1], env)
            if type(proc) == 'function' then
               local args = lisp.collect(x, 2, env)
               return proc(table.unpack(args)) or nil
            else
               local args = lisp.collect(x, 2, env)
               return proc(table.unpack(args)) or nil
            end

    else
           local args = lisp.collect(x, 1, env)
           return args
         end
      end

end

-- User defined procedure (lambda)
lisp.Proc = function (pars, body, env)
    local dict = {pars = pars, body = body, env = env}
    -- make callable
    setmetatable(dict, { __call = function (self, ...)
          return lisp.eval(self.body, lisp.Env(self.pars, {...}, self.env))
    end })
    return dict
end

-- Create list (parsing tree) from tokens
lisp.tree = function (tok)
   local t = table.remove(tok, 1)
   if t == '\'' then return {'quote', lisp.tree(tok)} end   -- use ' for quote
   if t == '(' then                                         -- new list
      local tbl = {}
      while tok[1] ~= ')' do
        tbl[#tbl + 1] = lisp.tree(tok)
      end
      table.remove(tok, 1)
      return tbl
   else
      return t ~= ')' and t or lisp.err("syntax error")
   end
end

-- Get tokens
lisp.parse = function (s)
  s = s:gsub(';+.-\n', '\n')                                     -- remove comments
  s = s:gsub('[()\']', {['(']=' ( ',[')']=' ) ', ['\'']=' \' '}) -- white space as delimeter
  local quotes = false
  local tok = {}
  
  for w in s:gmatch('%S+') do 
    if(quotes) then
      tok[#tok] = tok[#tok] .. ' ' .. w
    else 
      tok[#tok + 1] = w
    end
    
    if(utils.startswith(w, '"')) then
      quotes = true
    end
    
    if(utils.endswith(w, '"')) then
      quotes = false
    end
  end

  return lisp.tree(tok)
end


lisp.run = function(str, verbose, tr, pos)
   lisp.tr_now = tr
   lisp.pos_now = pos
   if verbose then lisp:log('>'..str) end
   local res = (#str > 0) and lisp.eval(lisp.parse(str)) or nil
   if res then lisp:log(res) end
   if not verbose then return res end
end

lisp.err = function(msg)
   lisp:log(msg)
   error(msg)
end

lisp.redraw = function()
  if lisp.live then repl.render(lisp, lisp.blink)
  elseif lisp.tracker then tracker.render(lisp)
  end

end
return lisp
