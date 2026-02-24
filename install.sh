#!/bin/bash
set -e

# Configuration
PLUGIN_NAME="FlowState"
CLAUDE_ROOT="${CLAUDE_ROOT:-$HOME/.claude}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Enable glob options for robust file handling
shopt -s nullglob dotglob

echo -e "${BLUE}📦 Installing $PLUGIN_NAME plugin...${NC}"
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
        echo -e "${YELLOW}  ⚠️  Backed up existing: $(basename "$file")${NC}"
        echo -e "     → $backup"
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
echo -e "${BLUE}→ Installing core documentation (CLAUDE.md)...${NC}"
if [ -f "CLAUDE.md" ]; then
    safe_copy "CLAUDE.md" "$CLAUDE_ROOT/CLAUDE.md"
    echo -e "${GREEN}  ✅ CLAUDE.md installed${NC}"
fi

# 2. Install ALL content from .claude/ directory
echo -e "${BLUE}→ Installing content from .claude/ directory...${NC}"

for item in .claude/*; do
    name=$(basename "$item")

    # Skip files that need special handling or should be ignored
    if [[ "$name" == "settings.json" ]]; then continue; fi
    if [[ "$name" == "settings.local.json" ]]; then continue; fi
    if [[ "$name" == "changelog_config.json" ]]; then continue; fi
    if [[ "$name" == "." || "$name" == ".." ]]; then continue; fi

    # Recursive copy for everything else
    if [ -e "$item" ]; then
        safe_copy "$item" "$CLAUDE_ROOT/$name"
        echo -e "${GREEN}  ✅ $name installed${NC}"
    fi
done

# Disable glob options
shopt -u nullglob dotglob

# 3. Handle changelog_config.json (with backup)
if [ -f ".claude/changelog_config.json" ]; then
    echo -e "${BLUE}→ Installing changelog_config.json...${NC}"
    if [ -f "$CLAUDE_ROOT/changelog_config.json" ]; then
        backup_file "$CLAUDE_ROOT/changelog_config.json"
    fi
    safe_copy ".claude/changelog_config.json" "$CLAUDE_ROOT/changelog_config.json"
    echo -e "${GREEN}  ✅ changelog_config.json installed${NC}"
fi

# 4. Handle settings.json with user interaction
if [ -f ".claude/settings.json" ]; then
    echo -e "${BLUE}→ Checking settings.json...${NC}"

    if [ -f "$CLAUDE_ROOT/settings.json" ]; then
        echo ""
        echo -e "${YELLOW}⚠️  Existing settings.json found at: $CLAUDE_ROOT/settings.json${NC}"
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
                echo -e "${GREEN}  ✅ settings.json replaced${NC}"
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
                    echo -e "${GREEN}  ✅ settings.json replaced${NC}"
                else
                    echo -e "${YELLOW}  ⏭️  Skipped settings.json${NC}"
                fi
                ;;
            *)
                echo -e "${YELLOW}  ⏭️  Kept existing settings.json${NC}"
                ;;
        esac
    else
        safe_copy .claude/settings.json "$CLAUDE_ROOT/settings.json"
        echo -e "${GREEN}  ✅ settings.json installed${NC}"
    fi
fi

# Summary
echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo -e "${BLUE}📚 Quick Start:${NC}"
echo "  1. Start workflow: ${GREEN}/optimize-prompt${NC}"
echo "  2. View commands:  ${GREEN}ls ~/.claude/commands/${NC}"
echo "  3. View skills:    ${GREEN}ls ~/.claude/skills/${NC}"
echo ""
echo -e "${YELLOW}💡 Tip: If this is your first installation, please review:${NC}"
echo "   ~/.claude/settings.json"
echo ""
