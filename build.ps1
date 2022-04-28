[CmdletBinding()]
Param(
    [Parameter()]
    [Switch]
    $Build,

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
        $GenerateHelp {
            if (-not (Test-Path (Join-Path $module -ChildPath 'SummitDocs.psd1'))){
                throw "Module not found, did you build it yet?"
            } else {
                Import-Module (Join-Path $module -ChildPath 'SummitDocs.psd1') -Force
                New-MarkdownHelp -Module SummitDocs -OutputFolder (join-Path $root -ChildPath 'docs') -Force
            }
        }
        $GenerateDocs {
            refreshenv
            $mkdocs = (Get-Command mkdocs).Source
            $mkDocsArgs = @('build')
            & $mkdocs @mkDocsArgs
        }

        $PublishDocs {
            <#
                git remote set-url origin https://$($env:GitUser):$($GitPassword)@github.com/repo.git
            #>
            $publishArgs = @('gh-deploy')
            & mkdocs @publishArgs
        }
    }
}