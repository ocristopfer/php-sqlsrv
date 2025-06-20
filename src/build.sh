#!/bin/bash

# Docker Build Script for Multiple PHP Versions
# This script builds Docker images from multiple Dockerfiles with different PHP versions

set -e  # Exit on any error

# Configuration
IMAGE_NAME="php-sqlsrv"  # Change this to your desired image name
BUILD_CONTEXT="."        # Build context directory
REGISTRY="ocristopfer/"              # Optional: Add your registry URL (e.g., "myregistry.com/")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to extract PHP version from filename
get_php_version() {
    local filename="$1"
    # Extract version from filename like "php7-4.Dockerfile" -> "7.4"
    echo "$filename" | sed -n 's/.*php\([0-9]\+\)-\([0-9]\+\)\.Dockerfile/\1.\2/p'
}

# Function to build Docker image
build_image() {
    local dockerfile="$1"
    local php_version="$2"
    local tag="${REGISTRY}${IMAGE_NAME}:php${php_version}"
    local quiet="$3"

    if [ "$quiet" != "true" ]; then
        print_status "Building image: $tag"
        print_status "Using Dockerfile: $dockerfile"
    fi

    if [ "$quiet" = "true" ]; then
        if docker build -f "$dockerfile" -t "$tag" "$BUILD_CONTEXT" > /dev/null 2>&1; then
            print_success "Successfully built: $tag"
            return 0
        else
            print_error "Failed to build: $tag"
            return 1
        fi
    else
        if docker build -f "$dockerfile" -t "$tag" "$BUILD_CONTEXT"; then
            print_success "Successfully built: $tag"
            return 0
        else
            print_error "Failed to build: $tag"
            return 1
        fi
    fi
}

# Function to list available Dockerfiles
list_dockerfiles() {
    print_status "Available Dockerfiles:"
    for dockerfile in php*.Dockerfile; do
        if [ -f "$dockerfile" ]; then
            local version=$(get_php_version "$dockerfile")
            echo "  - $dockerfile (PHP $version)"
        fi
    done
}

# Function to build all images
build_all() {
    local success_count=0
    local total_count=0
    local failed_builds=()
    local quiet="${1:-false}"

    if [ "$quiet" != "true" ]; then
        print_status "Starting build process for all PHP versions..."
        echo
    fi

    for dockerfile in php*.Dockerfile; do
        if [ -f "$dockerfile" ]; then
            local php_version=$(get_php_version "$dockerfile")

            if [ -z "$php_version" ]; then
                if [ "$quiet" != "true" ]; then
                    print_warning "Could not extract PHP version from: $dockerfile"
                fi
                continue
            fi

            ((total_count++))

            if [ "$quiet" != "true" ]; then
                echo
                print_status "Building $total_count: $dockerfile"
            fi

            if build_image "$dockerfile" "$php_version" "$quiet"; then
                ((success_count++))
            else
                failed_builds+=("$dockerfile")
            fi
        fi
    done

    echo
    print_status "Build Summary:"
    echo "  Total builds: $total_count"
    echo "  Successful: $success_count"
    echo "  Failed: $((total_count - success_count))"

    if [ ${#failed_builds[@]} -gt 0 ]; then
        echo
        print_error "Failed builds:"
        for failed in "${failed_builds[@]}"; do
            echo "  - $failed"
        done
        return 1
    else
        echo
        print_success "All builds completed successfully!"
        return 0
    fi
}

# Function to build specific PHP version
build_specific() {
    local target_version="$1"
    local dockerfile="php${target_version//./-}.Dockerfile"

    if [ ! -f "$dockerfile" ]; then
        print_error "Dockerfile not found: $dockerfile"
        return 1
    fi

    build_image "$dockerfile" "$target_version"
}

# Function to show built images
show_images() {
    print_status "Built images:"
    docker images | grep "$IMAGE_NAME" | head -20
}

# Function to clean up images
cleanup_images() {
    print_warning "This will remove all images matching pattern: ${IMAGE_NAME}:php*"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker images --format "table {{.Repository}}:{{.Tag}}" | grep "${IMAGE_NAME}:php" | xargs docker rmi
        print_success "Cleanup completed"
    else
        print_status "Cleanup cancelled"
    fi
}

# Function to show help
show_help() {
    cat << EOF
Docker Build Script for Multiple PHP Versions

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    build-all              Build all PHP versions
    build <version>        Build specific PHP version (e.g., 7.4, 8.3)
    list                   List available Dockerfiles
    images                 Show built images
    cleanup                Remove all built images
    help                   Show this help message

Examples:
    $0 build-all           # Build all available PHP versions
    $0 build 8.3           # Build only PHP 8.3
    $0 list                # List available Dockerfiles
    $0 images              # Show built images
    $0 cleanup             # Clean up all built images

Configuration:
    Edit the script to change:
    - IMAGE_NAME: Base name for your images
    - REGISTRY: Docker registry URL (optional)
    - BUILD_CONTEXT: Build context directory

EOF
}

# Main script logic
main() {
    case "${1:-}" in
        "build-all")
            build_all
            ;;
        "build")
            if [ -z "$2" ]; then
                print_error "Please specify PHP version (e.g., 7.4, 8.3)"
                exit 1
            fi
            build_specific "$2"
            ;;
        "list")
            list_dockerfiles
            ;;
        "images")
            show_images
            ;;
        "cleanup")
            cleanup_images
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        "")
            print_error "No command specified"
            show_help
            exit 1
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

# Run main function with all arguments
main "$@"
