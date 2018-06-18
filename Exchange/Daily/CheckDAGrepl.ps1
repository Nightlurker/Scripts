<#
.DESCRIPTION
   Checks the replication status of a DAG cluster
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()
Begin
{
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
    catch
    {
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
    $LogFile = Join-Path -Path $LogFolder -ChildPath ($Date + " - CheckDAGrepl.log")

    $ErrorFound = $false
}
Process
{
    Write-Log -Message "Starting Process Block of CheckDAGrepl.ps1" -Level "Info" -Path $LogFile

    # Checking for Database Copy errors
    $MailboxDatabase = Get-MailboxDatabase
    $MailboxDatabaseCopyStatus = $MailboxDatabase | Get-MailboxDatabaseCopyStatus | Format-List

    foreach ($DatabaseCopyStatus in $MailboxDatabaseCopyStatus) {
        if (($DatabaseCopyStatus.Status -ne "Mounted") -or ($DatabaseCopyStatus.Status -ne "Healthy")) {
            Write-Log -Message ("Database Copy Status of " + $DatabaseCopyStatus.Name + ": " + $DatabaseCopyStatus.Status) -Level "Error" -Path $LogFile
            $ErrorFound = $true
        }
    }

    # Checking for Exchange Replication Health faults
    $ExchangeServer = Get-ExchangeServer

    foreach ($Server in $ExchangeServer) {
        Write-Log -Message ("Starting Replication Health test for server: " + $Server.Name) -Level "Info" -Path $LogFile
        foreach ($Check in (Test-ReplicationHealth -Identity $Server.Name)) {
            if ($Check.Result -ne "Passed") {
                Write-Log -Message ("Replication Health " + $Check.Check + ": " + $Check.Result) -Level "Error" -Path $LogFile
                $ErrorFound = $true
            } else {
                Write-Log -Message ("Replication Health " + $Check.Check + ": " + $Check.Result) -Level "Info" -Path $LogFile
            }
        }
    }

    if ($ErrorFound) {
        Write-Log -Message "Error(s) detected, please check and resolve the faults found" -Level "Error" -Path $LogFile
    }
    else {
        Write-Log -Message "No error(s) found" -Level "Info" -Path $LogFile
    }

    Write-Log -Message "Ending Process Block of CheckDAGrepl.ps1" -Level "Info" -Path $LogFile
}
End
{
    Remove-PSSession -Session $ExchangeSession
}
