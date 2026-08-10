-- Keep CSV columns visually aligned in the editor, but never let the
-- padding spaces leak into the actual file on disk.
--
-- Quirk: RainbowShrink (the align-undo command) strips leading/trailing
-- whitespace from every field, not just the padding RainbowAlign added.
-- Fine for normal CSVs, but if a file intentionally has padded values,
-- this will strip that too.

local csv_align_group = vim.api.nvim_create_augroup("CsvAutoAlign", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = csv_align_group,
  pattern = { "csv", "tsv" },
  callback = function()
    vim.cmd("RainbowAlign")
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = csv_align_group,
  pattern = { "*.csv", "*.tsv" },
  callback = function()
    vim.cmd("RainbowShrink")
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = csv_align_group,
  pattern = { "*.csv", "*.tsv" },
  callback = function()
    vim.cmd("RainbowAlign")
  end,
})
