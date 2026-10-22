-- Leader must be set before any mapping or plugin reads it
vim.g.mapleader = " "

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.commands")
require("config.lazy")
