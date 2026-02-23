# Load private, machine-specific environment variables (not tracked by git)
if test -e ~/.env.local
    envsource ~/.env.local
end
