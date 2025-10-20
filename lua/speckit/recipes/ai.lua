local M = {}

local function get_visual_range()
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")

  local sr, sc = start_pos[2], start_pos[3]
  local er, ec = end_pos[2], end_pos[3]

  if sr > er or (sr == er and sc > ec) then
    sr, sc, er, ec = er, ec, sr, sc
  end

  return sr, sc, er, ec
end

local function get_visual_text()
  local sr, sc, er, ec = get_visual_range()
  local lines = vim.api.nvim_buf_get_lines(0, sr - 1, er, false)

  if #lines == 0 then
    return nil
  end

  lines[#lines] = string.sub(lines[#lines], 1, ec)
  lines[1] = string.sub(lines[1], sc)

  return table.concat(lines, "\n")
end

local function safe_require(name)
  local ok, mod = pcall(require, name)
  if ok then
    return mod
  end
end

local function send_to(target, text)
  local ai = safe_require("ai-terminals")
  if not ai then
    vim.notify("AI: ai-terminals.nvim not available", vim.log.levels.WARN)
    return
  end

  local filename = vim.api.nvim_buf_get_name(0)
  local header = string.format("`%s`", vim.fn.fnamemodify(filename, ":~:."))
  ai.send(target, string.format("%s\n\n%s", header, text))
end

local function run_diffview(cmd)
  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    vim.notify(
      string.format("AI: %s failed — diffview.nvim unavailable?\n%s", cmd, err),
      vim.log.levels.WARN
    )
  end
end

local function open_diff()
  run_diffview("DiffviewOpen")
end

local function close_diff()
  run_diffview("DiffviewClose")
end

local function stage_hunk()
  local gitsigns = safe_require("gitsigns")
  if not gitsigns then
    vim.notify("AI: gitsigns.nvim not available", vim.log.levels.WARN)
    return
  end
  gitsigns.stage_hunk()
end

local function reset_hunk()
  local gitsigns = safe_require("gitsigns")
  if not gitsigns then
    vim.notify("AI: gitsigns.nvim not available", vim.log.levels.WARN)
    return
  end
  gitsigns.reset_hunk()
end

local function create_command(name, callback, opts)
  vim.api.nvim_create_user_command(name, callback, opts or {})
end

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

local function telescope_integration()
  local actions = safe_require("telescope.actions")
  local action_state = safe_require("telescope.actions.state")
  local builtin = safe_require("telescope.builtin")

  if not (actions and action_state and builtin) then
    return
  end

  local function send_selection(target)
    return function(prompt_bufnr)
      local entry = action_state.get_selected_entry()
      actions.close(prompt_bufnr)

      local path = entry and (entry.path or entry.filename or entry.value)
      if not path then
        return
      end

      send_to(target, string.format("Open and analyze: `%s`", path))
    end
  end

  local function attach_mappings(_, attach_map)
    attach_map("i", "<C-a>", send_selection("aider"))
    attach_map("i", "<C-c>", send_selection("claude"))
    attach_map("i", "<C-o>", send_selection("codex"))
    attach_map("n", "ga", send_selection("aider"))
    attach_map("n", "gc", send_selection("claude"))
    attach_map("n", "go", send_selection("codex"))
    return true
  end

  local function wrap(fn)
    return function(opts)
      opts = opts or {}
      opts.attach_mappings = attach_mappings
      return fn(opts)
    end
  end

  package.loaded["speckit.telescope_ai"] = {
    find_files = wrap(builtin.find_files),
    live_grep = wrap(builtin.live_grep),
    diagnostics = wrap(builtin.diagnostics),
    buffers = wrap(builtin.buffers),
  }
end

function M.setup()
  create_command("AISendSelection", function(opts)
    local target = opts.fargs[1] or "aider"
    local text = get_visual_text()

    if not text or text == "" then
      vim.notify("AI: No visual selection", vim.log.levels.WARN)
      return
    end

    send_to(target, text)
  end, { nargs = "?", range = true })

  create_command("AIToggle", function(opts)
    local target = opts.fargs[1] or "aider"
    local client = safe_require("ai-terminals")
    if client and client.toggle then
      client.toggle(target)
    else
      vim.notify("AI: ai-terminals.nvim not available", vim.log.levels.WARN)
    end
  end, { nargs = "?" })

  create_command("AIAsk", function(opts)
    local target = (opts.fargs[1] and opts.fargs[1] ~= "" and opts.fargs[1]) or "claude"
    local prompt = table.concat(opts.fargs, " ", 2)
    if prompt == "" then
      prompt = vim.fn.input("Ask: ")
    end
    if prompt == "" then
      return
    end
    send_to(target, prompt)
  end, { nargs = "*" })

  create_command("AIReviewOpen", open_diff)
  create_command("AIReviewClose", close_diff)
  create_command("AIStageHunk", stage_hunk)
  create_command("AIResetHunk", reset_hunk)

  map("n", "<leader>atc", function()
    vim.cmd("AIToggle claude")
  end, "AI: Toggle Claude")
  map("n", "<leader>ata", function()
    vim.cmd("AIToggle aider")
  end, "AI: Toggle Aider")
  map("n", "<leader>ato", function()
    vim.cmd("AIToggle codex")
  end, "AI: Toggle Codex/OpenAI")

  map("x", "<leader>ats", ":'<,'>AISendSelection aider\n", "AI: Send Selection → Aider")
  map("x", "<leader>atS", ":'<,'>AISendSelection claude\n", "AI: Send Selection → Claude")
  map("x", "<leader>atO", ":'<,'>AISendSelection codex\n", "AI: Send Selection → Codex/OpenAI")

  map("n", "<leader>atq", function()
    vim.cmd("AIAsk claude")
  end, "AI: Quick Ask (Claude)")
  map("n", "<leader>atQ", function()
    vim.cmd("AIAsk aider")
  end, "AI: Quick Ask (Aider)")
  map("n", "<leader>atO", function()
    vim.cmd("AIAsk codex")
  end, "AI: Quick Ask (Codex/OpenAI)")

  map("n", "<leader>atr", open_diff, "AI: Review (DiffviewOpen)")
  map("n", "<leader>atR", close_diff, "AI: Review Close")
  map("n", "]h", stage_hunk, "AI: Stage Hunk")
  map("n", "[h", reset_hunk, "AI: Reset Hunk")

  telescope_integration()
end

return M
