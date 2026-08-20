return {
  {
    -- Declarative installer for standalone tools (formatters, linters)
    -- that mason-lspconfig doesn't cover since they're not LSP servers.
    -- "ruff" isn't listed here — it's dual-purpose and already
    -- ensure_installed by mason-lspconfig in lsp.lua for the LSP side;
    -- this just adds the two that have no LSP role at all.
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "stylua", "prettierd" },
    },
  },
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettierd" },
        javascriptreact = { "prettierd" },
        typescript = { "prettierd" },
        typescriptreact = { "prettierd" },
        astro = { "prettierd" },
        html = { "prettierd" },
        css = { "prettierd" },
        json = { "prettierd" },
        jsonc = { "prettierd" },
        python = { "ruff_format" },
        -- markdown deliberately absent: the wiki's formatting is
        -- obsidian.nvim's concern, not a general prose formatter's.
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },
}
