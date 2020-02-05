-- lander-01 (nc01-drone)
-- @pfig
--
-- E1 volume
-- E2 brightness
-- E3 density
-- K2 explore
-- K3 lift off

local worlds = {'dd', 'bc', 'eb'}
local world = 1

local level = 1.0
local level_slew = 10.0

local active = 1
local standby = 2
local buffers = {active, standby}
local durations = {}

local loop_length = 3
local fade_time = loop_length / 2

function init()
  prep_buffers(buffers)

  -- get out
  softcut.play(active, 1)
  delay(function()
    softcut.level(active, level)
  end)
  
  --[[ the 2nd world is already loaded, the first time we lift off
       we need to pre-load the 3rd world.
    ]]
  world = #buffers
end

function enc(n,d)
  if n == 1 then -- adjust volume
    -- don't want to wait 10 seconds, though
    softcut.level_slew_time(active, 0.001)
    level = util.clamp(level + d / 100, 0.0, 1.0)
    softcut.level(active, level)
    softcut.level_slew_time(active, level_slew)
  elseif n == 2 then
    -- brightness
  elseif n == 3 then
    -- density
  end
end

function key(n,z)
  if z == 1 then
    if n == 3 then -- lift off
      active, standby = standby, active

      -- always land on a familiar place
      softcut.loop_start(active, 0)
      softcut.loop_end(active, loop_length)

      -- exit the ship, let the memories of the old world fade away
      softcut.play(active, 1)
      delay(function()
        softcut.level(active, level)
      end)
      softcut.level(standby, 0.0)

      -- scout future travels
      world = wrap(world + 1, 1, #worlds)
      file, dur = scan(world)
      delay(function()
        softcut.buffer_read_mono(file, 0, 0, -1, 1, standby)
      end, level_slew / 2)
      durations[standby] = dur
    elseif n == 2 then -- explore
      biome = math.random(math.floor(durations[active]))
      radius = util.clamp(biome + loop_length, 0, durations[active])
      
      softcut.loop_start(active, biome)
      softcut.loop_end(active, radius)
    end
  end
end

function scan(w)
  local p = _path.code .. "nc01-drone/lib/" .. worlds[w] .. ".wav"
  local duration = 0
  
  if util.file_exists(p) == true then
    local ch, samples, samplerate = audio.file_info(p)
    duration = samples / samplerate
  else
    print("File " .. p .. " not found.")
  end
  
  return p, duration
end

function prep_buffers(buffers)
  softcut.buffer_clear()
  
  --[[ there doesn't seem to be a way to fade between buffers, so I will have
       two voices, and fade them in and out appropriately. this means the next
       voice needs to be pre-loaded and ready to go.
    ]]
  for b =  1, #buffers do
    file, dur = scan(b)
    durations[b] = dur
    softcut.buffer_read_mono(file, 0, 0, -1, 1, buffers[b])
    softcut.enable(b, 1)
    softcut.buffer(b, buffers[b])
    softcut.level(b, 0.0)
    softcut.loop(b, 1)
    softcut.loop_start(b, 0)
    softcut.loop_end(b, util.clamp(0 + loop_length, 0, dur))
    softcut.position(b ,1)
    softcut.rate(b, 1.0)
    softcut.fade_time(b, fade_time)
    softcut.level_slew_time(b, level_slew)
  end
end

-- thanks to @zebra for the next couple of utils
function delay(func, time)
  if time == nil then time = 0.005 end
  local m = metro.init(func)
  m:start(time, 1)
end

function wrap (x, min, max)
   local y = x
   while y > max do y = y - max end
   while y < min do y = y + min end
   return y
end

function redraw()
  screen.clear()
  screen.move(64,50)
  screen.aa(1)
  screen.font_face(4)
  screen.font_size(50)
  screen.text_center(".o.")
  screen.update()
end
