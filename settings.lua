data:extend({
    {
        type = "int-setting",
        name = "vehiclehud-size",
        setting_type = "runtime-per-user",
        default_value = 200,
        allowed_values = {100,200,300}
    },
    {
        type = "string-setting",
        name = "vehiclehud-anchor",
        setting_type = "runtime-per-user",
        default_value = "top right",
        allowed_values = {"top left", "top right", "bottom right", "bottom left"}
    },
    {
        type = "int-setting",
        name = "vehiclehud-offset-x",
        setting_type = "runtime-per-user",
        default_value = 400,
    },
    {
        type = "int-setting",
        name = "vehiclehud-offset-y",
        setting_type = "runtime-per-user",
        default_value = 100,
    },
    {
        type = "string-setting",
        name = "vehiclehud-stats",
        setting_type = "runtime-per-user",
        default_value = "yes",
        allowed_values = {"no","yes"}
    },

})