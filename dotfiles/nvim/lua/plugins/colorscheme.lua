-- Plain Monokai background, to match VS Code's default Monokai
return {
    "tanvirtin/monokai.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        require("monokai").setup({})
    end,
}
