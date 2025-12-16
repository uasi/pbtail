_default:
    @just --list

build:
    swift build

build-release:
    swift build --configuration release

build-release-archive:
    [[ -f .build/release/pbtail ]]
    mkdir -p release
    zip --junk-paths release/pbtail.zip .build/release/pbtail

format:
    swift format format --in-place --recursive Package.swift Sources

lint:
    swift format lint --recursive Package.swift Sources

test:
    swift test

prepare-release version:
    # Parent commit must be trunk
    jj log -n 0 -r 'exactly(@- & trunk(), 1)'

    # Working copy must be empty
    jj log -n 0 -r 'exactly(@ & empty(), 1)'

    # Verify version strings
    grep -F '"'{{ quote(version) }}'"' Sources/pbtail/pbtail.swift
    grep -E '^## ' CHANGELOG.md | grep -F {{ quote(version) }}

    # Test and build
    just lint
    just test
    just build-release
    just build-release-archive

    # Verify release artifacts
    unzip -d release release/pbtail.zip
    [[ "$(release/pbtail --version)" = {{ quote(version) }} ]]

    # Sign release artifacts
    command -v minisign-op >/dev/null 2>&1 && minisign-op -S -m release/pbtail.zip

    # Create a signed tag
    git tag -s -m v{{ quote(version) }} v{{ quote(version) }}
