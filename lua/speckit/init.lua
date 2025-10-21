local M = {}
local util = require("speckit.util")

local _kits = {
  core = require("speckit.kits.core"),
  ui = require("speckit.kits.ui"),
  git = require("speckit.kits.git"),
  coding = require("speckit.kits.coding"),
  lsp = require("speckit.kits.lsp"),
  ai = require("speckit.kits.ai"),
}

local defaults = { overrides = {} }
M._opts = vim.deepcopy(defaults)
M._extra_overrides = {}

local function current_overrides()
  local saved = vim.deepcopy(M._opts.overrides or {})
  local extras = vim.deepcopy(M._extra_overrides or {})
  return util.deep_merge(saved, extras)
end

local function apply_override(name, base, overrides)
  local override = overrides[name]
  if override == nil then
    return vim.deepcopy(base)
  end
  if override == false then
    return nil
  end

  local kit_copy = vim.deepcopy(base)

  if type(override) == "function" then
    local result = override(vim.deepcopy(kit_copy))
    if type(result) == "table" then
      return result
    end
    if result == false then
      return nil
    end
    return kit_copy
  end

  if type(override) ~= "table" then
    return kit_copy
  end

  local override_copy = vim.deepcopy(override)
  if type(override_copy.specs) == "function" then
    local mutated = override_copy.specs(vim.deepcopy(kit_copy.specs or {}))
    kit_copy.specs = type(mutated) == "table" and mutated or kit_copy.specs
    override_copy.specs = nil
  end

  return util.deep_merge(kit_copy, override_copy)
end

function M.setup(opts)
  M._opts = util.deep_merge(vim.deepcopy(defaults), opts or {})
  M._extra_overrides = {}
  return M
end

function M.available()
  local names = {}
  for k, _ in pairs(_kits) do
    table.insert(names, k)
  end
  table.sort(names)
  return names
end

function M.get(name)
  local kit = _kits[name]
  if not kit then
    return nil
  end
  local resolved = apply_override(name, kit, current_overrides())
  return resolved and vim.deepcopy(resolved) or nil
end

function M.use(names, extra_overrides)
  M._extra_overrides =
    util.deep_merge(M._extra_overrides or {}, vim.deepcopy(extra_overrides or {}))

  local merged_overrides = current_overrides()
  local acc, included = {}, {}

  local function include(name)
    if included[name] then
      return
    end
    local base = _kits[name]
    if not base then
      vim.notify("SpecKit: unknown kit '" .. name .. "'", vim.log.levels.WARN)
      return
    end
    included[name] = true

    for _, dep in ipairs(base.requires or {}) do
      include(dep)
    end

    local kit = apply_override(name, base, merged_overrides)
    if not kit then
      return
    end
    local list = kit.specs or kit
    for _, spec in ipairs(list or {}) do
      table.insert(acc, spec)
    end
  end

  for _, n in ipairs(names or {}) do
    include(n)
  end

  return acc
end

return M
