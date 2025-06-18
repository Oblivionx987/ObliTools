
#region Script Info
$Script_Name = "MultiSiteChecker-1.0.0.ps1"
$Description = "This script will monitor the status of multiple sites, allowing you to add, remove, and filter sites, and log their statuses."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "1.0.0"
$live = "Restricted"
$bmgr = "Restricted"
#endregion

#region Text Colors 
function Red     { process { Write-Host $_ -ForegroundColor Red }}
function Green   { process { Write-Host $_ -ForegroundColor Green }}
function Yellow  { process { Write-Host $_ -ForegroundColor Yellow }}
function Blue    { process { Write-Host $_ -ForegroundColor Blue }}
function Cyan    { process { Write-Host $_ -ForegroundColor Cyan }}
function Magenta { process { Write-Host $_ -ForegroundColor Magenta }}
function White   { process { Write-Host $_ -ForegroundColor White }}
function Gray    { process { Write-Host $_ -ForegroundColor Gray }}
#endregion

#region Main Descriptor
## START Main Descriptor
Write-Output "--------------------" | Yellow
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr" | Yellow
Write-Output "$Description" | Yellow
Write-Output "--------------------" | Yellow
## END Main Descriptor
#endregion

# Import required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic  # For InputBox

# Define paths
$csvFilePath = "C:\Users\Jessica\OneDrive\Seth\Oblivion Vault\Scripts\SiteChecker\Sites.csv"
$logFilePath = "C:\Users\Jessica\OneDrive\Seth\Oblivion Vault\Scripts\SiteChecker\SiteStatusLog.csv"

# Check CSV file
if (-not (Test-Path $csvFilePath)) {
    Write-Host "CSV file not found at $csvFilePath. Please check the path."
    exit
}
$sites = Import-Csv -Path $csvFilePath  # Should contain columns "Site" and (optionally) "Name"

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Site Status Monitor"
$form.Size = New-Object System.Drawing.Size(700, 600)
$form.StartPosition = "CenterScreen"

# DataGridView for site statuses
$gridView = New-Object System.Windows.Forms.DataGridView
$gridView.Size = New-Object System.Drawing.Size(660, 300)
$gridView.Location = New-Object System.Drawing.Point(10, 10)
$gridView.ReadOnly = $true
$gridView.AllowUserToAddRows = $false
$gridView.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
$gridView.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect

# Define columns:
$gridView.Columns.Add("Site", "Site")                          # Index 0
$gridView.Columns.Add("FriendlyName", "Name")                  # Index 1
$gridView.Columns.Add("Status", "Status")                      # Index 2
$gridView.Columns.Add("ResponseTime", "Response Time (ms)")    # Index 3
$gridView.Columns.Add("LastChecked", "Last Checked")           # Index 4

$form.Controls.Add($gridView)

# Dropdown to filter sites
$filterDropdown = New-Object System.Windows.Forms.ComboBox
$filterDropdown.Location = New-Object System.Drawing.Point(10, 320)
$filterDropdown.Size = New-Object System.Drawing.Size(150, 30)
$filterDropdown.Items.AddRange(@("All", "Up", "Down"))
$filterDropdown.SelectedIndex = 0
$form.Controls.Add($filterDropdown)

# Buttons
$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = "Refresh"
$refreshButton.Size = New-Object System.Drawing.Size(100, 30)
$refreshButton.Location = New-Object System.Drawing.Point(10, 360)
$form.Controls.Add($refreshButton)

$addSiteButton = New-Object System.Windows.Forms.Button
$addSiteButton.Text = "Add Site"
$addSiteButton.Size = New-Object System.Drawing.Size(100, 30)
$addSiteButton.Location = New-Object System.Drawing.Point(120, 360)
$form.Controls.Add($addSiteButton)

$removeSiteButton = New-Object System.Windows.Forms.Button
$removeSiteButton.Text = "Remove Site"
$removeSiteButton.Size = New-Object System.Drawing.Size(100, 30)
$removeSiteButton.Location = New-Object System.Drawing.Point(230, 360)
$form.Controls.Add($removeSiteButton)

$exportButton = New-Object System.Windows.Forms.Button
$exportButton.Text = "Export Status"
$exportButton.Size = New-Object System.Drawing.Size(100, 30)
$exportButton.Location = New-Object System.Drawing.Point(340, 360)
$form.Controls.Add($exportButton)

# Next refresh time label
$nextRefreshLabel = New-Object System.Windows.Forms.Label
$nextRefreshLabel.Text = "Next Refresh: Calculating..."
$nextRefreshLabel.Location = New-Object System.Drawing.Point(10, 400)
$nextRefreshLabel.Size = New-Object System.Drawing.Size(480, 30)
$form.Controls.Add($nextRefreshLabel)

# Details label to display site information
$detailsLabel = New-Object System.Windows.Forms.Label
$detailsLabel.Text = "Site Details: Select a site to view details."
$detailsLabel.Location = New-Object System.Drawing.Point(10, 440)
$detailsLabel.Size = New-Object System.Drawing.Size(680, 60)
$form.Controls.Add($detailsLabel)

# Event handler for row selection in the DataGridView
$gridView.Add_SelectionChanged({
    if ($gridView.SelectedRows.Count -gt 0) {
        $selectedRow = $gridView.SelectedRows[0]
        
        $siteName      = $selectedRow.Cells[0].Value
        $friendlyName  = $selectedRow.Cells[1].Value
        $status        = $selectedRow.Cells[2].Value
        $responseTime  = $selectedRow.Cells[3].Value
        $lastChecked   = $selectedRow.Cells[4].Value
        
        $detailsLabel.Text = "Site Details:`nSite: $siteName`nFriendly Name: $friendlyName`nStatus: $status`nResponse Time: $responseTime ms`nLast Checked: $lastChecked"
    }
    else {
        $detailsLabel.Text = "Site Details: Select a site to view details."
    }
})

# NotifyIcon for system tray
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Application
$notifyIcon.Visible = $true
$notifyIcon.Text = "Site Status Monitor"
$notifyIcon.ContextMenu = New-Object System.Windows.Forms.ContextMenu
$notifyIcon.ContextMenu.MenuItems.Add("Open", { $form.WindowState = 'Normal'; $form.Show(); $form.BringToFront() })
$notifyIcon.ContextMenu.MenuItems.Add("Exit", { $form.Close() })
$form.Add_FormClosing({ $notifyIcon.Dispose() })

# Function to update site statuses
function Update-SiteStatus {
    foreach ($site in $sites) {
        $siteName      = $site.Site
        $friendlyName  = $site.Name    # If your CSV has a column "Name"
        
        try {
            $ping         = Test-Connection -ComputerName $siteName -Count 1 -Quiet -ErrorAction Stop
            $status       = if ($ping) { "Up" } else { "Down" }
            $responseTime = (Test-Connection -ComputerName $siteName -Count 1 -ErrorAction Stop).ResponseTime
        } catch {
            $status       = "Down"
            $responseTime = "N/A"
        }
        
        $lastChecked = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
        # Find or add row (pick the first matching row)
        $row = $gridView.Rows | Where-Object { $_.Cells[0].Value -eq $siteName } | Select-Object -First 1
        if (-not $row) {
            $rowIndex = $gridView.Rows.Add()
            $row      = $gridView.Rows[$rowIndex]
            
            $row.Cells[0].Value = $siteName
            $row.Cells[1].Value = $friendlyName
            $row.Cells[2].Value = $status
            $row.Cells[3].Value = $responseTime
            $row.Cells[4].Value = $lastChecked
        }
        else {
            $row.Cells[1].Value = $friendlyName
            $row.Cells[2].Value = $status
            $row.Cells[3].Value = $responseTime
            $row.Cells[4].Value = $lastChecked
        }
    
        # Update row color based on status
        if ($status -eq "Up") {
            $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::LightGreen
        } else {
            $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::LightCoral
        }
    }
}

# Function to log site statuses
function Log-SiteStatus {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    foreach ($site in $sites) {
        $siteName = $site.Site
        $status = $gridView.Rows |
            Where-Object { $_.Cells[0].Value -eq $siteName } |
            Select-Object -First 1
        
        if ($status) {
            $statusValue = $status.Cells[2].Value  # Index 2 is "Status"
        } else {
            $statusValue = "N/A"
        }
        
        "$timestamp,$siteName,$statusValue" | Out-File -Append -FilePath $logFilePath
    }
}

# Filter dropdown event
$filterDropdown.Add_SelectedIndexChanged({
    $filter = $filterDropdown.Text
    foreach ($row in $gridView.Rows) {
        # Check the status in Cells[2]
        $rowStatus = $row.Cells[2].Value
        if ($filter -eq "All" -or $rowStatus -eq $filter) {
            $row.Visible = $true
        } else {
            $row.Visible = $false
        }
    }
})

# Refresh button event
$refreshButton.Add_Click({
    Update-SiteStatus
    # Optionally log each time
    # Log-SiteStatus
})

# Add site button event
$addSiteButton.Add_Click({
    # Use a real input box rather than a message box
    $newSite = [Microsoft.VisualBasic.Interaction]::InputBox("Enter new site address (e.g. google.com)", "Add Site")
    if ($newSite -and $newSite.Trim() -ne "") {
        # Optionally prompt for a friendly name
        $newName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a friendly name (optional)", "Add Site", $newSite)
        
        # Add to the DataGridView manually
        $rowIndex = $gridView.Rows.Add()
        $gridView.Rows[$rowIndex].Cells[0].Value = $newSite
        $gridView.Rows[$rowIndex].Cells[1].Value = $newName
        $gridView.Rows[$rowIndex].Cells[2].Value = "Unknown"
        $gridView.Rows[$rowIndex].Cells[3].Value = "N/A"
        $gridView.Rows[$rowIndex].Cells[4].Value = "Not Checked"
        
        # Also add it to $sites so it’s tracked in future pings
        $sites += [PSCustomObject]@{
            Site = $newSite
            Name = $newName
        }
    }
})

# Remove site button event
$removeSiteButton.Add_Click({
    if ($gridView.SelectedRows.Count -gt 0) {
        foreach ($row in $gridView.SelectedRows) {
            $siteToRemove = $row.Cells[0].Value  # The site name
            $gridView.Rows.Remove($row)
            
            # Also remove from $sites so it’s no longer tracked
            $sites = $sites | Where-Object { $_.Site -ne $siteToRemove }
        }
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Select a site to remove.", "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Export button event
$exportButton.Add_Click({
    $exportPath = "C:\Path\To\ExportedStatus.csv"
    # Overwrite existing file
    "Site,Name,Status,ResponseTime,LastChecked" | Out-File -FilePath $exportPath
    $gridView.Rows | ForEach-Object {
        $line = "{0},{1},{2},{3},{4}" -f `
            $_.Cells[0].Value, `
            $_.Cells[1].Value, `
            $_.Cells[2].Value, `
            $_.Cells[3].Value, `
            $_.Cells[4].Value
        $line | Out-File -Append -FilePath $exportPath
    }
    [System.Windows.Forms.MessageBox]::Show("Site statuses exported to $exportPath", "Export Complete")
})

# Timer for periodic updates
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 300000  # 5 minutes in milliseconds
$timer.Add_Tick({
    Update-SiteStatus
    # Optionally call Log-SiteStatus here to log each time
    # Log-SiteStatus

    # You could also update $nextRefreshLabel to show the next time
    # it will refresh, e.g. "Next Refresh: HH:mm:ss"
    $nextRefreshLabel.Text = "Next Refresh: " + (Get-Date).AddMilliseconds($timer.Interval).ToString("HH:mm:ss")
})

# Start timer and display GUI
$timer.Start()
Update-SiteStatus
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
