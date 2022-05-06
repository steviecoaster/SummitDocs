[CmdletBinding()]
Param(
    [Parameter()]
    [Switch]
    $Build,

    [Parameter()]
    [Switch]
    $Test,

    [Parameter()]
    [Switch]
    $GenerateHelp,

    [Parameter()]
    [Switch]
    $GenerateDocs,

    [Parameter()]
    [Switch]
    $PublishDocs
)

process {
    $root = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $moduleRoot = Join-Path $root -ChildPath 'Output'
    $module = Join-path $moduleRoot -ChildPath 'SummitDocs'
            
    switch ($true) {
        $Build {
            

            if (-not (Test-Path $moduleRoot)) {
                Remove-Item $moduleRoot -Recurse -Force -ErrorAction SilentlyContinue
                $null = New-Item $moduleRoot -ItemType Directory
            }

            if (-not (Test-Path $module)) {
                $null = New-Item $module -ItemType Directory
            }

            Copy-item $root\*.psd1 -Destination $module -Force

            $null = Get-ChildItem $root\public\*.ps1 | Foreach-Object {
                Get-Content $_.FullName | Add-Content (Join-Path $module -ChildPath 'SummitDocs.psm1')
            }
        }
        $Test {
            $module = Join-Path $module -ChildPath 'SummitDocs.psd1'
            Import-Module $Module

            Invoke-Pester (Join-Path $root -ChildPath 'tests')
        }
        $GenerateHelp {
            if (-not (Test-Path (Join-Path $module -ChildPath 'SummitDocs.psd1'))){
                throw "Module not found, did you build it yet?"
            } else {
                Import-Module (Join-Path $module -ChildPath 'SummitDocs.psd1') -Force
                New-MarkdownHelp -Module SummitDocs -OutputFolder (join-Path $root -ChildPath 'docs') -Force
            }
        }
        $GenerateDocs {
            $mkdocs = Get-ChildItem -Path "C:\hostedtoolcache\windows\Python\3.10.4\x64\Scripts\" -Recurse |
                        Where-Object Name -match 'mkdocs.exe' |
                        Select-Object -ExpandProperty Fullname

            if((Test-Path $mkdocs)){
                $mkDocsArgs = @('build')
                & $mkdocs @mkDocsArgs    
            } 
            else {
                throw "mkdocs not found for raisins"
            }
        }

        $PublishDocs {
           
            $gitArgs = @('remote','set-url','origin',"https://$($env:GitUser):$($env:GitPassword)@github.com/steviecoaster/SummitDocs.git")
            & git @gitArgs
           

            $mkdocs = Get-ChildItem -Path "C:\hostedtoolcache\windows\Python\3.10.4\x64\Scripts\" -Recurse |
            Where-Object Name -match 'mkdocs.exe' |
            Select-Object -ExpandProperty Fullname

            if((Test-Path $mkdocs)){
                
                $publishArgs = @('gh-deploy')
                & $mkdocs @publishArgs
    
            } 
            else {
                throw "mkdocs not found for raisins"
            }

        }
    }
}