vim.lsp.config("ruff", {
    on_attach = function(client)
        -- basedpyright's hover has the type information; ruff's would only duplicate it
        client.server_capabilities.hoverProvider = false
    end,
})
vim.lsp.enable("ruff")
