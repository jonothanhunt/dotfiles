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
-- line, not its distance from the cursor. nvim_win_text_height() (0.10+)
-- gives the real screen-row count between two points, folds and all, which
-- is what this is built on — recomputed as a cache on cursor move/scroll
-- rather than inside the statuscolumn expression itself, since that's
-- evaluated per drawn row and the option's own docs warn an expensive
-- per-row expression hurts render performance.

local M = {}

---@type table<integer, table<string, integer>> winid -> "lnum:virtnum" -> signed offset
local cache = {}

--- Signed screen-row distance between two (row, vcol) points, 0-based rows,
--- both directions handled since nvim_win_text_height only measures a range
--- low-to-high.
local function screen_rows_between(win, row0, vcol0, row1, vcol1)
  if row0 == row1 and vcol0 == vcol1 then
    return 0
  end
  local lo_row, lo_vcol, hi_row, hi_vcol, sign
  if row1 > row0 or (row1 == row0 and vcol1 > vcol0) then
    lo_row, lo_vcol, hi_row, hi_vcol, sign = row0, vcol0, row1, vcol1, 1
  else
    lo_row, lo_vcol, hi_row, hi_vcol, sign = row1, vcol1, row0, vcol0, -1
  end
  local h = vim.api.nvim_win_text_height(win, {
    start_row = lo_row,
    start_vcol = lo_vcol,
    end_row = hi_row,
    end_vcol = hi_vcol,
  })
  return sign * h.all
end

function M.recompute(win)
  win = win or vim.api.nvim_get_current_win()
  if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "markdown" then
    return
  end

  local cur = vim.api.nvim_win_get_cursor(win) -- {1-based lnum, 0-based byte col}
  local cur_row0 = cur[1] - 1
  local cur_vcol0 = vim.fn.virtcol({ cur[1], cur[2] + 1 }, false, win) - 1

  local top = vim.fn.line("w0", win)
  local bot = vim.fn.line("w$", win)

  local t = {}
  for lnum = top, bot do
    local row0 = lnum - 1
    -- Distance from the cursor to this line's own first (virtnum 0) row.
    local base = screen_rows_between(win, cur_row0, cur_vcol0, row0, 0)
    local height = vim.api.nvim_win_text_height(win, { start_row = row0, end_row = row0 }).all
    for v = 0, height - 1 do
      -- virtnum always increases going DOWN the screen within one logical
      -- line, regardless of whether that line sits above or below the
      -- cursor — so this is unconditionally + v, never - v. (A line wholly
      -- above the cursor with base = -5 has its virtnum=1 row at -4, one
      -- row CLOSER to the cursor, not -6.)
      t[lnum .. ":" .. v] = base + v
    end
  end
  cache[win] = t
end

--- The 'statuscolumn' expression, called once per drawn row.
function M.render()
  local win = vim.g.statusline_winid
  if vim.v.virtnum == 0 and vim.v.relnum == 0 then
    -- The cursor's own actual row — real file line number, same as native
    -- hybrid number+relativenumber.
    return "%=" .. vim.v.lnum .. " "
  end

  local t = cache[win]
  local offset = t and t[vim.v.lnum .. ":" .. math.max(vim.v.virtnum, 0)]
  if offset == nil or offset == 0 then
    return "%= "
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
