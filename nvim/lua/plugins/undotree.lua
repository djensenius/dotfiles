return {
	"jiaoshijie/undotree",
	---@module 'undotree.collector'
	opts = {
		-- your options
	},
	keys = { -- load the plugin only when using it's keybinding:
		{ "<leader>u", "<cmd>lua require('undotree').toggle()<cr>" },
	},
}
