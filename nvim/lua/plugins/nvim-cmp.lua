return {
  {
    -- Not nested under nvim-cmp's own (lazy, InsertEnter-gated)
    -- dependencies: lsp.lua needs to require() this at startup, before
    -- InsertEnter has necessarily fired, to advertise completion
    -- capabilities to every server. It's a tiny library with no real
    -- cost to just always having it on the runtimepath.
    "hrsh7th/cmp-nvim-lsp",
    lazy = false,
  },
  {
    "hrsh7th/nvim-cmp",
    lazy = true,
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-path",
    },
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
        -- obsidian.nvim adds itself as an extra source automatically
        -- inside vault markdown buffers (triggered by "[[", "[", or
        -- "#") — it doesn't need an entry here, only nvim_lsp/path do.
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "path" },
        }),
      })
    end,
  },
}
