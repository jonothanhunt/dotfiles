-- Centers the buffer with empty padding windows on either side, for a
-- readable prose width instead of text running edge-to-edge across a wide
-- terminal. Scoped to markdown only — code still wants the full width.
return {
  "shortcuts/no-neck-pain.nvim",
  ft = "markdown",
  opts = {
    width = 80,
  },
  config = function(_, opts)
    require("no-neck-pain").setup(opts)

    -- `ft`-triggered lazy-loading means this file's own FileType event has
    -- already fired by the time this runs, so the autocmd below won't catch
    -- the buffer that caused the load — enable directly for it here, once.
    require("no-neck-pain").enable()

    -- Every markdown file after the first re-fires FileType, since the
    -- plugin is already loaded by then. `enable()`, not the `:NoNeckPain`
    -- toggle command — toggling would switch it back off on the second file.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        require("no-neck-pain").enable()
      end,
    })
  end,
}
