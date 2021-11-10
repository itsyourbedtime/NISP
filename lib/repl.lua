--
-- repl module
-- @its_your_bedtime
--


local repl = {
    lines = {{},{},{},{},{},{}, {},{}},
    history = { entries = { [0] = '' }, index = 0 },
    offset = { x = 0, y = 0 },
    pos = {x = 1, y = 1},
    output = '',
    evaluated = false,
    running = false,
    view = 10,
    nl = 0
}

repl.hist = function(self, i)
    local e, t = self.history.entries[i], {}
    for i in e:gmatch('.') do t[#t + 1] = i end
    return t
end

repl.upd_hist = function(self, d)
    self.history.index = util.clamp(self.history.index + d, 0, #self.history.entries )
    self.lines[1] = self:hist(self.history.index)
end

repl.buildword = function(self, keyinput)
    if keyinput ~= nil then
        if self.pos.x ~= 1 then
            table.insert(self.lines[self.pos.y] , (#self.lines[self.pos.y] + self.pos.x) , keyinput)
        else
            table.insert(self.lines[self.pos.y], keyinput)
        end

        if #self.lines[self.pos.y] >= 31 then
            self.view = util.clamp(self.view - 1, 4, 10)
            self.pos.y = util.clamp(self.pos.y + 1, 1, 7)
            self.pos.x = 1
        end
    end
end

repl.rm = function(self, back)
    if back then
        if (#self.lines[self.pos.y] + self.pos.x) <= #self.lines[self.pos.y] then

            table.remove(self.lines[self.pos.y],  util.clamp((#self.lines[self.pos.y] + self.pos.x), 0, #self.lines[self.pos.y]))
            self.pos.x = self.pos.x + 1
        end
    else
        if (#self.lines[self.pos.y] + self.pos.x) > 1 then
            local pos = util.clamp((#self.lines[self.pos.y] + self.pos.x) - 1, 0, #self.lines[self.pos.y])
            table.remove(self.lines[self.pos.y],  pos)
        end
        if #self.lines[self.pos.y] + self.pos.x == 1 then
            self.pos.y = util.clamp(self.pos.y - 1, 1, #self.lines)
            self.view = util.clamp(self.view + 1, 1, 10)
        end
    end
end

repl.kb = function(self)
    if keyboard.state.UP then
      if self.nl == 0 then
        self:upd_hist(1)
      else
        self.pos.y = util.clamp(self.pos.y - 1, 1, #self.lines)
        self.pos.x = 1
      end
    elseif keyboard.state.LEFT then
        self.pos.x = util.clamp(self.pos.x - 1, ((-#self.lines[self.pos.y])+ 1) , 1)
    elseif keyboard.state.RIGHT then
        self.pos.x = util.clamp(self.pos.x + 1,( -#self.lines[self.pos.y]), 1)
    elseif keyboard.state.DOWN then
      if self.nl == 0 then
        self:upd_hist(-1)
      else
        self.pos.y = util.clamp(self.pos.y + 1, 1, #self.lines )
        self.pos.x = 1
      end
    elseif keyboard.state.BACKSPACE then
        self:rm(false)
    elseif keyboard.state.DELETE then
        self:rm(true)
    elseif keyboard.state.ENTER then
        self.pos.y = util.clamp(self.pos.y + 1, 1, 7)
        self.pos.x = #self.lines[self.pos.y + 1] > 0 and #self.lines[self.pos.y] or 1
    end
end

repl.evaluate = function(self)

      local f = ''
      for i = 1, #repl.lines do
          local l = table.concat(repl.lines[i])
          f = f .. tostring(l)
      end

      repl.nl = 0

      for c in f:gmatch('[()]') do
          repl.nl = util.clamp(repl.nl + (c == '(' and 1 or -1), 0, 8)
      end
      table.insert(repl.lines[repl.pos.y],'\n')
      repl.view = util.clamp(repl.view - repl.nl, 3, 10)

      if repl.nl == 0 then
          repl.view = 10
          repl.pos.y,repl.pos.x = 1, 1
      if string.len(f:gsub("%s+", "")) > 0 then
          repl.lines = {{},{},{},{},{},{},{},{}}
          table.insert( repl.history.entries, 1, f )
          self.run(f, true)
          repl.history.index = 0
      end
    end
end

repl.render = function(self, blink)
    local line = 1

    if repl.running then
        screen.level(3)
        screen.rect(124, 60, 4, 4)
        screen.fill()
        repl.running = false
    end

    screen.font_face(25)
    screen.font_size(6)
    screen.level(15)

    for i = 1, #repl.lines do
        local rev = #repl.lines - i
        local l = table.concat(repl.lines[i])
        screen.move(0, (48 + (((repl.view - 9) + i) *7 )))
        screen.text((i == 1 and '>' or '') .. tostring(l))
        screen.stroke()
    end

    screen.level(3)

    for i = #self.output - 8, #self.output do
        screen.move(0, (62 + (((line + repl.view) - 20) * 7)))
        screen.text(tostring(self.output[i - repl.offset.x] or ''))
        line = line + 1
    end

    screen.stroke()

    if blink then
        local strlen = #repl.lines[repl.pos.y] + repl.pos.x
        local intend = ((strlen * 8) / 2) - (repl.pos.y == 1 and 0 or 4)
        screen.level(2)
        screen.rect(intend, (42 + (((repl.view - 9) + (repl.pos.y))*7)), 3, 7)
        screen.fill()
    end
end


return repl
