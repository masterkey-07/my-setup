-- Groups Monokai paints with its solid base2 background, mapped to their foreground.
-- Clearing the background lets kitty's background_opacity (and picom's blur) show
-- through; floats keep their background.
local transparent_group_fg = {
    Normal = "white",
    SignColumn = "white",
    LineNr = "base5",
    CursorLineNr = "orange",
    Terminal = "white",
}

-- The fg must be repeated: monokai re-applies custom_hlgroups to its plugin groups
-- without merging, so a bg-only override would also wipe the foreground
local function transparent_hlgroups(palette)
    local hlgroups = {}
    for group, fg_name in pairs(transparent_group_fg) do
        hlgroups[group] = { fg = palette[fg_name], bg = "NONE" }
    end
    return hlgroups
end

return {
    "tanvirtin/monokai.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        local monokai = require("monokai")
        monokai.setup({ custom_hlgroups = transparent_hlgroups(monokai.classic) })
    end,
}
