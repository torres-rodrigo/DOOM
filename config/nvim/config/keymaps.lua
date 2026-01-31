-- Generic keymap helper
-- modes: string or table of strings (e.g., "n" or {"n", "v"})
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
