# User-based overrides (use $USER/$HOME, not presence of directories)

switch $USER
    case djensenius
        # Corp proxy for djensenius
        if not set -q GOPROXY
            set -gx GOPROXY 'https://goproxy.githubapp.com/mod,https://proxy.golang.org/,direct'
        else
            # If GOPROXY is already set (e.g., by the environment), keep it.
            set -gx GOPROXY $GOPROXY
        end

    case david
        # Personal user: unset to use default Go proxy behavior
        set -e GOPROXY
end
