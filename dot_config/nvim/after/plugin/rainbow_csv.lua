-- Keep CSV columns visually aligned in the editor, but never let the
-- padding spaces leak into the actual file on disk.
--
-- Quirk: RainbowShrink (the align-undo command) strips leading/trailing
-- whitespace from every field, not just the padding RainbowAlign added.
-- Fine for normal CSVs, but if a file intentionally has padded values,
-- this will strip that too.

-- RainbowAlign/Shrink throw on malformed CSVs (e.g. unbalanced quotes).
-- Wrap in pcall so a bad file never shows a raw stack trace.
local function try(cmd)
  local ok, err = pcall(vim.cmd, cmd)
  if ok then
    return true
  end
  -- FileType can fire twice per open; a second align is harmless.
  if tostring(err):find("already aligned", 1, true) then
    return true
  end
  -- Keep only the plugin's own message, e.g. "Unable to allign: ... line 5".
  return false, tostring(err):match("Unable[^\n]*") or tostring(err)
end

-- Fallback for CSVs with broken quotes: align by splitting on every
-- delimiter (the "simple" policy) so the file is still readable. This can
-- split cells that contain commas, so the buffer is locked read-only. That
-- stops padded or trimmed text from ever being saved back to the file.
local function align_view_only(reason)
  local ok, delim = pcall(function()
    return vim.fn["rainbow_csv#get_current_dialect"]()[1]
  end)
  if not ok or delim == "" then
    delim = ","
  end
  local ft = vim.fn["rainbow_csv#dialect_to_ft"](delim, "simple", "")
  vim.fn["rainbow_csv#ensure_syntax_exists"](ft, delim, "simple", "")
  vim.bo.syntax = ft
  local aligned = try("RainbowAlign")
  vim.b.csv_view_only = true
  vim.bo.modifiable = false
  vim.bo.buftype = "nowrite"
  vim.notify(
    "CSV has broken quoting: " .. reason .. "\n"
      .. (aligned and ("Showing a read-only preview (split on every '" .. delim .. "').\n")
        or "Could not align it at all.\n")
      .. "Fix the quotes in the source file to edit and save it here.",
    vim.log.levels.WARN
  )
end

local csv_align_group = vim.api.nvim_create_augroup("CsvAutoAlign", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = csv_align_group,
  pattern = { "csv", "tsv" },
  callback = function()
    if vim.b.csv_view_only then
      return
    end
    local ok, reason = try("RainbowAlign")
    if not ok then
      align_view_only(reason)
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = csv_align_group,
  pattern = { "*.csv", "*.tsv" },
  callback = function()
    try("RainbowShrink")
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = csv_align_group,
  pattern = { "*.csv", "*.tsv" },
  callback = function()
    try("RainbowAlign")
  end,
})
