--
-- tracker module
-- @its_your_bedtime
--

local music = require 'musicutil'
---
local textedit = include('lib/textedit')
local utils = include('lib/utils')
---
local tr_i = { {1, 2, 3}, {4, 5, 6}, {7, 8, 9}, {10, 11, 12} }
local tracker = { pos = { x = 1, y = 1}, edit = false,  buffer = { nil,  nil }, }
local bars = { [1] = { 11, 28, 31 }, [2] = { 39, 31, 61 }, [3] = { 69, 31, 91 }, [4] = { 99, 30, 121 } }
local s_offset, bounds_y, w, attached = 0, 9, {}, false
---
local function tr_spacing(tr) return (30 * tr) - 17 end
local function cursor_pos(x, y) return (y == tracker.pos.y and tracker.pos.x == x) and 9 or 1 end
local function format_val(v) return (v and string.len(v) < 2) and v .. '-' or v and v or '--' end
local function not_empty(t) for i=1,#t do if #t[i] > 0 then return true end end end

local function get_note(n)
  if n and string.match(n, '%a%d') then
    return utils.note_name_to_num(n)
  elseif n and string.match(n, '%d%d') then
    return tonumber(n)
  end
end

tracker.copy = function(self, p)
  if self.pos.x % 3 == 0 then
    self.buffer[1] =  p
  else
    self.buffer[2] = p
  end
end

tracker.paste = function(self)
  if self.pos.x % 3 == 0 then
    return self.buffer[1]
  else
    return self.buffer[2]
  end
end

tracker.buildword = function(self, keyinput, pat)
    if keyinput ~= nil then
        if #w <= 1 then
          if self.pos.x % 3 ~= 0 then
              table.insert(w, keyinput)
              local str = table.concat(w)
              if string.match(str, '%w') then
                  pat[self.pos.y][self.pos.x] = str
              end
          end
        end
    end
end

tracker.evaluate = function(self, s, tr, pos)
    local f = '('
    for i = 1, #s do
        local l = table.concat(s[i])
        f = f .. tostring(l)
    end
    f = f .. ')'
    local l = self.run(f, false, tr, pos)
    return l or false
end

tracker.exec = function(self)

    local pat = self.pat
    local pos = self.pos

    for i = 1, 4 do

      if self.pos % (self.div[i] > 0 and self.div[i] or 1)  == 0 then

        self.cycle[i] = self.pos >= self.length and self.cycle[i] + 1 or self.cycle[i]
        self.subpos[i] = self.subpos[i] >= self.length and 1 or self.subpos[i] + 1

          local tr    =  tr_i[i]
          local step  =  self.subpos[i]
          local s     =  tonumber(pat[step][tr[1]])
          local n     =  get_note(pat[step][tr[2]])
          local e, l  =  pat[step][tr[3]]

          if e then l = tracker.evaluate(self, e, i, step )  end

              if not self.mute[i] and s then
                  engine.noteOn(s, music.note_num_to_freq(n or 60), 1, s)
              end
          end
      end

    if attached then

      if tracker.pos.y < self.pos then s_offset = self.pos - bounds_y end

      s_offset = utils.update_offset(s_offset, self.pos, self.length, bounds_y, 1)
      s_offset = self.pos >= self.length and 0 or s_offset

    end

    self.pos = self.pos >= self.length and 1 or self.pos + 1

end

tracker.kb_code = function(c, val, pat, length)
    if tracker.edit then
        if keyboard.state.ESC then tracker.edit = false end
        if keyboard.state.ENTER and keyboard.shift() then
          textedit.evaluated = true
          pat[tracker.pos.y][tracker.pos.x] = textedit:store()
        end
        textedit:kb_code(c, val)
    else
        if keyboard.state.UP then
            tracker.pos.y = util.clamp(tracker.pos.y - 1, 1, length)
            attached, w = false, {}
        elseif keyboard.state.LEFT then
            tracker.pos.x = util.clamp(tracker.pos.x - 1, 1, 12)
            attached, w = false, {}
        elseif keyboard.state.RIGHT then
            tracker.pos.x = util.clamp(tracker.pos.x + 1, 1, 12)
            attached, w = false, {}
        elseif keyboard.state.DOWN then
            tracker.pos.y = util.clamp(tracker.pos.y + 1, 1, length)
            attached, w = false, {}
        elseif keyboard.state.CAPSLOCK then
          attached = not attached
        elseif keyboard.state.BACKSPACE then
            if tracker.pos.x % 3 ~= 0 then
              local s = pat[tracker.pos.y][tracker.pos.x]
              if s and string.len(s) > 1 then
                  pat[tracker.pos.y][tracker.pos.x] = string.sub(s, 1, 1)
                  table.remove(w)
              else
                  pat[tracker.pos.y][tracker.pos.x] = nil w = {}
              end
            else
              pat[tracker.pos.y][tracker.pos.x] = nil
            end
        elseif keyboard.state.ENTER then
            if (not tracker.edit and tracker.pos.x % 3 == 0) then
                textedit:open(pat[tracker.pos.y][tracker.pos.x])
                tracker.edit = true
            end
        end

    end
    s_offset = utils.update_offset(s_offset, tracker.pos.y, length, bounds_y, 0)
end

tracker.kb_char = function(k)
    if tracker.edit then
        textedit:kb_char(k)
    end
end

tracker.render = function(self)
    screen.font_face(25)
    screen.font_size(6)
    if tracker.edit then
      textedit.render(self.blink, self.pos, self.output)
    else
      screen.level(3)

      for i = 1, 4 do
       if not self.mute[i] then
         screen.rect(bars[i][1],  ((self.subpos[i] - s_offset) * 7)  - 6, bars[i][2], 7)
       else
         screen.rect(bars[i][3],  ((self.subpos[i] - s_offset) * 7)  - 6, 7, 7)
        end
      end

        screen.fill()

        for i= 1, bounds_y do
          local l = i + s_offset
          if l > self.length then return false end
          screen.level(4)
          screen.move(7, i * 7)
          screen.text_right(l)
          screen.stroke()

          for k = 1, 4 do
              local mute = self.mute[k]
              local tr = tr_i[k]
              local trk, note, expr = self.pat[l][tr[1]],  self.pat[l][tr[2]],  self.pat[l][tr[3]]

              screen.level(cursor_pos(tr[1], l))
              screen.move(tr_spacing(k), i  * 7)
              screen.text(format_val(trk))

              screen.level(cursor_pos(tr[2], l))
              screen.move(tr_spacing(k) + 10, i  * 7)
              screen.text(format_val(note))

              screen.level(cursor_pos(tr[3], l))
              screen.move(tr_spacing(k) + 20, i  * 7)
              screen.text(not_empty(expr or {}) and '*'  or '-')
          end
          screen.stroke()
        end
    end
end

return tracker
