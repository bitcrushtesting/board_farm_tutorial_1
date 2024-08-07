#!/bin/bash

# Copyright © 2024 Bitcrush Testing

# Function to check if the script is running on a Raspberry Pi
check_raspberry_pi() {
    if grep -q 'Raspberry Pi' /proc/cpuinfo; then
        echo "Running on Raspberry Pi."
        return 0
    else
        echo "This script is not running on a Raspberry Pi."
        return 1
    fi
}

# Function to prompt for input and read the response
prompt_for_input() {
    local prompt_message="$1"
    local input_variable_name="$2"
    # shellcheck disable=SC2229
    read -rp "$prompt_message: " "$input_variable_name"
}

# Function to check if arduino-cli is installed
check_arduino_cli() {
    if command -v arduino-cli &> /dev/null; then
        echo "arduino-cli is already installed."
        return 0
    else
        echo "arduino-cli is not installed."
        return 1
    fi
}

# Function to install arduino-cli
install_arduino_cli() {
    echo "Installing arduino-cli..."
    curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
    sudo mv bin/arduino-cli /usr/local/bin/
    echo "arduino-cli installed successfully."
}

install_github_runner() {
    echo "Installing GitHub runner..."
    RUNNER_DIR=${HOME}/actions-runner

    if [ -d "${RUNNER_DIR}" ] 
    then
        echo "GitHub runner is already installed."
        read -rp "Do you want to overwrite it? (yes/no) " yn

        case $yn in 
	        yes ) echo "Ok, proceeding";;
	        no ) echo "Not installing GitHub runner";
		        return;;
	        * ) echo "Invalid response. Not installing Github runner.";
		        return;;
        esac
    fi 
    rm -rf "${RUNNER_DIR}"
    mkdir -p "${RUNNER_DIR}" && cd "${RUNNER_DIR}"
    echo "Install folder: ${RUNNER_DIR}"
    curl -o actions-runner-linux-arm64-2.317.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.317.0/actions-runner-linux-arm64-2.317.0.tar.gz
    echo "7e8e2095d2c30bbaa3d2ef03505622b883d9cb985add6596dbe2f234ece308f3  actions-runner-linux-arm64-2.317.0.tar.gz" | shasum -a 256 -c
    tar xzf ./actions-runner-linux-arm64-2.317.0.tar.gz
    sudo ./bin/installdependencies.sh

    # Prompt for necessary inputs
    prompt_for_input "Enter your GitHub token" GH_TOKEN
    prompt_for_input "Enter the GitHub repository URL (e.g., https://github.com/user)" GH_URL
    prompt_for_input "Enter the GitHub runner name" GH_RUNNER_NAME
    # Configuring the GitHub runner
    ./config.sh remove --token "$GH_TOKEN"
    ./config.sh --url "$GH_URL" --token "$GH_TOKEN" --name "$GH_RUNNER_NAME" --work "${RUNNER_DIR}/_work" --unattended --replace
  
    # Create the systemd service file
    SERVICE_FILE="/etc/systemd/system/github-runner.service"
    sudo rm -f "${SERVICE_FILE}"
    sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=GitHub Actions Runner
After=network.target

[Service]
User=$USER
Group=$USER
WorkingDirectory=$RUNNER_DIR
ExecStart=$RUNNER_DIR/run.sh
Restart=always
RestartSec=10
StartLimitInterval=600
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOL

    # Reload systemd configuration
    sudo systemctl daemon-reload

    # Enable and start the service
    sudo systemctl enable github-runner.service
    sudo systemctl start github-runner.service

    # Verify the service status
    sudo systemctl status github-runner.service
}

install_python() {
    sudo apt update && sudo apt install -y \
        curl \
        git \
        jq \
        tree \
        python3 \
        python3-pip \
        python3-pytest \
        && sudo apt-get clean
}

# Main script execution
set -e
USER_ID=$(id -u)

if [[ "$USER_ID" -eq 0 ]] && [[ -z "$RUNNER_ALLOW_RUNASROOT" ]]; then
    echo "Must not run with sudo"
    exit 1
fi

if check_raspberry_pi; then
    if ! check_arduino_cli; then
        install_arduino_cli
    fi
    install_github_runner

else
    echo "This script can only be run on a Raspberry Pi."
    exit 1
fi
