function Get-PackageIcon {
    <#
    .SYNOPSIS
    Internalizes icon for Chocolatey Package from Community Repository
    
    .DESCRIPTION
    Downloads and publishes icon for internalized Chocolatey package to your own hosted repository. Re-writes package icon url in nuspec to new internal url.
    
    .PARAMETER InternalizerDownloadPath
    Path where internalized packages are located
    
    .PARAMETER IconRepository
    Url to your icon repository
    
    .PARAMETER PackageRepository
    Url to your package repository
    
    .PARAMETER Credential
    Credential to upload to your repository
    
    .PARAMETER ApiKey
    API to push fixed package to your package repository
    
    .EXAMPLE
    Get-PackageIcon -InternalizerDownloadPath C:\packages -IconRepository https://repo.fabrikam.com/repository/icons -PackageRepository https://repo.fabrikam.com/repository/packages
    
    .NOTES
    
    #>
    [cmdletBinding(HelpUri = 'https://steviecoaster.dev/SummitDocs/Get-PackageIcon/')]
    param(
        [Parameter(Mandatory)]
        [String[]]
        $InternalizerDownloadPath,

        [Parameter(Mandatory)]
        [String]
        $IconRepository,

        [Parameter(Mandatory)]
        [String]
        $PackageRepository,

        [Parameter(Mandatory)]
        [PSCredential]
        $Credential,

        [Parameter()]
        [String]
        $ApiKey
   
    )

    process {
        $nuspecs = $(Get-ChildItem $InternalizerDownloadPath -Recurse -Include *.nuspec, chocolateyInstall.ps1)

        Write-Verbose "Downloading icons and replacing values in nuspec files"

        foreach ($nuspec in $nuspecs) {

            [xml]$xml = $nuspec | Where-Object { $_.Extension -eq '.nuspec' } | Get-Content
            $iconurl = $xml.package.metadata.iconUrl
            $icon = ($iconurl -split ('/'))[-1]
            $iconPath = Join-Path 'C:\icons' "$icon"

            if ($iconurl) {

                $null = Invoke-WebRequest -Uri $iconurl -OutFile "$($iconPath)" -ErrorAction SilentlyContinue

                $user = $Credential.UserName
                $password = $Credential.GetNetworkCredential().Password

                $credPair = "{0}:{1}" -f $user, $password
                $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::Utf8.GetBytes($credPair))

                $params = @{
                    Headers         = @{
                        Authorization = "Basic $encodedCreds"
                    }

                    UseBasicParsing = $true
                    ContentType     = 'text/plain'
                }
            
                if ($iconPath -eq 'C:\icons\') {
                    $null
                }
                else {
                    $newUrl = "$($IconRepository)$icon"
                    Write-Verbose "Uploading: $iconPath"
                    $null = Invoke-WebRequest -Uri $newUrl -Method Put -infile $iconPath @params -ErrorAction SilentlyContinue

                    #Write new URL
                    $xml.package.metadata.iconUrl = $newUrl
                    $xml.Save($($nuspec.FullName))

                    $Script:RepackageDirectory = Split-Path -Parent -Path $InternalizerDownloadPath

                    $chocoPackArgs = @('pack', "$($nuspec.FullName)", "--output-directory='$RepackageDirectory'")
                    & choco @chocoPackArgs
                }

            }

        } 

        Write-Verbose "Uploading modified packages to repository"

        Get-ChildItem $RepackageDirectory -Recurse -Filter *.nupkg | Foreach-Object {
        
            $chocoPushArgs = @('push', "$($_.FullName)", "--source='$PackageRepository'")

            if ($ApiKey) {
                $chocoPushArgs += "--api-key='$ApiKey'"
            }

            if ($($PackageRepository.Split(':')[0]) -match 'http') {
                $chocoPushArgs += '--force'
            }

            & choco @chocoPushArgs
        }

        Remove-Item C:\icons -Recurse -Force
    }
}