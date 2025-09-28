return {
	"oribarilan/lensline.nvim",
	branch = "release/2.x",
	event = "LspAttach",
	config = function()
		require("lensline").setup()
	end,
}
