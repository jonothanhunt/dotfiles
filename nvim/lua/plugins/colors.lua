-- Gruvbox, matching the tmux status bar and Ghostty's palette.
--
-- transparent_mode lets Ghostty's background show through rather than
-- nvim painting its own. That matters more than usual here: Ghostty's
-- background is Adwaita's #222226, a colour Gruvbox has no equivalent
-- for, so nvim painting its own ground would put a visibly different
-- rectangle inside the terminal. Inheriting it means the editor, the
-- shell in the pane next door and every other app on the desktop are all
-- the same shade, and it follows automatically if that value ever
-- changes in ghostty/config.
return {
    {
        "ellisonleao/gruvbox.nvim",
        lazy = false,
        priority = 1000, -- load before anything that reads highlight groups
        config = function()
            require("gruvbox").setup({
                transparent_mode = true,
                -- "hard" matches the Ghostty theme ("Gruvbox Dark Hard").
                -- Transparency covers the main background, so what this
                -- actually decides is every surface it does not cover —
                -- popups, the sign column, split separators — and hard's
                -- #1d2021 is the closest of the three to the black behind.
                contrast = "hard",
                italic = {
                    comments = true,
                    strings = false,
                    operators = false,
                    emphasis = true,
                    folds = true,
                },
            })
            vim.o.background = "dark"
            vim.cmd.colorscheme("gruvbox")
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                theme = "gruvbox",
                -- Deliberately empty: segments are flat blocks of colour
                -- with no powerline arrows between them. The tmux bar
                -- directly below is built the same way, off this theme's
                -- palette, so the two read as one continuous strip.
                --
                -- Empty strings, not glyphs — a separator here would have
                -- to be matched by hand in tmux.conf, which cannot draw
                -- lualine's arrows without the plugin that owns its bar.
                section_separators = { left = "", right = "" },
                component_separators = { left = "", right = "" },
                globalstatus = true,
            },
        },
    },
}
