<#
.DESCRIPTION
   Disables and moves Active Directory User Objects to a designated OU for quarantine.
   Users that are moved are logged in a daily log file.
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
        Import-Module .\Find-ADUserByLoginDate.ps1 -ErrorAction Stop
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
    $UserLoginAge = 160 # Number of days of inactivity before user is moved and disabled.
    $QuarantineOU = "OU=Users,OU=Quarantine,DC=domain,DC=com" # Destination OU for old user objects
    $LogFolder = ".\Logs\" # Directory for storing logs
    $LogFile = Join-Path -Path $LogFolder -ChildPath ($Date + " - MoveAndDisable.log")
    $SourceOUs = @("OU=Clients,DC=domain,DC=com", "OU=Laptops,DC=domain,DC=com")
}
Process
{
    foreach ($OU in $SourceOUs)
    {
        Write-Log -Message ("Starting processing on OU: " + $OU) -Level Info -Path $LogFile

        $Users = Find-ADUserByLoginDate -DaysSinceLogin $UserLoginAge -OU $OU -IncludeNoLogonDate

        Write-Log -Message ("Found " + $Users.Count + " users to be moved and disabled") -Level Info -Path $LogFile
        
        foreach ($User in $Users)
        {
            $UserProcessingFailed = $false

            Write-Log -Message ("Processing user " + $User.DistinguishedName ) -Level Info -Path $LogFile
            
            # Disable user object
            try
            {
                Set-ADUser -Identity $User -Enabled $false -WhatIf
                Write-Log -Message ("User disabled") -Level Info -Path $LogFile
            }
            catch
            {
                Write-Log -Message ("Could not disable user") -Level Warn -Path $LogFile
                $UserProcessingFailed = $true
            }
            
            # Move user object
            try
            {
                $User | Move-ADObject -TargetPath $QuarantineOU -WhatIf
                Write-Log -Message ("User moved") -Level Info -Path $LogFile
            }
            catch
            {
                Write-Log -Message ("Could not move user") -Level Warn -Path $LogFile
                $UserProcessingFailed = $true
            }
            
            #Log status of process
            if ($UserProcessingFailed -eq $false)
            {
                Write-Log -Message ("User " + $User.Name + " successfully moved and disabled") -Level Info -Path $LogFile
            }
            else
            {
                Write-Log -Message ("User " + $User.Name + " processing failed") -Level Error -Path $LogFile
            }
        }

        Write-Log -Message ("Finished processing on OU: " + $OU) -Level Info -Path $LogFile
    }
}