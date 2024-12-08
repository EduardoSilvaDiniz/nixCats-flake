require("lze").load({
  { import = "plugins.lspconfig" },
  "cmp",
  after = function(plugin)
    require("plugin.cmp")
  end,
})
