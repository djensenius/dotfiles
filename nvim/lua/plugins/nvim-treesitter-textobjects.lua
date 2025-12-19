return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	branch = "main",
	lazy = true,
	config = function()
		require("nvim-treesitter-textobjects").setup({
			select = {
				lookahead = true,
			},
			move = {
				set_jumps = true,
			},
		})

		-- Select textobjects
		local select = require("nvim-treesitter-textobjects.select")
		local function map_select(key, query, desc)
			vim.keymap.set({ "x", "o" }, key, function()
				select.select_textobject(query, "textobjects")
			end, { desc = desc })
		end

		map_select("af", "@function.outer", "Select around function")
		map_select("if", "@function.inner", "Select inner function")
		map_select("ac", "@class.outer", "Select around class")
		map_select("ic", "@class.inner", "Select inner class")
		map_select("aa", "@parameter.outer", "Select around parameter")
		map_select("ia", "@parameter.inner", "Select inner parameter")

		-- Move textobjects
		local move = require("nvim-treesitter-textobjects.move")
		local function map_move(key, query, forward, start, desc)
			vim.keymap.set({ "n", "x", "o" }, key, function()
				if forward then
					if start then
						move.goto_next_start(query, "textobjects")
					else
						move.goto_next_end(query, "textobjects")
					end
				else
					if start then
						move.goto_previous_start(query, "textobjects")
					else
						move.goto_previous_end(query, "textobjects")
					end
				end
			end, { desc = desc })
		end

		-- Next
		map_move("]m", "@function.outer", true, true, "Next function start")
		map_move("]]", "@class.outer", true, true, "Next class start")
		map_move("]M", "@function.outer", true, false, "Next function end")
		map_move("][", "@class.outer", true, false, "Next class end")

		-- Previous
		map_move("[m", "@function.outer", false, true, "Prev function start")
		map_move("[[", "@class.outer", false, true, "Prev class start")
		map_move("[M", "@function.outer", false, false, "Prev function end")
		map_move("[]", "@class.outer", false, false, "Prev class end")
	end,
}
