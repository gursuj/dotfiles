-- ========================================================================== --
-- ==                           EDITOR SETTINGS                            == --
-- ========================================================================== --

-- Learn more about Neovim lua api
-- https://neovim.io/doc/user/lua-guide.html
-- https://vonheikemen.github.io/devlog/tools/build-your-first-lua-config-for-neovim/

vim.o.mouse = 'r' -- disables mouse right click. also allows ctrl-clicking links
vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hlsearch = false
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.showmode = false
vim.o.termguicolors = true
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.signcolumn = 'yes'
vim.o.winborder = 'rounded'

-- Space as leader key
vim.g.mapleader = vim.keycode('<Space>')

-- Basic clipboard interaction
vim.keymap.set({'n', 'x'}, '<leader>y', '"+y', {desc = 'Copy to clipboard'})
vim.keymap.set({'n', 'x'}, '<leader>p', '"+p', {desc = 'Paste clipboard content'})

vim.api.nvim_create_autocmd({'BufWinEnter'}, {
  -- group = 'userconfig',
  desc = 'remember cursor position when reopening file',
  pattern = '*',
  command = 'silent! normal! g`"zv',
})

-- ========================================================================== --
-- ==                               PLUGINS                                == --
-- ========================================================================== --

local mini = {}

mini.branch = 'main'
mini.packpath = vim.fn.stdpath('data') .. '/site'

function mini.require_deps()
  local mini_path = mini.packpath .. '/pack/deps/start/mini.nvim'

  if not vim.uv.fs_stat(mini_path) then
    print('Installing mini.nvim....')
    vim.fn.system({
      'git',
      'clone',
      '--filter=blob:none',
      'https://github.com/nvim-mini/mini.nvim',
      string.format('--branch=%s', mini.branch),
      mini_path
    })

    vim.cmd('packadd mini.nvim | helptags ALL')
  end

  local ok, deps = pcall(require, 'mini.deps')
  if not ok then
    return {}
  end

  return deps
end

local MiniDeps = mini.require_deps()
if not MiniDeps.setup then
  return
end

-- See :help MiniDeps.config
MiniDeps.setup({
  path = {
    package = mini.packpath,
  },
})

MiniDeps.add('folke/tokyonight.nvim')
MiniDeps.add('folke/which-key.nvim')
MiniDeps.add('VonHeikemen/ts-enable.nvim')
MiniDeps.add('neovim/nvim-lspconfig')
MiniDeps.add("mbbill/undotree")
MiniDeps.add("tpope/vim-fugitive")
MiniDeps.add("mechatroner/rainbow_csv")
MiniDeps.add("OXY2DEV/markview.nvim")
MiniDeps.add({
  source = 'nvim-mini/mini.nvim',
  checkout = mini.branch,
})
MiniDeps.add({
  source = 'nvim-treesitter/nvim-treesitter',
  checkout = 'main',
  hooks = {
    post_checkout = function()
      vim.cmd.TSUpdate()
    end,
  },
})

-- ========================================================================== --
-- ==                         PLUGIN CONFIGURATION                         == --
-- ========================================================================== --

-- commenting out both to use zed's current theme instead
-- vim.cmd.colorscheme('peachpuff') -- light theme
-- vim.cmd.colorscheme('tokyonight-night')

vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir"
vim.opt.undofile = true

-- See :help MiniIcons.config
-- Change style to 'glyph' if you have a font with fancy icons
require('mini.icons').setup({style = 'ascii'})

-- See :help MiniSurround.config
require('mini.surround').setup({})

-- See :help MiniNotify.config
require('mini.notify').setup({
  lsp_progress = {enable = false},
})

-- See :help MiniBufremove.config
require('mini.bufremove').setup({})

-- Close buffer and preserve window layout
vim.keymap.set('n', '<leader>bc', '<cmd>lua pcall(MiniBufremove.delete)<cr>', {desc = 'Close buffer'})

-- See :help MiniFiles.config
local mini_files = require('mini.files')
mini_files.setup({
	mappings = {
		go_in       = '<CR>',
		go_in_plus  = 'l',
	}
})

-- Toggle file explorer
-- See :help MiniFiles-navigation
vim.keymap.set('n', '<leader>e', function()
  if mini_files.close() then
    return
  end

  mini_files.open(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
end, {desc = 'File explorer (cwd)'})

-- launch explorer in dir from which nvim was launched
-- hmm this seems to work similar to above so I guess can be used as defdault? 
vim.keymap.set('n', '<leader>E', function()
  if mini_files.close() then
    return
  end

  mini_files.open()
end, {desc = 'File explorer'})

-- See :help MiniPick.config
require('mini.pick').setup({})

-- See available pickers
-- :help MiniPick.builtin
-- :help MiniExtra.pickers
vim.keymap.set('n', '<leader>?', '<cmd>Pick oldfiles<cr>', {desc = 'Search file history'})
vim.keymap.set('n', '<leader><space>', '<cmd>Pick buffers<cr>', {desc = 'Search open files'})
vim.keymap.set('n', '<leader>ff', '<cmd>Pick files<cr>', {desc = 'Search all files'})
vim.keymap.set('n', '<leader>fg', '<cmd>Pick grep_live<cr>', {desc = 'Search in project'})
vim.keymap.set('n', '<leader>fd', '<cmd>Pick diagnostic<cr>', {desc = 'Search diagnostics'})
vim.keymap.set('n', '<leader>fs', '<cmd>Pick buf_lines<cr>', {desc = 'Buffer local search'})

-- See :help MiniStatusline.config
require('mini.statusline').setup({})

-- See :help MiniExtra
require('mini.extra').setup({})

-- See :help MiniSnippets.config
require('mini.snippets').setup({})

-- See :help MiniCompletion.config
require('mini.completion').setup({
  lsp_completion = {
    source_func = 'omnifunc',
    auto_setup = false,
  },
})

-- markview.nvim: hybrid mode keeps the current line raw for editing,
-- rendered lines everywhere else. See :h markview.nvim
require('markview').setup({
  preview = {
    filetypes = { 'markdown', 'quarto', 'rmd' },
    modes = { 'n', 'no', 'c' },
    hybrid_modes = { 'n' }, -- hybrid (linewise) rendering in normal mode
    icon_provider = 'mini',
  },
})

-- See :help which-key.nvim-which-key-setup
require('which-key').setup({
  icons = {
    mappings = false,
    keys = {
      Space = 'Space',
      Esc = 'Esc',
      BS = 'Backspace',
      C = 'Ctrl-',
    },
  },
})

require('which-key').add({
  {'<leader>f', group = 'Fuzzy Find'},
  {'<leader>b', group = 'Buffer'},
})

-- Treesitter setup
-- NOTE: the list of supported parsers is in the documentation:
-- https://github.com/nvim-treesitter/nvim-treesitter/blob/main/SUPPORTED_LANGUAGES.md
local ts_parsers = {'lua', 'vim', 'vimdoc', 'c', 'query', 'markdown', 'markdown_inline', 'yaml'}

-- See :help ts-enable-config
vim.g.ts_enable = {
  parsers = ts_parsers,
  auto_install = true,
  highlights = true,
}

-- LSP setup
vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(event)
    local opts = {buffer = event.buf}
    vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
    vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
    vim.keymap.set('n', 'grd', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
    vim.keymap.set({'n', 'x'}, 'gq', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)

    local id = vim.tbl_get(event, 'data', 'client_id')
    local client = id and vim.lsp.get_client_by_id(id)

    if client and client:supports_method('textDocument/completion') then
      vim.bo[event.buf].omnifunc = 'v:lua.MiniCompletion.completefunc_lsp'
    end
  end,
})

