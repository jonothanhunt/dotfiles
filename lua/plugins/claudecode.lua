-- Claude Code ↔ Neovim bridge.
--
-- provider = "none" is deliberate. The plugin runs its WebSocket server
-- and MCP tools but never opens a terminal; Claude itself lives in a
-- tmux pane (prefix A), so the session outlives nvim and survives
-- detaching. What this buys over two unconnected panes is context:
-- Claude sees the current file and visual selection, and its proposed
-- edits arrive as real nvim diffs you accept with :w or reject with :q.
--
-- lazy = false because the server has to be listening — and its lockfile
-- written to ~/.claude/ide/ — before Claude starts in the other pane.
-- Lazy-loading on keys would mean no lockfile until the first keypress.
--
-- The upstream default keymaps include <leader>ac/af/ar/aC/am; all of
-- those drive the terminal this config doesn't manage, so they're
-- dropped. Everything left is context and diff review.
return {
    {
        "coder/claudecode.nvim",
        lazy = false,
        opts = {
            terminal = {
                provider = "none",
            },
        },
        keys = {
            { "<leader>a", nil, desc = "AI/Claude Code" },
            { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add buffer to context" },
            { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection" },
            { "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", ft = "NvimTree", desc = "Add file to context" },
            { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
            { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Reject diff" },
            { "<leader>aS", "<cmd>ClaudeCodeStatus<cr>", desc = "Connection status" },
        },
    },
}
