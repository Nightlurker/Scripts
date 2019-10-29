<#
.DESCRIPTION
   Finds users that are unused and logs them.
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
        if ((Get-Module -Name Write-Log)) {
            Remove-Module -Name Write-Log
        }
        Import-Module .\Write-Log.ps1 -ErrorAction Stop
    }
    catch
    {
        Write-Error -Message "Could not import Write-Log function."
        Exit 1
    }

    $Date = (Get-Date -Format d)
    $UserLoginAge = 160 # Number of days of inactivity for user to be logged.
    $LogFolder = ".\Logs\" # Directory for storing logs
    $LogFile = Join-Path -Path $LogFolder -ChildPath ($Date + " - ADUnused.log")
    $SourceOUs = @("OU=Clients,DC=domain,DC=com", "OU=Laptops,DC=domain,DC=com")
    $CsvDataFile = Join-Path -Path ".\" -ChildPath ($Date + " - ADUnused.csv")
}
Process
{
    $CsvData = @()

    foreach ($OU in $SourceOUs)
    {
        Write-Log -Message ("Starting processing on OU: " + $OU) -Level Info -Path $LogFile

        $Users = Find-ADUserByLoginDate -DaysSinceLogin $UserLoginAge -OU $OU -IncludeNoLogonDate

        Write-Log -Message ("Found " + $Users.Count + " users") -Level Info -Path $LogFile
        
        foreach ($User in $Users)
        {
            Write-Log -Message ("Adding " + $User.Name + " to CSV data") -Level Info -Path $LogFile

            $UserData = New-Object -TypeName psobject
            $UserData | Add-Member -MemberType NoteProperty -Name "Name" -Value $User.Name
            $UserData | Add-Member -MemberType NoteProperty -Name "SamAccountName" -Value $User.SamAccountName
            $UserData | Add-Member -MemberType NoteProperty -Name "DistinguishedName" -Value $User.DistinguishedName
            $UserData | Add-Member -MemberType NoteProperty -Name "LastLogonDate" -Value $User.LastLogonDate

            $CsvData += $UserData
        }

        Write-Log -Message ("Finished processing on OU: " + $OU) -Level Info -Path $LogFile
    }

    Write-Log -Message ("Writing CSV data to file: " + $CsvDataFile) -Level Info -Path $LogFile
    $CsvData | Export-Csv -Path $CsvDataFile -Encoding Unicode -Delimiter ";" -NoTypeInformation
}