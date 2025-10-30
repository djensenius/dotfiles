# rbenv only outside Codespaces and only if mise is not installed
if not test -d /workspaces; and not command -q mise
    status is-interactive; and command -q rbenv; and rbenv init - fish | source
end

if test -d /workspaces/github
    set -gx RAILS_ROOT /workspaces/github

    if set -q RBENV_HOOK_PATH
        set -e RBENV_HOOK_PATH
    end

    set -l env_script "$RAILS_ROOT/script/environment.sh"
    if test -f "$env_script"
        if grep -qE 'bash|BASH' "$env_script"
            bash "$env_script"
        else
            source "$env_script" 2>/dev/null
        end
    end

    if not set -q NON_GH_PATH
        set -gx NON_GH_PATH $PATH
    end

    function __read_vendor_ruby_sha
        set -l rv_file "$RAILS_ROOT/config/ruby-version"
        if not test -f "$rv_file"
            return 1
        end
        set -l contents
        if test -x "$rv_file"
            set contents (bash "$rv_file" 2>/dev/null)
        else
            set contents (cat "$rv_file")
        end
        set contents (string trim "$contents")
        if test -z "$contents"
            return 1
        end
        if not string match -qr '^[0-9a-fA-F]+$' -- "$contents"
            return 1
        end
        echo $contents
        return 0
    end

    set -l vendor_ruby_sha (__read_vendor_ruby_sha 2>/dev/null)
    if test $status -ne 0
        set vendor_ruby_sha dbd83256b1cec76c69756ecb8758b9e1079833de
    end
    set -l vendor_ruby_bin "$RAILS_ROOT/vendor/ruby/$vendor_ruby_sha/bin"

    if not test -d "$vendor_ruby_bin"
        echo "25-rbenv.fish: WARNING: vendor Ruby bin not found: $vendor_ruby_bin" 1>&2
    end

    # Ensure vendor ruby REALLY gets prepended:
    # Remove any existing occurrences first, then fish_add_path -p.
    if type -q fish_add_path
        if test -d "$vendor_ruby_bin"
            set -l cleaned
            for dir in $PATH
                if test "$dir" != "$vendor_ruby_bin"
                    set cleaned $cleaned $dir
                end
            end
            set -gx PATH $cleaned
            fish_add_path -p -g $vendor_ruby_bin
        end
    end

    # Remaining desired paths (append if they exist and aren’t already present)
    set -l other_paths \
        "$RAILS_ROOT/vendor/gitrpcd/build" \
        "$RAILS_ROOT/bin" \
        "$RAILS_ROOT/vendor/node" \
        /usr/local/share \
        /usr/local/go/bin \
        /go/bin \
        "/root/.rbenv/bin" \
        /usr/local/share/rbenv/bin \
        /usr/local/sbin \
        /usr/local/bin \
        /usr/sbin \
        /usr/bin \
        /sbin \
        /bin \
        "/workspaces/insights-dataplatform/.dotnet" \
        "/workspaces/actions/actions-dotnet/.dotnet" \
        /workspaces/actions/actions-codespaces/script \
        "$RAILS_ROOT/vendor/node/bin" \
        "$RAILS_ROOT-ui/node_modules/.bin"

    for p in $other_paths
        if test -d "$p"
            if type -q fish_add_path
                fish_add_path -a -g "$p"
            end
        end
    end

    # Interactive override: calling 'git' uses system binary.
    # function git --description 'Use system /usr/bin/git regardless of PATH'
    #   command /usr/bin/git $argv
    # end
    # Uncomment to inspect:
    # type -ap ruby
end
