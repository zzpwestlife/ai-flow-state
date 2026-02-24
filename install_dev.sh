#!/bin/bash
set -e

# Configuration
PLUGIN_NAME="FlowState"
CLAUDE_ROOT="${CLAUDE_ROOT:-$HOME/.claude}"
PROJECT_ROOT="$(pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛠️  Installing $PLUGIN_NAME in DEV MODE (Symlinks)...${NC}"
echo "Source directory: $PROJECT_ROOT"
echo "Target directory: $CLAUDE_ROOT"
echo ""

# Ensure directories exist
mkdir -p "$CLAUDE_ROOT/commands"
mkdir -p "$CLAUDE_ROOT/skills"
mkdir -p "$CLAUDE_ROOT/agents"
mkdir -p "$CLAUDE_ROOT/hooks"
mkdir -p "$CLAUDE_ROOT/docs"

# Function to create symlink
create_symlink() {
    local src="$1"
    local dest="$2"
    local name=$(basename "$src")

    # If destination exists and is a directory (and not a symlink to our source), backup
    if [ -d "$dest" ] && [ ! -L "$dest" ]; then
        echo -e "${YELLOW}  ⚠️  Backing up existing directory: $dest${NC}"
        mv "$dest" "${dest}.backup.$(date +%Y%m%d_%H%M%S)"
    elif [ -f "$dest" ] && [ ! -L "$dest" ]; then
        echo -e "${YELLOW}  ⚠️  Backing up existing file: $dest${NC}"
        mv "$dest" "${dest}.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    # Remove existing symlink if it exists
    if [ -L "$dest" ]; then
        rm "$dest"
    fi

    # Create symlink
    ln -s "$src" "$dest"
    echo -e "${GREEN}  🔗 Linked $name${NC}"
}

# 1. Link CLAUDE.md
echo -e "${BLUE}→ Linking CLAUDE.md...${NC}"
create_symlink "$PROJECT_ROOT/CLAUDE.md" "$CLAUDE_ROOT/CLAUDE.md"

# 2. Link Commands (individual files to allow other commands to coexist)
echo -e "${BLUE}→ Linking Commands...${NC}"
for file in .claude/commands/*.md; do
    name=$(basename "$file")
    create_symlink "$PROJECT_ROOT/$file" "$CLAUDE_ROOT/commands/$name"
done

# 3. Link Skills (directories)
echo -e "${BLUE}→ Linking Skills...${NC}"
for dir in .claude/skills/*; do
    if [ -d "$dir" ]; then
        name=$(basename "$dir")
        create_symlink "$PROJECT_ROOT/$dir" "$CLAUDE_ROOT/skills/$name"
    fi
done

# 4. Link Agents
echo -e "${BLUE}→ Linking Agents...${NC}"
for file in .claude/agents/*.md; do
    if [ -f "$file" ]; then
        name=$(basename "$file")
        create_symlink "$PROJECT_ROOT/$file" "$CLAUDE_ROOT/agents/$name"
    fi
done

# 5. Link Hooks
echo -e "${BLUE}→ Linking Hooks...${NC}"
for file in .claude/hooks/*; do
    if [ -f "$file" ]; then
        name=$(basename "$file")
        create_symlink "$PROJECT_ROOT/$file" "$CLAUDE_ROOT/hooks/$name"
    fi
done

# 6. Link Configs (carefully)
echo -e "${BLUE}→ Linking Configs...${NC}"
if [ -f ".claude/changelog_config.json" ]; then
    create_symlink "$PROJECT_ROOT/.claude/changelog_config.json" "$CLAUDE_ROOT/changelog_config.json"
fi

# Settings.json - ask before linking as it might contain tokens
if [ -f ".claude/settings.json" ]; then
    if [ ! -f "$CLAUDE_ROOT/settings.json" ]; then
        create_symlink "$PROJECT_ROOT/.claude/settings.json" "$CLAUDE_ROOT/settings.json"
    else
        echo -e "${YELLOW}  ⏭️  Skipped settings.json (exists)${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✅ Dev Mode Installation Complete!${NC}"
echo "Changes in $PROJECT_ROOT will now be reflected immediately in Claude Code."
