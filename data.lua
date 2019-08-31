local mydata = {
    {
        type = "sprite",
        name = "vehiclehud-face-300",
        filename = "__vehiclehud__/sprites/face.png",
        flags={"gui"},
        width = 300,
        height = 300
    },
    {
        type = "sprite",
        name = "vehiclehud-face-300-reverse",
        filename = "__vehiclehud__/sprites/reverse.png",
        flags={"gui"},
        width = 300,
        height = 300
    },
    {
        type = "sprite",
        name = "vehiclehud-face-300-fuel",
        filename = "__vehiclehud__/sprites/fuel.png",
        flags={"gui"},
        width = 300,
        height = 300
    },

}

for i=0,240,1 do
    table.insert(mydata, {
        type = "sprite",
        name = "vehiclehud-speedneedle-300-" .. i,
        filename = "__vehiclehud__/sprites/speedneedle/" .. i .. ".png",
        flags={"gui"},
        width = 300,
        height = 300
    }
    )
end

for i=0,140,1 do
    table.insert(mydata, {
        type = "sprite",
        name = "vehiclehud-fuelneedle-" .. i,
        filename = "__vehiclehud__/sprites/fuelneedle/" .. i .. ".png",
        flags={"gui"},
        width = 300,
        height = 300
    }
    )
end

data:extend(mydata)
-- data.raw.car["car"].friction = 0.01