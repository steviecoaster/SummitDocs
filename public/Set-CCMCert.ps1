function Set-CCMCert {
    <#
    .SYNOPSIS
    Certificate renewal script for Chocolatey Central Management(CCM)
    .DESCRIPTION
    This script will go through and renew the certificate association with both the Chocolatey Central Management Service and IIS Web hosted dashboard.
    .PARAMETER CertificateThumbprint
    Thumbprint value of the certificate you would like the Chocolatey Central Management Service and Web to run on.
    Please make sure the certificate is located in both the Cert:\LocalMachine\TrustedPeople\ and Cert:\LocalMachine\My certificate stores.
    #>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [String]
    $CertificateThumbprint
)

begin {
    if($host.name -ne 'ConsoleHost') {
        Write-Warning "This script cannot be ran from within PowerShell ISE"
        Write-Warning "Please launch powershell.exe as an administrator, and run this script again"
        break
    }
}

process {

    #Stop Central Management components
        Stop-Service chocolatey-central-management
        Get-Process chocolateysoftware.chocolateymanagement.web* | Stop-Process -ErrorAction SilentlyContinue -Force

    #Remove existing bindings
        Write-Verbose "Removing existing bindings"
        netsh http delete sslcert ipport=0.0.0.0:443

    #Add new CCM Web IIS Binding
        Write-Verbose "Adding new IIS binding to Chocolatey Central Management"
        $guid = [Guid]::NewGuid().ToString("B")
        netsh http add sslcert ipport=0.0.0.0:443 certhash=$CertificateThumbprint certstorename=MY appid="$guid"
        Get-WebBinding -Name ChocolateyCentralManagement | Remove-WebBinding
        New-WebBinding -Name ChocolateyCentralManagement -Protocol https -Port 443 -SslFlags 0 -IpAddress '*'        

    #Write Thumbprint to CCM Service appsettings.json
        $appSettingsJson = 'C:\ProgramData\chocolatey\lib\chocolatey-management-service\tools\service\appsettings.json'
        $json = Get-Content $appSettingsJson | ConvertFrom-Json
        $json.CertificateThumbprint = $CertificateThumbprint
        $json | ConvertTo-Json | Set-Content $appSettingsJson -Force

    #Try Restarting CCM Service
        try {
            Start-Service chocolatey-central-management -ErrorAction Stop
        }
        catch {
            #Try again...
            Start-Service chocolatey-central-management -ErrorAction SilentlyContinue
        }
        finally {
            if ((Get-Service chocolatey-central-management).Status -ne 'Running') {
             Write-Warning "Unable to start Chocolatey Central Management service, please start manually in Services.msc"
            }
        }
}
}