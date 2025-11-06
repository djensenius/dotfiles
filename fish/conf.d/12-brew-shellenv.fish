# Initialize brew environment variables (but avoid path_helper which reorders PATH)
# On macOS, brew shellenv calls path_helper which puts /usr/bin before mise paths
if test -x /opt/homebrew/bin/brew
    set -gx HOMEBREW_PREFIX /opt/homebrew
    set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
    set -gx HOMEBREW_REPOSITORY /opt/homebrew
    fish_add_path -g /opt/homebrew/bin /opt/homebrew/sbin
else if test -x /usr/local/bin/brew
    set -gx HOMEBREW_PREFIX /usr/local
    set -gx HOMEBREW_CELLAR /usr/local/Cellar
    set -gx HOMEBREW_REPOSITORY /usr/local
    fish_add_path -g /usr/local/bin /usr/local/sbin
else if test -x /home/linuxbrew/.linuxbrew/bin/brew
    set -gx HOMEBREW_PREFIX /home/linuxbrew/.linuxbrew
    set -gx HOMEBREW_CELLAR /home/linuxbrew/.linuxbrew/Cellar
    set -gx HOMEBREW_REPOSITORY /home/linuxbrew/.linuxbrew
    fish_add_path -g /home/linuxbrew/.linuxbrew/bin
end
