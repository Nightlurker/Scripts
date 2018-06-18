<#
.DESCRIPTION
   Description of the script
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()
Begin
{
    # Import Write-Log function
    try
    {
        Import-Module .\Write-Log.ps1 -ErrorAction Stop
    }
    catch
    {
        Write-Error -Message "Could not import Write-Log function."
        Exit 1
    }

    $Date = (Get-Date -Format d)
    $LogFolder = ".\Logs\" # Directory for storing logs
    $LogFile = Join-Path -Path $LogFolder -ChildPath ($Date + " - Mal.log")
}
Process
{
    Write-Log -Message "Starting Process Block of Mal.ps1" -Level "Info" -Path $LogFile
    # Code
    Write-Log -Message "Ending Process Block of Mal.ps1" -Level "Info" -Path $LogFile
}