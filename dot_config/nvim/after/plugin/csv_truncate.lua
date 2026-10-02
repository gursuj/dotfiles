-- Cap CSV cell width on screen. Long cells show their first N characters
-- plus "…"; the file text is never changed.
--
-- Works by hiding (concealing) the tail of each cell, so columns stay aligned
-- when the buffer was padded by RainbowAlign. Because you'd be looking at a
-- shortened view, the buffer is locked read-only while this is on, so
-- you can't accidentally save the shortened text. Toggling off restores it.
--
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
  vim.b[buf].csv_trunc_prev = nil
  vim.b[buf].csv_trunc = nil
end

local function enable(buf, width)
  local ok, dialect = pcall(vim.fn["rainbow_csv#get_current_dialect"])
  if not ok or dialect[2] == "monocolumn" then
    vim.notify("CsvTruncate: not a rainbow CSV buffer", vim.log.levels.WARN)
    return
  end
  local delim, policy = dialect[1], dialect[2]

  vim.b[buf].csv_trunc_prev = { modifiable = vim.bo[buf].modifiable, buftype = vim.bo[buf].buftype }
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nowrite"
  vim.b[buf].csv_trunc = width

  -- Show the "…" replacement character; level 2 hides the rest.
  vim.wo.conceallevel = 2
  vim.wo.concealcursor = "nvic"

  for lnum, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local col = 0
    for _, field in ipairs(field_list(line, delim, policy)) do
      -- Byte offset where a cell's visible width ends. -1 means it's shorter.
      local cut = vim.fn.byteidx(field, width)
      if cut >= 0 and cut < #field then
        local truncated = vim.trim(field) ~= "" and vim.fn.strdisplaywidth(vim.trim(field)) > width
        -- Truncated: keep width-1 chars and show "…". Otherwise just hide extra padding.
        local start = truncated and vim.fn.byteidx(field, width - 1) or cut
        vim.api.nvim_buf_set_extmark(buf, ns, lnum - 1, col + start, {
          end_col = col + #field,
          conceal = truncated and "…" or "",
        })
      end
      col = col + #field + #delim
    end
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

vim.api.nvim_create_user_command("CsvTruncate", function(opts)
  toggle(tonumber(opts.args))
end, { nargs = "?" })

vim.keymap.set("n", "<leader>cw", function()
  toggle()
end, { desc = "Toggle CSV cell truncation" })
