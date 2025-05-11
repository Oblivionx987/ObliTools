# Define the URL for the Cisco Finesse API endpoint that provides the waiting calls information
# You will need to replace this with the actual URL and ensure you have the correct credentials and permissions
$apiUrl = "https://salccx01.sncorp.intranet.com:8445/desktop/container/?locale=en_US#/queueData"

# Define the path to the alert sound file
$soundFilePath = "C:\Users\114825\Downloads\Original-Log-Commercial_The-Ren-and-Stimpy-Show.wav"

# Function to get the number of waiting calls from the Cisco Finesse API
function Get-WaitingCalls {
    try {
        # Make a web request to the Cisco Finesse API
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -UseBasicParsing -Credential (Get-Credential)
        
        # Assuming the response contains a JSON object with a property "waitingCalls"
        $waitingCalls = $response.waitingCalls
        
        return $waitingCalls
    } catch {
        Write-Error "Failed to retrieve waiting calls: $_"
        return $null
    }
}

# Function to play the alert sound
function Play-AlertSound {
    try {
        Add-Type -TypeDefinition @"
            using System;
            using System.Runtime.InteropServices;
            public class SoundPlayer {
                [DllImport("winmm.dll")]
                public static extern bool PlaySound(string lpszName, IntPtr hModule, int dwFlags);
            }
"@
        [SoundPlayer]::PlaySound($soundFilePath, [IntPtr]::Zero, 0x00020001)
    } catch {
        Write-Error "Failed to play alert sound: $_"
    }
}

# Main loop to check the number of waiting calls and play the alert if necessary
while ($true) {
    $waitingCalls = Get-WaitingCalls

    if ($waitingCalls -ne $null -and $waitingCalls -ge 3) {
        Write-Output "Waiting calls have reached $waitingCalls. Playing alert sound..."
        Play-AlertSound
    } else {
        Write-Output "Waiting calls: $waitingCalls"
    }

    # Wait for a specified interval before checking again (e.g., 1 minute)
    Start-Sleep -Seconds 60
}
