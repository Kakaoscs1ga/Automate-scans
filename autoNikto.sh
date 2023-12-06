#!/bin/bash

# Automated Nikto scanning script for multiple IP addresses with specific parameters

# Function to display usage information
usage() {
    echo "Usage: $0 -i <input_file> -o <output_directory>"
    echo "Example: $0 -i ip_addresses.txt -o scan_results"
    exit 1
}

# Initialize variables with default values
input_file="ip_addresses.txt"
timestamp=$(date +"%Y%m%d%H%M%S")
output_directory="nikto_scan_${timestamp}"

# Parse command line options
while getopts ":i:o:" opt; do
    case $opt in
        i)
            input_file="$OPTARG"
            ;;
        o)
            output_directory="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            usage
            ;;
    esac
done

# Check if required options are provided
if [ -z "$input_file" ]; then
    echo "Error: Input file must be specified."
    usage
fi

# Create output directory if it doesn't exist
mkdir -p "$output_directory"

# Store the IP addresses in an array
mapfile -t ip_addresses < "$input_file"

# Loop through each IP address in the array
for ip_address in "${ip_addresses[@]}"; do
    # Run Nikto scan for the current IP address
    echo -e "\n..........................................................................."
    echo "Scanning $ip_address..."
    nikto -h "$ip_address" -output "${output_directory}/nikto_scan_${ip_address}.txt"

    # Extract URLs from the Nikto scan output and save to the URL file
    grep -o 'See: [^ ]*' "${output_directory}/nikto_scan_${ip_address}.txt" | cut -d' ' -f2- | sed 's/:$//' >> "${output_directory}/extracted_urls_${ip_address}.txt"

    echo "Scans completed. Results stored in ${output_directory} directory."
    echo "Extracted URLs saved to ${output_directory}/extracted_urls_${ip_address}.txt"

    # Open URLs for the current IP address
    url_file="${output_directory}/extracted_urls_${ip_address}.txt"

    # Open each URL in a new browser page
    if [ -s "$url_file" ]; then
        echo "Opening URLs for $ip_address in the default browser..."
        while IFS= read -r url; do
            if command -v xdg-open > /dev/null; then
                xdg-open "$url"
            elif command -v open > /dev/null; then
                open "$url"
            else
                echo "Unsupported platform. Cannot open URLs."
            fi
        done < "$url_file"
    else
        echo "No URLs found or extracted for $ip_address."
    fi
done
