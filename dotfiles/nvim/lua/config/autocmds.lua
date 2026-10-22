vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight yanked text",
    callback = function()
        vim.hl.on_yank()
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    desc = "Spell check and soft wrap for prose",
    pattern = { "markdown", "gitcommit" },
    callback = function()
        vim.opt_local.spell = true
        vim.opt_local.wrap = true
    end,
})

vim.api.nvim_create_autocmd("LspAttach", {
    desc = "Built-in LSP completion",
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
        end
    end,
})
