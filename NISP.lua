-- NISP
--
--
-- scheme dialect livecoding 
--         tracker for norns
--
--
-- @its_your_bedtime
--
local keyb = hid.connect()
local lisp = include("lib/lisp")
local keycodes = include("lib/keycodes")
local fileselect = require('fileselect')
local textentry = require('textentry')

local kb = {s = {[42] = true, [54] = true }, c = {[29] = true, [125] = true, [127] = true, [97] = true}}
local live = true
local shift = false
local ctrl = false
local metro_main

local function get_key(code, val, shift)
    local c, s = keycodes.keys[code], keycodes.shifts[code]
    if c ~= nil and val == 1 then
        if shift then if s ~= nil then return s
        else return c end
        else return string.lower(c) end
    end
end


function load_project(pth)
  if string.find(pth, '.seq') ~= nil then
    local saved = tab.load(pth)
    if saved ~= nil then
      print("data found")
      lisp.pat = saved[2]
      params:read(norns.state.data .. saved[1] ..".pset")
    else
      print("no data")
    end
  end
end

function save_project(txt)
  if txt then
    local l = { txt, lisp.pat }
    local full_path = norns.state.data .. txt
    tab.save(l, full_path ..".seq")
    params:write(full_path .. ".pset")
  else
    print("save cancel")
  end
end



function keyb.event(typ, code, val)
    local menu = norns.menu.status()
    local k = get_key(code, val, shift)
    local down = val > 0 screen.ping()
    lisp.blink = true
    if code == 41 and val == 1 then lisp.live = not lisp.live return false end
    if code == 1 and val == 1 then 
      lisp.live = false 
        if shift then 
          norns.menu.toggle(not menu)
        elseif menu and not shift then 
          _norns.key(2, 1) 
        end
      end
    if kb.s[code] then shift = down and true end
    if kb.c[code] then ctrl = down and true end
    if not menu then
      lisp.kb_event(typ,code,val, shift, ctrl, k)
    else
        if (code == hid.codes.KEY_LEFT) and (val == 1 or val == 2) then
              if ctrl then _norns.enc(1, -8) else _norns.enc(3, shift and -20 or -2) end
        elseif (code == hid.codes.KEY_RIGHT) and (val == 1 or val == 2) then
              if ctrl then _norns.enc(1, 8) else _norns.enc(3, shift and 20 or 2) end 
        elseif (code == hid.codes.KEY_DOWN) and (val == 1 or val == 2) then
            _norns.enc(2, shift and 104 or 2) 
        elseif (code == hid.codes.KEY_UP) and (val == 1 or val == 2) then
            _norns.enc(2, shift and -104 or -2) 
        elseif (code == hid.codes.KEY_ENTER and val == 1) then
            _norns.key(3, 1) 
        end
    end
end

function init()
    screen.aa(0)
    params:add_trigger('save_p', "< Save project" )
    params:set_action('save_p', function(x) textentry.enter(save_project,  'new') end)
    params:add_trigger('load_p', "> Load project" )
    params:set_action('load_p', function(x) fileselect.enter(norns.state.data, load_project) end)
    params:add_trigger('new', "+ New" )
    params:set_action('new', function(x) init() end)
    params:add_separator()

    lisp.init()
    local metro_redraw = metro.init( function() redraw() end, 1 / 16)
    metro_redraw:start()

end

function enc(n, d)
  --if n == 3 then offset = util.clamp(offset + d, 1, 64) end
end


function redraw()
    screen.clear()
    lisp.redraw()
    screen.update()
end
