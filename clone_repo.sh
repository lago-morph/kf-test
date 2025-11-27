#!/bin/bash

# clone_repo.sh - Clone a GitHub repository using SSH
# Usage: clone_repo.sh REPOSITORY [--org ORGANIZATION]

set -euo pipefail  # Exit on error, undefined variable, or pipe failure

# Default GitHub organization (change this to your preferred default)
DEFAULT_GITHUB_ORGANIZATION="lago-morph"

# Initialize variables
GITHUB_REPOSITORY=""
GITHUB_ORGANIZATION="$DEFAULT_GITHUB_ORGANIZATION"
CLONE_DESTINATION="$HOME/src"

# Function to display usage information
usage() {
    cat << EOF
Usage: $(basename "$0") REPOSITORY [--org ORGANIZATION]

Clone a GitHub repository using SSH to ~/src/

Arguments:
    REPOSITORY          Name of the GitHub repository (required)

Options:
    --org ORGANIZATION  GitHub organization/user (default: $DEFAULT_GITHUB_ORGANIZATION)

Examples:
    $(basename "$0") my_repo
    $(basename "$0") test_repo --org my_org

Description:
    Clones git@github.com:ORGANIZATION/REPOSITORY to ~/src/REPOSITORY

EOF
    exit 1
}

# Function to display error message and exit
error_exit() {
    echo "Error: $1" >&2
    echo "Run '$(basename "$0")' without arguments for usage information." >&2
    exit 1
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    echo "Error: Missing required argument REPOSITORY" >&2
    echo "" >&2
    usage
fi

# First argument is always the repository name
GITHUB_REPOSITORY="$1"
shift

# Parse optional arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --org)
            if [ $# -lt 2 ]; then
                error_exit "--org requires an argument"
            fi
            GITHUB_ORGANIZATION="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            error_exit "Unknown argument: $1"
            ;;
    esac
done

# Validate repository name is not empty
if [ -z "$GITHUB_REPOSITORY" ]; then
    error_exit "Repository name cannot be empty"
fi

# Validate organization name is not empty
if [ -z "$GITHUB_ORGANIZATION" ]; then
    error_exit "Organization name cannot be empty"
fi

# Construct the Git URL
GIT_URL="git@github.com:${GITHUB_ORGANIZATION}/${GITHUB_REPOSITORY}.git"

# Construct the destination path
DESTINATION_PATH="${CLONE_DESTINATION}/${GITHUB_REPOSITORY}"

# Display what we're about to do
echo "================================"
echo "Cloning GitHub Repository"
echo "================================"
echo "Repository:    $GITHUB_REPOSITORY"
echo "Organization:  $GITHUB_ORGANIZATION"
echo "Git URL:       $GIT_URL"
echo "Destination:   $DESTINATION_PATH"
echo "================================"
echo ""

# Create src directory if it doesn't exist
if [ ! -d "$CLONE_DESTINATION" ]; then
    echo "Creating directory: $CLONE_DESTINATION"
    mkdir -p "$CLONE_DESTINATION" || error_exit "Failed to create directory: $CLONE_DESTINATION"
fi

# Check if destination already exists
if [ -d "$DESTINATION_PATH" ]; then
    error_exit "Destination directory already exists: $DESTINATION_PATH"
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    error_exit "git is not installed. Please install git first."
fi

# Clone the repository
echo "Cloning repository..."
if git clone "$GIT_URL" "$DESTINATION_PATH"; then
    echo ""
    echo "================================"
    echo "Successfully cloned repository!"
    echo "================================"
    echo "Location: $DESTINATION_PATH"
    echo ""
    echo "To navigate to the repository:"
    echo "cd $DESTINATION_PATH"
    echo "================================"
    exit 0
else
    error_exit "Failed to clone repository. Please check:
    1. The repository exists at $GIT_URL
    2. You have SSH access configured for GitHub
    3. Your SSH key is added to your GitHub account
    
    Test SSH connection with: ssh -T git@github.com"
fi

exit 0

# A nicer version of this prompt is in clone_repo.sh.md
# This script was created by claude sonnet 4.5 using the following prompt:
# Write me a bash script to clone a repository using git from github using the format git@github.com:${GITHUB_ORGANIZATION}/${GITHUB_REPOSITORY}.
# The name of this script should be clone_repo.sh
# The destination for the cloned repository will be in my linux home directory under the src directory.  For instance, if GITHUB_REPOSITORY is some_name, after it is cloned it will be in the directory ~/src/some_name.
# The GITHUB_REPOSITORY is a mandatory argument.  For instance, if the user invokes the script by typing clone_repo.sh my_repo, the script will set GITHUB_REPOSITORY to my_repo.  If the script is executed without an argument given, the script returns an error with an informative message including an example on how to invoke the script properly, including both the mandatory argument and the optional --org argument.
# The GITHUB_ORGANIZATION should have a default value defined in the script that is used if this is not over-ridden on the script command line.
# The user can over-ride the default GITHUB_ORGANIZATION by invoking the script with the optional --org argument.  For instance, to check out a repository named test_repo from the GITHUB_ORGANIZATION my_org, the user would invoke the script with clone_repo.sh test_repo --org my_org
# The script should use strict error handling so it exits with an informative error if there are any problems.
