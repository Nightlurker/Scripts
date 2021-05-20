<#
.DESCRIPTION
   Removes a users permission on all user calendars in Exchange to LimitedDetails
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    # Users permission to remove on calendar 
    [parameter(Mandatory=$true, HelpMessage="Users permission to remove on calendar.")]
    [ValidateNotNullOrEmpty()]
    [string]$User
)
Begin
{
    # Import Write-Log function
    try
    {
        Import-Module ..\..\Write-Log.ps1 -ErrorAction Stop
    }
    catch
    {
        Write-Error -Message "Could not import Write-Log function."
        Exit 1
    }

    $Date = (Get-Date -Format d)
    $LogFolder = ".\Logs\" # Directory for storing logs
    $LogFile = Join-Path -Path $LogFolder -ChildPath ($Date + " - RemoveCalendarPermissions.log")
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
    Write-Log -Message "Starting Process Block of RemoveCalendarPermissions.ps1" -Level "Info" -Path $LogFile

    $Mailboxes = Get-EXOMailbox -ResultSize Unlimited -Filter "(RecipientType -eq 'UserMailbox') -and (RecipientTypeDetails -eq 'UserMailbox')"

    foreach ($Mailbox in $Mailboxes) {
        Write-Log -Message ("Finding calendar folder for $($Mailbox.Identity)") -Level "Info" -Path $LogFile
        $CalendarFolder = ($Mailbox.Identity + ":\" + (Get-MailboxFolderStatistics -Identity $Mailbox.Identity -FolderScope Calendar | Where-Object FolderType -eq Calendar).FolderPath.TrimStart("/"))
        
        Write-Log -Message ("Checking permissions for folder $($CalendarFolder)") -Level "Info" -Path $LogFile
        $AccessRights = (Get-EXOMailboxFolderPermission -Identity $CalendarFolder -User $User -ErrorAction SilentlyContinue).AccessRights

        if ($AccessRights) {
            Write-Log -Message ("Mailbox $($Mailbox.Identity) has access right $($AccessRights) for $($User), removing.") -Level "Info" -Path $LogFile
            Remove-MailboxFolderPermission -Identity $CalendarFolder -User $User -Confirm:$false
            $ChangeCount++
        }
    }

    Write-Log -Message ("Removed a total of $($ChangeCount) calendar permissions") -Level "Info" -Path $LogFile
    Write-Log -Message "Ending Process Block of RemoveCalendarPermissions.ps1" -Level "Info" -Path $LogFile
}
End
{
    Disconnect-ExchangeOnline -Confirm:$false
    Remove-Module -Name Write-Log
}