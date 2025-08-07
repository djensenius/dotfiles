function git_new_push --description 'Shortcut to push new branch'
    if not command -sq git
        return 1
    end
    set -l repo_info (command git rev-parse --git-dir --is-inside-git-dir --is-bare-repository --is-inside-work-tree HEAD 2>/dev/null)
    test -n "$repo_info"
    or return

    set -l rbc (__fish_git_prompt_operation_branch_bare $repo_info)
    set -l b $rbc[2]
    set b (string replace refs/heads/ '' -- $b)
    git push --set-upstream origin $b
end
