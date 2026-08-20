vim.opt.number = true
vim.opt.cursorline = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 4
vim.opt.scrolloff = 8

-- One line per wheel event, down from the ver:3 default. tmux forwards
-- mouse events straight through when nvim is on the alternate screen,
-- so without this the editor kept scrolling 3x while the shell did 1.
-- Ghostty's mouse-scroll-multiplier is the knob for overall speed.
vim.opt.mousescroll = "ver:1,hor:6"

-- Auto-source a `.nvim.lua` from a directory's own root when opened, if trusted
-- (prompts once per file via :trust). Lets a project (e.g. a wiki repo) carry
-- its own plugin config instead of dotfiles hardcoding a path to it.
vim.opt.exrc = true

-- Persist undo history to disk, so it survives closing and reopening a file.
vim.opt.undofile = true

-- Case-insensitive search, except when the pattern itself has a capital
-- letter in it — then go case-sensitive.
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- New vertical/horizontal splits open to the right / below rather than
-- the left / above, matching where you'd expect them.
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Default (4000ms) is how long nvim waits before firing CursorHold and
-- writing swap files — LSP diagnostics and gitsigns both key off it, and
-- 4s reads as "broken" for both. 250ms is the common lower bound before
-- it starts costing noticeable CPU on every pause.
vim.opt.updatetime = 250

-- Reserve the gutter's diagnostic-sign column always, not only when a
-- sign is present — otherwise text visibly shifts left/right as
-- diagnostics come and go.
vim.opt.signcolumn = "yes"
