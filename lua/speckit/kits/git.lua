return {
  specs = {
    { "tpope/vim-fugitive", cmd = { "Git", "G" } },
    { "lewis6991/gitsigns.nvim", event = "BufReadPre", opts = {} },
    { "sindrets/diffview.nvim", cmd = { "DiffviewOpen", "DiffviewClose" } },
  },
}
