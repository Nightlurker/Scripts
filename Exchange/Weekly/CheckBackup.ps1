<#
.DESCRIPTION
   Checks if the last full backup is within the limits configured
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param()
Begin {
    # Import the config file
    try {
        if (-not (Test-Path $PSScriptRoot\..\Config.json)) {
            Throw [System.IO.FileNotFoundException]
        }
        $Config = Get-Content -Path $PSScriptRoot\..\Config.json | ConvertFrom-Json
    }
    catch {
        Write-Error -Message "Could not find a config file"
        Exit 1
    }

    # Import Write-Log function
    try {
        Import-Module $PSScriptRoot\..\Write-Log.ps1 -ErrorAction Stop
    }
    catch {
        Write-Error -Message "Could not import Write-Log function."
        Exit 1
    }

    # Import Exchange Session
    try {
        $ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $Config.ExchangeSessionURI -Authentication Kerberos
        Import-PSSession -Session $ExchangeSession
    }
    catch {
        Write-Error -Message "Could not import Exchange Session."
        Exit 1
    }

    $Date = (Get-Date -Format d)
    $LogFolder = ($PSScriptRoot + "\Logs\") # Directory for storing logs
    $LogFile = Join-Path -Path $LogFolder -ChildPath ($Date + " - CheckBackup.log")

    $ErrorFound = $false
}
Process {
    Write-Log -Message "Starting Process Block of CheckBackup.ps1" -Level "Info" -Path $LogFile

    # Checking for Database Copy errors
    $MailboxDatabase = Get-MailboxDatabase -Status

    foreach ($Database in $MailboxDatabase) {
        if ($Database.LastFullBackup -lt (Get-Date).AddDays(-$Config.Limits.LastFullBackup)) {
            Write-Log -Message ("Database Backup Status of " + $Database.Name + " is less than the limit, last backup was: " + $Database.LastFullBackup) -Level "Error" -Path $LogFile
            $ErrorFound = $true
        }
    }

    if ($ErrorFound) {
        Write-Log -Message "Error(s) detected, please check and resolve the faults found" -Level "Error" -Path $LogFile
    }
    else {
        Write-Log -Message "No error(s) found" -Level "Info" -Path $LogFile
    }

    Write-Log -Message "Ending Process Block of CheckBackup.ps1" -Level "Info" -Path $LogFile
}
End {
    Remove-PSSession -Session $ExchangeSession
}