<#
.DESCRIPTION
   Sets the default permission on all user calendars in Exchange to LimitedDetails
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    # Permission to set on calendar 
    [parameter(Mandatory=$false, HelpMessage="Permission to set on calendar.")]
    [ValidateNotNullOrEmpty()]
    [string]$Permission = "LimitedDetails"
)
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
        Connect-ExchangeOnline
    }
    catch {
        Write-Error -Message "Could not import Exchange Session."
        Exit 1
    }
}
Process
{
    Write-Log -Message "Starting Process Block of SetDefaultCalendarPermissions.ps1" -Level "Info" -Path $LogFile

    $Mailboxes = Get-EXOMailbox -ResultSize Unlimited -Filter "(RecipientType -eq 'UserMailbox') -and (RecipientTypeDetails -eq 'UserMailbox')"

    foreach ($Mailbox in $Mailboxes) {
        Write-Log -Message ("Finding calendar folder for $($Mailbox.Identity)") -Level "Info" -Path $LogFile
        $CalendarFolder = ($Mailbox.Identity + ":\" + (Get-EXOMailboxFolderStatistics -Identity $Mailbox.Identity -FolderScope Calendar | Where-Object FolderType -eq Calendar).FolderPath.TrimStart("/"))

        Write-Log -Message ("Checking permissions for folder $($CalendarFolder)") -Level "Info" -Path $LogFile
        $AccessRights = (Get-EXOMailboxFolderPermission -Identity $CalendarFolder -User Default -ErrorAction SilentlyContinue).AccessRights

        if ($AccessRights -ne $Permission) {
            Write-Log -Message ("Mailbox $($Mailbox.Identity) has access right $($AccessRights) for default user, changing to $($Permission).") -Level "Info" -Path $LogFile
            Set-MailboxFolderPermission -Identity $CalendarFolder -User Default -AccessRights $Permission
            $ChangeCount++
        }
    }

    Write-Log -Message ("Changed a total of $($ChangeCount) calendar permissions") -Level "Info" -Path $LogFile
    Write-Log -Message "Ending Process Block of SetDefaultCalendarPermissions.ps1" -Level "Info" -Path $LogFile
}
End
{
    Disconnect-ExchangeOnline
    Remove-Module -Name Write-Log
}