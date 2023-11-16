#!/bin/bash

# Automated Nmap scanning script for multiple IP addresses with specific parameters

# Function to display usage information
usage() {
    echo "Usage: $0 -i <input_file> -o <output_directory>"
    echo "Example: $0 -i ip_addresses.txt -o scan_results"
    exit 1
}

# Initialize variables with default values
input_file="ip_addresses.txt"
timestamp=$(date +"%Y%m%d%H%M%S")
output_directory="nmap_scan_$timestamp"

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

# Read IP addresses from the input file and perform Nmap scan
while IFS= read -r ip_address; do
	echo -e " "
	echo -e "---------------------------------------------------------------------------"
    echo "Running Nmap scan on $ip_address"
    nmap --top-ports 1000 -T4 -oN "$output_directory/nmap_results_$ip_address.txt" "$ip_address"
    echo "Scan complete. Results saved to $output_directory/nmap_results_$ip_address.txt"

    # Grep open ports from the Nmap results file
    open_ports=$(grep "open" "$output_directory/nmap_results_$ip_address.txt" |  cut -d'/' -f1 | tr '\n' ',')

    if [ -n "$open_ports" ]; then
        # Perform aggressive scan on open ports
	echo -e " "
        echo "Performing aggressive scan on open ports $open_ports"
        nmap -A -p "$open_ports" -oN "$output_directory/aggressive_scan_$ip_address.txt" "$ip_address"
        echo "Aggressive scan complete. Results saved to $output_directory/aggressive_scan_$ip_address.txt"
    else
        echo "No open ports found for $ip_address. Skipping aggressive scan."
    fi
done < "$input_file"
