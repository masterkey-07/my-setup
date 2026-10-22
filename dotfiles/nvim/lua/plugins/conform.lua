-- Hand-aligned Lua and shell, and notes in the vault, are only formatted on request
local skip_format_on_save = { lua = true, sh = true, markdown = true }

return {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
        {
            "<leader>cf",
            function()
                require("conform").format()
            end,
            mode = { "n", "v" },
            desc = "Format buffer or selection",
        },
    },
    opts = {
        formatters_by_ft = {
            python = { "ruff_organize_imports", "ruff_format" },
            sh = { "shfmt" },
            rust = { "rustfmt" },
            go = { "gofmt" },
        },
        formatters = {
            -- Match the setup scripts: 2-space indent, pipes at the start of continuation lines
            shfmt = { prepend_args = { "-i", "2", "-bn" } },
        },
        -- Filetypes not listed above use their language server's formatter, if it has one
        default_format_opts = { lsp_format = "fallback" },
        format_on_save = function(bufnr)
            if skip_format_on_save[vim.bo[bufnr].filetype] then
                return nil
            end
            return { timeout_ms = 1000 }
        end,
    },
}
