-- Cap CSV cell width on screen. Long cells show their first N characters
-- plus "…"; the file text is never changed.
--
-- Works by hiding (concealing) the tail of each cell, so columns stay aligned
-- when the buffer was padded by RainbowAlign. Because you'd be looking at a
-- shortened view, the buffer is locked read-only while this is on, so
-- you can't accidentally save the shortened text. Toggling off restores it.
--
-- Opens automatically for CSVs with cells longer than the width.
-- Usage: :CsvTruncate [width]   toggle (default width 40)
--        <leader>cw             same toggle with default width

local ns = vim.api.nvim_create_namespace("csv_truncate")
local default_width = 40

local function field_list(line, delim, policy)
  local ok, res = pcall(vim.fn["rainbow_csv#preserving_smart_split"], line, delim, policy)
  if ok and res[2] == 0 then
    return res[1]
  end
  -- Broken quotes on this line: fall back to a plain split on the delimiter.
  return vim.split(line, delim, { plain = true })
end

local function disable(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local prev = vim.b[buf].csv_trunc_prev
  if prev then
    vim.bo[buf].modifiable = prev.modifiable
    vim.bo[buf].buftype = prev.buftype
  end
  vim.wo.wrap = vim.b[buf].csv_trunc_wrap
  vim.b[buf].csv_trunc_prev = nil
  vim.b[buf].csv_trunc = nil
end

local function enable(buf, width, auto)
  local ok, dialect = pcall(vim.fn["rainbow_csv#get_current_dialect"])
  if not ok or dialect[2] == "monocolumn" then
    vim.notify("CsvTruncate: not a rainbow CSV buffer", vim.log.levels.WARN)
    return
  end
  local delim, policy = dialect[1], dialect[2]

  -- First pass: work out which cells to shorten, before touching the buffer.
  local marks, truncated_count = {}, 0
  for lnum, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local col = 0
    for _, field in ipairs(field_list(line, delim, policy)) do
      -- Byte offset where a cell's visible width ends. -1 means it's shorter.
      local cut = vim.fn.byteidx(field, width)
      if cut >= 0 and cut < #field then
        local text = vim.trim(field)
        local truncated = text ~= "" and vim.fn.strdisplaywidth(text) > width
        if truncated then
          truncated_count = truncated_count + 1
        end
        -- Truncated: keep width-1 chars and show "…". Otherwise just hide extra padding.
        local start = truncated and vim.fn.byteidx(field, width - 1) or cut
        table.insert(marks, { lnum - 1, col + start, col + #field, truncated and "…" or "" })
      end
      col = col + #field + #delim
    end
  end

  -- Automatic mode: files with no long cells stay normal and editable.
  if auto and truncated_count == 0 then
    return
  end

  vim.b[buf].csv_trunc_prev = { modifiable = vim.bo[buf].modifiable, buftype = vim.bo[buf].buftype }
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nowrite"
  vim.b[buf].csv_trunc = width

  -- Wrapping counts the hidden text, so each cell's tail would still push
  -- the rest of the row onto extra screen lines. Turn it off while active.
  vim.b[buf].csv_trunc_wrap = vim.wo.wrap
  vim.wo.wrap = false

  -- Show the "…" replacement character; level 2 hides the rest.
  vim.wo.conceallevel = 2
  vim.wo.concealcursor = "nvic"

  for _, m in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(buf, ns, m[1], m[2], { end_col = m[3], conceal = m[4] })
  end
  -- Broken-quote files already got their own warning from rainbow_csv.lua.
  if auto and not vim.b[buf].csv_view_only then
    vim.notify(
      ("CSV has cells over %d characters: shown shortened, buffer is read-only.\n"):format(width)
        .. "To edit: run :CsvTruncate (or press <leader>cw) to show full text and unlock,\n"
        .. "make your changes, then :w. Run it again to shorten the view.",
      vim.log.levels.WARN
    )
  end
end

local function toggle(width)
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].csv_trunc then
    disable(buf)
  else
    enable(buf, width or default_width)
  end
end

-- On by default for CSVs that actually have long cells. Scheduled so it runs
-- after the RainbowAlign autocmd, and skipped if already on (FileType can
-- fire twice per open).
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("CsvAutoTruncate", { clear = true }),
  pattern = { "csv", "tsv" },
  callback = function(args)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) and not vim.b[args.buf].csv_trunc then
        enable(args.buf, default_width, true)
      end
    end)
  end,
})

-- wrap/conceal belong to the window, not the buffer. Undo them when leaving
-- a truncated CSV so the next file in that window isn't affected, and set
-- them again if we come back.
local view_group = vim.api.nvim_create_augroup("CsvTruncateView", { clear = true })
vim.api.nvim_create_autocmd("BufWinLeave", {
  group = view_group,
  callback = function(args)
    if vim.b[args.buf].csv_trunc then
      vim.wo.wrap = vim.b[args.buf].csv_trunc_wrap
      vim.wo.conceallevel = 0
    end
  end,
})
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = view_group,
  callback = function(args)
    if vim.b[args.buf].csv_trunc then
      vim.wo.wrap = false
      vim.wo.conceallevel = 2
      vim.wo.concealcursor = "nvic"
    end
  end,
})

vim.api.nvim_create_user_command("CsvTruncate", function(opts)
  toggle(tonumber(opts.args))
end, { nargs = "?" })

vim.keymap.set("n", "<leader>cw", function()
  toggle()
end, { desc = "Toggle CSV cell truncation" })
