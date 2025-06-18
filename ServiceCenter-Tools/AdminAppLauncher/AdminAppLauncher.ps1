#region Script Info
$Script_Name = "AdminAppLauncher.ps1"
$Description = "This script will launch multiple applications elevated with a GUI."
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "06-17-25"
$version = "2.0.0"
$live = "WIP"
$bmgr = "WIP"
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
Write-Output "--------------------"
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr" | Yellow
Write-Output "$Description" | Yellow
Write-Output "--------------------"
## END Main Descriptor
#endregion


# -----------------------------------------------------------------------------
# AdminAppLauncher.ps1 – v2.1 (2025‑06‑14)
# -----------------------------------------------------------------------------
# A forward‑looking PowerShell WinForms GUI that lets an administrator launch
# multiple applications elevated. This version includes the following features:
#   1.  Edit / remove entries in‑GUI    (context‑menu)
#   2.  Visual status feedback          (Status column)
#   3.  Sort & search                   (column sorting + live filter box)
#   4.  Import / export app lists       (JSON)
#   5.  Drag‑and‑drop add               (drop EXE/LNK onto grid)
#   6.  Color & icon cues               (row alt‑colors + app icons)
#   7.  Dark‑mode awareness             (registry check → theme switch)
#   8.  Group launch sets               (Group column + filter)
#   9.  Launch ordering with delays     (Delay column; sequential launch)
# -----------------------------------------------------------------------------

# =========================
# 1. Load Assemblies
# =========================
Add-Type -AssemblyName System.Windows.Forms   # WinForms UI
Add-Type -AssemblyName System.Drawing         # Drawing/Colors/Icons
Add-Type -AssemblyName Microsoft.VisualBasic  # InputBox dialogs

# =========================
# 2. Application Settings
# =========================
[System.Windows.Forms.Application]::EnableVisualStyles()  # Modern UI
# [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false) # (causes error in PowerShell)
$ErrorActionPreference = 'Stop'  # Stop on errors

# =========================
# 3. Globals & User Info
# =========================
$currentUser = $env:USERNAME
$ConfigPath  = Join-Path $PSScriptRoot 'appconfig.json'  # Config file path

# =========================
# 4. Admin Check Function
# =========================
function Test-IsAdmin {
    $wp = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    $wp.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

#region ► THEME (Dark / Light) ◄
# Check if the OS supports DPI awareness (Windows 10 or later)
$dpiAware = [System.Environment]::OSVersion.Version.Major -ge 10

# Function to determine if the system is in dark mode
function Get-IsDarkMode {
    try {
        $rk = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        (Get-ItemProperty -Path $rk -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme -eq 0
    } catch { $false }
}

# Set colors based on the theme (dark or light mode)
$IsDark = Get-IsDarkMode
$BackColor = if ($IsDark) { [Drawing.Color]::FromArgb(30,30,30) } else { [Drawing.SystemColors]::Window }
$ForeColor = if ($IsDark) { [Drawing.Color]::WhiteSmoke } else { [Drawing.SystemColors]::ControlText }
#endregion

#region ► FORM & CONTROLS ◄
# Create the main form
$form               = [Windows.Forms.Form]::new()
$form.Text          = "Admin App Launcher - $currentUser"
$form.StartPosition = 'CenterScreen'
$form.BackColor     = $BackColor
$form.ForeColor     = $ForeColor
$form.AutoSize      = $false
$form.AutoSizeMode  = 'GrowOnly'  # Allow resizing but not shrinking below min size
$form.ControlBox    = $true  # Enable the default close button
$form.MinimumSize   = [System.Drawing.Size]::new(700, 350)
$form.Size          = [System.Drawing.Size]::new(960, 540)
$form.FormBorderStyle = 'Sizable'

# --- Add TabControl as root container ---
$tabControl = [Windows.Forms.TabControl]::new()
$tabControl.Dock = 'Fill'
$tabControl.BackColor = $BackColor
$tabControl.ForeColor = $ForeColor
# Add spacing between tab names (padding)
$tabControl.Padding = [System.Drawing.Point]::new(12, 4)  # Horizontal, Vertical padding
$form.Controls.Add($tabControl)

# --- Create Tab Pages ---
$tabLauncher   = [Windows.Forms.TabPage]::new()
$tabLauncher.Text = 'APP LAUNCHER'
$tabLauncher.BackColor = $BackColor
$tabLauncher.ForeColor = $ForeColor

$tabCompCheck  = [Windows.Forms.TabPage]::new()
$tabCompCheck.Text = 'COMP CHECK'
$tabCompCheck.BackColor = $BackColor
$tabCompCheck.ForeColor = $ForeColor

$tabSiteCheck  = [Windows.Forms.TabPage]::new()
$tabSiteCheck.Text = 'SITE CHECK'
$tabSiteCheck.BackColor = $BackColor
$tabSiteCheck.ForeColor = $ForeColor

$tabScripts    = [Windows.Forms.TabPage]::new()
$tabScripts.Text = 'SCRIPTS'
$tabScripts.BackColor = $BackColor
$tabScripts.ForeColor = $ForeColor

$tabSource     = [Windows.Forms.TabPage]::new()
$tabSource.Text = 'SOURCE FILES'
$tabSource.BackColor = $BackColor
$tabSource.ForeColor = $ForeColor

$tabControl.TabPages.AddRange(@($tabLauncher, $tabCompCheck, $tabSiteCheck, $tabScripts, $tabSource))

# --- Move launcher controls into APP LAUNCHER tab ---
# Use a TableLayoutPanel to hold the search panel, grid, and button panel for proper docking
$mainLauncherPanel = [Windows.Forms.TableLayoutPanel]::new()
$mainLauncherPanel.Dock = 'Fill'
$mainLauncherPanel.BackColor = $BackColor
$mainLauncherPanel.ColumnCount = 1
$mainLauncherPanel.RowCount = 3
$mainLauncherPanel.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Absolute, 36)) # Search panel
$mainLauncherPanel.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Percent, 100)) # Grid
$mainLauncherPanel.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Absolute, 48)) # Button panel

# Add a TableLayoutPanel to hold search, group filter, and timer label
$searchPanel = [Windows.Forms.TableLayoutPanel]::new()
$searchPanel.Dock = 'Top'
$searchPanel.Height = 36
$searchPanel.BackColor = $BackColor
$searchPanel.ColumnCount = 3
$searchPanel.RowCount = 1
$searchPanel.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 50)) # Search
$searchPanel.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 25)) # Group
$searchPanel.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 25)) # Timer

# Add a search/filter text box
$txtSearch = [Windows.Forms.TextBox]::new()
# $txtSearch.PlaceholderText = 'Search / filter…'  # Not supported in Windows PowerShell WinForms
$txtSearch.Dock = 'Fill'
$searchPanel.Controls.Add($txtSearch, 0, 0)

# Add a group filter combo box
$cboGroup = [Windows.Forms.ComboBox]::new()
$cboGroup.DropDownStyle = 'DropDownList'
$cboGroup.Items.Add('<All Groups>') | Out-Null
$cboGroup.SelectedIndex = 0
$cboGroup.Dock = 'Fill'
$searchPanel.Controls.Add($cboGroup, 1, 0)

# Add the timer label to the right
#$lblTimer = [Windows.Forms.Label]::new()
#$lblTimer.Text = "Time Left: 08:00:00"
#$lblTimer.Dock = 'Fill'
#$lblTimer.TextAlign = 'MiddleRight'
#$lblTimer.ForeColor = $ForeColor
#$lblTimer.BackColor = $BackColor
#$searchPanel.Controls.Add($lblTimer, 2, 0)
# Remove timer label from search panel
$searchPanel.Controls.Add((New-Object Windows.Forms.Label), 2, 0) # Empty placeholder

$mainLauncherPanel.Controls.Add($searchPanel, 0, 0)

# Add a data grid to display applications
$grid = [Windows.Forms.DataGridView]::new()
$grid.Dock = 'Top'  # Place directly below the search panel
$grid.Top = $searchPanel.Bottom
$grid.Height = $tabLauncher.ClientSize.Height - $searchPanel.Height - 60  # Leave space for buttons
$grid.Anchor = 'Top, Left, Right, Bottom'
$grid.AutoSizeRowsMode= 'AllCells'
$grid.AllowUserToAddRows = $false
$grid.RowHeadersVisible  = $false
$grid.SelectionMode      = 'FullRowSelect'
$grid.AllowDrop          = $true
$grid.EnableHeadersVisualStyles = $false
$grid.ScrollBars = 'Both'
$grid.AutoSizeColumnsMode = 'DisplayedCells'  # Shrink columns to fit content
$grid.ColumnHeadersHeightSizeMode = 'AutoSize'

# Apply dark mode styling to the grid if applicable
if ($IsDark) {
    $grid.DefaultCellStyle.BackColor        = $BackColor      # 30,30,30
    $grid.DefaultCellStyle.ForeColor        = $ForeColor      # WhiteSmoke
    $grid.DefaultCellStyle.SelectionBackColor = [Drawing.Color]::FromArgb(70,70,70)
    $grid.DefaultCellStyle.SelectionForeColor = $ForeColor
}

# Set grid background and gridline colors
$grid.BackgroundColor    = $BackColor
$grid.GridColor          = $ForeColor
$mainLauncherPanel.Controls.Add($grid, 0, 1)

# Set alternating row style for better readability
$alt = $grid.AlternatingRowsDefaultCellStyle
$alt.BackColor = if ($IsDark) { [Drawing.Color]::FromArgb(45,45,48) } else { [Drawing.Color]::FromArgb(235,235,235) }
$alt.ForeColor = $ForeColor

# Define columns for the grid
$columns = @()
$columns += [Windows.Forms.DataGridViewTextBoxColumn]@{HeaderText='Status'; Width=70; ReadOnly=$true; AutoSizeMode='DisplayedCells'}
$columns += [Windows.Forms.DataGridViewCheckBoxColumn]@{HeaderText='Sel'; Width=22; MinimumWidth=22; AutoSizeMode='DisplayedCells'}
$columns += [Windows.Forms.DataGridViewButtonColumn]@{HeaderText='Action'; Text='Start'; UseColumnTextForButtonValue=$true; Width=50; MinimumWidth=50; AutoSizeMode='DisplayedCells'}
$columns += [Windows.Forms.DataGridViewTextBoxColumn]@{HeaderText='Nickname'; Width=220; AutoSizeMode='Fill'}
$columns += [Windows.Forms.DataGridViewTextBoxColumn]@{HeaderText='Group'; Width=60; MinimumWidth=40; AutoSizeMode='DisplayedCells'}
$columns += [Windows.Forms.DataGridViewTextBoxColumn]@{HeaderText='Delay (s)'; Width=40; MinimumWidth=40; AutoSizeMode='DisplayedCells'}
$columns += [Windows.Forms.DataGridViewImageColumn]@{HeaderText='Icon'; Width=22; MinimumWidth=22; AutoSizeMode='DisplayedCells'}
$columns += [Windows.Forms.DataGridViewTextBoxColumn]@{HeaderText='Path'; Width=360; ReadOnly=$true}
foreach ($c in $columns){ [void]$grid.Columns.Add($c) }

# Add buttons for various actions in a FlowLayoutPanel for automatic layout
$btnAdd  = [Windows.Forms.Button]@{Text='Add Application'; Size=[Drawing.Size]::new(120,30)}
$btnRemove = [Windows.Forms.Button]@{Text='Remove Application'; Size=[Drawing.Size]::new(140,30)}
$btnImport = [Windows.Forms.Button]@{Text='Import'; Size=[Drawing.Size]::new(70,30)}
$btnExport = [Windows.Forms.Button]@{Text='Export'; Size=[Drawing.Size]::new(70,30)}
$btnStartSel = [Windows.Forms.Button]@{Text='Start Selection'; Size=[Drawing.Size]::new(120,30)}

$buttonPanel = [Windows.Forms.FlowLayoutPanel]::new()
$buttonPanel.FlowDirection = 'LeftToRight'
$buttonPanel.Dock = 'Fill'
$buttonPanel.Padding = [System.Windows.Forms.Padding]::new(8, 4, 8, 4)
$buttonPanel.AutoSize = $true
$buttonPanel.WrapContents = $false
$buttonPanel.Controls.AddRange(@($btnAdd,$btnRemove,$btnImport,$btnExport,$btnStartSel))
$mainLauncherPanel.Controls.Add($buttonPanel, 0, 2)

# Clear and add the main panel to the tab
$tabLauncher.Controls.Clear()
$tabLauncher.Controls.Add($mainLauncherPanel)

# --- BUTTON EVENT HANDLERS FOR APP LAUNCHER TAB ---
$btnAdd.Add_Click({
    $nick = [Microsoft.VisualBasic.Interaction]::InputBox('Enter application nickname:', 'Add Application')
    if ([string]::IsNullOrWhiteSpace($nick)) { return }
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = 'Executables (*.exe;*.lnk)|*.exe;*.lnk|All files (*.*)|*.*'
    $ofd.Title = 'Select Application Executable or Shortcut'
    if ($ofd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
    $path = $ofd.FileName
    if ([string]::IsNullOrWhiteSpace($path)) { return }
    $group = [Microsoft.VisualBasic.Interaction]::InputBox('Enter group (optional):', 'Add Application')
    $delay = [Microsoft.VisualBasic.Interaction]::InputBox('Enter launch delay in seconds (optional, default 0):', 'Add Application', '0')
    if (-not $delay -or $delay -lt 0) { $delay = 0 }
    Add-Row $nick $group $delay $path
    Export-Config
})

$btnRemove.Add_Click({
    $rowsToRemove = @($grid.SelectedRows)
    foreach ($row in $rowsToRemove) {
        if (-not $row.IsNewRow) { $grid.Rows.Remove($row) }
    }
    Export-Config
})

$btnImport.Add_Click({
    Import-Config
})

$btnExport.Add_Click({
    Export-Config
    [System.Windows.Forms.MessageBox]::Show('Configuration exported to appconfig.json.','Export Complete',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
})

$btnStartSel.Add_Click({
    $rows = $grid.Rows | Where-Object { $_.Cells[1].Value -eq $true -and -not $_.IsNewRow }
    if (-not $rows) {
        [System.Windows.Forms.MessageBox]::Show('No applications selected.','Start Selection',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    foreach ($row in $rows) {
        $path = $row.Cells[7].Value
        $delay = [int]$row.Cells[5].Value
        if ($delay -gt 0) { Start-Sleep -Seconds $delay }
        try {
            Start-Process -FilePath $path -Verb RunAs
            $row.Cells[0].Value = 'Started'
        } catch {
            $row.Cells[0].Value = 'Error'
            Write-ErrorLog ("Failed to start {0}: {1}" -f $path, $_)
        }
    }
})
# =========================
#  FUNCTIONS (must be after controls are created!)
# =========================

#region ► CONFIG LOAD / SAVE ◄
# Function to import configuration from JSON file
function Import-Config {
    if (!(Test-Path $ConfigPath)){ return }
    try {
        $json = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        $grid.SuspendLayout()
        $grid.Rows.Clear()
        # Ensure $json is always an array (robust for all cases)
        if ($null -eq $json) {
            $json = @()
        } elseif ($json -isnot [array]) {
            $json = @($json)
        }
        foreach ($app in $json){
            # Defensive: Only add if Nickname and Path are not null or empty
            if ($null -ne $app -and ($app.PSObject.Properties["Nickname"] -and $app.PSObject.Properties["Path"]) -and
                -not [string]::IsNullOrWhiteSpace($app.Nickname) -and -not [string]::IsNullOrWhiteSpace($app.Path)) {
                Add-Row $app.Nickname $app.Group $app.Delay $app.Path
            }
        }
        $grid.ResumeLayout()
        Update-Groups
    } catch {
        Write-ErrorLog "Failed to import config: $_"
        [System.Windows.Forms.MessageBox]::Show('Failed to import appconfig.json. Please check the file for errors.','Config Import Error',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# Function to export configuration to JSON file
$global:ExportConfigPending = $false
function Export-Config {
    if ($global:ExportConfigPending) { return }
    $global:ExportConfigPending = $true
    Start-Job -ScriptBlock {
        Start-Sleep -Milliseconds 300
        [System.Windows.Forms.Application]::OpenForms[0].Invoke({
            try {
                $apps = foreach ($row in $grid.Rows){
                    if ($row.IsNewRow){ continue }
                    [pscustomobject]@{
                        Nickname = $row.Cells[3].Value
                        Group    = $row.Cells[4].Value
                        Delay    = [int]($row.Cells[5].Value)
                        Path     = $row.Cells[7].Value
                    }
                }
                $apps | ConvertTo-Json -Depth 2 | Set-Content -Encoding UTF8 $ConfigPath
            } catch {
                Write-ErrorLog "Failed to export config: $_"
            }
            $global:ExportConfigPending = $false
        })
    } | Out-Null
}

# Helper to refresh group dropdown based on current grid
function Update-Groups {
    $current = $cboGroup.SelectedItem
    $cboGroup.Items.Clear()
    $cboGroup.Items.Add('<All Groups>') | Out-Null
    $groups = $grid.Rows | Where-Object { -not $_.IsNewRow -and $_.Cells[2].Value -and $_.Cells[2].Value -ne '' } | ForEach-Object { $_.Cells[2].Value } | Sort-Object -Unique
    foreach ($g in $groups) { $null = $cboGroup.Items.Add($g) }
    $cboGroup.SelectedIndex = if ($current -and $cboGroup.Items.Contains($current)) { $cboGroup.Items.IndexOf($current) } else { 0 }
}
#endregion

#region ► ROW HELPERS ◄
# Get-AppIcon: Returns the icon for a given executable path, with caching for performance
function Get-AppIcon($path){
    if ($script:iconCache.ContainsKey($path)) { return $script:iconCache[$path] }
    try {
        $icon = [Drawing.Icon]::ExtractAssociatedIcon($path)
    } catch {
        $icon = [Drawing.SystemIcons]::Application
    }
    $script:iconCache[$path] = $icon
    return $icon
}

# Add-Row: Adds a new application row to the App Launcher grid
#   $nick  - Nickname for the app (string)
#   $group - Group name (string)
#   $delay - Launch delay in seconds (int)
#   $path  - Full path to the executable (string)
function Add-Row([string]$nick,[string]$group,[int]$delay,[string]$path){
    # Defensive: Only add row if Nickname and Path are present and non-empty
    if ([string]::IsNullOrWhiteSpace($nick) -or [string]::IsNullOrWhiteSpace($path)) { return }
    if (-not $delay -or $delay -lt 0) { $delay = 0 }
    $row = $grid.Rows.Add()
    $grid.Rows[$row].Cells[0].Value = ''         # Status
    $grid.Rows[$row].Cells[1].Value = $false     # Sel
    # Do NOT set .Cells[2] (Action button column)
    $grid.Rows[$row].Cells[3].Value = $nick      # Nickname
    $grid.Rows[$row].Cells[4].Value = $group     # Group
    $grid.Rows[$row].Cells[5].Value = $delay     # Delay
    $grid.Rows[$row].Cells[6].Value = Get-AppIcon $path # Icon
    $grid.Rows[$row].Cells[7].Value = $path      # Path
}
#endregion

#region ► TESTING / ADMIN TOOLS ◄
# Optional: Add a Refresh Config button for quick testing
$btnRefreshConfig = [Windows.Forms.Button]@{Text='Refresh Config'; Size=[Drawing.Size]::new(110,30)}
$btnRefreshConfig.Add_Click({ Import-Config })
$buttonPanel.Controls.Add($btnRefreshConfig)
#endregion

#region ► ERROR LOGGING ◄
# Add error logging function
function Write-ErrorLog {
    param ([string]$Message)
    $LogFile = Join-Path $PSScriptRoot 'error.log'
    $Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    "$Timestamp - $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}
#endregion

# =========================
# 5. Load Configuration & Start
# =========================
# Load configuration and populate the grid
Import-Config

# Remove old group population logic (now handled by Refresh-Groups)

# Fix for timer not updating the form title
#$timer = [System.Windows.Forms.Timer]::new()
#$timer.Interval = 1000  # 1 second
#$global:remainingTime = [TimeSpan]::FromHours(8)  # Use global to persist value between ticks
#$lblTimer.Text = "Time Left: $($global:remainingTime.ToString('hh\:mm\:ss'))"
#$timer.Add_Tick({
#    $global:remainingTime = $global:remainingTime.Add([TimeSpan]::FromSeconds(-1))
#    if ($global:remainingTime.TotalSeconds -le 0) {
#        $timer.Stop()
#        $lblTimer.Text = "Time Left: 00:00:00"
#        [Windows.Forms.MessageBox]::Show('The script has reached its 8-hour limit and will now close.', 'Timeout', [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
#        $form.Close()
#    } else {
#        $lblTimer.Text = "Time Left: $($global:remainingTime.ToString('hh\:mm\:ss'))"
#    }
#})
#
#$timer.Start()

# --- Force close after 8 hours ---
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 28800
    [System.Diagnostics.Process]::GetCurrentProcess().Kill()
} | Out-Null

# --- SITE CHECK TAB: MultiSiteChecker Integration ---
$tabSiteCheck.Controls.Clear()

# Site grid
$siteGrid = [System.Windows.Forms.DataGridView]::new()
$siteGrid.Dock = 'Fill'
$siteGrid.AllowUserToAddRows = $false
$siteGrid.RowHeadersVisible = $false
$siteGrid.SelectionMode = 'FullRowSelect'
$siteGrid.AutoSizeColumnsMode = 'Fill'
[void]$siteGrid.Columns.Add('Site','Site')
[void]$siteGrid.Columns.Add('Name','Name')
[void]$siteGrid.Columns.Add('Status','Status')
[void]$siteGrid.Columns.Add('ResponseTime','Response Time (ms)')
[void]$siteGrid.Columns.Add('LastChecked','Last Checked')
$tabSiteCheck.Controls.Add($siteGrid)

# Input panel (bottom)
$sitePanel = [Windows.Forms.Panel]::new()
$sitePanel.Dock = 'Bottom'
$sitePanel.Height = 110
$sitePanel.Padding = '10,10,10,10'
$tabSiteCheck.Controls.Add($sitePanel)

$btnAddSite = [Windows.Forms.Button]@{Text='Add Site';Location=[Drawing.Point]::new(0,0);Size=[Drawing.Size]::new(100,26)}
$btnRemoveSite = [Windows.Forms.Button]@{Text='Remove Selected';Location=[Drawing.Point]::new(110,0);Size=[Drawing.Size]::new(130,26)}
$btnExportSite = [Windows.Forms.Button]@{Text='Export Status';Location=[Drawing.Point]::new(250,0);Size=[Drawing.Size]::new(120,26)}
$btnRefreshSite = [Windows.Forms.Button]@{Text='Refresh';Location=[Drawing.Point]::new(380,0);Size=[Drawing.Size]::new(90,26)}
$lblIntervalS = [System.Windows.Forms.Label]@{Text='Interval (s):';AutoSize=$true;Location=[Drawing.Point]::new(480,5)}
$numIntervalS = New-Object System.Windows.Forms.NumericUpDown
$numIntervalS.Location=[Drawing.Point]::new(560,2)
$numIntervalS.Minimum = 30
$numIntervalS.Maximum = 3600
$numIntervalS.Value = 300
$numIntervalS.Width = 70
$numIntervalS.Increment = 30
$sitePanel.Controls.AddRange(@($btnAddSite,$btnRemoveSite,$btnExportSite,$btnRefreshSite,$lblIntervalS,$numIntervalS))

# Filter dropdown
$filterDropdown = New-Object System.Windows.Forms.ComboBox
$filterDropdown.Location = New-Object System.Drawing.Point(650, 2)
$filterDropdown.Size = New-Object System.Drawing.Size(100, 26)
$filterDropdown.Items.AddRange(@('All','Up','Down'))
$filterDropdown.SelectedIndex = 0
$sitePanel.Controls.Add($filterDropdown)

# Next refresh label
$nextRefreshLabel = New-Object System.Windows.Forms.Label
$nextRefreshLabel.Text = 'Next Refresh: Calculating...'
$nextRefreshLabel.Location = New-Object System.Drawing.Point(0,40)
$nextRefreshLabel.Size = New-Object System.Drawing.Size(300, 22)
$sitePanel.Controls.Add($nextRefreshLabel)

# Details label
$detailsLabel = New-Object System.Windows.Forms.Label
$detailsLabel.Text = 'Site Details: Select a site to view details.'
$detailsLabel.Location = New-Object System.Drawing.Point(310,40)
$detailsLabel.Size = New-Object System.Drawing.Size(400, 60)
$sitePanel.Controls.Add($detailsLabel)

# Site data and helpers
$siteJsonPath = Join-Path $PSScriptRoot 'sites.json'
if (-not (Test-Path $siteJsonPath)) { '[]' | Set-Content $siteJsonPath -Encoding UTF8 }
$siteList = Get-Content $siteJsonPath -Raw | ConvertFrom-Json
if (-not $siteList) { $siteList = @() }

function Save-SiteList {
    $siteList | ConvertTo-Json -Depth 3 | Set-Content $siteJsonPath -Encoding UTF8
}

function Update-SiteStatus {
    foreach ($site in $siteList) {
        $siteName = $site.Site
        $friendlyName = $site.Name
        try {
            $ping = Test-Connection -ComputerName $siteName -Count 1 -Quiet -ErrorAction Stop
            $status = if ($ping) { 'Up' } else { 'Down' }
            $responseTime = (Test-Connection -ComputerName $siteName -Count 1 -ErrorAction Stop).ResponseTime
        } catch {
            $status = 'Down'
            $responseTime = 'N/A'
        }
        $lastChecked = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        # Find or add row
        $row = $siteGrid.Rows | Where-Object { $_.Cells[0].Value -eq $siteName } | Select-Object -First 1
        if (-not $row) {
            $rowIndex = $siteGrid.Rows.Add($siteName, $friendlyName, $status, $responseTime, $lastChecked)
            $row = $siteGrid.Rows[$rowIndex]
        } else {
            $row.Cells[1].Value = $friendlyName
            $row.Cells[2].Value = $status
            $row.Cells[3].Value = $responseTime
            $row.Cells[4].Value = $lastChecked
        }
        # Color row
        if ($status -eq 'Up') {
            $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::LightGreen
        } else {
            $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::LightCoral
        }
    }
}

# Seed grid
foreach ($site in $siteList) {
    $row = $siteGrid.Rows.Add($site.Site, $site.Name, 'Unknown', 'N/A', 'Not Checked')
}

# Add site
$btnAddSite.Add_Click({
    $newSite = [Microsoft.VisualBasic.Interaction]::InputBox('Enter new site address (e.g. google.com)', 'Add Site')
    if ($newSite -and $newSite.Trim() -ne '') {
        $newName = [Microsoft.VisualBasic.Interaction]::InputBox('Enter a friendly name (optional)', 'Add Site', $newSite)
        $rowIndex = $siteGrid.Rows.Add($newSite, $newName, 'Unknown', 'N/A', 'Not Checked')
        $siteList += [PSCustomObject]@{ Site = $newSite; Name = $newName }
        Save-SiteList
    }
})

# Remove site
$btnRemoveSite.Add_Click({
    foreach ($row in @($siteGrid.SelectedRows)) {
        $siteToRemove = $row.Cells[0].Value
        $siteGrid.Rows.Remove($row)
        $siteList = $siteList | Where-Object { $_.Site -ne $siteToRemove }
    }
    Save-SiteList
})

# Export status
$btnExportSite.Add_Click({
    $dlg = [Windows.Forms.SaveFileDialog]::new()
    $dlg.Filter = 'CSV files (*.csv)|*.csv'
    $dlg.FileName = 'SiteStatusExport.csv'
    if($dlg.ShowDialog() -ne 'OK'){ return }
    'Site,Name,Status,ResponseTime,LastChecked' | Out-File -FilePath $dlg.FileName
    foreach ($row in $siteGrid.Rows) {
        $line = "{0},{1},{2},{3},{4}" -f `
            $row.Cells[0].Value, $row.Cells[1].Value, $row.Cells[2].Value, $row.Cells[3].Value, $row.Cells[4].Value
        $line | Out-File -Append -FilePath $dlg.FileName
    }
})

# Refresh
$btnRefreshSite.Add_Click({ Update-SiteStatus })

# Timer and interval
$siteTimer = New-Object System.Windows.Forms.Timer
$siteTimer.Interval = ($numIntervalS.Value) * 1000
$siteTimer.Add_Tick({
    Update-SiteStatus
    $nextRefreshLabel.Text = "Next Refresh: " + (Get-Date).AddMilliseconds($siteTimer.Interval).ToString('HH:mm:ss')
    Export-SiteList
})
$siteTimer.Start()
$numIntervalS.Add_ValueChanged({ $siteTimer.Interval = ($numIntervalS.Value) * 1000 })

# Filter dropdown event
$filterDropdown.Add_SelectedIndexChanged({
    $filter = $filterDropdown.Text
    foreach ($row in $siteGrid.Rows) {
        $rowStatus = $row.Cells[2].Value
        $row.Visible = ($filter -eq 'All' -or $rowStatus -eq $filter)
    }
})

# Details label update on selection
$siteGrid.Add_SelectionChanged({
    if ($siteGrid.SelectedRows.Count -gt 0) {
        $selectedRow = $siteGrid.SelectedRows[0]
        $siteName = $selectedRow.Cells[0].Value
        $friendlyName = $selectedRow.Cells[1].Value
        $status = $selectedRow.Cells[2].Value
        $responseTime = $selectedRow.Cells[3].Value
        $lastChecked = $selectedRow.Cells[4].Value
        $detailsLabel.Text = "Site Details:`nSite: $siteName`nFriendly Name: $friendlyName`nStatus: $status`nResponse Time: $responseTime ms`nLast Checked: $lastChecked"
    } else {
        $detailsLabel.Text = 'Site Details: Select a site to view details.'
    }
})

# Cleanup on close
$form.Add_FormClosing({ $siteTimer.Stop(); Save-SiteList })

# --- COMP CHECK TAB: Computer Checker Grid ---
$tabCompCheck.Controls.Clear()

# Create the computer checker grid
$compGrid = [System.Windows.Forms.DataGridView]::new()
$compGrid.Dock = 'Fill'
$compGrid.AllowUserToAddRows = $false
$compGrid.RowHeadersVisible = $false
$compGrid.SelectionMode = 'FullRowSelect'
$compGrid.AutoSizeColumnsMode = 'Fill'
[void]$compGrid.Columns.Add('Name','Name')
[void]$compGrid.Columns.Add('Address','Address')
[void]$compGrid.Columns.Add('Group','Group')
[void]$compGrid.Columns.Add('Status','Status')
[void]$compGrid.Columns.Add('ConsecutiveFailures','Consecutive Failures')
$tabCompCheck.Controls.Add($compGrid)

# Listen for cell value changes in compGrid to keep $compDevices and devices.json in sync
$compGrid.Add_CellValueChanged({
    param($s, $e)
    if ($e.RowIndex -lt 0) { return }
    $row = $compGrid.Rows[$e.RowIndex]
    $name = $row.Cells[0].Value
    $addr = $row.Cells[1].Value
    $grp  = $row.Cells[2].Value
    # Find the device in $compDevices by Name
    $device = $compDevices | Where-Object { $_.Name -eq $name }
    if ($device) {
        $device.Address = $addr
        $device.Group = $grp
        # Optionally update Status if user edits it (not recommended)
    } else {
        # If not found, add it (should not happen, but for safety)
        $compDevices += [PSCustomObject]@{Name=$name;Address=$addr;Group=$grp;Status='Unknown';ConsecutiveFailures=0}
    }
    Save-CompDevices
})

# Load and save device list
$compJsonPath = Join-Path $PSScriptRoot 'devices.json'
if (-not (Test-Path $compJsonPath)) { '[]' | Set-Content $compJsonPath -Encoding UTF8 }
$compDevices = Get-Content $compJsonPath -Raw | ConvertFrom-Json
if (-not $compDevices) { $compDevices = @() }

function Save-CompDevices {
    $compDevices | ConvertTo-Json -Depth 3 | Set-Content $compJsonPath -Encoding UTF8
}

# Seed grid
foreach ($dev in $compDevices) {
    $row = $compGrid.Rows.Add($dev.Name, $dev.Address, $dev.Group, $dev.Status, $dev.ConsecutiveFailures)
}

# Add/Remove/Check buttons
$compPanel = [Windows.Forms.Panel]::new()
$compPanel.Dock = 'Bottom'
$compPanel.Height = 50
$tabCompCheck.Controls.Add($compPanel)

$btnAddComp = [Windows.Forms.Button]@{Text='Add Device';Location=[Drawing.Point]::new(0,0);Size=[Drawing.Size]::new(100,26)}
$btnRemoveComp = [Windows.Forms.Button]@{Text='Remove Selected';Location=[Drawing.Point]::new(110,0);Size=[Drawing.Size]::new(130,26)}
$btnTestComp = [Windows.Forms.Button]@{Text='Test Status';Location=[Drawing.Point]::new(250,0);Size=[Drawing.Size]::new(120,26)}
$compPanel.Controls.AddRange(@($btnAddComp,$btnRemoveComp,$btnTestComp))

# Add device
$btnAddComp.Add_Click({
    $name = [Microsoft.VisualBasic.Interaction]::InputBox('Enter device name:', 'Add Device')
    if ([string]::IsNullOrWhiteSpace($name)) { return }
    $addr = [Microsoft.VisualBasic.Interaction]::InputBox('Enter device address (hostname or IP):', 'Add Device')
    if ([string]::IsNullOrWhiteSpace($addr)) { return }
    $group = [Microsoft.VisualBasic.Interaction]::InputBox('Enter group (optional):', 'Add Device')
    $rowIndex = $compGrid.Rows.Add($name, $addr, $group, 'Unknown', 0)
    $global:compDevices += [PSCustomObject]@{Name=$name;Address=$addr;Group=$group;Status='Unknown';ConsecutiveFailures=0}
    Save-CompDevices
})

# Remove device
$btnRemoveComp.Add_Click({
    foreach ($row in @($compGrid.SelectedRows)) {
        $nameToRemove = $row.Cells[0].Value
        $compGrid.Rows.Remove($row)
        $compDevices = $compDevices | Where-Object { $_.Name -ne $nameToRemove }
    }
    Save-CompDevices
})

# Test status
$btnTestComp.Add_Click({
    foreach ($row in $compGrid.Rows) {
        $addr = $row.Cells[1].Value
        try {
            $ping = Test-Connection -ComputerName $addr -Count 1 -Quiet -ErrorAction Stop
            $row.Cells[3].Value = if ($ping) { 'Online' } else { 'Offline' }
            if ($ping) {
                $row.Cells[4].Value = 0
            } else {
                $row.Cells[4].Value = [int]$row.Cells[4].Value + 1
            }
        } catch {
            $row.Cells[3].Value = 'Error'
            $row.Cells[4].Value = [int]$row.Cells[4].Value + 1
        }
        # Update $compDevices
        $dev = $compDevices | Where-Object { $_.Name -eq $row.Cells[0].Value }
        if ($dev) {
            $dev.Status = $row.Cells[3].Value
            $dev.ConsecutiveFailures = $row.Cells[4].Value
        }
    }
    Save-CompDevices
})

[System.Windows.Forms.Application]::Run($form)
#endregion