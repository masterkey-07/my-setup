-- Center screen when jumping
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

-- Buffer navigation
vim.keymap.set("n", "<leader>bn", "<Cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", "<Cmd>bprevious<CR>", { desc = "Previous buffer" })

-- Window navigation with Alt+h/j/k/l; insert and terminal mode leave to normal mode first
vim.keymap.set("n", "<A-h>", "<C-w>h", { desc = "Window left" })
vim.keymap.set("n", "<A-j>", "<C-w>j", { desc = "Window down" })
vim.keymap.set("n", "<A-k>", "<C-w>k", { desc = "Window up" })
vim.keymap.set("n", "<A-l>", "<C-w>l", { desc = "Window right" })
vim.keymap.set({ "i", "t" }, "<A-h>", "<C-\\><C-n><C-w>h", { desc = "Window left" })
vim.keymap.set({ "i", "t" }, "<A-j>", "<C-\\><C-n><C-w>j", { desc = "Window down" })
vim.keymap.set({ "i", "t" }, "<A-k>", "<C-\\><C-n><C-w>k", { desc = "Window up" })
vim.keymap.set({ "i", "t" }, "<A-l>", "<C-\\><C-n><C-w>l", { desc = "Window right" })

-- Terminal
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Leave terminal mode" })
