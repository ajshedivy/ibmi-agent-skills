# IBM i Agent Skills
Agent skills for AI coding assistants to work with IBM i systems.

## What are Agent Skills?


Agent skills are reusable instruction sets that extend your coding agent's capabilities. They're defined in SKILL.md files with YAML frontmatter containing a name and description.

Skills let agents perform specialized tasks like:

- Generating release notes from git history
- Creating PRs following your team's conventions
- Integrating with external tools (Linear, Notion, etc.)

[**Agent Skills Documentation**](https://agentskills.io/home)

## Prerequisites

The [`ibmi-mcp-server`](https://github.com/IBM/ibmi-mcp-server) must be connected to your agent, providing:
- `describe_sql_object` - Get DDL/metadata for IBM i objects
- `execute_sql` - Run SQL SELECT statements on IBM i

### Setting up the MCP Server

Add the following configuration to your agent's MCP settings file:

**Claude Code project scoped MCP server** (`./ibmi-agent-skills/.mcp.json`):

```json
{
  "mcpServers": {
    "ibmi-mcp-server": {
      "command": "npx",
      "args": ["-y", "@ibm/ibmi-mcp-server@latest"],
      "env": {
        "NODE_OPTIONS": "--no-deprecation",
        "DB2i_HOST": "your-hostname.com",
        "DB2i_USER": "your-username",
        "DB2i_PASS": "your-password",
        "DB2i_PORT": "8076",
        "MCP_TRANSPORT_TYPE": "stdio",
        "IBMI_ENABLE_EXECUTE_SQL": "true"
      }
    }
  }
}
```

Replace the environment variables with your IBM i connection details:
- `DB2i_HOST` - Your IBM i hostname or IP address
- `DB2i_USER` - Your IBM i user profile
- `DB2i_PASS` - Your IBM i password
- `DB2i_PORT` - Mapepire port (default: `8076`)

For more configuration options, see the [ibmi-mcp-server documentation](https://github.com/IBM/ibmi-mcp-server).

## Available Skills

| Skill | Description |
|-------|-------------|
| `work-management` | Query, monitor, and analyze jobs on IBM i using SQL table functions `QSYS2.JOB_INFO` and `QSYS2.ACTIVE_JOB_INFO` |

## Installation

Install skills using [`npx skills`](https://github.com/vercel-labs/agent-skills).

### Clone and Install

```bash
# Clone the repository
git clone https://github.com/ajshedivy/ibmi-agent-skills.git
cd ibmi-agent-skills

# List available skills
npx skills add ./skills --list

# Install a specific skill
npx skills add ./skills/work-management
```

### Options

| Option | Description |
|--------|-------------|
| `-g, --global` | Install to user directory instead of project |
| `-a, --agent <agents...>` | Target specific agents (e.g., `claude-code`, `cursor`) |
| `-s, --skill <skills...>` | Install specific skills by name |
| `-l, --list` | List available skills without installing |
| `-y, --yes` | Skip all confirmation prompts |
| `--all` | Install all skills to all agents without prompts |

### Examples

```bash
# Install to Claude Code only
npx skills add ./skills/work-management -a claude-code

# Install globally (available across all projects)
npx skills add ./skills/work-management -g

# Non-interactive installation
npx skills add ./skills/work-management -g -a claude-code -y

# Install all skills to all agents
npx skills add ./skills --all
```

### Installation Scope

| Scope | Flag | Location | Use Case |
|-------|------|----------|----------|
| Project | (default) | `./<agent>/skills/` | Committed with your project, shared with team |
| Global | `-g` | `~/<agent>/skills/` | Available across all projects |

## Managing Skills

```bash
# List installed skills
npx skills list

# Check for updates
npx skills check

# Update all skills
npx skills update

# Remove a skill
npx skills remove work-management
```


