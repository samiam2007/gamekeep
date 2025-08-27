#!/bin/bash

# GameKeep Test Runner Script
# Runs all test suites with coverage reporting

set -e

echo "🎲 GameKeep Test Suite Runner"
echo "=============================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter is not installed. Please install Flutter first.${NC}"
    exit 1
fi

# Function to run tests with nice output
run_test_suite() {
    local suite_name=$1
    local test_path=$2
    
    echo -e "${YELLOW}Running $suite_name...${NC}"
    
    if flutter test $test_path --coverage; then
        echo -e "${GREEN}✓ $suite_name passed${NC}"
    else
        echo -e "${RED}✗ $suite_name failed${NC}"
        exit 1
    fi
    echo ""
}

# Clean previous coverage data
rm -rf coverage/

# Run unit tests
echo "1️⃣  Unit Tests"
echo "-------------"
run_test_suite "Model Tests" "test/models/"
run_test_suite "Service Tests" "test/services/"

# Run widget tests
echo "2️⃣  Widget Tests"
echo "---------------"
run_test_suite "Widget Tests" "test/widgets/"

# Run performance tests
echo "3️⃣  Performance Tests"
echo "--------------------"
run_test_suite "Performance Tests" "test/performance/"

# Run all tests together for coverage
echo "4️⃣  Running All Tests with Coverage"
echo "-----------------------------------"
flutter test --coverage

# Generate coverage report
if command -v lcov &> /dev/null; then
    echo ""
    echo "📊 Generating Coverage Report..."
    lcov --remove coverage/lcov.info \
         'lib/generated/*' \
         'lib/*.g.dart' \
         -o coverage/lcov.info
    
    # Generate HTML report if genhtml is available
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html
        echo -e "${GREEN}Coverage report generated at: coverage/html/index.html${NC}"
    fi
    
    # Display coverage summary
    echo ""
    echo "Coverage Summary:"
    lcov --summary coverage/lcov.info
fi

# Run integration tests (if on a connected device/emulator)
echo ""
echo "5️⃣  Integration Tests (Optional)"
echo "--------------------------------"
echo "To run integration tests, ensure you have a device/emulator connected and run:"
echo "flutter test integration_test/"

# Final summary
echo ""
echo "=============================="
echo -e "${GREEN}✅ All test suites completed!${NC}"
echo ""

# Check test coverage threshold
if command -v lcov &> /dev/null; then
    coverage_percent=$(lcov --summary coverage/lcov.info 2>&1 | grep -oE '[0-9]+\.[0-9]+%' | head -1 | sed 's/%//')
    
    if (( $(echo "$coverage_percent > 80" | bc -l) )); then
        echo -e "${GREEN}✓ Code coverage: ${coverage_percent}% (Excellent!)${NC}"
    elif (( $(echo "$coverage_percent > 60" | bc -l) )); then
        echo -e "${YELLOW}⚠ Code coverage: ${coverage_percent}% (Good, but could be improved)${NC}"
    else
        echo -e "${RED}✗ Code coverage: ${coverage_percent}% (Below recommended threshold)${NC}"
    fi
fi

echo ""
echo "Run 'open coverage/html/index.html' to view detailed coverage report"