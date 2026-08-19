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
