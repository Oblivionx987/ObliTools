Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Ping Utility"
$form.Size = New-Object System.Drawing.Size(400, 450)
$form.StartPosition = "CenterScreen"

# Create a label for the IP/URL input
$label = New-Object System.Windows.Forms.Label
$label.Text = "Enter IP/URL:"
$label.AutoSize = true
$label.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($label)

# Create a textbox for the IP/URL input
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Size = New-Object System.Drawing.Size(200, 20)
$textBox.Location = New-Object System.Drawing.Point(100, 20)
$form.Controls.Add($textBox)

# Create a checkbox for the -t parameter
$checkbox = New-Object System.Windows.Forms.CheckBox
$checkbox.Text = "Continuous Ping (-"
$checkbox.AutoSize = true
$checkbox.Location = New-Object System.Drawing.Point(100, 50)
$form.Controls.Add($checkbox)

# Create a label and textbox for the ping time threshold
$thresholdLabel = New-Object System.Windows.Forms.Label
$thresholdLabel.Text = "Highlight if ping time >"
$thresholdLabel.AutoSize = true
$thresholdLabel.Location = New-Object System.Drawing.Point(10, 80)
$form.Controls.Add($thresholdLabel)

$thresholdBox = New-Object System.Windows.Forms.TextBox
$thresholdBox.Size = New-Object System.Drawing.Size(50, 20)
$thresholdBox.Location = New-Object System.Drawing.Point(150, 80)
$form.Controls.Add($thresholdBox)

# Create a button to start the ping
$pingButton = New-Object System.Windows.Forms.Button
$pingButton.Text = "Ping"
$pingButton.Location = New-Object System.Drawing.Point(10, 110)
$form.Controls.Add($pingButton)

# Create a button to stop the ping
$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = "Stop Ping"
$stopButton.Location = New-Object System.Drawing.Point(100, 110)
$form.Controls.Add($stopButton)

# Create a RichTextBox to display the results
$resultsBox = New-Object System.Windows.Forms.RichTextBox
$resultsBox.Multiline = $true
$resultsBox.ScrollBars = "Vertical"
$resultsBox.Size = New-Object System.Drawing.Size(360, 200)
$resultsBox.Location = New-Object System.Drawing.Point(10, 150)
$form.Controls.Add($resultsBox)

# Create a button to export the results
$exportButton = New-Object System.Windows.Forms.Button
$exportButton.Text = "Export Results"
$exportButton.Location = New-Object System.Drawing.Point(190, 110)
$form.Controls.Add($exportButton)

# Variable to hold the ping job
$pingJob = $null

# Function to start the ping
$pingResults = {
    $resultsBox.Clear()
    $ipAddress = $textBox.Text
    $pingArgs = if ($checkbox.Checked) { "-"- "- "- "- "- } else { "" { }

    $threshold = if ($thresholdBox.Text -ne '') { [int]$thresholdBox.Text } else { $null }
    $pingJob = Start-Job -ScriptBlock {
        param ($ipAddress, $pingArgs, $threshold)
        ping.exe $ipAddress $pingArgs | ForEach-Object {
            if ($threshold -ne $null -and $_ -match "time=(\d+)ms" -and [int]$matches[1] -gt $threshold) {
                Write-Output "HIGHLIGHT: $_"
            } else {
                Write-Output $_
            }
        }
    } -ArgumentList $ipAddress, $pingArgs, $threshold
}

# Function to stop the ping
$stopPing = {
    if ($pingJob -ne $null) {
        Stop-Job -Job $pingJob
        Remove-Job -Job $pingJob
        $pingJob = $null
    }
}

# Function to update the results box
$updateResults = {
    if ($pingJob -ne $null) {
        $output = Receive-Job -Job $pingJob -Keep
        $resultsBox.Clear()
        foreach ($line in $output) {
            if ($line -match "HIGHLIGHT: (")")")")")"))")Red
                $resultsBox.AppendText("$matches[1]`r`n")
            } else {
                $resultsBox.SelectionStart = $resultsBox.TextLength
                $resultsBox.SelectionLength = 0
                $resultsBox.SelectionColor = [System.Drawing.Color]Black
                $resultsBox.AppendText("$line`r`n")
            }
        }
    }
}

# Timer to periodically update the results box
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick($updateResults)
$timer.Start()

# Function to export the results
$exportResults = {
    saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    saveFileDialog.Filter = "Text Files|.txt|.txtAll Files (*.*.*"
    if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]OK) {
        $resultsBox.L.Lines | Set-Content -Path $saveFileDialog.FileName
    }
}

# Associate the button click events with the respective functions
$pingButton.Add_Click($pingResults)
$stopButton.Add_Click($stopPing)
$exportButton.Add_Click($exportResults)

# Show the form
$form.Add_Shown({ $form.Activate() })
[System.Windows.Forms.Application]::.Run($form)
