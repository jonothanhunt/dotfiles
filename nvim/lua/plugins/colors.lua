-- Dracula, matching the tmux status bar and Ghostty's palette.
--
-- transparent_bg lets Ghostty's background show through rather than
-- nvim painting its own. Both are #282a36, so this is belt and braces —
-- but it also means changing the Ghostty theme later moves nvim with it
-- instead of leaving a mismatched rectangle inside the terminal.
return {
    {
        "Mofiqul/dracula.nvim",
        lazy = false,
        priority = 1000, -- load before anything that reads highlight groups
        config = function()
            require("dracula").setup({
                transparent_bg = true,
                italic_comment = true,
            })
            vim.cmd.colorscheme("dracula")
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                theme = "dracula",
                -- The same powerline glyphs the tmux bar uses, so the
                -- statusline and the status bar directly below it read
                -- as one continuous strip rather than two designs.
                section_separators = { left = "", right = "" },
                component_separators = { left = "", right = "" },
                globalstatus = true,
            },
        },
    },
}
