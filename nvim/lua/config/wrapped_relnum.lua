-- Makes the relative-number gutter count DISPLAY rows — including a
-- paragraph's wrapped continuations — instead of logical lines, matching
-- the gj/gk remap in ftplugin/markdown.lua. So the number read off the
-- gutter is exactly how many j/k presses away that row is, wrapped or not.
-- The absolute number on the cursor's own row is untouched: still the real
-- file line number, same as native hybrid number+relativenumber already
-- shows it.
--
-- No single built-in gives this directly: v:relnum counts logical lines,
-- and v:virtnum only tells you a row's wrap-index *within* one logical
-- line, not its distance from the cursor. This walks from the window's top
-- line down, using nvim_win_text_height() (0.10+, folds included) to get
-- each line's own row count, and stamps every row it passes with its actual
-- window row (1-indexed, matching winline()) — then every offset is just
-- that minus the cursor's own winline(). Recomputed as a cache on cursor
-- move/scroll rather than inside the statuscolumn expression itself, since
-- that's evaluated per drawn row and the option's own docs warn an
-- expensive per-row expression hurts render performance.
--
-- An earlier version tried to get the distance directly via
-- nvim_win_text_height's start_vcol/end_vcol, anchoring every line to its
-- own vcol 0 (virtnum 0) and adding the cursor's virtcol as an offset by
-- hand. That doesn't hold: end_vcol's "rounded up to full screen lines"
-- rounding (see :h nvim_win_text_height) doesn't compose the way plain
-- point-to-point distance would suggest, and it showed up as every row
-- from the window top down to the cursor's own row being off by a
-- consistent amount whenever the cursor sat anywhere but a wrapped line's
-- very first row. Walking forward from a known-good anchor (the window
-- top) with whole-line height queries only avoids vcol arithmetic
-- entirely, so there's nothing left to get subtly wrong.

local M = {}

---@type table<integer, table<string, integer>> winid -> "lnum:virtnum" -> signed offset
local cache = {}

function M.recompute(win)
  win = win or vim.api.nvim_get_current_win()
  if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "markdown" then
    return
  end

  local cursor_winline, top, bot = unpack(vim.api.nvim_win_call(win, function()
    return { vim.fn.winline(), vim.fn.line("w0"), vim.fn.line("w$") }
  end))

  local t = {}
  local row_counter = 1 -- window row (1-indexed) of the line currently being walked
  for lnum = top, bot do
    local row0 = lnum - 1
    local height = vim.api.nvim_win_text_height(win, { start_row = row0, end_row = row0 }).all
    for v = 0, height - 1 do
      t[lnum .. ":" .. v] = (row_counter + v) - cursor_winline
    end
    row_counter = row_counter + height
  end
  cache[win] = t
end

--- The 'statuscolumn' expression, called once per drawn row.
function M.render()
  local win = vim.g.statusline_winid
  if vim.v.virtnum < 0 then
    return "%= " -- diff filler / virtual lines: nothing meaningful to show
  end

  local t = cache[win]
  local offset = t and t[vim.v.lnum .. ":" .. vim.v.virtnum]
  if offset == nil then
    return "%= "
  end
  if offset == 0 then
    -- The cursor's actual display row — real file line number here,
    -- wherever within its logical line that happens to be. Was previously
    -- gated on virtnum == 0, which only ever showed it on a wrapped
    -- paragraph's FIRST row regardless of which row the cursor was really
    -- on, leaving the cursor's own row blank instead.
    return "%=" .. vim.v.lnum .. " "
  end
  return "%=" .. math.abs(offset) .. " "
end

function M.setup()
  local group = vim.api.nvim_create_augroup("wrapped_relnum", { clear = true })
  vim.api.nvim_create_autocmd({
    "CursorMoved",
    "CursorMovedI",
    "WinScrolled",
    "TextChanged",
    "TextChangedI",
    "VimResized",
  }, {
    group = group,
    callback = function()
      M.recompute()
    end,
  })

  -- FileType covers the buffer's first window; BufWinEnter covers a later
  -- :split of an already-loaded markdown buffer, since FileType doesn't
  -- re-fire for a buffer that already has its filetype set.
  vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
    group = group,
    pattern = "*",
    callback = function(args)
      if vim.bo[args.buf].filetype == "markdown" then
        vim.wo.statuscolumn = "%!v:lua.require'config.wrapped_relnum'.render()"
        M.recompute()
      end
    end,
  })
end

return M
