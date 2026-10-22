local parsers = {
    "bash",
    "c",
    "cpp",
    "diff",
    "dockerfile",
    "gitcommit",
    "go",
    "haskell",
    "javascript",
    "json",
    "lua",
    "markdown",
    "markdown_inline",
    "python",
    "query",
    "rust",
    "toml",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "yaml",
}

return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").install(parsers)

        -- Folding comes from 'foldexpr' in options.lua; this only turns on highlighting
        vim.api.nvim_create_autocmd("FileType", {
            desc = "Treesitter highlighting",
            callback = function(args)
                pcall(vim.treesitter.start, args.buf)
            end,
        })
    end,
}
