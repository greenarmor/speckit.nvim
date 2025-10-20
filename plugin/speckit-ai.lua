-- Ensures AI commands exist very early; real implementations come from recipes.
if vim.g.loaded_speckit_ai then
  return
end
vim.g.loaded_speckit_ai = true

local function stub(name)
  vim.api.nvim_create_user_command(name, function()
    vim.notify("SpecKit AI: command will activate after plugins init", vim.log.levels.INFO)
  end, { nargs = "*", range = true })
end

for _, cmd in ipairs({
  "AISendSelection",
  "AIToggle",
  "AIAsk",
  "AIReviewOpen",
  "AIReviewClose",
  "AIStageHunk",
  "AIResetHunk",
}) do
  stub(cmd)
end
