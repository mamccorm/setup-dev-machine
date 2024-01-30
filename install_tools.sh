#!/bin/bash

# Define packages and taps to install
declare -a formulae=("apko" "dive" "docker" "docker-credential-helper" "grype" "kind" "melange" "hashicorp/tap/terraform")
declare -a casks=("1password" "google-chrome" "slack" "visual-studio-code")
declare -a taps=("hashicorp/tap")

# Docker desktop Variables
DOCKER_URL="https://desktop.docker.com/mac/stable/arm64/Docker.dmg"
DMG_FILE="Docker.dmg"
VOLUME_PATH="/Volumes/Docker"
APPLICATIONS_DIR="/Applications"

# Function to install Docker
# Note, using 'brew cask' to install docker doesn't work so well.
# It'll continuously prompt each time for creds to create / remove links.

# NOTE: 'brew install --cask docker' does not install cleanly, and prompts
# multiple times for credentials (and we cannot run brew with sudo). As an
# alternative,e we pull doen the .dmg.
#
# This approach requires us to install 'docker' and 'docker-credential-helper'
# CLI tools separately (which we've already covered above).
#
install_docker_desktop() {
    echo "Initiating Docker Desktop installation..."

    # Download Docker for Apple Silicon
    echo "Downloading Docker..."
    curl -L $DOCKER_URL -o $DMG_FILE

    # Attach the DMG
    echo "Attaching DMG..."
    hdiutil attach $DMG_FILE -nobrowse

    # Copy Docker.app to the Applications directory
    echo "Copying Docker.app to the Applications folder..."
    cp -R "$VOLUME_PATH/Docker.app" $APPLICATIONS_DIR

    # Eject the volume
    echo "Ejecting Docker volume..."
    hdiutil detach $VOLUME_PATH

    # Remove the DMG file
    echo "Cleaning up..."
    rm $DMG_FILE

    echo "Docker has been installed. Please open Docker from the Applications folder to complete setup."
}

# Check for XCode Command Line Tools and install if not found
if ! xcode-select -p &>/dev/null; then
    echo "XCode Command Line Tools not found. Installing..."
    xcode-select --install
else
    echo "XCode Command Line Tools already installed."
fi

# Check for Homebrew and install if not found
if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew already installed."
    echo "Updating Homebrew..."
    brew update
fi

# Add necessary taps
for tap in "${taps[@]}"; do
    brew tap "$tap"
done

# Install or reinstall each formula
for package in "${formulae[@]}"; do
    if brew list --formula | grep -q "^${package%%/*}$"; then
        echo "$package is already installed. Attempting to reinstall..."
        brew reinstall "$package"
    else
        echo "Installing $package..."
        brew install "$package"
    fi
done

# Install or reinstall each cask
for app in "${casks[@]}"; do
    if brew list --cask | grep -q "^${app%%/*}$"; then
        echo "$app is already installed. Attempting to reinstall..."
        brew reinstall --cask "$app"
    else
        echo "Installing $app..."
        brew install --cask "$app"
    fi
done

# Check for ~/go/bin on $PATH
check_go_path() {
    if ! echo "$PATH" |grep -q "$USER/go/bin"; then
        if [[ "$SHELL" == "/bin/zsh" ]]; then
            echo 'export PATH="$PATH:$HOME/go/bin"' >> ~/.zshrc
            echo 'Added ~/go/bin to your $PATH. Reopen your terminal or run source ~/.zshrc when this script completes'
        else
            echo 'export PATH="$PATH:$HOME/go/bin"' >> ~/.bashrc
            echo 'Added ~/go/bin to your $PATH. Reopen your terminal or run source ~/.bashrc when this script completes'
        fi
    else
        echo "Already found $HOME/go/bin on path"
    fi
}

install_docker_desktop
check_go_path

echo "All tools including Docker installed or reinstalled successfully!"
