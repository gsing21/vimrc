vim.opt_local.conceallevel = 2
vim.opt_local.concealcursor = "nc"

vim.opt_local.colorcolumn = ""
vim.opt_local.wrap = true
vim.opt_local.spell = true

vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

vim.keymap.set({ "n", "v" }, "j", "gj", { buffer = true, silent = true })
vim.keymap.set({ "n", "v" }, "k", "gk", { buffer = true, silent = true })

