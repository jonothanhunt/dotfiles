return {
    'nvim-treesitter/nvim-treesitter',
    build = ":TSUpdate",
    config = function()
	local configs = require("nvim-treesitter.configs")
	configs.setup({
	    highlight = {
		enable = true,
	    },
	    indent = { enable = true },
	    ensure_installed = {
		"lua",
		"tsx",
		"typescript",
		"javascript",
		"astro",
		"html",
		"css",
		"json",
		"bash",
		"python",
		"markdown",
		"markdown_inline",
		"yaml",
	    },
	    auto_install = false,
	})
    end
}
