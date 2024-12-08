local cmp = require("cmp")
local lspkind = require("lspkind")

local function get_luasnip()
  local ok_luasnip, luasnip = pcall(require, "luasnip")
  return ok_luasnip and luasnip or {}
end

local function luasnip_jump_forward()
  local luasnip = get_luasnip()

  return cmp.mapping(function(fallback)
    if luasnip.jumpable(1) then
      luasnip.jump(1)
    else
      fallback()
    end
  end, { "i", "s" })
end

local function luasnip_jump_backward()
  local luasnip = get_luasnip()

  return cmp.mapping(function(fallback)
    if luasnip.jumpable(-1) then
      luasnip.jump(-1)
    else
      fallback()
    end
  end, { "i", "s" })
end

local function luasnip_supertab(select_opts)
  local luasnip = get_luasnip()

  return cmp.mapping(function(fallback)
    local col = vim.fn.col(".") - 1

    if cmp.visible() then
      cmp.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = true })
    elseif luasnip.expand_or_jumpable() then
      luasnip.expand_or_jump()
    elseif col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then
      fallback()
    else
      cmp.complete()
    end
  end, { "i", "s" })
end

local function luasnip_shift_supertab(select_opts)
  local luasnip = get_luasnip()

  return cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.select_prev_item(select_opts)
    elseif luasnip.jumpable(-1) then
      luasnip.jump(-1)
    else
      fallback()
    end
  end, { "i", "s" })
end


cmp.setup({
  mapping = {
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-f"] = luasnip_jump_forward(),
    ["<C-b"] = luasnip_jump_backward(),
    ["<Tab>"] = luasnip_supertab(),
    ["<S-Tab>"] = luasnip_shift_supertab(),
  },

  completion = {
    winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None,CursorLine:MyCursorLine",
    side_padding = 0,
  },

  window = {
    completion = {
      winhighlight = "Normal:Normal,FloatBorder:CmpCompletionBorder,CursorLine:Pmenu",
      border = "rounded",
      scrollbar = false,
      col_offset = -3,
      side_padding = 0,
    },
    documentation = {
      scrollbar = false,
      winhighlight = "Normal:Normal,FloatBorder:CmpCompletionBorder",
      border = "rounded",
    },
    snippet = {
      winhighlight = "Normal:Normal,FloatBorder:CmpCompletionBorder",
      border = "rounded",
    },
  },

  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },

  formatting = {
    fields = { "kind", "abbr", "menu" },
    format = lspkind.cmp_format(),

    -- format = function(entry, vim_item)
    -- 	vim_item.kind = (cmp_kinds[vim_item.kind] or "")
    --
    -- 	if entry == "Function" then
    -- 		local item = entry:get_completion_item()
    --
    -- 		log.debug(item)
    --
    -- 		if item.detail then
    -- 			vim_item.menu = item.detail
    -- 		end
    -- 	end
    --
    -- 	vim_item.abbr = vim_item.abbr:match("[^(]+")
    --
    -- 	return vim_item
    -- end,
  },

  sources = {
    { name = "luasnip",  max_item_count = 10 },
    { name = "nvim_lsp" },
    { name = "nvim_lua", keyword_length = 2 },
    { name = "buffer",   keyword_length = 3 },
    { name = "path" },
  },

  preselect = {
    cmp.PreselectMode.None,
  },

  sorting = {
    comparators = {
      cmp.config.compare.exact,
      cmp.config.compare.recently_used,
      cmp.config.compare.score,
    },
  },

  completeopt = "menu,menuone,noinsert",

  cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done()),

  enabled = function()
    local context = require("cmp.config.context")
    local disabled = false
    disabled = disabled or (vim.api.nvim_get_option_value("buftype", {}) == "prompt")
    disabled = disabled or (vim.api.nvim_get_option_value("buftype", {}) == "nofile")
    disabled = disabled or (vim.fn.reg_recording() ~= "")
    disabled = disabled or (vim.fn.reg_executing() ~= "")
    disabled = disabled or context.in_treesitter_capture("comment")
    return not disabled
  end,
})
--TODO cmdlines estao grandes demais!
cmp.setup.cmdline({ "/", "?" }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = "buffer" },
  },
})

cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = "path" },
  }, {
    { name = "cmdline" },
  }),
  matching = { disallow_symbol_nonprefix_matching = false },
})
