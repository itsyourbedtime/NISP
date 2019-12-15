---
--- nisp core functions
--- @its_your_bedtime
---

local shortenings = { ["atk"] = "amp_env_attack", ["dec"] = "amp_env_decay", ["sus"] = "amp_env_sustain", 
  ["rel"] = "amp_env_release", ["detune"] = "detune_cents", ["strch"] = "by_percentage",
  ["ctf"] = "filter_freq", ["res"] = "filter_resonance", ["ftype"] = "filter_type", 
  ["qlt"] = "quality", ["fm-lfo1"] = "freq_mod_lfo_1", ["fm-lfo2"] = "freq_mod_lfo_2",
  ["f-lfo1"] = "filter_freq_mod_lfo_1",  ["f-lfo2"] = "filter_freq_mod_lfo_2", 
  ["p-lfo1"] = "pan_mod_lfo_1", ["p-lfo2"] = "pan_mod_lfo_2", ["a-lfo1"] = "amp_mod_lfo_1", 
  ["a-lfo2"] = "amp_mod_lfo_2", ["fm-env"] = "freq_mod_env", ["f-fm-env"] = "filter_freq_mod_env", 
  ["f-fm-vel"] = "filter_freq_mod_vel", ["f-fm-pr"] = "filter_freq_mod_pressure", 
  ["f-track"] = "filter_tracking", ["p-env"] = "pan_mod_env", ["m-atk"] = "mod_env_attack", 
  ["m-dec"] = "mod_env_decay", ["m-sus"] = "mod_env_sustain", ["m-rel"] = "mod_env_release"
}

local core = {
  
   ------
   ------
   ------
   ['help'] = function( self ) return self.help end,
   ['quote'] = function( self, x, env ) return x[2] end,
   ['def'] =  function( self, x, env ) env[x[2]] = self.eval(x[3], env) end,
   ['lambda'] =  function( self, x, env ) return self.Proc(x[2], x[3], env) end,
   ['@'] = function( self, x, env ) return self.pos_now end,
   ['bpm'] = function( self, x, env ) self.bpm = self.eval(x[2], env) self.metro:bpm_change(self.bpm) end,
   ['div'] = function(self, x, env) local div = tonumber(self.eval(x[2], env))  self.div[self.tr_now] = div or 1 end,

   ------
   ------
   ------
   ['if'] =  function( self, x, env )
    local exp = self.eval(x[2], env)
      if exp == true then return self.eval(x[3], env)
      elseif exp == false or exp == nil then
         return self.eval(x[4], env ) 
      end
    end,
 
    ['when'] =  function( self, x, env )
      local exp = self.eval(x[2], env)
        if exp == true then return self.eval(x[3], env)
        end
      end,
   
   ['jmp'] = function( self, x, env )
          local l =  util.clamp(self.eval(x[2], env) or 1 - 1, 0, self.length)
          self.subpos[self.tr_now] = l or 0
   end,
   
   ['skip'] = function( self, x, env ) 
          self.subpos[self.tr_now] = self.subpos[self.tr_now] + 1
   end,
   
   ['mute'] = function( self, x, env )
     if #x == 2 then
         local dst = self.eval(x[2], env)
         self.mute[tonumber(dst)] = not self.mute[tonumber(dst)]
      else 
         self.mute[self.tr_now] = not self.mute[self.tr_now] 
      end
   end,

   ['sync'] = function( self, x, env )
      if #x == 2 then 
         local sync_to = self.subpos[util.clamp(self.eval(x[2], env), 1, 4)]
         for i = 1, 4 do self.subpos[i] = sync_to end
      else
         for i = 1, 4 do self.subpos[i] = self.pos end
      end
   end,
   
   ['ever'] = function( self, x, env )
      local s = self.eval(x[2], env)
        if self.cycle[self.tr_now] % s  == 0 then 
          self.cycle[self.tr_now] = 1
        return self.eval(x[3], env)   end

   end,

   ['length'] = function( self, x, env ) 
        local length = self.eval(x[2], env) or 16
        self.length = util.clamp(length, self.pos_now or 1, 99)
   end,


   ['save'] = function( self, x, env )
    local data = { pat = self.pat, bpm = self.bpm, div = self.div, length = self.length, mute = self.mute }
    tab.save( { nil , data }, norns.state.data .. tostring(self.eval(x[2], env)) ..".seq") 
 end,

 ['load'] = function( self, x, env )
    local saved = tab.load(norns.state.data .. tostring(self.eval(x[2], env))  .. ".seq")
    if saved ~= nil then for k,v in pairs(saved[2]) do self[k] = v end end
 end,
    
 --------------------------------
 ---------SOUND-OPS--------------
 --------------------------------
  ['note'] = function( self, x, env )
    if #x == 3 then
      local step = self.eval(x[2], env) 
      self.pat[step][self.tr_now * 3 - 1] = self.eval(x[3], env) 
    else
      self.pat[self.pos_now][self.tr_now * 3 - 1] = util.clamp(self.eval(x[2], env), 0, 99)
    end
 end,
 

 ['sample'] = function( self, x, env )
    if #x == 3 then
      local step = self.eval(x[2], env) 
      self.pat[step][self.tr_now * 3 - 2] = self.eval(x[3], env) 
    else
      self.pat[self.pos_now][self.tr_now * 3 - 2] = util.clamp(self.eval(x[2], env), 0, 99)
    end
 end,
   

['pos'] = function( self, x, env )
  local s_id = self.pat[self.pos_now][self.tr_now * 3 - 2] or false
  if not s_id or not tonumber(s_id) then return false end
  local length = params:get("end_frame_" .. s_id)
  local val = self.eval(x[2])
  local start_pos = util.clamp((tonumber(val) / 100 ) * length, 0, length ) 
  params:set("start_frame_" .. s_id, start_pos or 0) 
end,

}
  ------
  ------
  ------

  for k, v in pairs(shortenings) do
   core[k] = function(self, x, env)
      local s_id = self.pat[self.pos_now][self.tr_now * 3 - 2] or false
      if not s_id then return false end
      local val = self.eval(x[2], env)
      if val then params:set( shortenings[k] .. "_" .. s_id , val ) end
    end
  end
  
   

return core