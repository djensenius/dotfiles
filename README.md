# dotfiles
My config files for [NeoVim](https://neovim.io), [Fish](https://fishshell.com), [Starship](https://starship.rs),
[tmux](https://www.ocf.berkeley.edu/~ckuehl/tmux/), [git](https://git-scm.com),
[Kitty](https://sw.kovidgoyal.net/kitty/), and [Homebrew](https://brew.sh).

## GitHub Codespaces

A few features have been added to make this easier to use with [Codespaces](https://github.com/features/codespaces).

Mostly this all works out of the box, however here are some special notes about using a shared clipboard:

On my Mac I have installed [Clipper](https://github.com/wincent/clipper). The `clipper.json` file gets
linked to `~/.clipper.json`. I also added the following to my `~/.ssh/config`

```
Host codespaces
  Hostname localhost
  Port 2222
  User codespace
  RemoteForward /home/codespace/.clipper.sock /Users/david/.clipper.sock
  StreamLocalBindUnlink yes
  StrictHostKeyChecking no
  UpdateHostKeys no
```

To connect to my codespace I use:

```
gh cs ssh --profile codespaces
```

You can always use `gh alias` to make this easier. 😉
