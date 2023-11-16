#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 -h <input_file> -output <output_directory>"
    echo "Example: $0 -h ip_addresses.txt -output scan_results"
    exit 1

# Check if Nikto is installed
command -v nikto >/dev/null 2>&1 || { echo >&2 "Nikto is not installed. Please install it before running this script."; exit 1; }

# File containing IP addresses (one per line)
ip_file="ip_addresses.txt"

# Check if the IP file exists
if [ ! -f "$ip_file" ]; then
    echo "IP address file not found: $ip_file"
    exit 1
fi

# Create a timestamp for the output directory
timestamp=$(date +"%Y%m%d%H%M%S")
output_dir="nikto_scan_$timestamp"

# Create the output directory
mkdir "$output_dir"

# Create a file to store extracted URLs
url_file="$output_dir/extracted_urls_$ip_address.txt"

# Loop through each IP address in the file
while IFS= read -r ip_address; do
    # Run Nikto scan for the current IP address
    echo "Scanning $ip_address..."
    nikto -h "$ip_address" -output "$output_dir/nikto_scan_$ip_address.txt"
    
    # Extract URLs from the Nikto scan output and save to the URL file
    grep -o 'See: [^ ]*' "$output_dir/nikto_scan_$ip_address.txt" | cut -d' ' -f2- | sed 's/:$//' >> "$url_file"

done < "$ip_file"

echo "Scans completed. Results stored in $output_dir directory."
echo "Extracted URLs saved to $url_file."

# Open each URL in a new browser page
if [ -s "$url_file" ]; then
    echo "Opening URLs in the default browser..."
    while IFS= read -r url; do
        xdg-open "$url"
    done < "$url_file"
else
    echo "No URLs found or extracted."
fi
