<#
.DESCRIPTION
   Disables and moves Active Directory Computer Objects to a designated OU for quarantine.
   Computers that are moved are logged in a daily log file.
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
    $ComputerLoginAge = 160 # Number of days of inactivity before computer is moved and disabled.
    $QuarantineOU = "OU=Computers,OU=Quarantine,DC=domain,DC=com" # Destination OU for old computer objects
    $LogFolder = ".\Logs\" # Directory for storing logs
    $LogFile = Join-Path -Path $LogFolder -ChildPath ($Date + " - MoveAndDisable.log")
    $SourceOUs = @("OU=Clients,DC=domain,DC=com", "OU=Laptops,DC=domain,DC=com")
}
Process
{
    foreach ($OU in $SourceOUs)
    {
        Write-Log -Message ("Starting processing on OU: " + $OU) -Level Info -Path $LogFile

        $Computers = Find-ADComputerByLoginDate -DaysSinceLogin $ComputerLoginAge -OU $OU

        Write-Log -Message ("Found " + $Computers.Count + " computers to be moved and disabled") -Level Info -Path $LogFile
        
        foreach ($Computer in $Computers)
        {
            $ComputerProcessingFailed = $false

            Write-Log -Message ("Processing computer " + $Computer.DistinguishedName ) -Level Info -Path $LogFile
            
            # Disable computer object
            try
            {
                Set-ADComputer -Identity $Computer -Enabled $false -WhatIf
                Write-Log -Message ("Computer disabled") -Level Info -Path $LogFile
            }
            catch
            {
                Write-Log -Message ("Could not disable computer") -Level Warn -Path $LogFile
                $ComputerProcessingFailed = $true
            }
            
            # Move computer object
            try
            {
                $Computer | Move-ADObject -TargetPath $QuarantineOU -WhatIf
                Write-Log -Message ("Computer moved") -Level Info -Path $LogFile
            }
            catch
            {
                Write-Log -Message ("Could not move computer") -Level Warn -Path $LogFile
                $ComputerProcessingFailed = $true
            }
            
            #Log status of process
            if ($ComputerProcessingFailed -eq $false)
            {
                Write-Log -Message ("Computer " + $Computer.Name + " successfully moved and disabled") -Level Info -Path $LogFile
            }
            else
            {
                Write-Log -Message ("Computer " + $Computer.Name + " processing failed") -Level Error -Path $LogFile
            }
        }

        Write-Log -Message ("Finished processing on OU: " + $OU) -Level Info -Path $LogFile
    }
}