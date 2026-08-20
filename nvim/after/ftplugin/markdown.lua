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
