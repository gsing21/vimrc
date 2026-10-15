-- ========================================
-- Section 1: Core Settings
-- Core Keymaps, Options and extra functions
-- =======================================
vim.g.mapleader = " "

local function gh(repo) return "https://github.com/" .. repo end

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.confirm = false
vim.opt.smartindent = true
vim.opt.wrap = false

vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.colorcolumn = "80"
vim.opt.guicursor = ""
vim.opt.signcolumn = "yes"
vim.opt.showtabline = 0
vim.opt.expandtab = true

vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

vim.opt.termguicolors = true

vim.keymap.set('n', '<leader>v', vim.cmd.vsplit)
vim.keymap.set('n', '<leader>h', vim.cmd.split)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<leader>p", [["_dP]])

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set({ "n", "v" }, "<leader>d", "\"_d")

vim.keymap.set("i", "<C-c>", "<Esc>")

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")



vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },

    -- Can switch between these as you prefer
    virtual_text = true, -- Text shows up at the end of the line
    virtual_lines = false, -- Text shows up underneath the line, with virtual lines

    -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
    jump = {
        on_jump = function(_, bufnr)
            vim.diagnostic.open_float {
                bufnr = bufnr,
                scope = 'cursor',
                focus = false,
            }
        end,
    },
}

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
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
-- Colorschemes, Noice, Statusline, SmearCursor, Treesitter
-- =======================================
do
	-- Retrieves all the necessary plugins from the correct sources and then we set them all up
	vim.pack.add{
		gh 'nvim-mini/mini.statusline',
		gh "sphamba/smear-cursor.nvim",
		{ src = gh "rose-pine/neovim", name = "rose-pine" }
	}

	require("mini.statusline").setup()

	-- require("rose-pine").setup({
	-- 	styles = {
	-- 		italic = false
	-- 	}
	-- })
  vim.pack.add({
    "https://github.com/oskarnurm/koda.nvim",
  })
  -- require("koda").setup({ transparent = true })
  vim.cmd("colorscheme koda")


    
	-- vim.cmd("colorscheme rose-pine-main")
    require("smear_cursor").setup({
        -- enabled = false,
        cursor_color = "#ffffff",

        never_draw_over_target = true,

        smear_insert_mode = false,
        min_vertical_distance_smear = 2,
        min_horizontal_distance_smear = 2,

        time_interval = 17, -- ms
        stiffness = 0.9,
        trailing_stiffness = 0.4,
        damping = 0.99, -- stops bouncing

        -- anticipation = 0.2,
        -- distance_stop_animating = 0.6,
    })
	vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

	-- Ensure basic parsers are installed
	local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'latex' }
	require('nvim-treesitter').install(parsers)

	---@param buf integer
	---@param language string
	local function treesitter_try_attach(buf, language)
		-- Check if the buffer is valid (might not be after install completes)
		if not vim.api.nvim_buf_is_valid(buf) then return end

		-- Check if a parser exists and load it
		if not vim.treesitter.language.add(language) then return end

		-- Enable syntax highlighting and other treesitter features
		vim.treesitter.start(buf, language)

		-- Enable treesitter based folds
		-- For more info on folds see `:help folds`
		-- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
		-- vim.wo.foldmethod = 'expr'

		-- Check if treesitter indentation is available for this language, and if so enable it
		-- in case there is no indent query, the indentexpr will fallback to the vim's built in one
		local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

		-- Enable treesitter based indentation
		if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
	end

	local available_parsers = require('nvim-treesitter').get_available()
	vim.api.nvim_create_autocmd('FileType', {
		callback = function(args)
      if args.match == "tex" then return end
			local buf, filetype = args.buf, args.match

			local language = vim.treesitter.language.get_lang(filetype)
			if not language then return end

			local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

			if vim.tbl_contains(installed_parsers, language) then
				-- Enable the parser if it is already installed
				treesitter_try_attach(buf, language)
			elseif vim.tbl_contains(available_parsers, language) then
				-- If a parser is available in `nvim-treesitter`, auto-install it and enable it after the installation is done
				require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
			else
				-- Try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
				treesitter_try_attach(buf, language)
			end
		end,
	})
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
		builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
			previewer = false,
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

	require('fidget').setup({})

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
vim.pack.add({
    "https://github.com/OXY2DEV/markview.nvim",
})


require("markview").setup{
  latex = {
    enable = false
  }
}

vim.keymap.set('n', '<leader>mt', ':Markview toggle<CR>')
vim.keymap.set('n', '<leader>ms', ':Markview splitToggle<CR>')

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

-- ========================================
-- Section 11: Git and File Tracking
-- gitsigns, Fugitive, undofile
-- =======================================
vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
local gitsigns = require 'gitsigns'
gitsigns.setup {
    signs = {
        add = { text = '+' }, ---@diagnostic disable-line: missing-fields
        change = { text = '~' }, ---@diagnostic disable-line: missing-fields
        delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
        topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
        changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
    },
    on_attach = function(bufnr)
        -- Navigation
        vim.keymap.set('n', ']c', function()
            if vim.wo.diff then
                vim.cmd.normal { ']c', bang = true }
            else
                gitsigns.nav_hunk 'next'
            end
        end, { desc = 'Jump to next git [c]hange', buf = bufnr })

        vim.keymap.set('n', '[c', function()
            if vim.wo.diff then
                vim.cmd.normal { '[c', bang = true }
            else
                gitsigns.nav_hunk 'prev'
            end
        end, { desc = 'Jump to previous git [c]hange', buf = bufnr })

        -- Visual mode actions
        vim.keymap.set('v', '<leader>hs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [s]tage hunk', buf = bufnr })
        vim.keymap.set('v', '<leader>hr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [r]eset hunk', buf = bufnr })
        -- Normal mode actions
        vim.keymap.set('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk', buf = bufnr })
        vim.keymap.set('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk', buf = bufnr })
        vim.keymap.set('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer', buf = bufnr })
        vim.keymap.set('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer', buf = bufnr })
        vim.keymap.set('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk', buf = bufnr })
        vim.keymap.set('n', '<leader>hi', gitsigns.preview_hunk_inline, { desc = 'git preview hunk [i]nline', buf = bufnr })
        vim.keymap.set('n', '<leader>hb', function() gitsigns.blame_line { full = true } end, { desc = 'git [b]lame line', buf = bufnr })
        vim.keymap.set('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index', buf = bufnr })
        vim.keymap.set('n', '<leader>hD', function() gitsigns.diffthis '~' end, { desc = 'git [D]iff against last commit', buf = bufnr })
        vim.keymap.set('n', '<leader>hQ', function() gitsigns.setqflist 'all' end, { desc = 'git hunk [Q]uickfix list (all files in repo)', buf = bufnr })
        vim.keymap.set('n', '<leader>hq', gitsigns.setqflist, { desc = 'git hunk [q]uickfix list (all changes in this file)', buf = bufnr })
        -- Toggles
        vim.keymap.set('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line', buf = bufnr })
        vim.keymap.set('n', '<leader>tw', gitsigns.toggle_word_diff, { desc = '[T]oggle git intra-line [w]ord diff', buf = bufnr })
        -- Text object
        vim.keymap.set({ 'o', 'x' }, 'ih', gitsigns.select_hunk, { desc = 'text object [i]nside [h]unk', buf = bufnr })
    end,
}

