if Game.IsMultiplayer and CLIENT then return end

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Reactor"], "unsentChanges")

local geigerRadsIndex = {}

Hook.Add("geigercount", "geigereffect", function(effect, deltaTime, item, targets, worldPosition)
  local c = targets[1]
  if not c then
    item.condition = 101
    return
  end

  if not geigerRadsIndex[item] then
    geigerRadsIndex[item] = 0
  end

  local r = c.CharacterHealth.GetAffliction("radiationgeiger")
  local rads = 0
  if r then
    rads = r.Strength
  end

  local deltaRads = math.max(rads - geigerRadsIndex[item], 0)
  item.condition = 100 - (deltaRads * 10)
  geigerRadsIndex[item] = rads
end)

function replaceEntity(current, prefab, ...)
  local args = {...}

  -- XXX: this is a workaround for a race condition where `Entity.Spawner` is
  -- initialized after Luatrauma invokes our `<LuaHook>`s.
  if not Entity.Spawner then
    -- Reschedule it to run on the next frame... hopefully it will be initialized then
    Timer.Wait(function()
      replaceEntity(current, prefab, unpack(args))
    end, 35)
    return
  end

  Entity.Spawner.AddEntityToRemoveQueue(current)
  -- This needs to be done on the next tick because Barotrauma processes
  -- the spawn queue before the remove queue, which could result in the
  -- item container overflowing.
  Timer.Wait(function()
    Entity.Spawner.AddItemToSpawnQueue(prefab, unpack(args))
  end, 35)
end

-- To Swap out Inactive for Active Fuelrod
Hook.Add("fuelrodswap", "rodswap", function(effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end

  local prefab = ItemPrefab.GetItemPrefab(rod.Prefab.Identifier.Value .. "_active")
  replaceEntity(rod, prefab, item.ownInventory, rod.Condition, rod.Quality)
end)

-- Fulgurium Fuel rod Special effect AutoReactor Control
Hook.Add("fulguriumrodspecial", "fulguriumrodspecialed", function(effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end
  local light = rod:GetComponentString("LightComponent")

  if light.Range > 0 then
    local reactor = item:GetComponentString("Reactor")
    local correctionvalue = reactor.CorrectTurbineOutput - reactor.TargetTurbineOutput
    if math.abs(correctionvalue) < 15 then return end
    -- Host Only!
    if correctionvalue > 0 then
      reactor.TargetTurbineOutput = reactor.TargetTurbineOutput + 5
    else
      reactor.TargetTurbineOutput = reactor.TargetTurbineOutput - 5
    end
    rod.Condition = rod.Condition - 15
    reactor.unsentChanges = true
  end
end)

local heatspikePrefab = ItemPrefab.GetItemPrefab("heatspikeemitter")

-- Incendium Fuel rod Special effect, Uncontrolled Reactor Temp! + Spawning "heat spikes"
Hook.Add("incendiumrodspecial", "incendiumrodspecialed", function(effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end

  local light = rod:GetComponentString("LightComponent")
  local reactor = item:GetComponentString("Reactor")

  -- The higher the number, the worse it is!
  local luckynumber = math.random(1000)

  if light.Range < 300 then
    if luckynumber > 950 then
      reactor.Temperature = reactor.Temperature + 30
      reactor.unsentChanges = true
      rod.Condition = rod.Condition - 1
    elseif luckynumber > 700 then
      reactor.Temperature = reactor.Temperature + 20
      reactor.unsentChanges = true
      rod.Condition = rod.Condition - 0.5
    end
  elseif light.Range < 450 then
    if luckynumber > 995 then
      Entity.Spawner.AddItemToSpawnQueue(heatspikePrefab, rod.ownInventory, nil, nil, nil, false)
      rod.Condition = rod.Condition - 5
    elseif luckynumber > 900 then
      reactor.Temperature = reactor.Temperature + 30
      reactor.unsentChanges = true
      rod.Condition = rod.Condition - 1
    elseif luckynumber > 700 then
      reactor.Temperature = reactor.Temperature + 20
      reactor.unsentChanges = true
      rod.Condition = rod.Condition - 0.5
    end
  else
    if luckynumber > 950 then
      Entity.Spawner.AddItemToSpawnQueue(heatspikePrefab, rod.ownInventory, nil, nil, nil, false)
      rod.Condition = rod.Condition - 5
    elseif luckynumber > 800 then
      reactor.Temperature = reactor.Temperature + 30
      reactor.unsentChanges = true
      rod.Condition = rod.Condition - 1
    elseif luckynumber > 400 then
      reactor.Temperature = reactor.Temperature + 20
      reactor.unsentChanges = true
      rod.Condition = rod.Condition - 0.5
    end
  end
end)

-- To swap standard rods with corium
local moltenRodPrefab = ItemPrefab.GetItemPrefab("molten_rods")
Hook.Add("meltdownstandard", "rodswap", function(effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end
  replaceEntity(rod, moltenRodPrefab, item.ownInventory)
end)

-- To swap volatile rods with its critical variant
local criticalFulguriumPrefab = ItemPrefab.GetItemPrefab("supercritical_fulgurium")
Hook.Add("meltdownvolatile", "rodswap", function(effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end
  replaceEntity(rod, criticalFulguriumPrefab, item.ownInventory)
end)

-- To swap incendium rods with its critical variant
local criticalIncendiumPrefab = ItemPrefab.GetItemPrefab("supercritical_incendium")
Hook.Add("meltdownincendium", "rodswap", function(effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end
  replaceEntity(rod, criticalIncendiumPrefab, item.ownInventory)
end)
