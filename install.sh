#!/bin/bash

# Define the Git repository URL
REPO_URL="https://github.com/Elahi-cs/nvim-config.git"

# Define the target directory in the user's home
TARGET_DIR="$HOME/.test_config"

# Check if the target directory exists, create if it does not
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p $TARGET_DIR
    echo "Created $TARGET_DIR because it did not exist."
fi

# Clone the repository into a temporary directory
TEMP_DIR=$(mktemp -d)
git clone $REPO_URL $TEMP_DIR

# Check if the clone was successful
if [ $? -eq 0 ]; then
    # Copy the contents of the repo to the target directory
    cp -r $TEMP_DIR/* $TARGET_DIR

    # Clean up the temporary directory
    rm -rf $TEMP_DIR

    echo "Repository contents copied to $TARGET_DIR successfully."
else
    echo "Failed to clone the repository."
    exit 1
fi

