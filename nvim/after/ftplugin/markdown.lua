-- Markdown is prose, not code — these are scoped to this filetype only.

-- obsidian.nvim's UI (checkbox glyphs, hidden [[link]] / **bold** markup)
-- needs conceallevel > 0 to draw at all.
vim.opt_local.conceallevel = 1
-- ...and by default conceal is suspended on whichever line the cursor sits
-- on, revealing raw ** and [[ ]] there. "nc" keeps it concealed in Normal
-- and Command-line mode too; only Insert mode still shows the raw markup,
-- which is what you want while actually typing it.
vim.opt_local.concealcursor = "nc"

-- Wrap long lines at word boundaries instead of mid-word.
vim.opt_local.linebreak = true

-- Spellcheck prose. Change "en_gb" to "en_us" if that's not your spelling.
vim.opt_local.spell = true
vim.opt_local.spelllang = "en_gb"

-- j/k by display line instead of logical line — with linebreak above, a
-- long paragraph wraps across several screen rows that are all still one
-- logical line, so plain j/k jumps straight past all of them to the next
-- real line. gj/gk move by the row actually on screen instead, count and
-- all: 3j becomes 3gj, so it moves 3 rows down the wrapped paragraph rather
-- than 3 real lines. buffer = true: code files still want real-line j/k
-- (dj/yj with line numbers, etc.), so this only applies here.
vim.keymap.set({ "n", "x" }, "j", "gj", { buffer = true })
vim.keymap.set({ "n", "x" }, "k", "gk", { buffer = true })

-- Makes the gutter's relative numbers match the remap above: they count
-- display rows too, so a wrapped paragraph's continuation rows count as
-- real steps instead of all repeating the same relative number.
require("config.wrapped_relnum").setup()
