local M = {}

local util = require("speckit.util")

local defaults = {
  cli = {
    enabled = true,
    cmd = {
      "uvx",
      "--from",
      "git+https://github.com/github/spec-kit.git",
      "specify",
    },
    height = 15,
    split_cmd = nil,
    env = {},
    cwd = nil,
    startinsert = true,
    notify = true,
    default_script = nil,
    help_args = { "--help" },
  },
  prompts = {
    enabled = true,
    target = "claude",
    notify = true,
    commands = {
      specify = {
        name = "SpecKitSpecify",
        template = "/speckit.specify %s",
        input_prompt = "SpecKit specify: ",
        description = "Send a /speckit.specify prompt to the default AI terminal",
      },
      plan = {
        name = "SpecKitPlan",
        template = "/speckit.plan %s",
        input_prompt = "SpecKit plan: ",
        description = "Send a /speckit.plan prompt to the default AI terminal",
      },
      tasks = {
        name = "SpecKitTasks",
        template = "/speckit.tasks %s",
        input_prompt = "SpecKit tasks: ",
        description = "Send a /speckit.tasks prompt to the default AI terminal",
      },
    },
  },
}

local state = {
  prompt_commands = {},
}

local function deepcopy(value)
  return vim.deepcopy(value)
end

local function command_name(config, fallback)
  if type(config.name) == "string" and config.name ~= "" then
    return config.name
  end
  return fallback
end

local function delete_command(name)
  if type(name) ~= "string" or name == "" then
    return
  end
  pcall(vim.api.nvim_del_user_command, name)
end

local function join_cmd(cmd)
  local parts = {}
  for _, part in ipairs(cmd) do
    if type(part) == "string" and part:find("%s") then
      table.insert(parts, string.format('"%s"', part))
    else
      table.insert(parts, part)
    end
  end
  return table.concat(parts, " ")
end

local function open_terminal(cli_opts)
  local height = cli_opts.height or defaults.cli.height
  local split_cmd = cli_opts.split_cmd
  if type(split_cmd) == "function" then
    split_cmd()
  elseif type(split_cmd) == "string" and split_cmd ~= "" then
    vim.cmd(split_cmd)
  else
    vim.cmd(string.format("botright %dsplit", height))
  end

  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_win_set_buf(win, buf)
  return buf, win
end

local function has_flag(args, flag)
  for _, value in ipairs(args) do
    if value == flag then
      return true
    end
  end
  return false
end

local function run_cli(cli_opts, args, context)
  local base = deepcopy(cli_opts.cmd or {})
  if #base == 0 then
    vim.notify("SpecKit workflow CLI: command is empty", vim.log.levels.ERROR)
    return
  end

  for _, arg in ipairs(args or {}) do
    table.insert(base, arg)
  end

  local buf = nil
  local ok, err = pcall(function()
    buf = select(1, open_terminal(cli_opts))
  end)
  if not ok then
    vim.notify(
      string.format("SpecKit workflow CLI: failed to open terminal window (%s)", err),
      vim.log.levels.ERROR
    )
    return
  end

  local job
  local term_opts = {}
  if cli_opts.cwd then
    term_opts.cwd = cli_opts.cwd
  end
  if cli_opts.env and next(cli_opts.env) then
    term_opts.env = cli_opts.env
  end
  if type(cli_opts.on_exit) == "function" then
    term_opts.on_exit = cli_opts.on_exit
  end

  job = vim.fn.termopen(base, term_opts)
  if job <= 0 then
    local message =
      string.format("SpecKit workflow CLI: failed to run command (%s)", join_cmd(base))
    vim.notify(message, vim.log.levels.ERROR)
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    return
  end

  if cli_opts.notify ~= false then
    local label = context and context.label or "SpecKit CLI"
    vim.notify(string.format("%s → %s", label, join_cmd(base)), vim.log.levels.INFO)
  end

  if cli_opts.startinsert ~= false then
    vim.cmd("startinsert")
  end
end

local function ensure_prompt_commands_cleared()
  for _, name in pairs(state.prompt_commands) do
    delete_command(name)
  end
  state.prompt_commands = {}
end

local function safe_require(name)
  local ok, mod = pcall(require, name)
  if ok then
    return mod
  end
end

local function send_prompt(target, text, notify_label)
  local ai = safe_require("ai-terminals")
  if not ai then
    vim.notify("SpecKit prompts require ai-terminals.nvim (enable the ai kit)", vim.log.levels.WARN)
    return false
  end
  ai.send(target, text)
  if notify_label then
    vim.notify(string.format("%s → %s", notify_label, target), vim.log.levels.INFO)
  end
  return true
end

local function setup_cli(opts)
  if opts.enabled == false then
    delete_command("SpecKitCLI")
    delete_command("SpecKitInit")
    return
  end

  local cli_opts = opts

  delete_command("SpecKitCLI")
  vim.api.nvim_create_user_command("SpecKitCLI", function(cmd_opts)
    local args = {}
    if cmd_opts.args ~= "" then
      args = deepcopy(cmd_opts.fargs)
    else
      args = deepcopy(cli_opts.help_args or defaults.cli.help_args)
    end
    run_cli(cli_opts, args, { label = "SpecKit CLI" })
  end, {
    nargs = "*",
    desc = "Run the specify CLI inside a terminal buffer",
  })

  delete_command("SpecKitInit")
  vim.api.nvim_create_user_command("SpecKitInit", function(cmd_opts)
    local provided = deepcopy(cmd_opts.fargs)
    if #provided == 0 then
      local project = vim.fn.input("Project name: ")
      project = vim.trim(project)
      if project == "" then
        return
      end
      table.insert(provided, project)
    end

    if cli_opts.default_script and not has_flag(provided, "--script") then
      table.insert(provided, "--script")
      table.insert(provided, cli_opts.default_script)
    end

    local args = { "init" }
    vim.list_extend(args, provided)
    run_cli(cli_opts, args, { label = "SpecKit init" })
  end, {
    nargs = "*",
    desc = "Run specify init with optional arguments",
    complete = function(arglead, line, cursorpos)
      local before = line:sub(1, cursorpos)
      local words = vim.split(before, "%s+", { trimempty = true })
      local prev = words[#words - 1]
      if prev == "--script" then
        local scripts = { "sh", "ps" }
        local matches = {}
        for _, value in ipairs(scripts) do
          if vim.startswith(value, arglead) then
            table.insert(matches, value)
          end
        end
        return matches
      end
      return {}
    end,
  })
end

local function resolve_template(template, input)
  if type(template) == "function" then
    return template(input)
  end
  if type(template) == "string" and template ~= "" then
    local ok, result = pcall(string.format, template, input)
    if ok then
      return result
    end
  end
  return input
end

local function setup_prompts(opts)
  ensure_prompt_commands_cleared()

  if opts.enabled == false then
    return
  end

  local target_default = opts.target or defaults.prompts.target
  local notify = opts.notify

  for key, config in pairs(opts.commands or {}) do
    local name = command_name(config, "SpecKit" .. key:gsub("^%l", string.upper))
    delete_command(name)

    vim.api.nvim_create_user_command(name, function(cmd_opts)
      local input = cmd_opts.args
      if input == "" then
        input = vim.fn.input(config.input_prompt or (name .. ": "))
      end
      input = vim.trim(input)
      if input == "" then
        return
      end
      local message = resolve_template(config.template, input)
      local target = config.target or target_default
      local label = notify ~= false and (config.description or name) or nil
      send_prompt(target, message, label)
    end, {
      nargs = "*",
      desc = config.description,
    })

    state.prompt_commands[key] = name
  end
end

function M.setup(opts)
  local merged = util.deep_merge(deepcopy(defaults), opts or {})
  setup_cli(merged.cli or {})
  setup_prompts(merged.prompts or {})
end

return M
