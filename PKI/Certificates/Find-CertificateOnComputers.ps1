<#
.DESCRIPTION
   Searches for a spesific Certificate Thumbprint on a selection of computers from AD
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Para]
)
Begin {
    # Import Write-Log function
    try {
        Import-Module .\Write-Log.ps1 -ErrorAction Stop
    }
    catch {
        Write-Error -Message "Could not import Write-Log function."
        Exit 1
    }

    $Date = (Get-Date -Format d)
    $LogFolder = ".\Logs\" # Directory for storing logs
    $LogFile = Join-Path -Path $LogFolder -ChildPath ($Date + " - Find-CertificateOnComputers.log")

    $CertThumbprint = “12345abcdef6789ghijkl”
    $adSearchBase = “OU=Servers,DC=supinfo,DC=local”
    $allmachines = Get-ADComputer -Filter ‘ObjectClass -eq “Computer”‘ -searchbase $adSearchBase | Select –ExpandProperty Name | Sort-Object
    $failedMachines = @()
}
Process {
    Write-Log -Message "Starting Process Block of Find-CertificateOnComputers.ps1" -Level "Info" -Path $LogFile

    foreach ($machine in $machines)
    {

        #beginning of the try/catch

        Write-Host “Scanning for cert with thumbprint $certThumbprint on machine $machine”

        try
        {

            $store = New-Object System.Security.Cryptography.X509Certificates.x509Store(“\\$machine\My”, “LocalMachine”)

            $store.Open(0)

            $scanningCert = $store.Certificates | Where-Object {$_.Thumbprint -eq $certThumbprint}

            if (!$scanningCert)
            {

                Write-Host “certificate with thumbprint $certThumbprint does not exist on machine $machine”

                $failedMachines += $machine

            }

            $store.Close()

        }

        catch
        {

            Write-Error “Unable to scan certificate with thumbprint $certThumbprint for machine $machine”

        }

    }

    Write-Host “Machines that don’t contain the specify cert: $failedMachines”

    Write-Log -Message "Ending Process Block of Find-CertificateOnComputers.ps1" -Level "Info" -Path $LogFile
}
End {
    Remove-Module -Name Write-Log
}