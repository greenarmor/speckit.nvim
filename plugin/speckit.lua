if vim.g.loaded_speckit then
  return
end
vim.g.loaded_speckit = true

local ok, speckit = pcall(require, "speckit")
if not ok then
  return
end

vim.api.nvim_create_user_command("SpecKitList", function()
  local kits = speckit.available()
  vim.notify("SpecKit available: " .. table.concat(kits, ", "), vim.log.levels.INFO)
end, {})

vim.api.nvim_create_user_command("SpecKitShow", function(opts)
  local name = opts.fargs[1]
  if not name then
    vim.notify("Usage: :SpecKitShow <kit>", vim.log.levels.WARN)
    return
  end
  local data = speckit.get(name)
  if not data then
    vim.notify("SpecKit: kit not found: " .. name, vim.log.levels.ERROR)
    return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(vim.inspect(data), "\n"))
  vim.api.nvim_set_current_buf(buf)
  vim.bo.filetype = "lua"
end, { nargs = 1 })
