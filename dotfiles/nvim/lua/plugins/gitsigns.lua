-- Gutter markers only; diffs and merges happen in VS Code
return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
}
