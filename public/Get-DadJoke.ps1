function Get-DadJoke {
    <#
    .SYNOPSIS
    This is as terrible as it sounds

    .DESCRIPTION
    Tells you a dad joke. It's really creepy.
        
    .EXAMPLE
    Get-DadJoke

    It's super simple
    
    .NOTES
    I blame @juddmissile for this
    #>
    [cmdletBinding(HelpUri = 'https://steviecoaster.dev/SummitDocs/Get-DadJoke/')]
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