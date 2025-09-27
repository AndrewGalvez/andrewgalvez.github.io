#!/bin/bash

# Configuration
GAMES_JSON="public/games.json"
PREV_DIR="prev_releases"
DOWNLOAD_DIR="public/downloads"
WASM_DIR="public/wasm"
DOWNLOADED_ANYTHING=false

# Create necessary directories
mkdir -p "$PREV_DIR" "$DOWNLOAD_DIR" "$WASM_DIR"

# Function to extract repo name from GitHub URL
get_repo_from_url() {
    echo "$1" | sed 's|https://github.com/||' | sed 's|.git$||'
}

# Function to get game prefix from repo name
get_game_prefix() {
    local repo="$1"
    echo "${repo##*/}"  # Get last part after /
}

# Check if required tools are available
check_dependencies() {
    local missing_deps=()
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if ! command -v gh &> /dev/null; then
        missing_deps+=("gh")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v unzip &> /dev/null; then
        missing_deps+=("unzip")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "❌ Missing required dependencies: ${missing_deps[*]}"
        echo "Please install them before running this script."
        exit 1
    fi
}

# Function to handle WASM zip extraction
handle_wasm_zip() {
    local zip_file="$1"
    local game_prefix="$2"
    
    echo "🎮 Processing WASM zip file: $(basename "$zip_file")"
    
    # First, let's see what's in the zip
    echo "🔍 Inspecting zip contents..."
    local zip_contents=$(unzip -l "$zip_file" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "❌ Failed to inspect zip file"
        return 1
    fi
    
    # Show top-level structure
    echo "📁 Zip structure:"
    echo "$zip_contents" | grep -E "^\s*[0-9]+" | head -10 | awk '{print "   " $4}'
    
    # Remove any existing extracted folders for this game in wasm directory
    # Look for folders that might have been extracted previously
    local existing_folders=$(find "$WASM_DIR" -maxdepth 1 -type d -name "*" | grep -v "^$WASM_DIR$")
    if [ -n "$existing_folders" ]; then
        echo "🧹 Checking for existing WASM folders to clean up..."
        # Remove folders that contain files from this game (based on zip contents)
        local first_folder=$(echo "$zip_contents" | grep -E "^\s*[0-9]+" | head -1 | awk '{print $4}' | cut -d'/' -f1)
        if [ -n "$first_folder" ] && [ -d "$WASM_DIR/$first_folder" ]; then
            echo "🗑️  Removing old version: $WASM_DIR/$first_folder"
            rm -rf "$WASM_DIR/$first_folder"
        fi
    fi
    
    # Extract zip contents directly to WASM directory (preserving internal folder structure)
    echo "📦 Extracting WASM files to: $WASM_DIR"
    if unzip -q "$zip_file" -d "$WASM_DIR"; then
        echo "✅ Successfully extracted WASM files"
        
        # Find what was actually extracted
        local extracted_folders=$(find "$WASM_DIR" -maxdepth 1 -type d -name "*" | grep -v "^$WASM_DIR$")
        if [ -n "$extracted_folders" ]; then
            echo "📁 Extracted folders:"
            echo "$extracted_folders" | sed 's/^/   /'
            
            # Count files in all extracted folders
            local wasm_count=$(find "$WASM_DIR" -name "*.wasm" | wc -l)
            local js_count=$(find "$WASM_DIR" -name "*.js" | wc -l)
            local data_count=$(find "$WASM_DIR" -name "*.data" | wc -l)
            local html_count=$(find "$WASM_DIR" -name "*.html" | wc -l)
            
            echo "   📊 Total files found: ${wasm_count} .wasm, ${js_count} .js, ${data_count} .data, ${html_count} .html"
            
            # Show some example files
            echo "📄 Sample extracted files:"
            find "$WASM_DIR" -type f | head -5 | sed 's/^/   /'
        else
            echo "⚠️  No folders extracted, files may be at root level"
            # List files directly in WASM_DIR
            find "$WASM_DIR" -maxdepth 1 -type f | head -5 | sed 's/^/   /'
        fi
        
        return 0
    else
        echo "❌ Failed to extract WASM zip file"
        return 1
    fi
}

# Check if games.json exists
if [ ! -f "$GAMES_JSON" ]; then
    echo "❌ Games JSON file not found: $GAMES_JSON"
    exit 1
fi

# Check dependencies
check_dependencies

echo "🚀 Starting game release checker..."
echo "Games file: $GAMES_JSON"
echo "Previous releases: $PREV_DIR"
echo "Download directory: $DOWNLOAD_DIR"
echo "WASM directory: $WASM_DIR"
echo ""

# Process each game in games.json
while IFS='|' read -r game_name github_url; do
    # Skip empty lines
    [ -z "$game_name" ] && continue
    
    echo "===================="
    echo "Checking: $game_name"
    echo "Repo: $github_url"
    
    # Extract repository path
    REPO=$(get_repo_from_url "$github_url")
    GAME_PREFIX=$(get_game_prefix "$REPO")
    PREV_FILE="$PREV_DIR/${GAME_PREFIX}.txt"
    
    echo "Repository: $REPO"
    echo "Game prefix: $GAME_PREFIX"
    
    # Get latest release info
    echo "Fetching release information..."
    FULL="$(gh api repos/$REPO/releases/latest 2>/dev/null)"
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to fetch release info for $REPO"
        echo "   This could be due to:"
        echo "   - Repository doesn't exist or is private"
        echo "   - No GitHub authentication (try: gh auth login)"
        echo "   - Network issues"
        continue
    fi
    
    # Check if there are any releases
    if [ "$FULL" = "null" ] || [ -z "$FULL" ]; then
        echo "ℹ️  No releases found for $game_name"
        continue
    fi
    
    # Parse release information
    ID="$(echo "$FULL" | jq -r '.id // empty')"
    TAG="$(echo "$FULL" | jq -r '.tag_name // empty')"
    PREV="$(cat "$PREV_FILE" 2>/dev/null || echo '')"
    
    if [ -z "$ID" ] || [ -z "$TAG" ]; then
        echo "❌ Failed to parse release information"
        continue
    fi
    
    echo "Current release: $TAG (ID: $ID)"
    echo "Previous ID: ${PREV:-'None'}"
    
    if [ "$ID" != "$PREV" ]; then
        echo "🎉 New release found for $game_name!"
        DOWNLOADED_ANYTHING=true
        
        # Check if there are assets
        ASSET_COUNT=$(echo "$FULL" | jq '.assets | length')
        if [ "$ASSET_COUNT" -eq 0 ]; then
            echo "⚠️  No assets found in release"
            echo "$ID" > "$PREV_FILE"
            continue
        fi
        
        echo "Downloading $ASSET_COUNT asset(s)..."
        
        # Create a temporary file to store asset info
        TEMP_ASSETS=$(mktemp)
        echo "$FULL" | jq -r '.assets[] | "\(.browser_download_url)|\(.name)"' > "$TEMP_ASSETS"
        
        # Download each asset with original filename
        while IFS='|' read -r download_url original_name; do
            [ -z "$download_url" ] && continue
            
            target_path="$DOWNLOAD_DIR/$original_name"
            
            echo "📥 Downloading: $original_name"
            echo "   URL: $download_url"
            echo "   Target: $target_path"
            
            # Remove old file if it exists
            [ -f "$target_path" ] && rm "$target_path"
            
            # Download new file with progress bar and error handling
            if curl -L --fail --show-error --progress-bar "$download_url" -o "$target_path"; then
                echo "✅ Successfully downloaded: $original_name"
                # Verify file was actually downloaded and has content
                if [ -f "$target_path" ] && [ -s "$target_path" ]; then
                    echo "   File size: $(du -h "$target_path" | cut -f1)"
                    
                    # Special handling for wasm.zip files
                    if [[ "$original_name" == "wasm.zip" ]]; then
                        echo "🎯 Detected WASM zip file"
                        if handle_wasm_zip "$target_path" "$GAME_PREFIX"; then
                            echo "✅ WASM files processed successfully"
                        else
                            echo "❌ Failed to process WASM files"
                        fi
                    fi
                else
                    echo "❌ Downloaded file is empty or missing"
                fi
            else
                echo "❌ Failed to download: $original_name"
            fi
        done < "$TEMP_ASSETS"
        
        # Clean up temporary file
        rm "$TEMP_ASSETS"
        
        # Update the stored release ID
        echo "$ID" > "$PREV_FILE"
        echo "✅ Updated release tracking for $game_name"
        
    else
        echo "ℹ️  No new release for $game_name"
    fi
    
    echo ""
done < <(jq -r '.data[] | select(.githubpath != "none" and .githubpath != null) | "\(.name)|\(.githubpath)"' "$GAMES_JSON")

echo "🏁 Finished checking all games!"
echo ""

if [ "$DOWNLOADED_ANYTHING" = true ]; then
    echo "📦 New downloads detected - updating website..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ Not in a git repository. Skipping git operations."
        exit 1
    fi
    
    # Check if there are changes to commit
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "📝 Committing changes..."
        git add .
        git commit -m "Updated downloads - $(date '+%Y-%m-%d %H:%M:%S')"
        
        echo "🚀 Pushing to repository..."
        if git push; then
            echo "✅ Successfully pushed changes"
            
            # Deploy if npm is available and package.json exists
            if command -v npm &> /dev/null && [ -f "package.json" ]; then
                echo "🌐 Deploying website..."
                if npm run deploy; then
                    echo "✅ Website deployed successfully"
                else
                    echo "❌ Failed to deploy website"
                    exit 1
                fi
            else
                echo "⚠️  npm not available or package.json not found - skipping deployment"
            fi
        else
            echo "❌ Failed to push changes"
            exit 1
        fi
    else
        echo "ℹ️  No changes to commit"
    fi
else
    echo "ℹ️  No new downloads - website update not needed"
fi

echo ""
echo "✨ Script completed successfully!"
