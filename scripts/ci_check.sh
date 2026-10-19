#!/bin/bash

set -e

echo "=========================================="
echo "Blockshade CI Check"
echo "=========================================="
echo ""

cd "$(dirname "$0")/.."

echo "1. Getting dependencies..."
flutter pub get
echo "   Done."
echo ""

echo "2. Running flutter analyze..."
flutter analyze --fatal-infos
echo "   Analyze passed."
echo ""

echo "3. Running tests..."
flutter test
echo "   Tests passed."
echo ""

echo "4. Verifying levels are loadable..."
if [ -f "assets/levels/world1.json" ] && [ -f "assets/levels/world2.json" ] && [ -f "assets/levels/world3.json" ]; then
    echo "   All level files present."
    
    world1_count=$(cat assets/levels/world1.json | grep -c '"id"')
    world2_count=$(cat assets/levels/world2.json | grep -c '"id"')
    world3_count=$(cat assets/levels/world3.json | grep -c '"id"')
    total=$((world1_count + world2_count + world3_count))
    
    echo "   World 1: $world1_count levels"
    echo "   World 2: $world2_count levels"
    echo "   World 3: $world3_count levels"
    echo "   Total: $total levels"
    
    if [ "$total" -ne 60 ]; then
        echo "   ERROR: Expected 60 levels, found $total"
        exit 1
    fi
    
    solvable_count=$(grep -c '"solvable": true' assets/levels/*.json || echo 0)
    echo "   Solvable: $solvable_count levels"
    
    if [ "$solvable_count" -ne 60 ]; then
        echo "   ERROR: Not all levels are solvable!"
        exit 1
    fi
    
    echo "   All levels verified."
else
    echo "   ERROR: Level files missing!"
    exit 1
fi
echo ""

echo "=========================================="
echo "All checks passed!"
echo "=========================================="
