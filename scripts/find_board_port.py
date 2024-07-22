#!/usr/bin/env python3
# Copyright © 2024 Bitcrush Testing

import subprocess
import json
import sys
import argparse

def run_command(command):
    """Run a shell command and return the output."""
    try:
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        return result.stdout.decode('utf-8').strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running command {command}: {e.stderr.decode('utf-8')}")
        sys.exit(1)

def find_board_port(fqbn):
    """Find the port of a connected board with the given FQBN."""
    command = ["arduino-cli", "board", "list", "--fqbn", fqbn, "--format", "json"]
    output = run_command(command)
    boards = json.loads(output)
    
    for board in boards['detected_ports']:
        return board['port']['address']
    
    print(f"No board found with FQBN {fqbn}")
    sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Find the port of a connected board based on the given FQBN.")
    parser.add_argument("fqbn", help="Fully Qualified Board Name (FQBN) of the Arduino board")
    args = parser.parse_args()
    
    port = find_board_port(args.fqbn)
    print(port)

if __name__ == "__main__":
    main()
