-- ========================================
-- Section 1: Core Settings
-- Core Keymaps, Options and extra functions
-- =======================================
vim.g.mapleader = " "

local function gh(repo) return "https://github.com/" .. repo end

vim.o.nu = true
vim.o.relativenumber = true

vim.o.undofile = true
vim.o.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.o.confirm = false
vim.o.smartindent = true
vim.o.wrap = false

vim.o.backup = false
vim.o.swapfile = false
vim.o.colorcolumn = "80"
vim.o.guicursor = ""
vim.o.signcolumn = "yes"
vim.o.showtabline = 0

vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.softtabstop = 4

vim.o.termguicolors = false

vim.keymap.set('n', '<leader>v', vim.cmd.vsplit)
vim.keymap.set('n', '<leader>h', vim.cmd.split)

do

  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local stdout = result.stdout or ''
      local output = stderr ~= '' and stderr or stdout
      if output == '' then output = 'No output from build command.' end
      vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
  end

  -- This autocommand runs after a plugin is installed or updated and
  --  runs the appropriate build command for that plugin if necessary.
  --
  -- See `:help vim.pack-events`
  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then return end

      if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
        run_build(name, { 'make' }, ev.data.path)
        return
      end

      if name == 'LuaSnip' then
        if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
        return
      end

      if name == 'nvim-treesitter' then
        if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
        vim.cmd 'TSUpdate'
        return
      end
    end,
  })
end

-- ========================================
-- Section 2: Aesthetics
-- Colorschemes, Noice, Statusline, SmearCursor
-- =======================================
do
	-- Retrieves all the necessary plugins from the correct sources and then we set them all up
	vim.pack.add{ 
		gh 'nvim-mini/mini.statusline',
		gh "sphamba/smear-cursor.nvim",
		{ src = gh "rose-pine/neovim", name = "rose-pine" }
	}

	require("mini.statusline").setup()

	require("rose-pine").setup()
	vim.cmd("colorscheme rose-pine-main")
	require('smear_cursor').setup({})
end

-- ========================================
-- Section 3: Fuzzy Finder
-- Telescope
-- =======================================
do
	local telescope_plugins = {
		gh 'nvim-lua/plenary.nvim',
		gh 'nvim-telescope/telescope.nvim',
		gh 'nvim-telescope/telescope-ui-select.nvim'
	}

	if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end

	vim.pack.add(telescope_plugins)

	local telescope = require("telescope")
	local builtin = require("telescope.builtin")

	telescope.setup {
		extensions = {
			['ui-select'] = { require("telescope.themes").get_dropdown() },
		}
	}

	pcall(telescope.load_extension, 'fzf')
	pcall(telescope.load_extension, 'ui-select')

	vim.keymap.set('n', '<leader>sf', builtin.fd)
	vim.keymap.set('n', '<leader>sk', builtin.keymaps)
	vim.keymap.set('n', '<leader>sgl', builtin.live_grep)
	vim.keymap.set('n', '<leader>sgf', builtin.git_files)
	vim.keymap.set('n', '<leader>sb', builtin.builtin)
	vim.keymap.set('n', '<leader>sh', builtin.help_tags)
	vim.keymap.set({'n', 'v' }, '<leader>sw', builtin.grep_string)
	vim.keymap.set('n', '<leader>sd', builtin.diagnostics)
	vim.keymap.set('n', '<leader>st', builtin.current_buffer_tags)
	vim.keymap.set('n', '<leader>sT', builtin.tags)
	vim.keymap.set('n', '<leader>sm', function()
		builtin.marks {
			mark_type = "local"
		}
	end)
	vim.keymap.set('n', '<leader>sM', function()
		builtin.marks {
			mark_type = "global"
		}
	end)
	vim.keymap.set('n', '<leader>sq', builtin.quickfix)
	vim.keymap.set('n', '<leader>sQ', builtin.quickfixhistory)
	vim.keymap.set({'n', 'v'}, '<leader>sH', builtin.man_pages)

	vim.api.nvim_create_autocmd('LspAttach', {
		group = vim.api.nvim_create_augroup("telescope-lsp-attach", { clear = true }),
		callback = function(event)
			local buf = event.buf

			local map = function(keys, func, mode)
				mode = mode or 'n'
				vim.keymap.set(mode, keys, func, { buffer = buf })
			end

			map('grr', builtin.lsp_references)
			map('grd', builtin.lsp_definitions)
			map('g0', builtin.lsp_document_symbols)
			map('gw', builtin.lsp_dynamic_workspace_symbols)
		end
	})

	vim.keymap.set('n', '<leader>/', function()
		builtin.current_buffer_fuzzy_finder(require("telescope.themes").get_dropdown() {
			previewer = false,
			winblend = 10
		})
	end)

	vim.keymap.set('n', '<leader>s/', function()
		builtin.live_grep {
			grep_open_files = true,
			prompt_title = "Live Grep in Open Files"
		}
	end)

	vim.keymap.set("n", "<leader>sn", "<cmd>e ~/.config/nvim/init.lua<CR>")
	vim.keymap.set("n", "<leader>sc", "<cmd>e ~/.config/ghostty/config.ghostty<CR>")

	vim.keymap.set("n", "<leader><leader>", builtin.buffers)
end

-- ========================================
-- Section 4: LSP and Autocomplete
-- Mason, Blink, Fidget 
-- =======================================
do
	vim.pack.add { 
		gh 'j-hui/fidget.nvim',
		gh 'mason-org/mason-lspconfig.nvim',
		gh 'mason-org/mason.nvim',
		gh 'neovim/nvim-lspconfig',
	}

	vim.pack.add {
		{ src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' },
	}

	vim.pack.add {
		{ src = gh "L3MON4D3/LuaSnip", version = vim.version.range '2.*' }
	}

	vim.api.nvim_create_autocmd('LspAttach', {
		group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
		callback = function(event)
			local map = function (keys, func, mode)
				mode = mode or 'n'
				vim.keymap.set(mode, keys, func, { buffer = event.buf })
end

			map("grD", vim.lsp.buf.declaration)
			map("grn", vim.lsp.buf.rename)
			map("gra", vim.lsp.buf.code_action, { 'n', 'x' })
			local client = vim.lsp.get_client_by_id(event.data.client_id)

			if client and client:supports_method('textDocument/documentHighlight', event.buf) then
				local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
				vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
					buffer = event.buf,
					group = highlight_augroup,
					callback = vim.lsp.buf.document_highlight,
				})

				vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
					buffer = event.buf,
					group = highlight_augroup,
					callback = vim.lsp.buf.clear_references,
				})

				vim.api.nvim_create_autocmd('LspDetach', {
					group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
					callback = function(event2)
						vim.lsp.buf.clear_references()
						vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
					end,
				})
			end
		end
	})


	local servers = {
		clangd = {},
		rust_analyzer = {},
		zls = {},
		pyright = {},
		stylua = {},
		lua_ls = {
			on_init = function(client)
				client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

				if client.workspace_folders then
					local path = client.workspace_folders[1].name
					if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
				end

				local current_settings = client.config.settings --[[@as lspconfig.settings.lua_ls]]
				client.config.settings.Lua = vim.tbl_deep_extend('force', current_settings.Lua, {
					runtime = {
						version = 'LuaJIT',
						path = { 'lua/?.lua', 'lua/?/init.lua' },
					},
					workspace = {
						checkThirdParty = false,
						-- NOTE: this is a lot slower and will cause issues when working on your own configuration.
						--  See https://github.com/neovim/nvim-lspconfig/issues/3189
						library = vim.api.nvim_get_runtime_file('', true),
					},
				})
			end,
			---@type lspconfig.settings.lua_ls
			settings = {
				Lua = {
					format = { enable = false }, -- Disable formatting (formatting is done by stylua)
				},
			},
		}
	}

	local ensure_installed = vim.tbl_keys(servers or {})
	vim.list_extend(ensure_installed, {})

	require('fidget').setup()

	require('mason').setup()



	require("mason-lspconfig").setup {
		automatic_enable = false,
		ensure_installed = ensure_installed
	}

	for name, server in pairs(servers) do
		vim.lsp.config(name, server)
		vim.lsp.enable(name)
	end

	require('LuaSnip').setup()

	require("blink.cmp").setup {
		keymap = { preset = 'default' },

		appearance = {
			nerd_font_variant = "mono"
		},

		completion = { documentation = { auto_show = true, auto_show_delay_ms = 250 } },

		sources = { default = { 'lsp', 'path', 'snippets' } },

		snippets = { preset = 'luasnip' },

		fuzzy = { implementation = "rust" },

		signature = { enabled = true }
	}
end



-- ========================================
-- Section 5: Buffer Jumping and Splits
-- TBD for how I want to handle this
-- =======================================
vim.pack.add { gh 'famiu/bufdelete.nvim' }
vim.keymap.set("n", "<leader>c", function()
	require"bufdelete".bufdelete()
	vim.api.nvim_win_close(0, false)
end)

-- ========================================
-- Section 6: Marks
-- Harpoon, Other Handling TBD
-- =======================================
vim.pack.add { 
	{ src = gh 'ThePrimeagen/harpoon', version = 'harpoon2' }
}

local harpoon = require("harpoon")

-- REQUIRED
harpoon:setup()
-- REQUIRED

vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<C-t>", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<C-n>", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<C-s>", function() harpoon:list():select(4) end)

-- Toggle previous & next buffers stored within Harpoon list
vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end)
vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end)
-- ========================================
-- Section 7: Journaling and Notes
--  TBD
-- =======================================


-- ========================================
-- Section 8: Debugging
--  Nvim-DAP 
-- =======================================


-- ========================================
-- Section 9: Test Runner
-- TBD 
-- =======================================


-- ========================================
-- Section 10: Terminal Integration
--  TBD
-- =======================================


-- ========================================
-- Section 11: File explorer
-- Oil
-- =======================================
vim.pack.add({
    gh 'stevearc/oil.nvim',
	gh 'nvim-tree/nvim-web-devicons'
})

require("oil").setup()
local detail = false
require("oil").setup({
	float = {
		max_height = 0.8,
		max_width = 0.9,
		border = "rounded"
	},
	keymaps = {
		["<leader>."] = {
			desc = "Toggle file detail view",
			callback = function()
				detail = not detail
				if detail then
					require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
				else
					require("oil").set_columns({ "icon" })
				end
			end,
		},
	},
})

vim.keymap.set('n', '<leader>-', require("oil").open_float)
vim.keymap.set('n', '-', vim.cmd.Oil)

