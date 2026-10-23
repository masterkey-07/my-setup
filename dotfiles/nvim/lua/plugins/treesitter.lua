local parsers = {
    "bash",
    "c",
    "clojure",
    "cpp",
    "dart",
    "diff",
    "dockerfile",
    "gitcommit",
    "go",
    "haskell",
    "java",
    "javascript",
    "json",
    "kotlin",
    "lua",
    "markdown",
    "markdown_inline",
    "php",
    "python",
    "query",
    "rust",
    "sql",
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
