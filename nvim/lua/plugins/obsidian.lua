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
  opts = {
    workspaces = {
      {
        name = "wiki",
        path = "~/Documents/personal/wiki",
      },
    },
    notes_subdir = "notes",
    new_notes_location = "notes_subdir",
    note_id_func = function(title)
      if title ~= nil then
        return title
      end
      return tostring(os.time())
    end,
    disable_frontmatter = false,
  },
}
