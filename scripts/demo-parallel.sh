#!/usr/bin/env bash
# Demonstration script showing parallel installation benefits
# This simulates cargo installs with shorter delays to show the concept

echo "🚀 Parallel Installation Demo"
echo "=============================="
echo ""
echo "This demo shows how parallel installation works by simulating"
echo "cargo package installations with shorter delays."
echo ""

# Source the parallel installation framework
# shellcheck disable=SC1091
source "$(dirname "$0")/parallel-install.sh"

# Demo cargo installation with simulated delays
demo_cargo_install() {
    local package="$1"
    local delay="$2"
    echo "Installing $package (simulated ${delay}s)..."
    sleep "$delay"
    echo "$package installation completed"
}

echo "=== Sequential Mode (Original) ==="
start_time=$(date +%s)

demo_cargo_install "eza" 3
demo_cargo_install "ripgrep" 4
demo_cargo_install "bat" 2
demo_cargo_install "fd-find" 3
demo_cargo_install "atuin" 5

sequential_time=$(($(date +%s) - start_time))
echo "Sequential time: ${sequential_time}s"
echo ""

echo "=== Parallel Mode (Enhanced) ==="
start_time=$(date +%s)

# Start all installations in parallel
run_parallel "demo_eza" "demo_cargo_install eza 3"
run_parallel "demo_ripgrep" "demo_cargo_install ripgrep 4"
run_parallel "demo_bat" "demo_cargo_install bat 2"
run_parallel "demo_fd_find" "demo_cargo_install fd-find 3"
run_parallel "demo_atuin" "demo_cargo_install atuin 5"

# Wait for all to complete
demo_operations=("demo_eza" "demo_ripgrep" "demo_bat" "demo_fd_find" "demo_atuin")
wait_for_parallel "${demo_operations[@]}"

parallel_time=$(($(date +%s) - start_time))
echo ""
echo "Parallel time: ${parallel_time}s"
echo ""

# Calculate improvement
improvement=$((sequential_time - parallel_time))
percentage=$(( (improvement * 100) / sequential_time ))

echo "=== Results ==="
echo "Sequential: ${sequential_time}s"
echo "Parallel:   ${parallel_time}s"
echo "Improvement: ${improvement}s (${percentage}% faster)"
echo ""
echo "In the real installation, cargo packages can take 30-120s each,"
echo "so parallel execution provides much more significant time savings!"