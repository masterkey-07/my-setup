-- Servers that come with their own toolchain (rustup, go, ghcup) aren't installed through Mason
local mason_servers = {
    "basedpyright",
    "bashls",
    "clangd",
    "dockerls",
    "jsonls",
    "lua_ls",
    "marksman",
    "ruff",
    "taplo",
    "ts_ls",
    "yamlls",
}

-- Non-LSP tools from Mason, used by conform.nvim
local mason_tools = {
    "shfmt",
}

local function install_mason_tools()
    local registry = require("mason-registry")
    registry.refresh(function()
        for _, name in ipairs(mason_tools) do
            local package = registry.get_package(name)
            if not package:is_installed() then
                package:install()
            end
        end
    end)
end

local function load_server_configs()
    for _, path in ipairs(vim.api.nvim_get_runtime_file("lua/servers/*.lua", true)) do
        require("servers." .. vim.fn.fnamemodify(path, ":t:r"))
    end
end

return {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
        { "mason-org/mason.nvim", opts = {} },
        "mason-org/mason-lspconfig.nvim",
    },
    config = function()
        require("mason-lspconfig").setup({
            ensure_installed = mason_servers,
            -- Each file in lua/servers/ enables its own server
            automatic_enable = false,
        })
        install_mason_tools()
        load_server_configs()
    end,
}
