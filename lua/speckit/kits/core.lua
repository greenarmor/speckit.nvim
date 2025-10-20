return {
  specs = {
    { "nvim-lua/plenary.nvim", lazy = true },
    { "tpope/vim-sleuth", event = "BufReadPost" },
    {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      event = { "BufReadPost", "BufNewFile" },
      opts = {
        highlight = { enable = true },
        indent = { enable = true },
        ensure_installed = {
          "lua",
          "vim",
          "vimdoc",
          "bash",
          "json",
          "markdown",
          "python",
          "javascript",
          "typescript",
        },
      },
      config = function(_, opts)
        require("nvim-treesitter.configs").setup(opts)
      end,
    },
    { "numToStr/Comment.nvim", opts = {}, keys = { "gc", "gb" } },
    { "kylechui/nvim-surround", version = "*", event = "VeryLazy", opts = {} },
  },
}
