#!/bin/bash

display_menu() {
    clear
    echo "Select the self-test to run:"
    echo "1. Short self-test"
    echo "2. Long self-test"
    echo "3. Conveyance self-test"
    echo "4. Current attributes"
    echo "5. nvme-cli attributes"
    echo "Enter your choice (1-3):"
}

handle_input() {
    read -n1 -s choice
    case $choice in
        1)
            run_short_test "$drive_label"
            ;;
        2)
            run_long_test "$drive_label"
            ;;
        3)
            run_conveyance_test "$drive_label"
            ;;
        4)
            sudo smartctl -a /dev/"$drive_label"
            exit
            ;;
        5)
            echo "Try sudo nvme help..."
            sudo nvme smart-log /dev/"$drive_label"
            exit
            ;;
        *)
            echo "Invalid choice. Please try again."
            handle_input
            ;;
    esac
}

# Functions to run the self-test
run_short_test() {

    echo "Running short self-test on /dev/$1..."
    smartctl -t short /dev/"$1"
    show_progress
}

run_long_test() {

    echo "Running long self-test on /dev/$1..."
    smartctl -t long /dev/"$1"
    show_progress
}

run_conveyance_test() {

    echo "Running conveyance self-test on /dev/$1..."
    smartctl -t conveyance /dev/"$1"
    show_progress
}

show_progress() {

# Check that the test didn't fail
    output=$(smartctl -a /dev/"$drive_label")
    if echo "$output" | grep -q "in progress"; then
        echo ""
    else
        echo "Aborting..."
        exit
    fi

# Wait for the test to complete
    while true; do
    	output=$(smartctl -a /dev/"$drive_label")
    	percentage=$(echo "$output" | grep "remaining")
    	if echo "$output" | grep -q "in progress"; then
        	echo "in progress... $percentage"
    	else
        	break
    	fi
    	sleep 10
    done
}

display_results() {
        echo "S.M.A.R.T. TEST COMPLETE!!! for /dev/$drive_label:"
        smartctl -i -A -l selftest /dev/"$drive_label"
}


# Check if an argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 /dev/<drive_label>"
    echo "Available devices:"
    lsblk
    exit 1
fi

# Check if the drive label exists
drive_id=$(lsblk -no NAME,TYPE | grep -E "^$1\s+(disk|part)$")
if [ -z "$drive_id" ]; then
    echo "Error: Drive label '$1' not found."
    echo "Usage: $0 /dev/<drive_label>"
    echo "Available devices:"
    lsblk
    exit 1
fi

drive_label="$1"
display_menu
handle_input
display_results
