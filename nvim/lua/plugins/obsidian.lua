return {
  "epwalsh/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  -- No `opts` here on purpose: this only makes the plugin available for
  -- markdown files. Actual vault config (workspace path, notes dir, etc.)
  -- lives in each vault's own `.nvim.lua`, loaded via 'exrc' — not here,
  -- so this file never needs to know where any particular vault lives.
  --
  -- Markdown-wide settings (conceallevel, spell, etc.) live in
  -- after/ftplugin/markdown.lua, nvim's own convention for this — not here.
}
