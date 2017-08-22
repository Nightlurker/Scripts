<#
.DESCRIPTION
   Removes Active Directory Computer Objects to a designated OU that has not been logged on for the designated timeperiod.
   Computers that are removed are logged in a daily log file.
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

    # Import Find-ADComputerByLoginDate function
    try
    {
        .\Find-ADComputerByLoginDate.ps1 -ErrorAction Stop
    }
    catch
    {
        Write-Error -Message "Could not import Find-ADComputerByLoginDate function."
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
    $ComputerLoginAge = 190 # Number of days of inactivity before computer is removed.
    $QuarantineOU = "OU=Computers,OU=Quarantine,DC=domain,DC=com" # OU to delete computers from
    $LogFolder = ".\Logs\" # Directory for storing logs
    $LogFile = Join-Path -Path $LogFolder -ChildPath ($Date + " - Remove.log")
}
Process
{
    Write-Log -Message ("Starting removing computer objects in OU: " + $QuarantineOU) -Level Info -Path $LogFile

    $Computers = Find-ADComputerByLoginDate -DaysSinceLogin $ComputerLoginAge -OU $QuarantineOU

    Write-Log -Message ("Found " + $Computers.Count + " computers to be removed") -Level Info -Path $LogFile

    foreach ($Computer in $Computers)
    {
        Write-Log -Message ("Processing computer " + $Computer.DistinguishedName ) -Level Info -Path $LogFile

        try
        {
            Remove-ADComputer -Identity $Computer -WhatIf
            Write-Log -Message ("Computer removed") -Level Info -Path $LogFile
        }
        catch
        {
            Write-Log -Message ("Could not remove computer") -Level Warn -Path $LogFile
        }
        
    }

    Write-Log -Message ("Finished removing computer objects in OU: " + $QuarantineOU) -Level Info -Path $LogFile
}