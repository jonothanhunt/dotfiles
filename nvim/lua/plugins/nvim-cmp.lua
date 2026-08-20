return {
  "hrsh7th/nvim-cmp",
  lazy = true,
  ft = "markdown",
  config = function()
    vim.opt.completeopt = { "menu", "menuone", "noselect" }

    local cmp = require("cmp")
    cmp.setup({
      mapping = cmp.mapping.preset.insert({
        ["<Tab>"] = cmp.mapping.confirm({ select = true }),
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-e>"] = cmp.mapping.abort(),
      }),
      -- No sources declared here: obsidian.nvim registers itself as a cmp
      -- source automatically inside vault markdown buffers (triggered by
      -- typing "[[", "[", or "#"). Nothing else uses nvim-cmp yet.
      sources = {},
    })
  end,
}
