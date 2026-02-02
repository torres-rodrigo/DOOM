-- Leader key ==================================================
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Cursor ==================================================
vim.o.guicursor = ""

-- Mouse ==================================================
vim.o.mouse = 'a'

-- UI ==================================================
vim.g.have_nerd_fonts = true

vim.o.number = true
vim.o.relativenumber = true

vim.o.showmode = false

vim.o.signcolumn = "yes"

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.wrap = false

--vim.o.scrolloff = 7

vim.o.laststatus = 3

vim.o.termguicolors = true

vim.o.list = true

vim.o.pumheight = 13
vim.o.pumblend = 15

-- Editing ==================================================
-- vim.o.spelllang = { 'en' } -- not working

vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.expandtab = true
vim.o.smarttab = true

vim.o.shiftwidth = 4
vim.o.shiftround = true

vim.o.smartindent = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.hlsearch = true
vim.o.incsearch = true

vim.o.virtualedit = 'block'

vim.o.inccommand = 'split'

-- Search / Grep ==================================================
vim.o.grepformat = "%f:%l:%c:%m"
vim.o.grepprg    = "rg --vimgrep"

-- Completion ==================================================
vim.o.completeopt = "menu,menuone,noselect" -- "menuone,noselect,fuzzy,nosort"

-- Times ==================================================
vim.o.timeoutlen = 900
vim.o.updatetime = 300

-- Windows / Scrolling ==================================================
vim.o.jumpoptions = "view"
vim.o.winminwidth = 5
vim.o.smoothscroll = true

-- Folds ==================================================
vim.o.foldlevel   = 10
vim.o.foldnestmax = 10
vim.o.foldmethod  = 'indent'
vim.o.foldtext    = ''
