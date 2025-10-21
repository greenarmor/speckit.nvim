# speckit.nvim — Spec Kit for Neovim (lazy.nvim)


<p align="center">
  <a href="https://github.com/greenarmor/speckit.nvim/actions">
    <img alt="CI" src="https://img.shields.io/github/actions/workflow/status/greenarmor/speckit.nvim/ci.yml?branch=main&label=CI&logo=github">
  </a>
  <a href="https://github.com/greenarmor/speckit.nvim/releases">
    <img alt="GitHub release" src="https://img.shields.io/github/v/release/greenarmor/speckit.nvim?display_name=tag&sort=semver">
  </a>
  <a href="https://github.com/greenarmor/speckit.nvim/blob/main/LICENSE">
    <img alt="License" src="https://img.shields.io/badge/License-MIT-blue.svg">
  </a>
  <a href="https://github.com/folke/lazy.nvim">
    <img alt="lazy.nvim" src="https://img.shields.io/badge/compatible-lazy.nvim-green">
  </a>
  <a href="https://neovim.io">
    <img alt="Neovim" src="https://img.shields.io/badge/Neovim-%E2%89%A50.9-57A143?logo=neovim&logoColor=white">
  </a>
</p>


Pre-curated plugin **kits** you can mix & match, plus an **AI kit** that integrates
[`aweis89/ai-terminals.nvim`](https://github.com/aweis89/ai-terminals.nvim) with ready-made keymaps,
Snacks/Telescope actions, and review helpers.

## Requirements
- Neovim >= 0.9 (0.10+ recommended)
- Git
- [lazy.nvim](https://github.com/folke/lazy.nvim)
- (Optional) Telescope, which-key
- At least one AI CLI on your PATH (e.g., `aider`, `claude`, `gemini`, `openai`/Codex)

## Quick Start

### 1) Bootstrap lazy.nvim
Add this to your `init.lua`:
```lua
-- ~/.config/nvim/init.lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
```

### 2) Add speckit.nvim
If using this repo directly:
```lua
require("speckit").setup({
  overrides = {
    lsp = { servers = { lua_ls = true, tsserver = true, pyright = true } },
    ai = {
      terminals = {
        aider  = { cmd = function() return "aider --watch-files" end },
        claude = { cmd = function() return "claude" end },
        codex  = {
          cmd = function()
            return vim.env.SPECKIT_CODEX_CMD
              or "openai api chat.completions.create --model gpt-4o-mini --stream"
          end,
        },
      },
      auto_terminal_keymaps = {
        prefix = "<leader>at",
        terminals = {
          { name = "claude", key = "c" },
          { name = "aider",  key = "a" },
          { name = "codex",  key = "o" },
        },
      },
      trigger_formatting = { enabled = true, timeout_ms = 4000 },
    },
  },
})

require("lazy").setup({
  { "greenarmor/speckit.nvim" },
  unpack(require("speckit").use({ "core", "ui", "git", "coding", "lsp", "ai" })),
})
```

### Customizing kits
- **Per-server LSP settings:** pass a table instead of `true` and it will be deep-merged with the defaults.

  ```lua
  require("speckit").setup({
    overrides = {
      lsp = {
        servers = {
          lua_ls = {
            settings = { Lua = { diagnostics = { globals = { "vim" } } } },
          },
          tsserver = true,
        },
      },
    },
  })
  ```

- **Removing specs:** provide a function override that receives the kit table and returns a new version.

  ```lua
  require("speckit").setup({
    overrides = {
      git = function(kit)
        kit.specs = vim.tbl_filter(function(spec)
          return spec[1] ~= "sindrets/diffview.nvim"
        end, kit.specs)
        return kit
      end,
    },
  })
  ```

If you get from vendor plugin spec entry:
```lua
require("lazy").setup({
  { "greenarmor/speckit.nvim" }, -- after you push to GitHub
  unpack(require("speckit").use({ "core", "ui", "git", "coding", "lsp", "ai" })),
})
```

### 3) Install
- Open Neovim and run `:Lazy sync`
- Restart Neovim
- Run `:SpecKitList` then `:SpecKitShow ai` to inspect kits

## AI Recipes & Keymaps

With the **ai** kit enabled, you get commands and keymaps:

- `:AISendSelection [terminal]` — send visual selection (default: `aider`)
- `:AIToggle [terminal]` — toggle AI terminal (default: `aider`)
- `:AIAsk [terminal] [prompt…]` — prompt to AI (default: `claude`)
- `:AIReviewOpen` / `:AIReviewClose` — open/close `diffview.nvim`
- `:AIStageHunk` / `:AIResetHunk` — via `gitsigns.nvim`

## Spec Kit Workflow Helpers

Recreate the Spec Kit quick start loop without leaving Neovim:

- `:SpecKitInit [project …]` — opens a terminal split and runs
  `uvx --from git+https://github.com/github/spec-kit.git specify init …` for you.
- `:SpecKitCLI [args…]` — run any `specify` sub-command in-place (defaults to
  `--help` when called without arguments).
- `:SpecKitSpecify`, `:SpecKitPlan`, `:SpecKitTasks` — send `/speckit.*` prompts
  to your default AI terminal (requires the **ai** kit / `ai-terminals.nvim`).

Customize the workflow behaviour during setup:

```lua
require("speckit").setup({
  workflow = {
    cli = {
      cmd = { "uvx", "--from", "/path/to/spec-kit", "specify" },
      default_script = "sh",
      height = 12,
    },
    prompts = {
      target = "aider",
      commands = {
        specify = { description = "Send spec prompt" },
        plan = { target = "claude" },
      },
    },
  },
})
```

Leave any field out to use the defaults shown above.

> **Note**
> The **ai** kit automatically pulls in the **git** kit so you get the supporting plugins and mappings without having to enable both manually.

**Default keymaps**
- `<leader>ata` toggle Aider
- `<leader>atc` toggle Claude
- `<leader>ato` toggle Codex/OpenAI
- Visual: `<leader>ats` → Aider, `<leader>atS` → Claude
- Visual: `<leader>atO` → Codex/OpenAI
- Review: `<leader>atr` open diffview, `<leader>atR` close; `]h` stage / `[h` reset

> Set the `SPECKIT_CODEX_CMD` environment variable to point at your preferred Codex/OpenAI CLI invocation (defaults to the `openai` CLI with `gpt-4o-mini`).

See `lua/speckit/recipes/ai.lua` for details and Telescope integration helpers.

The script ensures the working tree is clean, creates the `v1.2.3` tag, pushes
it to `origin`, and—when the [GitHub CLI](https://cli.github.com/) is
available—triggers `gh release create` with generated notes. Pushing the tag
also activates the **Release** GitHub Actions workflow, which creates a release
with auto-generated notes when the tag lands on GitHub.

## License
MIT

## Development

This repository includes helper scripts under `scripts/` to smooth out
local development:

- `./scripts/stylua.sh` — downloads a pinned StyLua release to
  `.cache/stylua/` (if needed) and then executes it. Use this instead of
  calling `stylua` directly in environments where the formatter is not
  pre-installed, for example: `./scripts/stylua.sh --check lua/`.
