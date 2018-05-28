<#
.DESCRIPTION
   Description of the script
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
    $LogFile = Join-Path -Path $LogFolder -ChildPath ($Date + " - MailboxAvailability.log")

    $ErrorFound = $false
}
Process
{
    Write-Log -Message "Starting Process Block of MailboxAvailability.ps1" -Level "Info" -Path $LogFile

    Get-MailboxDatabase -Identity DB01 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB02 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB03 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB04 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB05 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB06 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB07 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB08 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB09 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB10 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB11 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB12 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB13 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB14 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB15 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB16 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB17 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB18 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB19 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB20 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB21 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB22 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB23 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB24 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB25 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB26 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB27 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB28 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB29 -status |Fortmat-List mounted
    Get-MailboxDatabase -Identity DB30 -status |Fortmat-List mounted

    if ($ErrorFound) {
        Write-Log -Message "Error(s) detected, please check and resolve the faults found" -Level "Error" -Path $LogFile
    }
    else {
        Write-Log -Message "No error(s) found" -Level "Info" -Path $LogFile
    }

    Write-Log -Message "Ending Process Block of MailboxAvailability.ps1" -Level "Info" -Path $LogFile
}
End
{
    Remove-PSSession -Session $ExchangeSession
}