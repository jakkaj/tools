#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

# Script name for help text
SCRIPT_NAME="$(basename "$0")"

# Configuration
CONTAINER_PREFIX="code-server"
BASE_PORT=8080
MAX_PORT=8099
PASSWORD="jordo"
DOCKER_IMAGE="linuxserver/code-server:latest"

# Status output functions
print_status() { echo "[*] $1"; }
print_success() { echo "[✓] $1"; }
print_error() { echo "[✗] $1" >&2; }

show_help() {
  cat << EOF
NAME
    $SCRIPT_NAME - Launch code-server Docker containers with automatic port and naming

SYNOPSIS
    $SCRIPT_NAME [--help]
    $SCRIPT_NAME [directory]

DESCRIPTION
    Launches a code-server (VS Code in the browser) Docker container with automatic
    ordinal naming and port allocation. Multiple instances can run side-by-side,
    each getting the next available container name and port.

    Containers are named sequentially: code-server-1, code-server-2, etc.
    Ports are allocated starting at 8080, finding the first available port.

PARAMETERS
    directory
        Optional. Directory to mount as the project workspace.
        Defaults to current working directory if not specified.
        Will be mounted at /home/coder/project inside the container.

OPTIONS
    --help, -h
        Display this help message and exit

EXAMPLES
    # Start code-server in current directory
    $SCRIPT_NAME

    # Start code-server with a specific project directory
    $SCRIPT_NAME ~/projects/myapp

    # Start multiple instances (run command multiple times)
    $SCRIPT_NAME ~/project1  # Gets code-server-1 on port 8080
    $SCRIPT_NAME ~/project2  # Gets code-server-2 on port 8081

CONTAINER DETAILS
    Image: $DOCKER_IMAGE
    Password: $PASSWORD
    Port range: $BASE_PORT-$MAX_PORT
    Mount: <directory>:/workspace
    Restart policy: none (manual restart required)

    Environment variables:
    PUID/PGID                      Run as your user (avoids permission issues)
    PASSWORD                       Password for authentication
    DEFAULT_WORKSPACE              Opens directly in your project folder

REMOTE ACCESS
    For remote access, use SSH port forwarding to avoid certificate issues:

    ssh -L 8080:localhost:8080 user@remote-host

    Then open http://localhost:8080 in your browser.
    This creates a secure tunnel and browsers treat localhost as a secure context.

MANAGEMENT
    # List running code-server containers
    docker ps --filter "name=$CONTAINER_PREFIX"

    # Stop a specific container
    docker stop code-server-1

    # Stop all code-server containers
    docker stop \$(docker ps -q --filter "name=$CONTAINER_PREFIX")

    # Remove all code-server containers
    docker rm \$(docker ps -aq --filter "name=$CONTAINER_PREFIX")

ALIAS
    jk-cs - Shortened alias available after running setup

REQUIREMENTS
    - Docker must be installed and running
    - User must have permission to run Docker commands

AUTHOR
    Part of the jk-tools collection

EOF
}

# Find the next available ordinal number for container naming
find_next_ordinal() {
  local ordinal=1

  # Get list of existing container names (running and stopped)
  local existing_containers
  existing_containers=$(docker ps -a --filter "name=^${CONTAINER_PREFIX}-" --format "{{.Names}}" 2>/dev/null || echo "")

  if [[ -z "$existing_containers" ]]; then
    echo "$ordinal"
    return
  fi

  # Extract ordinal numbers and find the next available
  while true; do
    if ! echo "$existing_containers" | grep -q "^${CONTAINER_PREFIX}-${ordinal}$"; then
      echo "$ordinal"
      return
    fi
    ((ordinal++))

    # Safety limit
    if [[ $ordinal -gt 100 ]]; then
      print_error "Too many containers exist (>100)"
      exit 1
    fi
  done
}

# Find the next available port starting from BASE_PORT
find_available_port() {
  local port=$BASE_PORT

  while [[ $port -le $MAX_PORT ]]; do
    # Check if port is in use using lsof (works on macOS and Linux)
    if ! lsof -i ":$port" >/dev/null 2>&1; then
      # Also check if Docker has a container mapped to this port
      if ! docker ps --format "{{.Ports}}" 2>/dev/null | grep -q "0.0.0.0:${port}->"; then
        echo "$port"
        return
      fi
    fi
    ((port++))
  done

  print_error "No available ports in range $BASE_PORT-$MAX_PORT"
  exit 1
}

# Detect git worktree and return the parent .git directory path
# Returns empty string if not a worktree, or the path to mount if it is
detect_worktree_git_dir() {
  local project_dir="$1"
  local git_file="${project_dir}/.git"

  # Check if .git is a file (worktree) rather than a directory
  if [[ -f "$git_file" ]]; then
    # Print to stderr so it doesn't pollute the return value
    echo "[*] Detected .git file (worktree indicator)" >&2

    # Parse the gitdir path from the .git file
    local gitdir
    gitdir=$(grep "^gitdir:" "$git_file" | sed 's/^gitdir: //')
    echo "[*]   gitdir points to: $gitdir" >&2

    if [[ -n "$gitdir" ]]; then
      # Convert relative path to absolute if needed
      if [[ ! "$gitdir" = /* ]]; then
        gitdir="${project_dir}/${gitdir}"
      fi
      gitdir=$(cd "$(dirname "$gitdir")" 2>/dev/null && pwd)/$(basename "$gitdir")

      # Find the main .git directory (parent of worktrees/)
      # gitdir is typically: /path/to/repo/.git/worktrees/name
      local main_git_dir
      main_git_dir=$(echo "$gitdir" | sed 's|/worktrees/.*$||')

      if [[ -d "$main_git_dir" ]]; then
        echo "[*]   Parent .git directory: $main_git_dir" >&2
        echo "$main_git_dir"
        return
      fi
    fi
  fi

  echo ""
}

# Main function
main() {
  # Show help if requested
  if [[ $# -gt 0 ]] && [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
  fi

  # Check Docker is available
  if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker is not installed or not in PATH"
    exit 1
  fi

  # Check Docker daemon is running
  if ! docker info >/dev/null 2>&1; then
    print_error "Docker daemon is not running"
    exit 1
  fi

  # Determine project directory
  local project_dir
  if [[ $# -gt 0 ]]; then
    project_dir="$(cd "$1" && pwd)"
  else
    project_dir="$(pwd)"
  fi

  # Verify directory exists
  if [[ ! -d "$project_dir" ]]; then
    print_error "Directory does not exist: $project_dir"
    exit 1
  fi

  print_status "Project directory: $project_dir"

  # Detect git worktree and get parent git directory
  local worktree_git_dir
  worktree_git_dir=$(detect_worktree_git_dir "$project_dir")

  # Find next available ordinal and port
  local ordinal
  local port
  ordinal=$(find_next_ordinal)
  port=$(find_available_port)

  local container_name="${CONTAINER_PREFIX}-${ordinal}"

  print_status "Container name: $container_name"
  print_status "Port: $port"

  # Pull latest image (optional, can be skipped if image exists)
  print_status "Ensuring Docker image is available..."
  docker pull "$DOCKER_IMAGE" >/dev/null 2>&1 || true

  # Run the container
  print_status "Starting code-server container..."

  local container_id
  # Build docker run command with optional worktree mount
  local docker_cmd=(
    docker run -d
    --name "$container_name"
    -p "${port}:8443"
    -v "${project_dir}:/workspace"
  )

  # Add worktree git directory mount if detected
  if [[ -n "$worktree_git_dir" ]]; then
    print_status "Adding worktree mount: ${worktree_git_dir}:${worktree_git_dir}:ro"
    docker_cmd+=(-v "${worktree_git_dir}:${worktree_git_dir}:ro")
  fi

  docker_cmd+=(
    -e "PUID=$(id -u)"
    -e "PGID=$(id -g)"
    -e "PASSWORD=$PASSWORD"
    -e "DEFAULT_WORKSPACE=/workspace"
    "$DOCKER_IMAGE"
  )

  container_id=$("${docker_cmd[@]}")

  if [[ -z "$container_id" ]]; then
    print_error "Failed to start container"
    exit 1
  fi

  # Wait a moment for container to start
  sleep 1

  # Verify container is running
  if docker ps -q --filter "id=$container_id" | grep -q .; then
    print_success "Container started successfully"
    echo ""
    echo "  URL:       http://localhost:${port}"
    echo "  Password:  $PASSWORD"
    echo "  Container: $container_name"
    echo "  Project:   $project_dir"
    echo ""
    echo "  Remote: ssh -L ${port}:localhost:${port} user@this-host"
    echo "  Stop:   docker stop $container_name"
  else
    print_error "Container failed to start. Check logs with: docker logs $container_name"
    exit 1
  fi
}

main "$@"
