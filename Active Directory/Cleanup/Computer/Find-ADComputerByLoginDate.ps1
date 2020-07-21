<#
.Synopsis
   Finds computer objects in Active Directory that has not been logged in for the spesified time period.
.DESCRIPTION
   Finds computer objects in Active Directory that has not been logged in for the spesified time period.
   Filterable by OU.
.EXAMPLE
   .\Find-ADComputerByLoginDate -DaysSinceLogin 60 -OU "OU=Example,DC=Domain,DC=Com"
.EXAMPLE
   .\Find-ADComputerByLoginDate -DaysSinceLogin 365
#>
function Find-ADComputerByLoginDate
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # How many days since the computer was logged in.
        [Parameter(Mandatory=$true, HelpMessage="Set the days since last login.")]
        [ValidateNotNullOrEmpty()]
        [int]$DaysSinceLogin,

        # Path of OU to search in.
        [parameter(Mandatory=$false, HelpMessage="Define path of OU to search.")]
        [ValidateNotNullOrEmpty()]
        [string]$OU = [System.String]::Empty,

        # Which DC to use
        [parameter(Mandatory=$false, HelpMessage="Which DC to use for the query.")]
        [ValidateNotNullOrEmpty()]
        [string]$Server = [System.String]::Empty
    )

    Begin
    {
        # Import Active Directory Module
        try
        {
            Import-Module ActiveDirectory -ErrorAction Stop
        }
        catch
        {
            Write-Error -Message "Could import load Active Directory Powershell Module."
            Exit 1
        }

        # Create date object for use with AD Cmdlet
        $DateObjectForFilter = (Get-Date).AddDays(-$DaysSinceLogin)

        try
        {
            if ($OU -eq [System.String]::Empty)
            {
                $OU = (Get-ADDomain).DistinguishedName
            }
            elseif(Get-ADOrganizationalUnit -Identity $OU)
            {            
                Write-Verbose "Given OU exists."            
            }
        }
        catch
        {
            Write-Error -Message "Could not get Active Directory location."
            Exit 1
        }
    }
    Process
    {
        try
        {
            $Arguments = @{
                Properties = "Name","lastLogonDate"
                Filter = {lastLogonDate -lt $DateObjectForFilter}
                SearchBase = $OU
                ErrorAction = "Stop"
            }

            if ($Server -ne [System.String]::Empty) {
                $Arguments.Add("Server", $Server)
            }

            $Computers = Get-ADComputer @Arguments
        }
        catch
        {
            Write-Error -Message "Could not find computer objects."
            Exit 1
        }
    }
    End
    {
        Return $Computers
    }
}