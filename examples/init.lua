-- Example init.lua snippet using speckit.nvim
-- Assumes lazy.nvim bootstrap above this block.

require("speckit").setup({
  overrides = {
    lsp = { servers = { lua_ls = true, tsserver = true, pyright = true } },
    ai = {
      terminals = {
        aider = {
          cmd = function()
            return "aider --watch-files --model claude-3-7"
          end,
        },
        claude = {
          cmd = function()
            return "claude"
          end,
        },
      },
      auto_terminal_keymaps = {
        prefix = "<leader>at",
        terminals = { { name = "claude", key = "c" }, { name = "aider", key = "a" } },
      },
      trigger_formatting = { enabled = true, timeout_ms = 4000 },
    },
  },
})

require("lazy").setup(require("speckit").use({ "core", "ui", "git", "coding", "lsp", "ai" }))
