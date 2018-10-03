<#
.DESCRIPTION
   Sets the default permission on all user calendars in Exchange to LimitedDetails
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
    $LogFile = Join-Path -Path $LogFolder -ChildPath ($Date + " - SetDefaultCalendarPermissions.log")
    $ChangeCount = 0

    # Import Exchange Session
    try {
        if (-Not (Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.Exchange" -and $_.State -eq "Opened"})) {
            $ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $Config.ExchangeSessionURI -Authentication Kerberos
            Import-PSSession -Session $ExchangeSession
        }
    }
    catch {
        Write-Error -Message "Could not import Exchange Session."
        Exit 1
    }
}
Process
{
    Write-Log -Message "Starting Process Block of SetDefaultCalendarPermissions.ps1" -Level "Info" -Path $LogFile

    $Mailboxes = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox

    foreach ($Mailbox in $Mailboxes) {
        $CalendarFolder = ($Mailbox.Identity + ":\" + (Get-MailboxFolderStatistics -Identity $Mailbox.Identity -FolderScope Calendar | Where-Object FolderType -eq Calendar).FolderPath.TrimStart("/"))

        Write-Log -Message ("Checking permissions for folder " + $CalendarFolder) -Level "Info" -Path $LogFile

        if ((Get-MailboxFolderPermission -Identity $CalendarFolder -User Default -ErrorAction SilentlyContinue).AccessRights -ne "LimitedDetails") {
            Write-Log -Message ("Mailbox " + $Mailbox.Identity + " does not have access right LimitedDetails for default user, changing.") -Level "Warn" -Path $LogFile
            Set-MailboxFolderPermission -Identity $CalendarFolder -User Default -AccessRights LimitedDetails
            $ChangeCount++
        }
    }

    Write-Log -Message ("Changed a total of " + $Count + " calendar permissions") -Level "Info" -Path $LogFile
    Write-Log -Message "Ending Process Block of SetDefaultCalendarPermissions.ps1" -Level "Info" -Path $LogFile
}
End
{
    if (Get-Variable -Name "ExchangeSession" -Scope Global -ErrorAction SilentlyContinue) {
        Remove-PSSession -Session $ExchangeSession
    }
    Remove-Module -Name Write-Log
}