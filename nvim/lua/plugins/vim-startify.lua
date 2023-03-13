function CommandToStartifyTable(command)
    return function()
        local cmd_output = vim.fn.systemlist(command .. " 2>/dev/null")
        local files =
            vim.tbl_map(
            function(v)
                return {line = v, path = v}
            end,
            cmd_output
        )
        return files
    end
end

return {
  "mhinz/vim-startify",
  config = function()
    vim.g.startify_lists = {
      { type = CommandToStartifyTable("git ls-files -m"), header = {"   Git modified"}},
      { type = CommandToStartifyTable("git ls-files -o --exclude-standard"), header = {"   Git untracked"}},
      { type = "files", header = {"   Files" } },
      { type = "commands", header = { "    Commands" } }, -- Commands from above
      { type = "sessions",  header = {"   Sessions"} },
      { type = "bookmarks", header = {"   Bookmarks"} },
    }
    vim.g.startify_session_autoload = 1
    vim.g.startify_session_delete_buffers = 1
    vim.g.startify_fortune_use_unicode = 1
    vim.g.startify_change_to_vcs_root = 1
    vim.g.startify_session_persistence = 1
    vim.g.startify_enable_special = 0
    vim.g.startify_custom_header = {
      [[    (q\_/p)]],
      [[.-.  |. .|]],
      [[   \ =\,/=]],
      [[    )/ _ \]],
      [[   (/\):(/\]],
      [[    \_   _/]],
      [[    `""^""`]],
    }
  end,
}
