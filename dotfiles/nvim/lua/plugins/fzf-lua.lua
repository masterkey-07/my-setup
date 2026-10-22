return {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    keys = {
        { "<leader>ff", "<Cmd>FzfLua files<CR>", desc = "Find files" },
        { "<leader>fg", "<Cmd>FzfLua live_grep<CR>", desc = "Grep" },
        { "<leader>fb", "<Cmd>FzfLua buffers<CR>", desc = "Buffers" },
        { "<leader>fh", "<Cmd>FzfLua helptags<CR>", desc = "Help" },
        { "<leader>fr", "<Cmd>FzfLua oldfiles<CR>", desc = "Recent files" },
        { "<leader>fd", "<Cmd>FzfLua diagnostics_document<CR>", desc = "Diagnostics" },
    },
    opts = {},
}
