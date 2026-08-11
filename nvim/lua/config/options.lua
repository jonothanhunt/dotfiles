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
