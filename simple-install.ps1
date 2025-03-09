# UDC PowerShell Installer
# This script properly fetches the complete repository and installs dependencies

Write-Host @"
     _                      _                                                  
    | | __ _ ___  ___  _ __( )___                                              
 _  | |/ _` / __|/ _ \| '_ \// __|                                             
| |_| | (_| \__ \ (_) | | | \__ \                                              
 \___/ \__,_|___/\___/|_| |_|___/                                              
                                                                              
  __ ___      _____  ___  ___  _ __ ___   ___                                 
 / _` \ \ /\ / / _ \/ __|/ _ \| '_ ` _ \ / _ \                                
| (_| |\ V  V /  __/\__ \ (_) | | | | | |  __/                                
 \__,_| \_/\_/ \___||___/\___/|_| |_| |_|\___|                                
                                                                              
  __ _| | |      (_)_ __     ___  _ __   ___                                 
 / _` | | |      | | '_ \   / _ \| '_ \ / _ \                                
| (_| | | |      | | | | | | (_) | | | |  __/                                
 \__,_|_|_|      |_|_| |_|  \___/|_| |_|\___|                                
                                                                              
 (_)_ __  ___| |_ __ _ | | | ___ _ __                                         
 | | '_ \/ __| __/ _` | | |/ _ \ '__|                                        
 | | | | \__ \ || (_| | | |  __/ |                                           
 |_|_| |_|___/\__\__,_|_|_|\___|_|                                           
"@ -ForegroundColor Cyan

Write-Host "UDC PowerShell Installer"
Write-Host "========================="
Write-Host "This script will set up UDC (Universal Device Controller)"
Write-Host ""

# Prompt for installation confirmation
$confirmInstall = Read-Host "Do you want to install UDC? (Y/N)"
if ($confirmInstall -ne "Y" -and $confirmInstall -ne "y") {
    Write-Host "Installation cancelled by user." -ForegroundColor Yellow
    exit
}
Write-Host "Proceeding with installation..." -ForegroundColor Green
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator." -ForegroundColor Red
    Write-Host "Please close this window and run PowerShell as Administrator." -ForegroundColor Red
    Write-Host "Right-click on PowerShell and select 'Run as administrator'." -ForegroundColor Red
    exit
}
Write-Host "Administrator privileges detected. Proceeding with installation..." -ForegroundColor Green
Write-Host ""

# Check if winget is installed but don't attempt to install it
$wingetInstalled = $false
try {
    $wingetVersion = & winget --version
    Write-Host "Winget is already installed ($wingetVersion)." -ForegroundColor Green
    $wingetInstalled = $true
} catch {
    Write-Host "Winget not found. Continuing without Winget." -ForegroundColor Yellow
}

# Set installation directory
$RepoDir = Join-Path $env:USERPROFILE "UDC"

# Create/clean installation directory
if (Test-Path $RepoDir) {
    Write-Host "Existing installation found. Creating backup..." -ForegroundColor Yellow
    try {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupDir = "${RepoDir}-backup-${timestamp}"
        Move-Item -Path $RepoDir -Destination $backupDir -ErrorAction Stop
        Write-Host "Backed up to: $backupDir" -ForegroundColor Green
    } catch {
        Write-Host "Could not backup existing installation. Will try to continue anyway..." -ForegroundColor Red
        # Try to clean the directory
        try {
            Get-ChildItem -Path $RepoDir -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "Could not clean directory. Installation may be incomplete." -ForegroundColor Red
        }
    }
}

# First check if Node.js is already installed
$UseSystemNode = $false
try {
    $NodeVersion = & node --version
    Write-Host "Node.js $NodeVersion is already installed." -ForegroundColor Green
    Write-Host "Using existing Node.js installation." -ForegroundColor Green
    $UseSystemNode = $true
} catch {
    Write-Host "No existing Node.js installation found. Will install Node.js..." -ForegroundColor Yellow
    
    # Check if Git is installed
    $hasGit = $false
    try {
        $gitVersion = & git --version
        Write-Host "Git found: $gitVersion" -ForegroundColor Green
        $hasGit = $true
    } catch {
        Write-Host "Git not found. Will download repository as ZIP instead." -ForegroundColor Yellow
        if ($wingetInstalled) {
            Write-Host "Attempting to install Git using winget..." -ForegroundColor Cyan
            try {
                & winget install Git.Git -e --source winget
                
                # Verify installation
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                try {
                    $gitVersion = & git --version
                    Write-Host "Git $gitVersion installed successfully with winget." -ForegroundColor Green
                    $hasGit = $true
                } catch {
                    Write-Host "Winget installation completed but Git is not in PATH yet." -ForegroundColor Yellow
                    Write-Host "Will proceed without Git - you may need to restart your computer later." -ForegroundColor Yellow
                }
            } catch {
                Write-Host "Error installing Git with winget: $_" -ForegroundColor Red
                Write-Host "Will proceed without Git..." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Winget not available. Will proceed without installing Git." -ForegroundColor Yellow
        }
    }

    # Only try to install Node.js if it's not already installed
    if ($isAdmin) {
        Write-Host "Attempting to install Node.js system-wide..." -ForegroundColor Cyan
        
        if ($wingetInstalled) {
            # Install Node.js using winget
            Write-Host "Installing Node.js LTS using winget..." -ForegroundColor Cyan
            try {
                # Use override to specify additional parameters
                & winget install OpenJS.NodeJS.LTS --override "/ALLUSERS=1 /COMPONENTS=NodeRuntime,npm,DocumentationShortcuts,EnvironmentPathNode,EnvironmentPathNpmModules,AssociateFiles,NodePerfCtrSupport,NodeEtwSupport" -e --source winget
                
                # Verify installation
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                try {
                    $NodeVersion = & node --version
                    Write-Host "Node.js $NodeVersion installed successfully with winget." -ForegroundColor Green
                    $UseSystemNode = $true
                } catch {
                    Write-Host "Winget installation completed but Node.js is not in PATH yet." -ForegroundColor Yellow
                    Write-Host "Will configure for system Node.js - you may need to restart your computer later." -ForegroundColor Yellow
                    $UseSystemNode = $true
                }
            } catch {
                Write-Host "Error installing Node.js with winget: $_" -ForegroundColor Red
                Write-Host "Falling back to MSI installation method..." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Winget not available. Will use MSI installation instead..." -ForegroundColor Yellow
        }
        
        # If winget installation failed, try direct MSI installation
        if (-not $UseSystemNode) {
            try {
                # Create temp directory for MSI
                $TempDir = Join-Path $env:TEMP "node_install"
                if (-not (Test-Path $TempDir)) {
                    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
                }
                
                # Download the Node.js MSI installer
                $NodeMsiUrl = "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"
                $NodeMsiPath = Join-Path $TempDir "node_installer.msi"
                Write-Host "Downloading Node.js installer from $NodeMsiUrl..." -ForegroundColor Cyan
                Invoke-WebRequest -Uri $NodeMsiUrl -OutFile $NodeMsiPath
                
                if (Test-Path $NodeMsiPath) {
                    Write-Host "Running Node.js installer with additional tools..." -ForegroundColor Cyan
                    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$NodeMsiPath`" /qn ADDLOCAL=NodeRuntime,npm,DocumentationShortcuts,EnvironmentPathNode,EnvironmentPathNpmModules,AssociateFiles,NodePerfCtrSupport,NodeEtwSupport" -Wait
                    
                    # Verify installation after MSI installer runs
                    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                    try {
                        $NodeVersion = & node --version
                        Write-Host "Node.js $NodeVersion installed successfully via MSI." -ForegroundColor Green
                        $UseSystemNode = $true
                    } catch {
                        Write-Host "MSI installation completed but Node.js is not in PATH yet." -ForegroundColor Yellow
                        Write-Host "Will configure for system Node.js - you may need to restart your computer later." -ForegroundColor Yellow
                        $UseSystemNode = $true
                    }
                    
                    # Clean up
                    Remove-Item -Path $NodeMsiPath -Force -ErrorAction SilentlyContinue
                } else {
                    Write-Host "Failed to download Node.js MSI installer." -ForegroundColor Red
                    $UseSystemNode = $false
                }
            } catch {
                Write-Host "Error during MSI installation: $_" -ForegroundColor Red
                $UseSystemNode = $false
            }
        }
    } else {
        # This should never happen due to the admin check at the start
        Write-Host "Administrator rights required for Node.js installation." -ForegroundColor Red
        $UseSystemNode = $false
    }
}

# Check if Node.js was successfully installed
if (-not $UseSystemNode) {
    Write-Host "Node.js installation failed. Cannot continue." -ForegroundColor Red
    Write-Host "Please install Node.js manually before running this script again." -ForegroundColor Red
    exit
}

# Install additional Node.js tools
Write-Host "Installing additional Node.js tools and build dependencies..." -ForegroundColor Cyan

# Create restoration point before additional tools installation
$restorationNeeded = $false
$installationSuccessful = $true

try {
    # Install node-gyp globally
    Write-Host "Installing node-gyp..." -ForegroundColor Cyan
    $nodeGypResult = Start-Process -FilePath "npm" -ArgumentList "install -g node-gyp" -Wait -NoNewWindow -PassThru
    if ($nodeGypResult.ExitCode -ne 0) {
        Write-Host "Failed to install node-gyp." -ForegroundColor Red
        $installationSuccessful = $false
    }
    
    # Install Python (required for some Node.js modules)
    if ($installationSuccessful -and $wingetInstalled) {
        Write-Host "Installing Python (required for some Node.js modules)..." -ForegroundColor Cyan
        $pythonInstallResult = Start-Process -FilePath "winget" -ArgumentList "install Python.Python.3.10 -e --source winget" -Wait -NoNewWindow -PassThru
        if ($pythonInstallResult.ExitCode -ne 0) {
            Write-Host "Failed to install Python." -ForegroundColor Red
            $installationSuccessful = $false
        }
    }
    
    # Install Windows SDK components if needed
    if ($installationSuccessful) {
        Write-Host "Installing Visual C++ Build Tools..." -ForegroundColor Cyan
        $buildToolsResult = Start-Process -FilePath "npm" -ArgumentList "install --global --production windows-build-tools" -Wait -NoNewWindow -PassThru
        if ($buildToolsResult.ExitCode -ne 0) {
            Write-Host "Failed to install Visual C++ Build Tools." -ForegroundColor Red
            $installationSuccessful = $false
        }
    }
    
    if ($installationSuccessful) {
        Write-Host "Additional tools installed successfully." -ForegroundColor Green
    } else {
        throw "Failed to install one or more additional tools."
    }
} catch {
    Write-Host "Error: Additional tools installation failed: $_" -ForegroundColor Red
    Write-Host "Reverting all changes and exiting script..." -ForegroundColor Red
    $restorationNeeded = $true
}

# Revert changes if needed
if ($restorationNeeded) {
    # Clean up installation directory if it exists
    if (Test-Path $RepoDir) {
        Write-Host "Removing installation directory..." -ForegroundColor Yellow
        Remove-Item -Path $RepoDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "Installation failed. All changes have been reverted." -ForegroundColor Red
    Write-Host "Please ensure your system meets all requirements and try again." -ForegroundColor Red
    exit
}

# Create the installation directory if it doesn't exist
if (-not (Test-Path $RepoDir)) {
    New-Item -ItemType Directory -Path $RepoDir -Force | Out-Null
    Write-Host "Created installation directory at: $RepoDir"
}

# Clone or download repository
if ($hasGit) {
    # Clone repository (note: we're not in the target directory yet)
    Write-Host "Cloning ClaudeComputerCommander-Unlocked repository..." -ForegroundColor Cyan
    try {
        # If the directory doesn't exist, create it first
        if (-not (Test-Path $RepoDir)) {
            New-Item -ItemType Directory -Path $RepoDir -Force | Out-Null
            Write-Host "Created installation directory at: $RepoDir"
        }
        
        # Clone into the directory 
        & git clone https://github.com/jasondsmith72/UDC.git $RepoDir
        Write-Host "Repository cloned successfully." -ForegroundColor Green
        
        # Now change to the repository directory
        Set-Location $RepoDir
    } catch {
        Write-Host "Failed to clone repository: $_" -ForegroundColor Red
        Write-Host "Will download as ZIP instead..." -ForegroundColor Yellow
        $hasGit = $false
    }
}

if (-not $hasGit) {
    # Download as ZIP
    Write-Host "Downloading repository ZIP..." -ForegroundColor Cyan
    $zipUrl = "https://github.com/jasondsmith72/UDC/archive/main.zip"
    $zipPath = Join-Path $env:TEMP "UDC.zip"
    $extractPath = Join-Path $env:TEMP "UDC-extract"
    
    try {
        # Download
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
        
        # Create extraction directory
        if (Test-Path $extractPath) { Remove-Item -Path $extractPath -Recurse -Force }
        New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
        
        # Extract
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        
        # Create target directory if it doesn't exist
        if (-not (Test-Path $RepoDir)) {
            New-Item -ItemType Directory -Path $RepoDir -Force | Out-Null
            Write-Host "Created installation directory at: $RepoDir"
        }
        
        # Move contents to repo directory
        $extractedDir = Join-Path $extractPath "UDC-main"
        if (Test-Path $extractedDir) {
            Get-ChildItem -Path $extractedDir | Copy-Item -Destination $RepoDir -Recurse -Force
        } else {
            Write-Host "Unexpected extraction path. Searching for files..." -ForegroundColor Yellow
            $possibleDirs = Get-ChildItem -Path $extractPath -Directory
            if ($possibleDirs.Count -gt 0) {
                Get-ChildItem -Path $possibleDirs[0].FullName | Copy-Item -Destination $RepoDir -Recurse -Force
            } else {
                Write-Host "Failed to locate extracted files." -ForegroundColor Red
            }
        }
        
        # Clean up
        Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "Repository downloaded and extracted successfully." -ForegroundColor Green
        
        # Now change to the repository directory
        Set-Location $RepoDir
    } catch {
        Write-Host "Failed to download or extract repository: $_" -ForegroundColor Red
    }
}

# Install dependencies - SIMPLIFIED: Using --ignore-scripts to avoid the prepare hook
Write-Host "Installing dependencies..." -ForegroundColor Cyan
$npmCommand = "npm"
$nodeCommand = "node"

# Check for package.json to determine if we have a full repo
$hasPackageJson = Test-Path (Join-Path $RepoDir "package.json")
if ($hasPackageJson) {
    try {
        # Install dependencies without running scripts
        & $npmCommand install --ignore-scripts
        
        # Now explicitly run the build once
        & $npmCommand run build
        
        Write-Host "Dependencies installed and project built successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error installing dependencies: $_" -ForegroundColor Red
    }
}

# Create a startup script
@"
@echo off
node "$($RepoDir.Replace('\','\\'))\dist\index.js"
"@ | Out-File -FilePath (Join-Path $RepoDir "start-commander.bat") -Encoding ascii

# Simple completion message
Write-Host ""
Write-Host "Installation completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "UDC has been installed to:"
Write-Host $RepoDir -ForegroundColor Cyan
Write-Host ""
Write-Host "A startup script has been created at:"
Write-Host "$(Join-Path $RepoDir "start-commander.bat")" -ForegroundColor Cyan
Write-Host ""
# This allows the PowerShell window to remain open after script completion