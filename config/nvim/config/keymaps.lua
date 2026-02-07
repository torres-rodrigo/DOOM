-- Generic keymap helper
-- modes: string or table of strings (e.g., 'n' or {'n', 'v'})
-- lhs: the key(s) you want to press
-- rhs: the action (command or function)
-- desc: description of the mapping
-- opts: optional extra options
local function map(modes, lhs, rhs, desc, opts)
    opts = opts or {}
    if desc then
        opts.desc = desc
    end
    vim.keymap.set(modes, lhs, rhs, opts)
end


-- Insert Mode ==================================================
map('i', ',', ',<c-g>u', 'Undo break point on ,')
map('i', '.', '.<c-g>u', 'Undo break point on .')
map('i', ';', ';<c-g>u', 'Undo break point on ;')
map('i', '(', '(<c-g>u', 'Undo break point on (')
map('i', '{', '{<c-g>u', 'Undo break point on {')

map('i', '<C-h>', '<C-w>', 'Delete word backwards')
map('i', '<C-l>', '<C-o>dw', 'Delete word forwards')

-- Normal Mode ==================================================
map('n', '<Esc>', '<cmd>nohlsearch<CR>', 'Clear search')

map('n', 'J', 'm<J`z', 'Join line below')

map('n', '<C-u>', '<C-u>zz', 'Page Up')
map('n', '<C-d>', '<C-d>zz', 'Page Down')

map('n', 'n', 'nzzzv', 'Next search')
map('n', 'N', 'Nzzzv', 'Previous search')

map({'n', 'v', 'x'}, '<leader>y', [["+y]], 'Yank to system clipboard')
map('n', '<leader>Y', [["+Y]], 'Yank line to system clipboard')

map('n', '<leader>o', 'o<Esc>', 'Insert line below normal mode')
map('n', '<leader>O', 'O<Esc>', 'Insert line above normal mode')

map({'n', 'v'}, '<leader>d', [["_d]], 'Delete to NULL')
map({'n', 'v'}, '<leader>c', [["_c]], 'Change to NULL')

map('n', '<leader>vs', ':vsplit ', 'Open vertical split with a file')
map('n', '<leader>hs', ':split ', 'Open horizontal split with a file')

map('n', '<C-h>', '<C-w><C-h>', 'Move focus to the left window')
map('n', '<C-l>', '<C-w><C-l>', 'Move focus to the right window')
map('n', '<C-j>', '<C-w><C-j>', 'Move focus to the lower window')
map('n', '<C-k>', '<C-w><C-k>', 'Move focus to the upper window')

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
map('n', '<C-S-h>', '<C-w>H', 'Move window to the left')
map('n', '<C-S-l>', '<C-w>L', 'Move window to the right')
map('n', '<C-S-j>', '<C-w>J', 'Move window to the lower')
map('n', '<C-S-k>', '<C-w>K', 'Move window to the upper')

map('n', '<C-Up>', ':resize +5<CR>', 'Increase split height')
map('n', '<C-Down>', ':resize -5<CR>', 'Decrease split height')
map('n', '<C-Right>', ':vertical resize +5<CR>', 'Increase split width')
map('n', '<C-Left>', ':vertical resize -5<CR>', 'Decrease split width')

map('v', 'K', ":m '<-2<CR>gv=gv", 'Move selection up')
map('v', 'J', ":m '>+1<CR>gv=gv", 'Move selection down')
map('v', '<', '<gv', 'Indent selection out')
map('v', '>', '>gv', 'Indent selection in')
map('v', '$', '$h', 'Select till end of line leaving the new line')

-- NOT SURE SECTION
-- vim.keymap.set("n", "<leader>sw", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/g<Left><Left><Left>]], { desc = '[S]ubstitute current [W]ord' })

-- vim.keymap.set("n", "<leader>ss", function()
--     local search = vim.fn.input("Search: ")
--     local replace = vim.fn.input("Replace with: ")
--     local command = ":%s/" .. search .. "/" .. replace .. "/g"
--     vim.api.nvim_feedkeys(command, "n", false)
-- end, { desc = '[S]ubstitute [S]earch' })

-- vim.keymap.set("n", "<leader>si", function()
--     local search = vim.fn.input("Search: ")
--     local replace = vim.fn.input("Replace with: ")
--     vim.cmd(":%s/" .. search .. "/" .. replace .. "/gc")
-- end, { desc = '[S]ubstitute [I]nteractive' })

-- vim.keymap.set("n", "<leader>r", '"_diwP', { noremap = true, silent = true, desc = 'Replace word with register'} )

-- vim.keymap.set("x", "<leader>r", '"_dP', { noremap = true, silent = true, desc = 'Replace selection with register' })
