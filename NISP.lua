-- NISP
--
--
-- scheme dialect livecoding
--         tracker for norns
--
--
-- @its_your_bedtime
--
local keyboard = require 'core/keyboard'
local lisp = include("lib/lisp")
local keycodes = include("lib/keycodes")
local fileselect = require('fileselect')
local textentry = require('textentry')

local kb = {s = {[42] = true, [54] = true }, c = {[29] = true, [125] = true, [127] = true, [97] = true}}
local live = true
local shift = false
local ctrl = false
local metro_main

function load_project(pth)
  if string.find(pth, '.seq') ~= nil then
    local saved = tab.load(pth)
    if saved ~= nil then
      print("data found")
      for k,v in pairs(saved[2]) do lisp[k] = v end
      lisp.metro:bpm_change(saved[2].bpm)
      if saved[1] then params:read(norns.state.data .. saved[1] .. ".pset") end
    else
      print("no data")
    end
  end
end

function save_project(txt)
  if txt then
    local data = { pat = lisp.pat, bpm = lisp.bpm, div = lisp.div, length = lisp.length, mute = lisp.mute }
    tab.save({ txt, data }, norns.state.data .. txt ..".seq")
    params:write( norns.state.data .. txt .. ".pset")
  else
    print("save cancel")
  end
end

function keyboard.code(c, val)
    local menu = norns.menu.status()
    screen.ping()
    lisp.blink = true
    shift = keyboard.shift()
    ctrl = keyboard.ctrl()
    if keyboard.state.GRAVE then lisp.live = not lisp.live return false end
    if keyboard.state.ESC then
      lisp.live = false
        if shift then
          norns.menu.toggle(not menu)
        elseif menu and not shift then
          _norns.key(2, 1)
        end
    end
    if not menu then
      lisp.kb_code(c, val)
    else
      if keyboard.state.LEFT then
            if ctrl then _norns.enc(1, -8) else _norns.enc(3, shift and -20 or -2) end
      elseif keyboard.state.RIGHT then
            if ctrl then _norns.enc(1, 8) else _norns.enc(3, shift and 20 or 2) end
      elseif keyboard.state.DOWN then
          _norns.enc(2, shift and 104 or 2)
      elseif keyboard.state.UP then
          _norns.enc(2, shift and -104 or -2)
      elseif keyboard.state.ENTER then
          _norns.key(3, 1)
      end
    end
end

function keyboard.char(k)
    local menu = norns.menu.status()
    if not menu then
      lisp.kb_char(k)
    end
end

function init()
    screen.aa(0)
    math.randomseed(os.time())
    params:add_trigger('save_p', "< Save project" )
    params:set_action('save_p', function(x) textentry.enter(save_project,  'new') end)
    params:add_trigger('load_p', "> Load project" )
    params:set_action('load_p', function(x) fileselect.enter(norns.state.data, load_project) end)
    params:add_trigger('new', "+ New" )
    params:set_action('new', function(x) init() end)
    params:add_separator()

    lisp.init()
    local metro_redraw = metro.init( function() redraw() end, 1 / 30)
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
