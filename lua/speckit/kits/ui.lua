return {
  specs = {
    {
      "nvim-lualine/lualine.nvim",
      event = "VeryLazy",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      opts = { options = { theme = "auto", globalstatus = true } },
    },
    {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      cmd = "Neotree",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
      },
      opts = { filesystem = { follow_current_file = { enabled = true } } },
    },
    { "rcarriga/nvim-notify", lazy = true },
  },
}
