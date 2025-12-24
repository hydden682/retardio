#!/bin/bash
#
# Retardio Automated Test Suite
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test result tracking
declare -a FAILED_TESTS

# Functions
print_header() {
    echo -e "\n${BOLD}${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC} ${BOLD}$1${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════╝${NC}\n"
}

print_test() {
    echo -e "${BLUE}[TEST $TESTS_TOTAL]${NC} $1"
}

pass_test() {
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓ PASS${NC} $1\n"
}

fail_test() {
    ((TESTS_FAILED++))
    FAILED_TESTS+=("$1")
    echo -e "${RED}✗ FAIL${NC} $1\n"
}

run_test() {
    ((TESTS_TOTAL++))
    print_test "$1"

    if eval "$2"; then
        pass_test "$1"
        return 0
    else
        fail_test "$1"
        return 1
    fi
}

# Start tests
clear
cat << "EOF"
╔══════════════════════════════════════════════════════╗
║                                                      ║
║         RETARDIO AUTOMATED TEST SUITE                ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Test 1: File Existence
print_header "Phase 1: File Existence Tests"

run_test "retardio_master_setup.sh exists" "test -f retardio_master_setup.sh"
run_test "easy_setup.sh exists" "test -f easy_setup.sh"
run_test "connect_nodes.sh exists" "test -f connect_nodes.sh"
run_test "create_installer.sh exists" "test -f create_installer.sh"
run_test "chainparamsseeds.h exists" "test -f src/chainparamsseeds.h"

# Test 2: Script Syntax
print_header "Phase 2: Script Syntax Tests"

run_test "retardio_master_setup.sh syntax" "bash -n retardio_master_setup.sh"
run_test "easy_setup.sh syntax" "bash -n easy_setup.sh"
run_test "connect_nodes.sh syntax" "bash -n connect_nodes.sh"
run_test "create_installer.sh syntax" "bash -n create_installer.sh"

# Test 3: Script Permissions
print_header "Phase 3: Permission Tests"

run_test "retardio_master_setup.sh executable" "test -x retardio_master_setup.sh"
run_test "easy_setup.sh executable" "test -x easy_setup.sh"
run_test "connect_nodes.sh executable" "test -x connect_nodes.sh"
run_test "create_installer.sh executable" "test -x create_installer.sh"

# Test 4: chainparamsseeds.h validation
print_header "Phase 4: Configuration Tests"

RETARDIO_COUNT=$(grep -c "Retardio" src/chainparamsseeds.h || echo 0)
run_test "chainparamsseeds.h cleared (Retardio mentions <= 2)" "test $RETARDIO_COUNT -le 2"

SEED_SIZE=$(wc -l < src/chainparamsseeds.h)
run_test "chainparamsseeds.h is small (<50 lines)" "test $SEED_SIZE -lt 50"

# Test 5: Build system
print_header "Phase 5: Build System Tests"

if [ -d "build" ]; then
    run_test "Build directory exists" "true"

    if [ -f "build/Makefile" ]; then
        run_test "Makefile exists" "true"
    else
        fail_test "Makefile exists"
    fi
else
    fail_test "Build directory exists"
    echo -e "${YELLOW}Skipping build tests (no build directory)${NC}\n"
fi

# Test 6: Built binaries (if they exist)
print_header "Phase 6: Binary Tests"

if [ -f "build/bin/retardiod" ]; then
    run_test "retardiod binary exists" "true"
    run_test "retardiod is executable" "test -x build/bin/retardiod"
    run_test "retardiod version check" "build/bin/retardiod --version 2>&1 | grep -q 'version'"
else
    echo -e "${YELLOW}⚠ Skipping binary tests (not built yet)${NC}\n"
fi

if [ -f "build/bin/retardio-cli" ]; then
    run_test "retardio-cli binary exists" "true"
    run_test "retardio-cli is executable" "test -x build/bin/retardio-cli"
else
    echo -e "${YELLOW}⚠ Skipping CLI tests (not built yet)${NC}\n"
fi

# Test 7: Documentation
print_header "Phase 7: Documentation Tests"

run_test "START_HERE.md exists" "test -f START_HERE.md"
run_test "ONE_COMMAND_SETUP.md exists" "test -f ONE_COMMAND_SETUP.md"
run_test "NODE_CONNECTION_GUIDE.md exists" "test -f NODE_CONNECTION_GUIDE.md"

# Test 8: Package creation
print_header "Phase 8: Package Creation Test"

if command -v tar &> /dev/null; then
    echo "Creating test package..."
    if ./create_installer.sh > /tmp/package_test.log 2>&1; then
        run_test "Package creation successful" "true"

        if [ -f "retardio_installer_v1.0.0.tar.gz" ]; then
            run_test "Package archive exists" "true"

            # Test extraction
            mkdir -p /tmp/retardio_test
            if tar -xzf retardio_installer_v1.0.0.tar.gz -C /tmp/retardio_test 2>/dev/null; then
                run_test "Package extraction works" "true"
                run_test "Package contains setup script" "test -f /tmp/retardio_test/retardio_installer/retardio_master_setup.sh"
                rm -rf /tmp/retardio_test
            else
                fail_test "Package extraction works"
            fi
        else
            fail_test "Package archive exists"
        fi
    else
        fail_test "Package creation successful"
        echo "See /tmp/package_test.log for details"
    fi
else
    echo -e "${YELLOW}⚠ Skipping package test (tar not available)${NC}\n"
fi

# Test 9: Node operation (if running)
print_header "Phase 9: Node Operation Tests"

if pgrep -x "retardiod" > /dev/null; then
    echo -e "${BLUE}Node is running, testing RPC...${NC}\n"

    if [ -f "build/bin/retardio-cli" ]; then
        if build/bin/retardio-cli -datadir=~/.retardio getblockchaininfo &> /dev/null; then
            run_test "Node RPC responds" "true"

            BLOCKCOUNT=$(build/bin/retardio-cli -datadir=~/.retardio getblockcount 2>/dev/null || echo 0)
            run_test "Can query block count" "test $BLOCKCOUNT -ge 0"

            CONNCOUNT=$(build/bin/retardio-cli -datadir=~/.retardio getconnectioncount 2>/dev/null || echo -1)
            run_test "Can query connection count" "test $CONNCOUNT -ge 0"
        else
            fail_test "Node RPC responds"
        fi
    else
        echo -e "${YELLOW}⚠ CLI not built, skipping RPC tests${NC}\n"
    fi
else
    echo -e "${YELLOW}⚠ Node not running, skipping operation tests${NC}\n"
fi

# Summary
print_header "Test Summary"

echo -e "${BOLD}Total Tests:${NC} $TESTS_TOTAL"
echo -e "${GREEN}${BOLD}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}${BOLD}Failed:${NC} $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║                                                      ║${NC}"
    echo -e "${GREEN}${BOLD}║              ✓ ALL TESTS PASSED! ✓                   ║${NC}"
    echo -e "${GREEN}${BOLD}║                                                      ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Your Retardio setup is ready to use!${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}${BOLD}║                                                      ║${NC}"
    echo -e "${RED}${BOLD}║              ✗ SOME TESTS FAILED ✗                   ║${NC}"
    echo -e "${RED}${BOLD}║                                                      ║${NC}"
    echo -e "${RED}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}Failed tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "  ${RED}✗${NC} $test"
    done
    echo ""
    echo -e "${YELLOW}Please fix the issues above before proceeding.${NC}"
    echo ""
    exit 1
fi
