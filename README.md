# Claude Desktop Commander MCP

[![npm downloads](https://img.shields.io/npm/dw/@jasondsmith72/desktop-commander)](https://www.npmjs.com/package/@jasondsmith72/desktop-commander)
[![GitHub Repo](https://img.shields.io/badge/GitHub-jasondsmith72%2FClaudeComputerCommander-blue)](https://github.com/jasondsmith72/ClaudeComputerCommander)


Short version. Two key things. Terminal commands and diff based file editing.

This is a server that allows Claude desktop app to execute long-running terminal commands on your computer and manage processes through Model Context Protocol (MCP) + Built on top of [MCP Filesystem Server](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem) to provide additional search and replace file editing capabilities.

This is a fork of [wonderwhy-er/ClaudeComputerCommander](https://github.com/wonderwhy-er/ClaudeComputerCommander) with enhanced configuration options.

## Features

- Execute terminal commands with output streaming
- Command timeout and background execution support
- Process management (list and kill processes)
- Session management for long-running commands
- Full filesystem operations:
  - Read/write files
  - Create/list directories
  - Move files/directories
  - Search files
  - Get file metadata
  - Code editing capabilities:
  - Surgical text replacements for small changes
  - Full file rewrites for major changes
  - Multiple file support
  - Pattern-based replacements
- **NEW: Configurable allowed directories** - Specify which directories Claude can access
- **NEW: Uninstall script** - Easy removal of the tool from Claude Desktop

## Installation
First, ensure you've downloaded and installed the [Claude Desktop app](https://claude.ai/download) and you have [npm installed](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm).

### Option 1: Custom Setup (Recommended)
This method is best if you don't have permissions to directly modify the Claude config file or prefer a guided approach:

1. Clone the repository:
```powershell
git clone https://github.com/jasondsmith72/ClaudeComputerCommander.git
```

2. Navigate to the cloned directory (IMPORTANT - make sure to do this as a separate command):
```powershell
cd ClaudeComputerCommander
```

3. Install dependencies:
```powershell
npm install
```

4. Build the project:
```powershell
npm run build
```

5. Run the appropriate setup script based on your needs:
```powershell
# For Windows with automatic configuration:
npm run setup:windows

# For guided manual setup (works on any platform):
npm run setup:custom

# For standard setup (requires write access to Claude config):
npm run setup
```

6. Follow any on-screen instructions provided by the setup script.

7. Restart Claude if it's running.

> **IMPORTANT NOTE FOR WINDOWS USERS**: Make sure to run each command separately. Do not combine commands like `cd ClaudeComputerCommander npm install` as this will cause errors. Use separate command lines for each step.

### Option 2: Add to claude_desktop_config manually
Add this entry to your claude_desktop_config.json (on Windows, found at %APPDATA%\\Claude\\claude_desktop_config.json):
```json
{
  "mcpServers": {
    "desktop-commander": {
      "command": "npx",
      "args": [
        "-y",
        "@jasondsmith72/desktop-commander"
      ]
    }
  }
}
```
Restart Claude if running.

## Uninstallation

To uninstall ClaudeComputerCommander, you have two options:

### Option 1: Using the uninstall script (Recommended)

If you have the repository locally:
```powershell
cd ClaudeComputerCommander
npm run uninstall
```

If you've installed it globally:
```powershell
npx @jasondsmith72/desktop-commander uninstall
```

This will:
1. Create a backup of your Claude configuration file
2. Remove all references to desktopCommander from the configuration
3. Log the changes made for reference

### Option 2: Manual uninstallation

1. Open your Claude Desktop configuration file:
   - Windows: `%APPDATA%\\Claude\\claude_desktop_config.json`
   - Mac: `~/Library/Application Support/Claude/claude_desktop_config.json`

2. Remove the `desktopCommander` entry from the `mcpServers` section.

3. Restart Claude Desktop.

4. If you installed the package globally, uninstall it:
   ```powershell
   npm uninstall -g @jasondsmith72/desktop-commander
   ```

## Configuration

### Allowed Directories
By default, Claude can only access:
1. The current working directory (where the server is running from)
2. The user's home directory

You can customize this by editing the `config.json` file in the root of the project:

```json
{
  "blockedCommands": [
    "format",
    "mount",
    "umount",
    ...
  ],
  "allowedDirectories": [
    "~",                 // User's home directory
    "~/Documents",       // Documents folder
    "~/Projects",        // Projects folder
    ".",                 // Current working directory
    "/path/to/folder"    // Any absolute path
  ]
}
```

**Notes on allowed directories:**
- Use `~` to refer to the user's home directory
- Use `.` to refer to the current working directory
- You can specify absolute paths as well
- For security reasons, each path is validated before access is granted

### Blocked Commands
You can configure which commands are blocked by editing the `blockedCommands` array in `config.json`:

```json
{
  "blockedCommands": [
    "format",
    "mount",
    "umount",
    "mkfs",
    "fdisk",
    "dd",
    "sudo",
    "su",
    ...
  ]
}
```

## Usage

The server provides these tool categories:

### Terminal Tools
- `execute_command`: Run commands with configurable timeout
- `read_output`: Get output from long-running commands
- `force_terminate`: Stop running command sessions
- `list_sessions`: View active command sessions
- `list_processes`: View system processes
- `kill_process`: Terminate processes by PID
- `block_command`/`unblock_command`: Manage command blacklist

### Filesystem Tools
- `read_file`/`write_file`: File operations
- `create_directory`/`list_directory`: Directory management  
- `move_file`: Move/rename files
- `search_files`: Pattern-based file search
- `get_file_info`: File metadata
- `list_allowed_directories`: View which directories the server can access

### Edit Tools
- `edit_block`: Apply surgical text replacements (best for changes <20% of file size)
- `write_file`: Complete file rewrites (best for large changes >20% or when edit_block fails)

Search/Replace Block Format:
```
filepath.ext
<<<<<<< SEARCH
existing code to replace
=======
new code to insert
>>>>>>> REPLACE
```

Example:
```
src/main.js
<<<<<<< SEARCH
console.log("old message");
=======
console.log("new message");
>>>>>>> REPLACE
```

## Handling Long-Running Commands

For commands that may take a while:

1. `execute_command` returns after timeout with initial output
2. Command continues in background
3. Use `read_output` with PID to get new output
4. Use `force_terminate` to stop if needed

## Troubleshooting

If you encounter issues setting up or using the MCP server:

1. Check that Claude Desktop is properly installed and has been run at least once
2. Verify that the claude_desktop_config.json file exists and is properly formatted
3. Make sure you have the required permissions to modify the config file
4. Restart Claude Desktop after making changes to the config
5. Check that your desired file paths are in the allowed directories configuration
6. If you're getting "access denied" errors, use the `list_allowed_directories` tool to see which directories are accessible
7. **Command syntax issues**: In PowerShell or Command Prompt, make sure to run each command separately on its own line. Don't combine commands like `cd ClaudeComputerCommander npm install` as this will cause errors.
8. **Directory issues**: Ensure you're in the correct directory before running npm commands. After cloning, you must `cd` into the ClaudeComputerCommander directory.
9. **Permission issues**: If you encounter permission errors, try running your terminal as Administrator.

## Common Installation Errors

### Error: "A positional parameter cannot be found that accepts argument 'install'"
This occurs when you try to run multiple commands on one line. In PowerShell, run these as separate commands:
```powershell
# CORRECT:
cd ClaudeComputerCommander
npm install

# INCORRECT:
cd ClaudeComputerCommander npm install
```

### Error: "Could not read package.json: Error: ENOENT: no such file or directory"
This happens when you try to run npm commands outside the project directory. Make sure you've navigated to the ClaudeComputerCommander directory first:
```powershell
# First navigate to the directory
cd ClaudeComputerCommander

# Then run npm commands
npm install
npm run build
```

## Contributing

If you find this project useful, please consider giving it a ⭐ star on GitHub! This helps others discover the project and encourages further development.

We welcome contributions from the community! Whether you've found a bug, have a feature request, or want to contribute code, here's how you can help:

- **Found a bug?** Open an issue at [github.com/jasondsmith72/ClaudeComputerCommander/issues](https://github.com/jasondsmith72/ClaudeComputerCommander/issues)
- **Have a feature idea?** Submit a feature request in the issues section
- **Want to contribute code?** Fork the repository, create a branch, and submit a pull request
- **Questions or discussions?** Start a discussion in the GitHub Discussions tab

All contributions, big or small, are greatly appreciated!

## License

MIT
