if Game.IsMultiplayer and CLIENT then return end

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Reactor"], "unsentChanges")

local geigerRadsIndex = {}

Hook.Add("geigercount", "geigereffect", function (effect, deltaTime, item, targets, worldPosition)
  local c = targets[1]
  if not c then
    item.condition = 100
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

-- To Swap out Inactive for Active Fuelrod
Hook.Add("fuelrodswap", "rodswap", function (effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end

  local rod_identifier = rod.Prefab.Identifier.Value
  local rod_conidition = rod.Condition
  local rod_quality = rod.Quality

  Entity.Spawner.AddEntityToRemoveQueue(rod)

  Timer.Wait(function()
    local prefab = ItemPrefab.GetItemPrefab(rod_identifier .. "_active")
    Entity.Spawner.AddItemToSpawnQueue(prefab, item.ownInventory, rod_conidition, rod_quality)
  end,
  100)
end)

-- Fulgurium Fuel rod Special effect AutoReactor Control
Hook.Add("fulguriumrodspecial", "fulguriumrodspecialed", function (effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end
  local light = rod.GetComponentString("LightComponent")

  if light.Range > 0 then
    local reactor = item.GetComponentString("Reactor")
    local correctionvalue = reactor.CorrectTurbineOutput - reactor.TargetTurbineOutput
    if math.abs(correctionvalue) < 15 then return end
    --Host Only!
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
Hook.Add("incendiumrodspecial", "incendiumrodspecialed", function (effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end

  local light = rod.GetComponentString("LightComponent")
  local reactor = item.GetComponentString("Reactor")

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
Hook.Add("meltdownstandard", "rodswap", function (effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end
  local rod_identifier = rod.Prefab.Identifier.Value

  Entity.Spawner.AddEntityToRemoveQueue(rod)

  Timer.Wait(function()
    local prefab = ItemPrefab.GetItemPrefab("molten_rods")
    Entity.Spawner.AddItemToSpawnQueue(prefab, item.ownInventory)
  end,
  100)
end)

-- To swap volatile rods with its critical variant
Hook.Add("meltdownvolatile", "rodswap", function (effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end
  local rod_identifier = rod.Prefab.Identifier.Value

  Entity.Spawner.AddEntityToRemoveQueue(rod)

  Timer.Wait(function()
    local prefab = ItemPrefab.GetItemPrefab("supercritical_fulgurium")
    Entity.Spawner.AddItemToSpawnQueue(prefab, item.ownInventory)
  end,
  100)
end)

-- To swap incendium rods with its critical variant
Hook.Add("meltdownincendium", "rodswap", function (effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end
  local rod_identifier = rod.Prefab.Identifier.Value

  Entity.Spawner.AddEntityToRemoveQueue(rod)

  Timer.Wait(function()
    local prefab = ItemPrefab.GetItemPrefab("supercritical_incendium")
    Entity.Spawner.AddItemToSpawnQueue(prefab, item.ownInventory)
  end,
  100)
end)
