<#
.DESCRIPTION
   Finds all groups in a OU path and writes their members to a CSV file
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
    $LogFolder = ".\Logs\" # Directory for storing logs
    $LogFile = Join-Path -Path $LogFolder -ChildPath ($Date + " - ADGroupMembers.log")
    $SourceOUs = @("OU=Groups,DC=domain,DC=com", "OU=MoreGroups,DC=domain,DC=com")
    $CsvDataFile = Join-Path -Path ".\" -ChildPath ($Date + " - ADGroupMembers.csv")
}
Process
{
    $CsvData = @()
    foreach ($OU in $SourceOUs)
    {
        Write-Log -Message ("Starting processing on OU: " + $OU) -Level Info -Path $LogFile

        $Groups = Get-ADGroup -SearchBase $OU -Filter *

        Write-Log -Message ("Found " + $Groups.Count + " groups") -Level Info -Path $LogFile
        
        foreach ($Group in $Groups)
        {

            Write-Log -Message ("Processing group " + $Group.DistinguishedName ) -Level Info -Path $LogFile
            
            #Get all group members
            try {
                $Members = Get-ADGroupMember -Identity $Group -Recursive

                foreach ($Member in $Members) {
                    Write-Log -Message ("Adding " + $Member.Name + " in group " + $Group.Name + " to CSV data") -Level Info -Path $LogFile

                    $MemberData = New-Object -TypeName psobject
                    $MemberData | Add-Member -MemberType NoteProperty -Name "GroupName" -Value $Group.Name
                    $MemberData | Add-Member -MemberType NoteProperty -Name "GroupDistinguishedName" -Value $Group.DistinguishedName
                    $MemberData | Add-Member -MemberType NoteProperty -Name "MemberName" -Value $Member.Name
                    $MemberData | Add-Member -MemberType NoteProperty -Name "MemberSamAccountName" -Value $Member.SamAccountName
                    $MemberData | Add-Member -MemberType NoteProperty -Name "MemberDistinguishedName" -Value $Member.DistinguishedName

                    $CsvData += $MemberData
                }
            }
            catch {
                Write-Log -Message ("Error adding to CSV data") -Level Error -Path $LogFile
            }
        }

        Write-Log -Message ("Finished processing on OU: " + $OU) -Level Info -Path $LogFile
    }
    Write-Log -Message ("Writing CSV data to file: " + $CsvDataFile) -Level Info -Path $LogFile
    $CsvData | Export-Csv -Path $CsvDataFile -Encoding Unicode -Delimiter ";" -NoTypeInformation
}