    [CmdletBinding()]
    Param(
        [switch]$CheckInternetConnection,
        [switch]$LogToFile
    )

    $FilePath = 'D:\System\Script\UpdateScript.log'

    function Log-Message {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Message,
            [Parameter(Mandatory = $true)]
            [string]$FilePath,
            [string]$DateTimeFormat = "yyyy-MM-dd HH:mm:ss",
            [switch]$NoClobber
        )

        $currentTime = Get-Date -Format $DateTimeFormat

        if (Test-Path $FilePath -PathType Leaf) {
            if ($NoClobber) {
                Write-Error "File already exists at $FilePath. Specify a new file path or use -NoClobber switch."
                return
            }
        }

        try {
            # Open file handle in append mode
            $fileHandle = [System.IO.File]::Open($FilePath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
            $streamWriter = [System.IO.StreamWriter]::new($fileHandle, [System.Text.Encoding]::UTF8)

            # Write message to file
            $streamWriter.WriteLine("[$currentTime] $Message")
            $streamWriter.Flush()

            # Close file handle and stream writer
            $streamWriter.Close()
            $fileHandle.Close()
        } catch {
            Write-Error "Failed to write to file $FilePath. $_"
        }

        # Add message to message buffer
        $global:MessageBuffer += "[$currentTime] $Message`r`n"
    }


    function Install-Updates {
        Write-Host "Running with administrative privileges. Checking for updates..."
        Log-Message -Message "Running with administrative privileges. Checking for updates..." -FilePath $FilePath

        $session = New-Object -ComObject Microsoft.Update.Session
        $searcher = $session.CreateUpdateSearcher()
        $updates = $searcher.Search("IsInstalled=0")
        if ($updates.Updates.Count -eq 0) {
            Write-Host "No updates available to install."
            Log-Message -Message "No updates available to install." -FilePath $FilePath
            return
        }
        Write-Host "Found $($updates.Updates.Count) updates to install. Downloading and installing updates..."
        Log-Message -Message "Found $($updates.Updates.Count) updates to install. Downloading and installing updates..." -FilePath $FilePath

        $installer = $session.CreateUpdateInstaller()
        $installer.Updates = $updates.Updates
        $installationResult = $installer.DownloadAndInstall()
        if ($installationResult.ResultCode -eq "2") {
            Write-Host "Updates require a restart. Restarting computer..."
            Log-Message -Message "Updates require a restart. Restarting computer..." -FilePath $FilePath
            Restart-Computer -Force
        } else {
            Write-Host "Updates installed successfully."
            Log-Message -Message "Updates installed successfully." -FilePath $FilePath
        }
    }


    function Test-Administrator {
        $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (!$isAdmin) {
            Write-Error "Administrator privileges required to run the script."
            return $false
        }
        return $true
    }

    $MessageBuffer = ""

    if ($LogToFile) {
        $LogPath = 'D:\System\Script\UpdateScript.log'
    }

    if (!(Test-Administrator)) {
        Write-Error "Administrator privileges required to run the script."
        return
    }

    if ($CheckInternetConnection) {
        $PingResult = Test-NetConnection -ComputerName 'www.google.com' -InformationLevel Quiet
        if ($PingResult -ne 'True') {
            Write-Error "No internet connection. Please check the connection and try again."
            return
        }
    }
    Install-Updates

    if ($LogToFile) {
        try {
            Log-Message -Message $MessageBuffer -FilePath $LogPath -NoClobber
        } catch {
            Write-Error "Unable to write log file to $LogPath"
        }
    }

    Write-Host "Script completed successfully."
