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

echo -e "${BLUE}📦 Installing $PLUGIN_NAME plugin...${NC}"
echo "Target directory: $CLAUDE_ROOT"
echo ""

# Ensure directories exist
mkdir -p "$CLAUDE_ROOT/commands"
mkdir -p "$CLAUDE_ROOT/skills"
mkdir -p "$CLAUDE_ROOT/agents"
mkdir -p "$CLAUDE_ROOT/hooks"

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

# Copy files
echo -e "${BLUE}→ Installing commands...${NC}"
if [ -d ".claude/commands" ]; then
    cp -R .claude/commands/* "$CLAUDE_ROOT/commands/"
fi

echo -e "${BLUE}→ Installing skills...${NC}"
if [ -d ".claude/skills" ]; then
    cp -R .claude/skills/* "$CLAUDE_ROOT/skills/"
fi

echo -e "${BLUE}→ Installing agents...${NC}"
if [ -d ".claude/agents" ]; then
    cp -R .claude/agents/* "$CLAUDE_ROOT/agents/"
fi

echo -e "${BLUE}→ Installing hooks...${NC}"
if [ -d ".claude/hooks" ]; then
    cp -R .claude/hooks/* "$CLAUDE_ROOT/hooks/"
fi

# Handle settings.json with user interaction
if [ -f ".claude/settings.json" ]; then
    echo -e "${BLUE}→ Checking settings.json...${NC}"

    if [ -f "$CLAUDE_ROOT/settings.json" ]; then
        echo ""
        echo -e "${YELLOW}⚠️  Existing settings.json found at:$CLAUDE_ROOT/settings.json${NC}"
        echo "Please choose an option:"
        echo "  1) Keep existing (skip)"
        echo "  2) Backup and replace"
        echo "  3) Show diff and decide"
        echo ""
        read -p "Your choice [1/2/3]: " choice

        case "$choice" in
            2)
                backup_file "$CLAUDE_ROOT/settings.json"
                cp .claude/settings.json "$CLAUDE_ROOT/settings.json"
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
                    cp .claude/settings.json "$CLAUDE_ROOT/settings.json"
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
        cp .claude/settings.json "$CLAUDE_ROOT/settings.json"
        echo -e "${GREEN}  ✅ settings.json installed${NC}"
    fi
fi

# Install configuration files
echo -e "${BLUE}→ Installing configuration files...${NC}"
if [ -f ".claude/changelog_config.json" ]; then
    if [ -f "$CLAUDE_ROOT/changelog_config.json" ]; then
        backup_file "$CLAUDE_ROOT/changelog_config.json"
    fi
    cp .claude/changelog_config.json "$CLAUDE_ROOT/changelog_config.json"
    echo -e "${GREEN}  ✅ changelog_config.json installed${NC}"
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
