return {
	"echasnovski/mini.surround",
	version = "*",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		require("mini.surround").setup()
	end,
}
