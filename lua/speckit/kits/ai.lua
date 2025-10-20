return {
  requires = { "git" },
  specs = {
    {
      "aweis89/ai-terminals.nvim",
      dependencies = { "folke/snacks.nvim" },
      opts = {
        auto_terminal_keymaps = {
          prefix = "<leader>at",
          terminals = {
            { name = "claude", key = "c" },
            { name = "aider", key = "a" },
            { name = "codex", key = "o" },
          },
        },
        terminals = {
          claude = {
            cmd = function()
              return "claude"
            end,
            path_header_template = "`%s`",
          },
          aider = {
            cmd = function()
              return "aider --watch-files"
            end,
            path_header_template = "`%s`",
          },
          codex = {
            cmd = function()
              return vim.env.SPECKIT_CODEX_CMD
                or "openai api chat.completions.create --model gpt-4o-mini --stream"
            end,
            path_header_template = "`%s`",
          },
        },
        trigger_formatting = { enabled = true, timeout_ms = 4000 },
        watch_cwd = { enabled = false },
      },
      config = function(_, opts)
        local ai = require("ai-terminals")
        ai.setup(opts)

        local ok_actions, sa = pcall(require, "ai-terminals.snacks_actions")
        if ok_actions then
          local ok_snacks, snacks = pcall(require, "snacks")
          if ok_snacks then
            sa.apply(snacks.config)
          end
        end

        require("speckit.recipes.ai").setup()
      end,
    },
  },
}
