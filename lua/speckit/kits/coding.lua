return {
  specs = {
    {
      "hrsh7th/nvim-cmp",
      event = "InsertEnter",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
      },
      opts = function()
        local cmp = require("cmp")
        return {
          snippet = {
            expand = function(args)
              require("luasnip").lsp_expand(args.body)
            end,
          },
          mapping = cmp.mapping.preset.insert({
            ["<C-n>"] = cmp.mapping.select_next_item(),
            ["<C-p>"] = cmp.mapping.select_prev_item(),
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
            ["<C-Space>"] = cmp.mapping.complete(),
          }),
          sources = cmp.config.sources(
            { { name = "nvim_lsp" }, { name = "luasnip" } },
            { { name = "buffer" }, { name = "path" } }
          ),
        }
      end,
    },
    { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
    {
      "stevearc/conform.nvim",
      event = { "BufWritePre" },
      opts = { format_on_save = { timeout_ms = 1000, lsp_fallback = true } },
    },
  },
}
