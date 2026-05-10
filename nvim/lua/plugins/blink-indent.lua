return {
	"saghen/blink.indent",
	--- @module 'blink.indent'
	opts = {
		mappings = {
			object_scope_with_border = "",
		},
	},
	config = function(_, opts)
		require("blink.indent").setup(opts)
		for _, mode in ipairs({ "x", "o" }) do
			pcall(vim.keymap.del, mode, "ai")
		end
	end,
}
