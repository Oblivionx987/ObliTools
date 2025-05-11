Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Define CSV path
$csvPath = Join-Path -Path $PSScriptRoot -ChildPath "Sites.csv"

# Create CSV if it doesn't exist
if (!(Test-Path -Path $csvPath)) {
    New-Item -ItemType File -Path $csvPath | Out-Null
    # Add headers to the CSV
    "SiteName,Link" | Out-File -FilePath $csvPath -Encoding UTF8
    Write-Host "Created new CSV file with headers"
} else {
    Write-Host "CSV file already exists"
}

# Load data from CSV
function Load-Sites {
    Write-Host "Loading sites from $csvPath"
    $sites = Import-Csv -Path $csvPath | Where-Object { $_.SiteName -and $_.Link }
    Write-Host "Loaded $($sites.Count) sites"
    foreach ($site in $sites) {
        Write-Host "SiteName: $($site.SiteName), Link: $($site.Link)"
    }
    return $sites
}

# Save data to CSV
function Save-Site {
    param (
        [string]$SiteName,
        [string]$Link
    )
    $site = [PSCustomObject]@{
        SiteName = $SiteName
        Link     = $Link
    }
    $sites = Load-Sites
    $sites += $site
    $sites | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Saved site: $SiteName, $Link"
}

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Link Manager"
$form.Size = New-Object System.Drawing.Size(400, 500)
$form.StartPosition = "CenterScreen"

# Label for Site Name
$siteNameLabel = New-Object System.Windows.Forms.Label
$siteNameLabel.Text = "Site Name:"
$siteNameLabel.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($siteNameLabel)

# TextBox for Site Name
$siteNameTextBox = New-Object System.Windows.Forms.TextBox
$siteNameTextBox.Location = New-Object System.Drawing.Point(100, 10)
$siteNameTextBox.Size = New-Object System.Drawing.Size(250, 20)
$form.Controls.Add($siteNameTextBox)

# Label for Link
$linkLabel = New-Object System.Windows.Forms.Label
$linkLabel.Text = "Link:"
$linkLabel.Location = New-Object System.Drawing.Point(10, 40)
$form.Controls.Add($linkLabel)

# TextBox for Link
$linkTextBox = New-Object System.Windows.Forms.TextBox
$linkTextBox.Location = New-Object System.Drawing.Point(100, 40)
$linkTextBox.Size = New-Object System.Drawing.Size(250, 20)
$form.Controls.Add($linkTextBox)

# Button to add site
$addButton = New-Object System.Windows.Forms.Button
$addButton.Text = "Add Site"
$addButton.Location = New-Object System.Drawing.Point(100, 70)
$addButton.Add_Click({
    if ($siteNameTextBox.Text -and $linkTextBox.Text) {
        Write-Host "Adding site: $($siteNameTextBox.Text), $($linkTextBox.Text)"
        Save-Site -SiteName $siteNameTextBox.Text -Link $linkTextBox.Text
        $siteNameTextBox.Clear()
        $linkTextBox.Clear()
        Refresh-SiteButtons
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please enter both a site name and a link.")
    }
})
$form.Controls.Add($addButton)

# Panel to hold dynamically created buttons
$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.Location = New-Object System.Drawing.Point(10, 110)
$buttonPanel.Size = New-Object System.Drawing.Size(360, 340)
$buttonPanel.AutoScroll = $true
$buttonPanel.BackColor = [System.Drawing.Color]::LightGray
$form.Controls.Add($buttonPanel)

# Function to refresh buttons based on CSV content
function Refresh-SiteButtons {
    $buttonPanel.Controls.Clear()
    $y = 0
    $sites = Load-Sites
    if ($sites) {
        $sites | ForEach-Object {
            param ($site)
            if ($site.SiteName -and $site.Link) {
                Write-Host "Creating button for site: $($site.SiteName), link: $($site.Link)"
                
                $linkButton = New-Object System.Windows.Forms.Button
                $linkButton.Text = $site.SiteName
                $linkButton.Size = New-Object System.Drawing.Size(340, 30)
                $linkButton.Location = New-Object System.Drawing.Point(0, $y)
                $linkButton.Tag = $site.Link
                $linkButton.BackColor = [System.Drawing.Color]::White
                $linkButton.ForeColor = [System.Drawing.Color]::Black
                $linkButton.Font = New-Object System.Drawing.Font("Arial", 10)
                $linkButton.Add_Click({
                    if ($linkButton.Tag) {
                        Start-Process -FilePath $linkButton.Tag
                    } else {
                        [System.Windows.Forms.MessageBox]::Show("The link is empty or invalid.")
                    }
                })
                
                $buttonPanel.Controls.Add($linkButton)
                Write-Host "Button added: $($linkButton.Text)"
                $y += 35
            } else {
                Write-Host "Skipping invalid site entry: SiteName=$($site.SiteName), Link=$($site.Link)"
            }
        }
    } else {
        Write-Host "No sites found in CSV."
    }
}

# Initial load of buttons
Refresh-SiteButtons

# Show the form
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
