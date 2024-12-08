local lsp = require("lspconfig")

local servers = {
  gopls = {},
  jdtls = {},
}
require("lze").load({
  "nvim-lspconfig",
  for_cat = "general.always",
  event = "FileType",
  after = function(plugin)
    for name, conf in pairs(servers) do
      lsp[name].setup(conf)
    end
  end,
})
