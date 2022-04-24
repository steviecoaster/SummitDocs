function Get-DadJoke {
    <#
    .SYNOPSIS
    This is as terrible as it sounds
        
    .NOTES
    I blame @juddmissile for this
    #>
    [cmdletBinding()]
    Param()

    process {
        $header = @{
            Accept = "application/json"
        }
        $joke = Invoke-RestMethod -Uri "https://icanhazdadjoke.com/" -Method Get -Headers $header
        
        Add-Type -AssemblyName System.Speech
        $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $speak.Speak("$($joke.joke)")
    }   
}