-- 
-- simple text editor
-- @its_your_bedtime
--

local textedit = {
    lines = {{},{},{},{},{},{}, {}},
    pos = {x = 1, y = 1},
    running = false,
    evaluated = false,
}

textedit.open = function(self, t)
  self.lines = t or {{},{},{},{},{},{},{}}
end

textedit.store = function(self)
  return self.lines
end

textedit.buildword = function(self, keyinput)
    if keyinput ~= nil then
        if self.pos.x ~= 1 then
            table.insert(self.lines[self.pos.y] , (#self.lines[self.pos.y] + self.pos.x) , keyinput)
            if #self.lines[self.pos.y] > 32 then
              local l = self.lines[self.pos.y][#self.lines[self.pos.y]]
              table.remove(self.lines[self.pos.y], #self.lines[self.pos.y])
              table.insert(self.lines[self.pos.y + 1], 1, l)
            end          
        else
            table.insert(self.lines[self.pos.y], keyinput)
        end
        if #self.lines[self.pos.y] > 32 then
          self.pos.y = util.clamp(self.pos.y + 1, 1, 7)
          self.pos.x = 1
        end
    end
end

textedit.rm = function(self, back)
    if back then
        if (#self.lines[self.pos.y] + self.pos.x) <= #self.lines[self.pos.y] then
            table.remove(self.lines[self.pos.y],  util.clamp((#self.lines[self.pos.y] + self.pos.x), 0, #self.lines[self.pos.y]))
            self.pos.x = self.pos.x + 1
        end
    else
        if (#self.lines[self.pos.y] + self.pos.x) > 1 then
            table.remove(self.lines[self.pos.y],  util.clamp((#self.lines[self.pos.y] + self.pos.x) - 1, 0, #self.lines[self.pos.y]))
        end
        if #self.lines[self.pos.y] + self.pos.x == 1 then
            self.pos.y = util.clamp(self.pos.y - 1, 1, #self.lines)
        end
    end
end

textedit.kb = function(self, typ, code, val, shift, k)
    local down = val > 0 
    if ( code == 103) and down then 
        self.pos.y = util.clamp(self.pos.y - 1, 1, #self.lines)
    elseif ( code == 105) and down then 
        self.pos.x = util.clamp(self.pos.x - 1, (-#self.lines[self.pos.y] + 1) , 1)
    elseif ( code == 106) and down then 
        self.pos.x = util.clamp(self.pos.x + 1, (-#self.lines[self.pos.y] + 1), 1)
    elseif ( code == 108) and down then 
        self.pos.y = util.clamp(self.pos.y + 1, 1, #self.lines)
    elseif code == 14 and down then 
        self:rm(false)
    elseif code == 111 and down then 
        self:rm(true)
    elseif (code == 28) and val == 1 then
        if not shift then
            self.pos.y = util.clamp(self.pos.y + 1, 1, 7)
        end
    end
    if #self.lines[self.pos.y] < 1 then self.pos.x = 1 end
    self:buildword(k)
end

textedit.render = function(blink, run, output)
    screen.font_face(25)
    screen.font_size(6)

    screen.level(run % 2 == 0 and 6 or 1)
    screen.rect(124, 60, 4, 4)
    screen.fill()

    if textedit.evaluated then
        screen.level(2)
        screen.rect(0, 0, 128, 57)
        screen.fill()
        textedit.evaluated = false
    end

    screen.level(15)
    
    for i = 1, #textedit.lines do
        screen.move(0, 8 * i)
        local l = table.concat(textedit.lines[i])
        screen.text(tostring(l))
        screen.stroke()
    end
    
    screen.level(3)
    screen.move(0, 63)
    screen.text(output[#output])
    screen.stroke()

    if blink then
        screen.level(2)
        screen.rect((((#textedit.lines[textedit.pos.y] + textedit.pos.x) * 8) / 2) - 4, (textedit.pos.y * 8) - 6, 3, 7)
        screen.fill()
    end
end

return textedit