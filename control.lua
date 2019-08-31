--[[
todo
- click on face switches to a moveable frame, closing that switches back to the sprite
]]

WORK_INTERVAL = 1

require("mod-gui")
local floor = math.floor
local ceil = math.ceil
local abs = math.abs
local sqrt = math.sqrt
local insert = table.insert

local function getFuelPercentage(entity)
    local empty_slots = 0
    local potentialFuelvalue = 0
    local currentFuelValue = 0
    local entities = {}

    if entity.train then
        local train = entity.train
        if train.manual_mode or train.speed >= 0 then
            for _, entity in pairs(train.locomotives.front_movers) do
                insert(entities, entity)
            end
        end
        if train.manual_mode or train.speed < 0 then
            for _, entity in pairs(train.locomotives.back_movers) do
                insert(entities, entity)
            end
        end
    else
        insert(entities, entity)
    end


    for _, entity in ipairs(entities) do
        local burner = entity.burner
        if burner then
            local inventory = burner.inventory
            for i = 1, #inventory do
                local slot = inventory[i]
                if slot.valid_for_read then
                    local burnable_name = slot.name
                    local burnable_count = slot.count
                    local burnable_stacksize = game.item_prototypes[burnable_name].stack_size
                    local burnable_fuelvalue = game.item_prototypes[burnable_name].fuel_value

                    potentialFuelvalue = potentialFuelvalue + (burnable_stacksize * burnable_fuelvalue)
                    currentFuelValue = currentFuelValue + (burnable_count * burnable_fuelvalue)
                else
                    empty_slots = empty_slots + 1
                end
            end

            if empty_slots > 0 and #inventory > empty_slots then
                potentialFuelvalue = potentialFuelvalue / (#inventory - empty_slots) * #inventory
            elseif empty_slots == #inventory then
                if burner.currently_burning then
                    potentialFuelvalue = burner.currently_burning.fuel_value * burner.currently_burning.stack_size
                end
            end

            if burner.currently_burning then
                currentFuelValue = currentFuelValue + burner.remaining_burning_fuel
                potentialFuelvalue = potentialFuelvalue + burner.currently_burning.fuel_value
            end
        end
    end

    -- game.print("Empty slots: " .. empty_slots)
    -- game.print("Potential: " .. potentialFuelvalue)
    -- game.print("Current: " .. currentFuelValue)
    -- game.print("Percentage: " .. (100 * currentFuelValue / potentialFuelvalue))

    if potentialFuelvalue == 0 then
        return 0
    end

    if currentFuelValue > potentialFuelvalue then
        return 100
    end

    return 100 * currentFuelValue / potentialFuelvalue

end

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function hideHud(player)
    player.gui.screen["vehiclehud"].destroy();
    global.vehicleHUDs[player.name] = nil
    global.vehicleHUDsCount = global.vehicleHUDsCount - 1
end
local function showHud(player, entity)
    if global.vehicleHUDs[player.name] then
        hideHud(player)
    end

    local playerSettings = settings.get_player_settings(player)

    local hudHeight = playerSettings["vehiclehud-size"].value
    local hudWidth = playerSettings["vehiclehud-size"].value
    local offsetX = playerSettings["vehiclehud-offset-x"].value
    local offsetY = playerSettings["vehiclehud-offset-y"].value
    local anchor = playerSettings["vehiclehud-anchor"].value


    local positionX,positionY = 0,0
    if anchor == "bottom right" then
        positionX = player.display_resolution.width - hudWidth - 25 - offsetX
        positionY = player.display_resolution.height - hudHeight - 25  - offsetY
    elseif anchor == "bottom left" then
        positionX = offsetX
        positionY = player.display_resolution.height - hudHeight - 25 - offsetY
    elseif anchor == "top left" then
        positionX = offsetX
        positionY = offsetY
    elseif anchor == "top right" then
        positionX = player.display_resolution.width - hudWidth - 25 - offsetX
        positionY = offsetY
    end

    local root = player.gui.screen.add{
        type = "frame",
        name = "vehiclehud",
        style = "outer_frame_without_shadow"
    }
    root.style.width = hudWidth
    root.style.height = hudHeight
    root.location = {
        x = positionX,
        y = positionY,
    }

    local gui = root.add{
        type = "empty-widget"
    }

    gui.style.width = hudWidth
    gui.style.height = hudHeight
    gui.drag_target = root

    local face = gui.add{
        type = "sprite",
        name = "vehiclehud-face",
        sprite = "vehiclehud-face-300"
    }
    face.ignored_by_interaction = true
    face.resize_to_sprite = false
    face.style.height = hudHeight
    face.style.width = hudWidth

    local reverse = gui.add{
        type = "sprite",
        name = "vehiclehud-reverse",
        sprite = "vehiclehud-face-300-reverse"
    }
    -- face.drag_target = gui
    reverse.resize_to_sprite = false
    reverse.style.height = hudHeight
    reverse.style.width = hudWidth
    reverse.visible = false
    reverse.ignored_by_interaction = true

    local fuel = gui.add{
        type = "sprite",
        name = "vehiclehud-fuel",
        sprite = "vehiclehud-face-300-fuel"
    }
    -- face.drag_target = gui
    fuel.resize_to_sprite = false
    fuel.style.height = hudHeight
    fuel.style.width = hudWidth
    fuel.visible = false
    fuel.ignored_by_interaction = true


    local speedneedle = gui.add{
        type = "sprite",
        name = "vehiclehud-speedneedle",
        sprite = "vehiclehud-speedneedle-300-0"
    }
    speedneedle.resize_to_sprite = false
    speedneedle.style.height = hudHeight
    speedneedle.style.width = hudWidth
    speedneedle.ignored_by_interaction = true

    local fuelneedle = gui.add{
        type = "sprite",
        name = "vehiclehud-fuelneedle",
        sprite = "vehiclehud-fuelneedle-0"
    }
    fuelneedle.resize_to_sprite = false
    fuelneedle.style.height = hudHeight
    fuelneedle.style.width = hudWidth
    fuelneedle.ignored_by_interaction = true

    global.vehicleHUDs[player.name] = {
        root = root,
        gui = gui,
        entity = entity,
        lastSpeed = 0,
        lastFuelPercent = 0,
        lastFuelChecked = 0
    }
    global.vehicleHUDsCount = global.vehicleHUDsCount + 1
end

local function updateHud(hud)
    local entity = hud.entity
    if not (entity and entity.valid) then return end

    local speedthreshold = 1.38889
    local entitySpeed = entity.speed
    local absSpeed = abs(entitySpeed)
    local toohigh = absSpeed > speedthreshold

    if toohigh then
        -- clicking effect when speed is too high
        absSpeed = clamp(absSpeed, 0, speedthreshold) - (game.tick % 4) * 0.01
    end

    if hud.lastSpeed ~= entitySpeed or toohigh then
        hud.gui["vehiclehud-reverse"].visible = entitySpeed < 0

        local findSpriteId = clamp(floor(absSpeed * 216 * 240 / 300 + 0.5), 0, 240)
        hud.gui["vehiclehud-speedneedle"].sprite = "vehiclehud-speedneedle-300-" .. findSpriteId
        hud.lastSpeed = entitySpeed
    end

    local fuelPercentage
    if game.tick > hud.lastFuelChecked + 120 then
        hud.lastFuelChecked = game.tick
        fuelPercentage = getFuelPercentage(hud.entity)
    else
        fuelPercentage = hud.lastFuelPercent
    end

    if hud.lastFuelPercent ~= fuelPercentage then
        hud.gui["vehiclehud-fuelneedle"].sprite = "vehiclehud-fuelneedle-" .. clamp(floor(fuelPercentage * 1.4 + 0.5), 0, 140)
        hud.gui["vehiclehud-fuel"].visible = fuelPercentage < 10

        hud.lastFuelPercent = fuelPercentage
    end

    if fuelPercentage < 5 then
        hud.gui["vehiclehud-fuel"].visible = (game.tick % 120) > 60
    end
end

local function showVehicleStats(vehicle, player)
    local vehiclePrototype = vehicle.prototype
    local max_speed



    if vehicle.type == "car" then

        local vehicle_weight = vehiclePrototype.weight
        local friction_force = vehiclePrototype.friction_force
        local terrain_friction_modifier = vehiclePrototype.terrain_friction_modifier
        local average_tile_friction_modifier = 1.6 -- Average of tile Friction is a calc of all tiles the bounding box of the vehicle resides over
        local car_friction_modifier = 1
        local sticker_friction_modifier = 1
        local combined_friction = 1-friction_force * (1+terrain_friction_modifier * (average_tile_friction_modifier-1)) * car_friction_modifier * sticker_friction_modifier

        -- game.print("Combined friction: " .. combined_friction)

        local combined_friction_square = combined_friction * combined_friction


        local vehicle_consumption = vehiclePrototype.consumption
        local vehicle_consumption_modifier = 1
        local vehicle_effectivity = vehiclePrototype.effectivity
        local fuel_acceleration_multiplier = 1
        local fuel_top_speed_multiplier = 1
        local speed_bonus = 1
        local sticker_bonus = 1

        -- game.print(serpent.block{vehicle_weight,friction_force,vehicle_consumption,vehicle_effectivity})

        local energy_per_tick = vehicle_consumption * vehicle_consumption_modifier * vehicle_effectivity * fuel_acceleration_multiplier * fuel_top_speed_multiplier * speed_bonus * sticker_bonus

        -- game.print("Energy per tick: " .. energy_per_tick)

        local max_energy = energy_per_tick * combined_friction_square / (1-combined_friction_square)

        -- game.print("Max energy: " .. max_energy)

        max_speed = sqrt(max_energy * 2 / vehicle_weight) * 3.6
    else
        max_speed = vehicle.train.max_forward_speed * 216
    end

    player.print("Max speed: " .. (floor(max_speed*100)/100) .. ' km/h')
end


script.on_init(function()
    global.vehicleHUDs = global.vehicleHUDs or {}
    global.vehicleHUDsCount = global.vehicleHUDsCount or 0

end)

script.on_nth_tick(WORK_INTERVAL, function(event)
    if global.vehicleHUDsCount == 0 then return end

    for _, hud in pairs(global.vehicleHUDs) do
        if hud.entity.valid then
            updateHud(hud)
        else
            hideHud(game.players[_])
        end
    end

end)

script.on_event(defines.events.on_gui_location_changed, function(event)
    local element = event.element
    if element.valid then
        if element.name == "vehiclehud" then
            local playerSettings = settings.get_player_settings(game.players[event.player_index])

            playerSettings["vehiclehud-offset-x"] = {value = element.location.x}
            playerSettings["vehiclehud-offset-y"] = {value = element.location.y}
            playerSettings["vehiclehud-anchor"] = {value = "top left"}

        end
    end
end)
script.on_event(defines.events.on_player_display_resolution_changed, function(event)
-- todo: check position against resolution and make sure the widget is inside the viewport
end)



script.on_event(defines.events.on_player_driving_changed_state, function(event)
    local player = game.players[event.player_index]
    local playerSettings = settings.get_player_settings(player)

    if player.driving then
        showHud(player, event.entity)


        if playerSettings["vehiclehud-stats"].value == "yes" then
            showVehicleStats(event.entity, player)
        end

    else
        hideHud(player)
    end
end)
