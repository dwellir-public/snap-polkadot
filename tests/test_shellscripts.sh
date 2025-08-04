#!/bin/sh

# Setup mock environment for testing outside of snap
setup_mock_snap_environment() {
    # Set default values if not already set (for testing outside snap)
    if [ -z "$SNAP" ]; then
        SNAP="${SNAP:-$(pwd)}"
        export SNAP
    fi
    
    if [ -z "$SNAP_COMMON" ]; then
        SNAP_COMMON="${SNAP_COMMON:-/tmp/snap-polkadot-test}"
        export SNAP_COMMON
        # Create the directory if it doesn't exist
        mkdir -p "$SNAP_COMMON"
    fi
    
    if [ -z "$SNAP_DATA" ]; then
        SNAP_DATA="${SNAP_DATA:-/tmp/snap-polkadot-data-test}"
        export SNAP_DATA
        mkdir -p "$SNAP_DATA"
    fi
    
    # Always create mock snapctl for testing to avoid permission issues
    # Create a temporary mock snapctl script
    MOCK_SNAPCTL_DIR="/tmp/mock-snapctl-$$"
    mkdir -p "$MOCK_SNAPCTL_DIR"
    
    cat > "$MOCK_SNAPCTL_DIR/snapctl" << 'EOF'
#!/bin/sh
# Mock snapctl for testing

MOCK_CONFIG_FILE="/tmp/mock-snap-config-$$"

case "$1" in
    "get")
        key="$2"
        if [ -f "$MOCK_CONFIG_FILE" ]; then
            # Look for exact key match, handle both key=value and key formats
            value=$(grep "^$key=" "$MOCK_CONFIG_FILE" 2>/dev/null | head -1 | cut -d'=' -f2-)
            if [ -n "$value" ]; then
                echo "$value"
            fi
        fi
        ;;
    "set")
        key_value="$2"
        # Remove any existing entry for this key
        key=$(echo "$key_value" | cut -d'=' -f1)
        if [ -f "$MOCK_CONFIG_FILE" ]; then
            grep -v "^$key=" "$MOCK_CONFIG_FILE" > "$MOCK_CONFIG_FILE.tmp" 2>/dev/null || true
            mv "$MOCK_CONFIG_FILE.tmp" "$MOCK_CONFIG_FILE" 2>/dev/null || true
        fi
        # Add the new key=value pair
        echo "$key_value" >> "$MOCK_CONFIG_FILE"
        ;;
    "unset")
        key="$2"
        if [ -f "$MOCK_CONFIG_FILE" ]; then
            grep -v "^$key=" "$MOCK_CONFIG_FILE" > "$MOCK_CONFIG_FILE.tmp" 2>/dev/null || true
            mv "$MOCK_CONFIG_FILE.tmp" "$MOCK_CONFIG_FILE" 2>/dev/null || true
        fi
        ;;
    *)
        echo "Mock snapctl: unsupported command $1" >&2
        exit 1
        ;;
esac
EOF
    chmod +x "$MOCK_SNAPCTL_DIR/snapctl"
    
    # Prepend to PATH to ensure our mock takes precedence
    export PATH="$MOCK_SNAPCTL_DIR:$PATH"
    
    # Set a cleanup trap
    trap 'rm -rf "$MOCK_SNAPCTL_DIR" "/tmp/mock-snap-config-$$" 2>/dev/null' EXIT
    
    echo "Mock snap environment setup:"
    echo "  SNAP=$SNAP"
    echo "  SNAP_COMMON=$SNAP_COMMON"
    echo "  SNAP_DATA=$SNAP_DATA"
    echo "  snapctl: $(command -v snapctl)"
    
    # Verify our mock is being used
    if [ "$(command -v snapctl)" = "$MOCK_SNAPCTL_DIR/snapctl" ]; then
        echo "  Mock snapctl is active"
    else
        echo "  Warning: Real snapctl may still be in use"
    fi
}

# Test function for validate_service_args
test_validate_service_args() {
    echo "Testing validate_service_args function..."
    
    # Setup mock environment first
    setup_mock_snap_environment
    
    . $SNAP/utils/service-args-utils.sh

    local test_count=0
    local passed_count=0
    
    # Helper function to run a test case
    run_test_case() {
        local description="$1"
        local args="$2"
        local expected_exit_code="$3"
        local test_name="$4"
        
        test_count=$((test_count + 1))
        echo "  Test $test_count: $description"
        
        # Capture current service args to restore later
        local original_args="$(get_service_args)"
        
        # Run validate_service_args in a subshell to capture exit code
        (validate_service_args $args) >/dev/null 2>&1
        local actual_exit_code=$?
        
        if [ "$actual_exit_code" -eq "$expected_exit_code" ]; then
            echo "    PASSED: Expected exit code $expected_exit_code, got $actual_exit_code"
            passed_count=$((passed_count + 1))
        else
            echo "    FAILED: Expected exit code $expected_exit_code, got $actual_exit_code"
        fi
        
        # Restore original service args
        set_service_args "$original_args"
    }
    
    # Test 1: Valid base-path with equals format (allowed path)
    run_test_case "Valid base-path with equals format" \
                  "--base-path=$SNAP_COMMON/polkadot_base/data" \
                  0 \
                  "valid_base_path_equals"
    
    # Test 2: Valid base-path with space format (allowed path)
    run_test_case "Valid base-path with space format" \
                  "--base-path $SNAP_COMMON/polkadot_base/subdir" \
                  0 \
                  "valid_base_path_space"
    
    # Test 3: Valid base-path pointing to /mnt
    run_test_case "Valid base-path pointing to /mnt" \
                  "--base-path=/mnt/external-drive" \
                  0 \
                  "valid_mnt_path"
    
    # Test 4: Valid base-path pointing to /media
    run_test_case "Valid base-path pointing to /media" \
                  "--base-path=/media/usb-drive" \
                  0 \
                  "valid_media_path"
    
    # Test 5: Valid base-path pointing to /run/media
    run_test_case "Valid base-path pointing to /run/media" \
                  "--base-path=/run/media/user/drive" \
                  0 \
                  "valid_run_media_path"
    
    # Test 6: Invalid base-path (not in allowed paths)
    run_test_case "Invalid base-path (not allowed)" \
                  "--base-path=/home/user/data" \
                  1 \
                  "invalid_base_path"
    
    # Test 7: Invalid base-path pointing to root
    run_test_case "Invalid base-path pointing to root" \
                  "--base-path=/" \
                  1 \
                  "invalid_root_path"
    
    # Test 8: Invalid base-path pointing to /tmp
    run_test_case "Invalid base-path pointing to /tmp" \
                  "--base-path=/tmp/polkadot" \
                  1 \
                  "invalid_tmp_path"
    
    # Test 9: Missing path after --base-path flag
    run_test_case "Missing path after --base-path flag" \
                  "--base-path" \
                  1 \
                  "missing_base_path"
    
    # Test 10: Multiple arguments with valid base-path
    run_test_case "Multiple arguments with valid base-path" \
                  "--name=test-node --base-path=$SNAP_COMMON/polkadot_base --port=30333" \
                  0 \
                  "multiple_args_valid"
    
    # Test 11: Multiple arguments with invalid base-path
    run_test_case "Multiple arguments with invalid base-path" \
                  "--name=test-node --base-path=/invalid/path --port=30333" \
                  1 \
                  "multiple_args_invalid"
    
    # Test 12: No base-path argument (should pass)
    run_test_case "No base-path argument" \
                  "--name=test-node --port=30333" \
                  0 \
                  "no_base_path"
    
    # Test 13: Empty arguments (should pass)
    run_test_case "Empty arguments" \
                  "" \
                  0 \
                  "empty_args"
    
    # Test 14: Base-path exactly matching allowed path (not subdirectory)
    run_test_case "Base-path exactly matching allowed path" \
                  "--base-path=$SNAP_COMMON/polkadot_base" \
                  0 \
                  "exact_allowed_path"
    
    # Test 15: Multiple base-path arguments (last one invalid)
    run_test_case "Multiple base-path arguments (last invalid)" \
                  "--base-path=$SNAP_COMMON/polkadot_base --base-path=/invalid/path" \
                  1 \
                  "multiple_base_paths_invalid"
    
    # Print test summary
    echo ""
    echo "Test Summary:"
    echo "  Total tests: $test_count"
    echo "  Passed: $passed_count"
    echo "  Failed: $((test_count - passed_count))"
    
    if [ "$passed_count" -eq "$test_count" ]; then
        echo "  All tests passed!"
        return 0
    else
        echo "  Some tests failed."
        return 1
    fi
}

test_validate_service_args