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
local tracker = { pos = { x = 1, y = 1}, edit = false,  buffer = { cell = nil,  expr = nil }, }
local s_offset, bounds_y, w = 0, 9, {}
local attached = false

local function tr_spacing(tr) return (30 * tr) - 17 end
local function cursor_pos(x, y) return (y == tracker.pos.y and tracker.pos.x == x) and 9 or 1 end
local function format_val(v) return (v and string.len(v) < 2) and v .. '-' or v and v or '--' end 
  
local function get_note(n)
  if n and string.match(n, '%a%d') then
    return utils.note_name_to_num(n)
  elseif n and string.match(n, '%d%d') then
    return tonumber(n)
  end
end


tracker.copy = function(self)
  if tracker.pos.x % 3 == 0 then
    self.buf[1] =  self.pat[tracker.pos.y][tracker.pos.x]
    return self.buf[1]
  else
    self.buf[2] = self.pat[tracker.pos.y][tracker.pos.x]
    return self.buf[2]
  end
end

tracker.paste = function(self)
  if tracker.pos.x % 3 == 0 then
    self.pat[tracker.pos.y][tracker.pos.x] = self.buf[1]
  else
    self.pat[tracker.pos.y][tracker.pos.x] =  self.buf[2] 
  end
end


tracker.buildword = function(self, keyinput, pat)
    if keyinput ~= nil then
        if #w <= 1 then
          table.insert(w, keyinput)
          if self.pos.x % 3 ~= 0 then
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

    self.pos = self.pos >= self.length and 1 or self.pos + 1

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
  
          if not self.mute[i] then
            
              if s then
                
                  if l ~= false then engine.noteOn(s, music.note_num_to_freq(n or 60), 1, s) end
                
              end
          end
        end
    end
    
    if attached then
      
      if tracker.pos.y < self.pos then s_offset = self.pos - bounds_y end
      
      s_offset = utils.update_offset(s_offset, self.pos, self.length, bounds_y, 1)
      s_offset = self.pos >= self.length and 0 or s_offset 
    
    end
    
end

tracker.kb_event = function(typ, code, val, shift, k, pat, length)
    local down = val > 0 screen.ping()
    if tracker.edit then
        if code == 1 and down then tracker.edit = false end
        if code == 28 and down and shift then 
          pat[tracker.pos.y][tracker.pos.x] = textedit:kb(typ, code, val, shift, k) 
        end
        textedit:kb(typ, code, val, shift, k) 
    else
        if (code == 103) and down then 
            tracker.pos.y = util.clamp(tracker.pos.y - 1, 1, length) 
            attached, w = false, {}
        elseif (code == 105) and down then 
            tracker.pos.x = util.clamp(tracker.pos.x - 1, 1, 12)
            attached, w = false, {}
        elseif (code == 106) and down then 
            tracker.pos.x = util.clamp(tracker.pos.x + 1, 1, 12)
            attached, w = false, {}
        elseif (code == 108) and down then 
            tracker.pos.y = util.clamp(tracker.pos.y + 1, 1, length)
            attached, w = false, {}
        elseif code == 58 and down then
          attached = not attached
        elseif code == 14 and down then 
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
        elseif code == 28 and down then
            if (not tracker.edit and tracker.pos.x % 3 == 0) then tracker.edit = true
                if pat[tracker.pos.y][tracker.pos.x] then
                  textedit:open(pat[tracker.pos.y][tracker.pos.x]) 
                end
            end
        end
        
    end
    s_offset = utils.update_offset(s_offset, tracker.pos.y, length, bounds_y, 0)
end

tracker.render = function(self)
    screen.font_face(25)
    screen.font_size(6)
    if tracker.edit then
      textedit.render(self.blink, self.pos, self.output)
    else
      screen.level(3)
       if not self.mute[1] then 
         screen.rect(11,  ((self.subpos[1] - s_offset) * 7)  - 6, 28, 7) 
       else 
         screen.rect(31,  ((self.subpos[1] - s_offset) * 7)  - 6, 7, 7) 
        end
       if not self.mute[2] then 
         screen.rect(39, ((self.subpos[2] - s_offset) * 7)  - 6, 31, 7) 
       else
         screen.rect(61, ((self.subpos[2] - s_offset) * 7)  - 6, 7, 7) 
       end
       if not self.mute[3] then 
         screen.rect(69, ((self.subpos[3] - s_offset) * 7)  - 6, 31, 7) 
       else
         screen.rect(91, ((self.subpos[3] - s_offset) * 7)  - 6, 7, 7) 
       end
       if not self.mute[4] then 
         screen.rect(99, ((self.subpos[4] - s_offset) * 7)  - 6, 30, 7) 
       else
         screen.rect(121, ((self.subpos[4] - s_offset) * 7)  - 6, 7, 7) 
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
              screen.text((expr and #expr[1] > 0) and '*' or '-')
          end
          screen.stroke()
        end
    end
end

return tracker