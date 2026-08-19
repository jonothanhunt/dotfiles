return {
  "epwalsh/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  init = function()
    -- obsidian.nvim's UI (checkbox glyphs, hidden [[link]] / **bold** markup)
    -- needs conceallevel > 0. Scoped to markdown only, not a global option.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        vim.opt_local.conceallevel = 1
      end,
    })
  end,
  -- No `opts` here on purpose: this only makes the plugin available for
  -- markdown files. Actual vault config (workspace path, notes dir, etc.)
  -- lives in each vault's own `.nvim.lua`, loaded via 'exrc' — not here,
  -- so this file never needs to know where any particular vault lives.
}
