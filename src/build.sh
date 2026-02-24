#!/bin/bash

# Docker Build Script for Multiple PHP Versions
# This script builds Docker images from multiple Dockerfiles with different PHP versions and variants

set -e  # Exit on any error

# Configuration
IMAGE_NAME="php-sqlsrv"
REGISTRY="ocristopfer/"

# Resolve the directory where this script lives so it works from any CWD
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_CONTEXT="$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status()  { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# Extract PHP version and variant from filename
# e.g. "php7-4.Dockerfile" -> "7.4|"
#      "php7-4-nginx.Dockerfile" -> "7.4|nginx"
get_php_info() {
    local filename="$1"
    if [[ "$filename" =~ php([0-9]+)-([0-9]+)(-(.+))?\.Dockerfile ]]; then
        echo "${BASH_REMATCH[1]}.${BASH_REMATCH[2]}|${BASH_REMATCH[4]}"
    else
        echo "|"
    fi
}

# Build the full image tag
create_tag() {
    local php_version="$1"
    local variant="$2"
    if [ -n "$variant" ]; then
        echo "${REGISTRY}${IMAGE_NAME}:php${php_version}-${variant}"
    else
        echo "${REGISTRY}${IMAGE_NAME}:php${php_version}"
    fi
}

# Build a single image; optionally push it afterwards
build_image() {
    local dockerfile="$1"
    local php_version="$2"
    local variant="$3"
    local do_push="${4:-false}"
    local tag
    tag=$(create_tag "$php_version" "$variant")

    print_status "Building $tag  (Dockerfile: $(basename "$dockerfile"))"

    docker build -f "$dockerfile" -t "$tag" "$BUILD_CONTEXT" || {
        print_error "Failed to build: $tag"
        return 1
    }
    print_success "Built: $tag"

    if [ "$do_push" = "true" ]; then
        push_image "$tag"
    fi
}

# Push a single tag to the registry
push_image() {
    local tag="$1"
    print_status "Pushing $tag ..."
    docker push "$tag" || {
        print_error "Failed to push: $tag"
        return 1
    }
    print_success "Pushed: $tag"
}

# List available Dockerfiles
list_dockerfiles() {
    print_status "Available Dockerfiles:"
    for dockerfile in "$SCRIPT_DIR"/php*.Dockerfile; do
        [ -f "$dockerfile" ] || continue
        local info php_version variant
        info=$(get_php_info "$(basename "$dockerfile")")
        php_version="${info%%|*}"
        variant="${info##*|}"
        if [ -n "$php_version" ]; then
            local label="PHP $php_version"
            [ -n "$variant" ] && label="$label - $variant"
            echo "  - $(basename "$dockerfile") ($label)"
        else
            echo "  - $(basename "$dockerfile") (unable to parse version)"
        fi
    done
}

# Build (and optionally push) all images
build_all() {
    local do_push="${1:-false}"
    local success_count=0 total_count=0
    local failed_builds=()

    print_status "Starting build for all PHP versions..."
    [ "$do_push" = "true" ] && print_status "Images will be pushed after each build."
    echo

    for dockerfile in "$SCRIPT_DIR"/php*.Dockerfile; do
        [ -f "$dockerfile" ] || continue
        local info php_version variant
        info=$(get_php_info "$(basename "$dockerfile")")
        php_version="${info%%|*}"
        variant="${info##*|}"

        if [ -z "$php_version" ]; then
            print_warning "Could not extract PHP version from: $(basename "$dockerfile")"
            continue
        fi

        total_count=$((total_count + 1))
        echo
        local label="PHP $php_version"
        [ -n "$variant" ] && label="$label - $variant"
        print_status "[$total_count] $label"

        if build_image "$dockerfile" "$php_version" "$variant" "$do_push"; then
            success_count=$((success_count + 1))
        else
            failed_builds+=("$(basename "$dockerfile")")
        fi
    done

    echo
    print_status "Build Summary:"
    echo "  Total:      $total_count"
    echo "  Successful: $success_count"
    echo "  Failed:     $((total_count - success_count))"

    if [ ${#failed_builds[@]} -gt 0 ]; then
        echo
        print_error "Failed builds:"
        for f in "${failed_builds[@]}"; do echo "  - $f"; done
        return 1
    fi

    echo
    print_success "All builds completed successfully!"
}

# Build (and optionally push) a specific version/variant
build_specific() {
    local target_version="$1"
    local target_variant="${2:-}"
    local do_push="${3:-false}"
    local dockerfile

    if [ -n "$target_variant" ]; then
        dockerfile="$SCRIPT_DIR/php${target_version//./-}-${target_variant}.Dockerfile"
    else
        dockerfile="$SCRIPT_DIR/php${target_version//./-}.Dockerfile"
    fi

    if [ ! -f "$dockerfile" ]; then
        print_error "Dockerfile not found: $(basename "$dockerfile")"
        print_status "Available Dockerfiles for PHP $target_version:"
        for alt in "$SCRIPT_DIR"/php${target_version//./-}*.Dockerfile; do
            [ -f "$alt" ] || continue
            local info variant
            info=$(get_php_info "$(basename "$alt")")
            variant="${info##*|}"
            if [ -n "$variant" ]; then
                echo "  - $(basename "$alt") (variant: $variant)"
            else
                echo "  - $(basename "$alt") (base)"
            fi
        done
        return 1
    fi

    build_image "$dockerfile" "$target_version" "$target_variant" "$do_push"
}

# Push all images that match the image name pattern
push_all() {
    print_status "Pushing all ${IMAGE_NAME} images..."
    local tags
    tags=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "^${REGISTRY}${IMAGE_NAME}:php")
    if [ -z "$tags" ]; then
        print_warning "No local images found matching ${REGISTRY}${IMAGE_NAME}:php*"
        return 1
    fi
    while IFS= read -r tag; do
        push_image "$tag"
    done <<< "$tags"
    print_success "All pushes completed."
}

show_images() {
    print_status "Built images:"
    docker images | grep "$IMAGE_NAME"
}

cleanup_images() {
    print_warning "This will remove all images matching: ${REGISTRY}${IMAGE_NAME}:php*"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker images --format "{{.Repository}}:{{.Tag}}" \
            | grep "^${REGISTRY}${IMAGE_NAME}:php" \
            | xargs -r docker rmi
        print_success "Cleanup completed."
    else
        print_status "Cleanup cancelled."
    fi
}

show_help() {
    cat << EOF
Docker Build Script for Multiple PHP Versions and Variants

Usage: $0 <command> [options]

Commands:
  build-all                     Build all PHP versions/variants
  build-all --push              Build all and push to registry
  push-all                      Push all already-built images

  build <version> [variant]     Build a specific version (e.g. 8.3, 7.4 nginx)
  build <version> [variant] --push   Build and push

  push <version> [variant]      Push a specific image

  list                          List available Dockerfiles
  images                        Show locally built images
  cleanup                       Remove all built images
  help                          Show this message

Examples:
  $0 build-all
  $0 build-all --push
  $0 build 8.3
  $0 build 7.4 nginx --push
  $0 push 8.4
  $0 push-all
  $0 list
  $0 images
  $0 cleanup

Tag format:
  php7-4.Dockerfile          -> ${REGISTRY}${IMAGE_NAME}:php7.4
  php7-4-nginx.Dockerfile    -> ${REGISTRY}${IMAGE_NAME}:php7.4-nginx
  php8-3.Dockerfile          -> ${REGISTRY}${IMAGE_NAME}:php8.3
  php8-4.Dockerfile          -> ${REGISTRY}${IMAGE_NAME}:php8.4
EOF
}

# ── Main ────────────────────────────────────────────────────────────────────

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

case "${1:-}" in
    build-all)
        DO_PUSH=false
        [[ "${2:-}" == "--push" ]] && DO_PUSH=true
        build_all "$DO_PUSH"
        ;;
    build)
        if [ -z "${2:-}" ]; then
            print_error "Please specify a PHP version (e.g., 7.4, 8.3)"
            exit 1
        fi
        VERSION="$2"
        VARIANT=""
        DO_PUSH=false
        # parse remaining args: optional variant (no --) and optional --push
        shift 2
        for arg in "$@"; do
            case "$arg" in
                --push) DO_PUSH=true ;;
                *)      VARIANT="$arg" ;;
            esac
        done
        build_specific "$VERSION" "$VARIANT" "$DO_PUSH"
        ;;
    push-all)
        push_all
        ;;
    push)
        if [ -z "${2:-}" ]; then
            print_error "Please specify a PHP version (e.g., 7.4, 8.3)"
            exit 1
        fi
        TAG=$(create_tag "$2" "${3:-}")
        push_image "$TAG"
        ;;
    list)    list_dockerfiles ;;
    images)  show_images ;;
    cleanup) cleanup_images ;;
    help|-h|--help) show_help ;;
    "")
        print_error "No command specified."
        show_help
        exit 1
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
