function New-FileSystemWatcher {
    <#
    .SYNOPSIS
    Creates a filesystem watcher for building Chocolatey packages
    
    .DESCRIPTION
    Starts a filesystem watcher allowing you to drop binaries into a folder, and get Chocolatey packages out the other end
    
    .PARAMETER Path
    Path for the watcher
    
    .EXAMPLE
    New-FileSystemWatcher -Path C:\drop
    
    .NOTES
    
    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.dev/SummitDocs/New-FileSystemWatcher/')]
    Param(
        [Parameter()]
        [String]
        $Path = 'C:\drop'
    )

    process {
        $FileFilter = '*'  
        $IncludeSubfolders = $false
        $AttributeFilter = [IO.NotifyFilters]::FileName, [IO.NotifyFilters]::LastWrite 

        try {
            $watcher = New-Object -TypeName System.IO.FileSystemWatcher -Property @{
                Path                  = $Path
                Filter                = $FileFilter
                IncludeSubdirectories = $IncludeSubfolders
                NotifyFilter          = $AttributeFilter
            }

            # define the code that should execute when a change occurs:
            $action = {
    
                # change type information:
                $file = (Get-ChildItem $Path -Include *.exe, *.msi -Recurse).Fullname

                Write-Host "Processing: $file"

                $chocoArgs = @('new'
                    "--file='$file'"
                    '--build-package'
                    "--output-directory='C:\processed'")

                Write-Host "Received arguments: $($chocoArgs -join ' ')"
                & choco @chocoArgs
            
                Write-Host "Removing binary"
                Remove-Item $file -Force

                Get-ChildItem -Path 'C:\processed' -Exclude *.nupkg | Remove-Item -Recurse -Force
            }

            $handlers = . {
                Register-ObjectEvent -InputObject $watcher -EventName Changed  -Action $action 
            }

            $watcher.EnableRaisingEvents = $true

            Write-Host "Watching for changes to $Path"

            do {
                Wait-Event -Timeout 1
            } while ($true)
        }
        finally {
            # this gets executed when user presses CTRL+C:
            $watcher.EnableRaisingEvents = $false
            $handlers | ForEach-Object {
                Unregister-Event -SourceIdentifier $_.Name
            }
            $handlers | Remove-Job
            $watcher.Dispose()
  
            Write-Warning "Event Handler disabled, monitoring ends."
        }
    }
}