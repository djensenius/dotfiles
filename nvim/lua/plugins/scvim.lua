return {
	"davidgranstrom/scnvim",
	event = "VeryLazy",
	ft = { "supercollider" },
	config = function()
		require("scnvim").setup()
	end,
}
