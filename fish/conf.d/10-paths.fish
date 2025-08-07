# Generic paths (deduplicated and ordered)
fish_add_path -g $HOME/.local/bin

if test -d $HOME/.cargo/bin
    fish_add_path -g $HOME/.cargo/bin
end

# Homebrew (Apple Silicon, Intel macOS)
if test -d /opt/homebrew/bin
    fish_add_path -g /opt/homebrew/bin
end
if test -d /usr/local/sbin
    fish_add_path -g /usr/local/sbin
end

# Linuxbrew
if test -d /home/linuxbrew/.linuxbrew/bin
    fish_add_path -g /home/linuxbrew/.linuxbrew/bin
end
