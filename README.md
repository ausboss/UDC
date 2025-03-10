# Claude Desktop Commander MCP 🔓 UNRESTRICTED FILE ACCESS

[![npm downloads](https://img.shields.io/npm/dw/@jasondsmith72/desktop-commander)](https://www.npmjs.com/package/@jasondsmith72/desktop-commander)
[![GitHub Repo](https://img.shields.io/badge/GitHub-jasondsmith72%2FUDC-blue)](https://github.com/jasondsmith72/UDC)

## 🔓 UNRESTRICTED FILE ACCESS

This enhanced version of ClaudeComputerCommander has been modified to provide completely unrestricted access to your entire filesystem. All directory limitations have been removed, giving Claude comprehensive capabilities across your system. (**Must run Claude Desktop as Administrator to bypass windows secruity) 

**Key Features:

Universal Drive Access: Full access to all drives (C:, D:, etc.) on Windows and root directory (/) on Unix-like systems
Boundary-Free Navigation: No restrictions on which directories or files Claude can interact with
Comprehensive File Operations: Read, write, and modify files in any location, including system directories
Intelligent Fallback Mechanisms: If direct file operations encounter issues, the system automatically uses command execution alternatives
Command Execution: Terminal commands and diff-based file editing across the entire filesystem

**Technical Implementation:

Modified source code bypasses all directory validation
Configuration settings allow access to all drives and paths
Environmental variables signal unrestricted mode to the system
Command-based fallbacks leverage PowerShell or shell commands when needed

This provides maximum flexibility and eliminates permission errors while working with your filesystem. Please use with appropriate caution as Claude will have complete access to all parts of your computer's file system.

**Origin of this modidfed MCP servers below. 

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
- **NEW: Full unrestricted filesystem access** - Access any file or folder on your computer
- **NEW: Command-based fallbacks** - Even when direct file access fails, commands will be used as a fallback
- **NEW: Improved path handling** - Better support for Windows paths and relative directories

## Installation
First, ensure you've downloaded and installed the [Claude Desktop app](https://claude.ai/download)

For best results download and install [Node.js](https://nodejs.org/en/download) and make sure to install all tools. (this will install python and other tools that will be needed for other mcp servers)


### Windows Installation

#### Option 1: One-Line PowerShell Installer (Windows Only)

**Easiest Method:** Copy and paste this single command into PowerShell (run as administrator):

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/jasondsmith72/UDC/main/install.ps1'))
```

This command will:
1. Temporarily set execution policy to allow the script to run
2. Configure security protocols
3. Download and execute the installer script automatically
4. Install all dependencies (Node.js without tools and Git if needed)
5. Set up the UDC with unrestricted file access
6. Follow the on-screen prompts.
7. the installer will show you the direct path for UTC and give you the code to put in the config file.
8. Add the config to Claude desktop, click hamburger top left and click settings then go to developer and edit the config file.
9. Restart Claude if it's running.

### macOS and Linux Installation (Untested) 

First, ensure you've downloaded and installed the [Claude Desktop app](https://claude.ai/download) and you have [npm installed](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm).

For macOS and Linux users, there is no automatic installation script available. Please follow these manual steps instead:

1. Clone the repository:
```bash
git clone https://github.com/jasondsmith72/UDC.git
```

2. Navigate to the cloned directory:
```bash
cd UDC
```

3. Install dependencies:
```bash
npm install
```

4. Build the project:
```bash
npm run build
```

5. Run the setup script:
```bash
npm run setup:custom
```

6. Follow the on-screen instructions to configure Claude Desktop.

7. Restart Claude if it's running.

8. For macOS users, the Claude Desktop config file is located at: `~/Library/Application Support/Claude/claude_desktop_config.json`

9. For Linux users, check for the Claude config file in a similar application data location.

### Option 2: Custom Setup (All Platforms)
This method is best if you prefer more control over the setup process:

1. Clone the repository:
```bash
git clone https://github.com/jasondsmith72/UDC.git
```

2. Navigate to the cloned directory 
```bash
cd UDC
```

3. Install dependencies:
```bash
npm install
```

4. Build the project:
```bash
npm run build
```

5. Run the appropriate setup script based on your needs:
```bash
# For Windows with automatic configuration:
npm run setup:windows

# For guided manual setup (works on any platform):
npm run setup:custom

# For standard setup (requires write access to Claude config):
npm run setup
```

6. Follow any on-screen instructions provided by the setup script.


###  Add to Claude Desktop config manually (All Platforms)
Add this entry to your claude_desktop_config.json:

- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Linux: Check your application data folder

```json
{
  "mcpServers": {
    "desktopCommander": {
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
```bash
cd UDC
npm run uninstall
```

If you've installed it globally:
```bash
npx @jasondsmith72/desktop-commander uninstall
```

This will:
1. Create a backup of your Claude configuration file
2. Remove all references to desktopCommander from the configuration
3. Log the changes made for reference

### Option 2: Manual uninstallation

1. Open your Claude Desktop configuration file:
   - Windows: `%APPDATA%\Claude\claude_desktop_config.json`
   - Mac: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Linux: Check your application data folder

2. Remove the `desktopCommander` entry from the `mcpServers` section.

3. Restart Claude Desktop.

4. If you installed the package globally, uninstall it:
   ```bash
   npm uninstall -g @jasondsmith72/desktop-commander
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
5. Check the log files for detailed error messages:
   - `server.log`: General operation logs
   - `file-operations.log`: Detailed file operation logs


## Contributing

If you find this project useful, please consider giving it a ⭐ star on GitHub! This helps others discover the project and encourages further development.

We welcome contributions from the community! Whether you've found a bug, have a feature request, or want to contribute code, here's how you can help:

- **Found a bug?** Open an issue at [github.com/jasondsmith72/UDC/issues](https://github.com/jasondsmith72/UDC/issues)
- **Have a feature idea?** Submit a feature request in the issues section
- **Want to contribute code?** Fork the repository, create a branch, and submit a pull request
- **Questions or discussions?** Start a discussion in the GitHub Discussions tab

All contributions, big or small, are greatly appreciated!

## License

MIT
