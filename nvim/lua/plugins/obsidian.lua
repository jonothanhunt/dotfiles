-- lazy.nvim plugin spec for the wiki. Goes in your dotfiles (e.g.
-- ~/.config/nvim/lua/plugins/obsidian.lua), NOT in the wiki — lazy resolves
-- plugin specs at startup, long before a wiki directory is the cwd.
--
-- Deliberately no `opts`/`config` here: every wiki-specific setting lives in
-- the wiki's own `.nvim.lua`, which calls `require("obsidian").setup()`
-- itself. Setting options in both places is how they drift.
return {
  -- The community fork. The original epwalsh/obsidian.nvim is unmaintained,
  -- and the fork has since renamed enough options (`frontmatter.enabled`,
  -- `open.func`) and commands (`:Obsidian <subcommand>`) that they are not
  -- drop-in interchangeable.
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- latest release rather than main
  -- Loaded explicitly by the wiki's .nvim.lua, so no ft/cmd trigger here.
  lazy = true,
}
