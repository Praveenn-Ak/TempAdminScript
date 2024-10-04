$logPath = "C:\Windows\logs\Software\TempAdmin.log"
function Write-log{
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp : $message"
    Add-Content -Path $logPath -Value $logMessage
}

Write-log "TempAdminScript execution started"
function Remove-DisconnectedSessions {
    Write-log "Checking and removing disconnected sessions"
    $sessions = query user
    foreach ($session in $sessions) {    
        $sessionDetails = $session -split '\s+'
       
        if ($sessionDetails[3] -eq 'Disc') {
            $sessionId = $sessionDetails[2]

            logoff $sessionId
            Write-log "Logged off disconnected session: $sessionId"
            
        }
    }
}

Remove-DisconnectedSessions

Write-log "Checking Current user"
function Get-CurrentUser {
    $explorerProcesses = Get-WmiObject Win32_Process -Filter "Name='explorer.exe'"
    $loggedOnUsers = @()   
    foreach ($process in $explorerProcesses) {
        $user = $process.GetOwner().User
        $loggedOnUsers += $user
    }
    $distinctUsers = $loggedOnUsers | Select-Object -Unique
   
    Write-log "Current user identified as: $distinctUsers"
     return $distinctUsers
}


function Add-UserToAdmins {
    param (
        [string]$username

    )

    if ((Get-Service -Name GroupMgmtSvc -ErrorAction SilentlyContinue).status -eq "Running" ) { 
    Write-log "Stopping GroupMgmtSvc Service " 
    Set-Service -Name GroupMgmtSvc -StartupType Disabled -Status Stopped -ErrorAction SilentlyContinue
    Get-Service -Name GroupMgmtSvc | Stop-Service -Force -ErrorAction SilentlyContinue
    Write-log "Stopped and GroupMgmtSvc Service" 
    }else
    {
    Write-log "GroupMgmtSvc Service is not Running" 
    }

    if ((Get-Service -Name GroupMgmtSvc -ErrorAction SilentlyContinue).status -eq "Stopped" ){
    try {
        Add-LocalGroupMember -SID S-1-5-32-544 -Member $username -ErrorAction Stop
        Write-log "Successfully added User $username to local admin group"
        } 
    catch {
    Write-log "Failed to add User $username to local admin group. Error: $_"
            }
      }

}

function Create-ScheduledTask {
    param (
        [string]$username,
        [int]$delayInHours = 48
    )

    $TaskName = "RemoveAdmin_$currentUser"
    $scriptPath = Create-RemovalScript -username $username
    $startTime = (Get-Date).AddHours($delayInHours)
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -File `"$scriptPath`" -username '$username'"
    $trigger = New-ScheduledTaskTrigger -Once -At $startTime 
    $principal = New-ScheduledTaskPrincipal -UserId “NT AUTHORITY\SYSTEM” -LogonType Password -RunLevel Highest 
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName "RemoveAdmin_$username" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Remove user $username from local admin group after 48 hours" -ErrorAction SilentlyContinue | Out-Null
    
    Write-log "Created scheduled task $TaskName to remove user $currentUser after 48 hours."

    }

function Create-RemovalScript {
    param (
        [string]$username
    )

    $scriptPath = "C:\Windows\logs\Software\RemoveAdmin_$username.ps1"
    $scriptContent = @"

`$logPath = "C:\Windows\logs\Software\TempAdmin.log"

# Function to log actions
    function Write-log {
    param([string]`$message)
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logMessage = "`$timestamp : `$message"
    Add-Content -Path `$logPath -Value `$logMessage
}
    function Remove-UserFromAdmins {
    param ([string]`$username)
    Remove-LocalGroupMember -SID S-1-5-32-544 -Member `$username
    }
    # Call the function
    Remove-UserFromAdmins -username '$username'

    # Remove the scheduled task

    try {
        Write-log "Attempting to unregister the scheduled task 'RemoveAdmin_$username' "
        Unregister-ScheduledTask -TaskName 'RemoveAdmin_$username' -Confirm:`$false -ErrorAction Stop
        Write-log "Successfully unregistered the task 'RemoveAdmin_$username'."
    } catch {
        Write-log "Failed to unregister the task 'RemoveAdmin_$username'. Error: `$_"
    }


    # Remove the script file itself
    Try{
    Write-log "Removing temp admin removal script from local disk"
    Remove-Item -Path `"$scriptPath`" -Force
    }Catch{
    Write-log "`$_"

    }
"@

    $scriptContent | Out-File -FilePath $scriptPath -Force -ErrorAction SilentlyContinue

    return $scriptPath
}

$currentUser = Get-CurrentUser
if ($currentUser) {
    
    Add-UserToAdmins -username $currentUser

    Create-ScheduledTask -username $currentUser
} 
