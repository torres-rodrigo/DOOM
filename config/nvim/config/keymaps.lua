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
map('i', '{', '(<c-g>u', 'Undo break point on {')

-- Normal Mode ==================================================
map('n', '<Esc>', '<cmd>nohlsearch<CR>', 'Clear search')

map('n', 'J', 'm<J`z', 'Join line below')

map('n', '<C-u>', '<C-u>zz', 'Page Up')
map('n', '<C-d>', '<C-d>zz', 'Page Down')

map('n', 'n', 'nzzzv', 'Next search')
map('n', 'N', 'Nzzzv', 'Previous search')

map({'n', 'v', 'x'}, '<leader>y', [["+y]], 'Yank to system clipboard')
map('n', '<leader>Y', [["+Y]], 'Yank line to system clipboard')

map('n', '<C-h>', '<C-w><C-h>', 'Move focus to the left window')
map('n', '<C-l>', '<C-w><C-l>', 'Move focus to the right window')
map('n', '<C-j>', '<C-w><C-j>', 'Move focus to the lower window')
map('n', '<C-k>', '<C-w><C-k>', 'Move focus to the upper window')

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
map('n', '<C-S-h>', '<C-w>H', 'Move window to the left')
map('n', '<C-S-l>', '<C-w>L', 'Move window to the right')
map('n', '<C-S-j>', '<C-w>J', 'Move window to the lower')
map('n', '<C-S-k>', '<C-w>K', 'Move window to the upper')
