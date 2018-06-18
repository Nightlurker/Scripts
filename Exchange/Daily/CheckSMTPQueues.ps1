<#
.DESCRIPTION
   Checks that all the SMTP queues on Exchange servers are bellow the configured limit
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
    $LogFile = Join-Path -Path $LogFolder -ChildPath ($Date + " - CheckSMTPQueues.log")

    $ErrorFound = $false
}
Process
{
    Write-Log -Message "Starting Process Block of CheckSMTPQueues.ps1" -Level "Info" -Path $LogFile

    #Checking the queues on all Exchange servers
    $ExchangeServer = Get-ExchangeServer

    foreach ($Server in $ExchangeServer) {
        Write-Log -Message ("Checking SMTP Queue for: " + $Server.Name) -Level "Info" -Path $LogFile
        foreach ($Queue in (Get-Queue -Server $Server.Name)) {
            if ($Queue.MessageCount -ge $Config.Limits.Queue) {
                Write-Log -Message ("The queue " + $Queue.Identity + " is larger than the limit of " + $Config.Limits.Queue) -Level "Error" -Path $LogFile
                $ErrorFound = $true
            }
        }
    }

    if ($ErrorFound) {
        Write-Log -Message "Error(s) detected, please check and resolve the faults found" -Level "Error" -Path $LogFile
    }
    else {
        Write-Log -Message "No error(s) found" -Level "Info" -Path $LogFile
    }

    Write-Log -Message "Ending Process Block of CheckSMTPQueues.ps1" -Level "Info" -Path $LogFile
}
End
{
    Remove-PSSession -Session $ExchangeSession
    Remove-Module -Name Write-Log
}