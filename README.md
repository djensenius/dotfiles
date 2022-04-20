# dotfiles
My config files for Vim, Fish, Starship, and tmux.

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
