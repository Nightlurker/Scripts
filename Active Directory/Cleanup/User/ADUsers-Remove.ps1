<#
.DESCRIPTION
   Removes Active Directory User Objects to a designated OU that has not been logged on for the designated timeperiod.
   Users that are removed are logged in a daily log file.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()
Begin
{
    # Import Active Directory Module
    try
    {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
    catch
    {
        Write-Error -Message "Could not import Active Directory Powershell Module."
        Exit 1
    }

    # Import Find-ADUserByLoginDate function
    try
    {
        .\Find-ADUserByLoginDate.ps1 -ErrorAction Stop
    }
    catch
    {
        Write-Error -Message "Could not import Find-ADUserByLoginDate function."
        Exit 1
    }

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
    $UserLoginAge = 190 # Number of days of inactivity before user is removed.
    $QuarantineOU = "OU=Users,OU=Quarantine,DC=domain,DC=com" # OU to delete users from
    $LogFolder = ".\Logs\" # Directory for storing logs
    $LogFile = Join-Path -Path $LogFolder -ChildPath ($Date + " - Remove.log")
}
Process
{
    Write-Log -Message ("Starting removing user objects in OU: " + $QuarantineOU) -Level Info -Path $LogFile

    $Users = Find-ADUserByLoginDate -DaysSinceLogin $UserLoginAge -OU $QuarantineOU

    Write-Log -Message ("Found " + $Users.Count + " users to be removed") -Level Info -Path $LogFile

    foreach ($User in $Users)
    {
        Write-Log -Message ("Processing user " + $User.DistinguishedName ) -Level Info -Path $LogFile

        try
        {
            Remove-ADUser -Identity $User -WhatIf
            Write-Log -Message ("User removed") -Level Info -Path $LogFile
        }
        catch
        {
            Write-Log -Message ("Could not remove user") -Level Warn -Path $LogFile
        }
        
    }

    Write-Log -Message ("Finished removing user objects in OU: " + $QuarantineOU) -Level Info -Path $LogFile
}