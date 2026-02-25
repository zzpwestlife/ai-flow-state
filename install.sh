#!/bin/bash
set -e

# Configuration
PLUGIN_NAME="FlowState"

# Colors
# Use tput if available, otherwise fallback to ANSI codes or empty string
if command -v tput >/dev/null 2>&1; then
    GREEN=$(tput setaf 2)
    BLUE=$(tput setaf 4)
    YELLOW=$(tput setaf 3)
    RED=$(tput setaf 1)
    NC=$(tput sgr0)
else
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m'
fi

# Helper function for colored echo
cecho() {
    local color="$1"
    local message="$2"
    echo "${color}${message}${NC}"
}

# Determine Installation Target
if [ -z "$CLAUDE_ROOT" ]; then
    echo "Where would you like to install FlowState?"
    echo "  1) System (Global) - ~/.claude (Recommended for personal tools)"
    echo "  2) Project (Local) - <project_path>/.claude (Recommended for team sharing)"
    echo ""
    read -p "Your choice [1/2]: " install_choice
    
    case "$install_choice" in
        2)
            user_project_path=""
            
            # Try macOS native folder selection dialog first
            if [[ "$(uname)" == "Darwin" ]]; then
                cecho "$BLUE" "Opening Finder to select project directory..."
                # Use osascript to show folder selection dialog
                # Redirect stderr to /dev/null to suppress error if user cancels
                selected_path=$(osascript -e 'try
                    tell application "System Events"
                        activate
                        set folderPath to choose folder with prompt "Select Project Directory for FlowState Installation"
                        POSIX path of folderPath
                    end tell
                on error
                    return ""
                end try' 2>/dev/null)
                
                if [ -n "$selected_path" ]; then
                    user_project_path="$selected_path"
                    # Remove trailing slash if present (osascript returns path with trailing slash)
                    user_project_path=${user_project_path%/}
                else
                    cecho "$YELLOW" "Selection cancelled or failed. Falling back to manual input."
                fi
            fi

            # Fallback to manual input if no path selected (or not on macOS)
            if [ -z "$user_project_path" ]; then
                echo ""
                cecho "$BLUE" "Please enter the absolute path to your project directory:"
                read -e -p "Project Path (default: current directory): " user_project_path
                
                # Default to current directory if empty
                if [ -z "$user_project_path" ]; then
                    user_project_path=$(pwd)
                fi
            else
                 cecho "$GREEN" "Selected project path: $user_project_path"
            fi
            
            # Resolve relative paths to absolute paths
            # Using python for cross-platform realpath/abspath if readlink -f is not available or behaves differently
            if command -v python3 >/dev/null 2>&1; then
                user_project_path=$(python3 -c "import os; print(os.path.abspath('$user_project_path'))")
            else
                # Fallback for simple cases
                if [[ "$user_project_path" != /* ]]; then
                    user_project_path="$(pwd)/$user_project_path"
                fi
            fi

            # Check if directory exists
            if [ ! -d "$user_project_path" ]; then
                cecho "$RED" "Error: Directory '$user_project_path' does not exist."
                exit 1
            fi
            
            CLAUDE_ROOT="$user_project_path/.claude"
            PROJECT_INSTALL=true
            cecho "$GREEN" "Target set to: $CLAUDE_ROOT"
            echo ""
            ;;
        *)
            CLAUDE_ROOT="$HOME/.claude"
            PROJECT_INSTALL=false
            ;;
    esac
else
    # Environment variable overrides interactive choice
    PROJECT_INSTALL=false
fi

# Enable glob options for robust file handling
shopt -s nullglob dotglob

cecho "$BLUE" "📦 Installing $PLUGIN_NAME plugin..."
echo "Target directory: $CLAUDE_ROOT"
echo ""

# Ensure directories exist
mkdir -p "$CLAUDE_ROOT/commands"
mkdir -p "$CLAUDE_ROOT/skills"
mkdir -p "$CLAUDE_ROOT/agents"
mkdir -p "$CLAUDE_ROOT/hooks"
mkdir -p "$CLAUDE_ROOT/docs"
mkdir -p "$CLAUDE_ROOT/audit"

# Backup function
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        cecho "$YELLOW" "  ⚠️  Backed up existing: $(basename "$file")"
        echo "     → $backup"
    fi
}

# Recursive copy function that handles symlinks (replaces them with copies)
# This fixes "cp: identical" errors when switching from dev (symlink) to prod (copy) mode
safe_copy() {
    local src="$1"
    local dest="$2"
    
    # If destination is a symlink (file or directory), remove it first
    if [ -L "$dest" ]; then
        rm "$dest"
    fi
    
    if [ -d "$src" ]; then
        # Check if source and destination are the same
        if [[ "$(realpath "$src")" == "$(realpath "$dest")" ]]; then
            cecho "$YELLOW" "  ⏭️  Skipping self-copy: $dest"
            return
        fi

        mkdir -p "$dest"
        for child in "$src"/*; do
            local name=$(basename "$child")
            safe_copy "$child" "$dest/$name"
        done
    else
        cp "$src" "$dest"
    fi
}

# 1. Install CLAUDE.md from root (special case as it's outside .claude)
cecho "$BLUE" "→ Installing core documentation (CLAUDE.md)..."
if [ -f "CLAUDE.md" ]; then
        if [ "$PROJECT_INSTALL" = true ]; then
            # For project install, CLAUDE.md stays in root, but maybe we want to backup/replace existing one
            # The script is likely run from root, so CLAUDE.md is already there.
            # If we are installing INTO another project (unlikely usage pattern for this script), we'd copy.
            # But let's assume we are installing FROM a repo TO the current dir.
            # If source CLAUDE.md is different from destination CLAUDE.md (e.g. updating template), copy.
            
            DEST_CLAUDE_MD="$(dirname "$CLAUDE_ROOT")/CLAUDE.md"
            if [[ "$(realpath "CLAUDE.md")" != "$(realpath "$DEST_CLAUDE_MD")" ]]; then
                safe_copy "CLAUDE.md" "$DEST_CLAUDE_MD"
                cecho "$GREEN" "  ✅ CLAUDE.md installed to project root"
            else
                 cecho "$YELLOW" "  ⏭️  CLAUDE.md already in place (Project Root)"
            fi
        else
            safe_copy "CLAUDE.md" "$CLAUDE_ROOT/CLAUDE.md"
            cecho "$GREEN" "  ✅ CLAUDE.md installed to global config"
        fi
    fi

# 2. Install ALL content from .claude/ directory
cecho "$BLUE" "→ Installing content from .claude/ directory..."

for item in .claude/*; do
    name=$(basename "$item")

    # Skip files that need special handling or should be ignored
    if [[ "$name" == "settings.json" ]]; then continue; fi
    if [[ "$name" == "settings.local.json" ]]; then continue; fi
    if [[ "$name" == "changelog_config.json" ]]; then continue; fi
    if [[ "$name" == "." || "$name" == ".." ]]; then continue; fi

    # Recursive copy for everything else
    if [[ "$(realpath "$item")" == "$(realpath "$CLAUDE_ROOT/$name")" ]]; then
        cecho "$YELLOW" "  ⏭️  Skipping self-copy: $name"
    else
        if [ -e "$item" ]; then
            safe_copy "$item" "$CLAUDE_ROOT/$name"
            cecho "$GREEN" "  ✅ $name installed"
        fi
    fi
done

# Disable glob options
shopt -u nullglob dotglob

# 3. Handle changelog_config.json (with backup)
if [ -f ".claude/changelog_config.json" ]; then
    cecho "$BLUE" "→ Installing changelog_config.json..."
    if [ -f "$CLAUDE_ROOT/changelog_config.json" ]; then
        backup_file "$CLAUDE_ROOT/changelog_config.json"
    fi
    if [[ "$(realpath ".claude/changelog_config.json")" != "$(realpath "$CLAUDE_ROOT/changelog_config.json")" ]]; then
        safe_copy ".claude/changelog_config.json" "$CLAUDE_ROOT/changelog_config.json"
        cecho "$GREEN" "  ✅ changelog_config.json installed"
    else
        cecho "$YELLOW" "  ⏭️  Skipped self-copy: changelog_config.json"
    fi
fi

# 4. Handle settings.json with user interaction
if [ -f ".claude/settings.json" ]; then
    cecho "$BLUE" "→ Checking settings.json..."

    if [ -f "$CLAUDE_ROOT/settings.json" ]; then
        echo ""
        cecho "$YELLOW" "⚠️  Existing settings.json found at: $CLAUDE_ROOT/settings.json"
        echo "Please choose an option:"
        echo "  1) Keep existing (skip)"
        echo "  2) Backup and replace"
        echo "  3) Show diff and decide"
        echo ""
        read -p "Your choice [1/2/3]: " choice

        case "$choice" in
            2)
                backup_file "$CLAUDE_ROOT/settings.json"
                safe_copy .claude/settings.json "$CLAUDE_ROOT/settings.json"
                cecho "$GREEN" "  ✅ settings.json replaced"
                ;;
            3)
                echo ""
                echo "=== Diff ==="
                diff "$CLAUDE_ROOT/settings.json" ".claude/settings.json" || true
                echo "=== End of diff ==="
                echo ""
                read -p "Replace? [y/N]: " replace
                if [[ "$replace" =~ ^[Yy]$ ]]; then
                    backup_file "$CLAUDE_ROOT/settings.json"
                    safe_copy .claude/settings.json "$CLAUDE_ROOT/settings.json"
                    cecho "$GREEN" "  ✅ settings.json replaced"
                else
                    cecho "$YELLOW" "  ⏭️  Skipped settings.json"
                fi
                ;;
            *)
                cecho "$YELLOW" "  ⏭️  Kept existing settings.json"
                ;;
        esac
    else
        if [[ "$PROJECT_INSTALL" = true && "$(realpath ".claude/settings.json")" == "$(realpath "$CLAUDE_ROOT/settings.json")" ]]; then
             cecho "$YELLOW" "  ⏭️  Skipping self-copy: settings.json"
        else
            safe_copy .claude/settings.json "$CLAUDE_ROOT/settings.json"
            cecho "$GREEN" "  ✅ settings.json installed"
        fi
    fi
fi

# Summary
echo ""
cecho "$GREEN" "✅ Installation complete!"
echo ""
cecho "$BLUE" "📚 Quick Start:"
if [ "$PROJECT_INSTALL" = true ]; then
    echo "  1. Navigate to project: ${GREEN}cd $(dirname "$CLAUDE_ROOT")${NC}"
    echo "  2. Start workflow:      ${GREEN}/optimize-prompt${NC}"
    echo "  3. View commands:       ${GREEN}ls .claude/commands/${NC}"
    echo "  4. View skills:         ${GREEN}ls .claude/skills/${NC}"
else
    echo "  1. Start workflow: ${GREEN}/optimize-prompt${NC}"
    echo "  2. View commands:  ${GREEN}ls ~/.claude/commands/${NC}"
    echo "  3. View skills:    ${GREEN}ls ~/.claude/skills/${NC}"
fi

echo ""
cecho "$YELLOW" "💡 Tip: If this is your first installation, please review:"
if [ "$PROJECT_INSTALL" = true ]; then
    echo "   $(dirname "$CLAUDE_ROOT")/.claude/settings.json"
else
    echo "   ~/.claude/settings.json"
fi
echo ""
