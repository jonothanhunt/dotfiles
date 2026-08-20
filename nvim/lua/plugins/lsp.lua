return {
  {
    "williamboman/mason.nvim",
    config = true,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    -- mason-lspconfig installs each server via mason, then calls
    -- vim.lsp.enable() for it automatically (default behaviour) — no
    -- imperative per-server .setup{} calls needed, that's the old
    -- lspconfig-only pattern from before Neovim 0.11 had native LSP config.
    opts = {
      ensure_installed = {
        "ts_ls", -- TypeScript / JavaScript / TSX
        "astro",
        "html",
        "cssls",
        "tailwindcss",
        "jsonls",
        "lua_ls", -- also covers editing this config
        "bashls",
        "pyright", -- Python types
        "ruff", -- Python lint + format, replaces flake8/black/isort
      },
    },
    config = function(_, opts)
      -- lua_ls doesn't know `vim` is a real global inside an nvim config
      -- (it's only injected at runtime) and flags every use of it unless
      -- told. This has to be registered before the server starts.
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
          },
        },
      })

      require("mason-lspconfig").setup(opts)
    end,
  },
  {
    -- Second spec entry for a plugin already declared above (as a
    -- dependency) — lazy.nvim merges these by name, this just adds an
    -- `init` that only needs to run once regardless of which server
    -- ends up starting first: diagnostic UI config, plus the one LSP
    -- keymap Neovim doesn't already bind by default (see comment below).
    "neovim/nvim-lspconfig",
    init = function()
      -- Advertise nvim-cmp's extended completion capabilities to every
      -- server, so completion candidates actually flow through to it
      -- (without this, servers still work, they just quietly offer a
      -- more limited completion response than they're capable of).
      local cmp_ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if cmp_ok then
        vim.lsp.config("*", { capabilities = cmp_lsp.default_capabilities() })
      end

      vim.diagnostic.config({
        severity_sort = true,
        underline = true,
        signs = true,
        virtual_text = { prefix = "●", spacing = 2 },
        float = { border = "rounded", source = true },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf }
          -- gO, grr, gra, grn, gri, grt and <C-s> (insert mode) are already
          -- Neovim 0.11 built-in defaults once a client attaches. K isn't.
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        end,
      })
    end,
  },
}
