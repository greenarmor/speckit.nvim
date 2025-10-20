return {
  servers = { lua_ls = true },
  specs = {
    {
      "neovim/nvim-lspconfig",
      event = { "BufReadPre", "BufNewFile" },
      dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
      config = function(_, _)
        local lsp = require("lspconfig")
        local ok_m, mason = pcall(require, "mason")
        local ok_mlsp, mason_lsp = pcall(require, "mason-lspconfig")
        if ok_m then
          mason.setup()
        end
        if ok_mlsp then
          mason_lsp.setup()
        end

        local defaults = {
          capabilities = vim.lsp.protocol.make_client_capabilities(),
          on_attach = function(_, bufnr)
            local map = function(m, lhs, rhs)
              vim.keymap.set(m, lhs, rhs, { buffer = bufnr })
            end
            map("n", "gd", vim.lsp.buf.definition)
            map("n", "gr", vim.lsp.buf.references)
            map("n", "K", vim.lsp.buf.hover)
            map("n", "<leader>rn", vim.lsp.buf.rename)
          end,
        }

        local servers_requested = (require("speckit").get("lsp") or {}).servers or {}
        for name, enabled in pairs(servers_requested) do
          if enabled then
            local server = lsp[name]
            if not server then
              vim.notify(
                string.format("SpecKit LSP: unknown server '%s'", name),
                vim.log.levels.WARN
              )
            else
              local server_opts = vim.deepcopy(defaults)
              if type(enabled) == "table" then
                server_opts = vim.tbl_deep_extend("force", server_opts, enabled)
              end
              server.setup(server_opts)
            end
          end
        end
      end,
    },
    { "folke/neodev.nvim", ft = "lua", opts = {} },
  },
}
