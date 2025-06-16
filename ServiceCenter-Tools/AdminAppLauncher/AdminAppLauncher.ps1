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
$txtSearch.PlaceholderText = 'Search / filter…'
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

$tabLauncher.Controls.Add($searchPanel)

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
$tabLauncher.Controls.Add($grid)

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
$buttonPanel.Dock = 'Bottom'
$buttonPanel.Padding = [System.Windows.Forms.Padding]::new(8, 4, 8, 4)
$buttonPanel.AutoSize = $true
$buttonPanel.WrapContents = $false
$buttonPanel.Controls.AddRange(@($btnAdd,$btnRemove,$btnImport,$btnExport,$btnStartSel))
$tabLauncher.Controls.Add($buttonPanel)

# --- COMP CHECK TAB: Device Status Checker UI ---
# Remove placeholder label
$tabCompCheck.Controls.Clear()

# Device grid
if ($null -eq $compGrid) {
    $compGrid = [System.Windows.Forms.DataGridView]::new()
    $compGrid.Dock = 'Fill'
    $compGrid.AllowUserToAddRows = $false
    $compGrid.RowHeadersVisible = $false
    $compGrid.SelectionMode = 'FullRowSelect'
    $compGrid.AutoSizeColumnsMode = 'Fill'
    $compGrid.Columns.Clear()
    [void]$compGrid.Columns.Add('Name','Name')
    [void]$compGrid.Columns.Add('Address','IP / Hostname')
    [void]$compGrid.Columns.Add('Group','Group')
    $statusCol = $compGrid.Columns.Add('Status','Status')
    $compGrid.Columns[$statusCol].ReadOnly = $true
    $tabCompCheck.Controls.Add($compGrid)
}

# Input panel (bottom)
$compPanel = [System.Windows.Forms.Panel]::new()
$compPanel.Dock = 'Bottom'
$compPanel.Height = 110
$compPanel.Padding = '10,10,10,10'
$tabCompCheck.Controls.Add($compPanel)

$lblNameC  = [System.Windows.Forms.Label]@{Text='Name:';AutoSize=$true;Location=[Drawing.Point]::new(0,5)}
$txtNameC  = [System.Windows.Forms.TextBox]@{Location=[Drawing.Point]::new(50,2);Size=[Drawing.Size]::new(150,22)}
$lblIPC    = [System.Windows.Forms.Label]@{Text='IP/Host (opt):';AutoSize=$true;Location=[Drawing.Point]::new(220,5)}
$txtIPC    = [System.Windows.Forms.TextBox]@{Location=[Drawing.Point]::new(310,2);Size=[Drawing.Size]::new(150,22)}
$lblGroupC = [System.Windows.Forms.Label]@{Text='Group:';AutoSize=$true;Location=[Drawing.Point]::new(480,5)}
$txtGroupC = [System.Windows.Forms.TextBox]@{Location=[Drawing.Point]::new(530,2);Size=[Drawing.Size]::new(120,22)}
$btnAddC   = [System.Windows.Forms.Button]@{Text='Add';Location=[Drawing.Point]::new(660,0);Size=[Drawing.Size]::new(80,26)}
$btnRemoveC   = [System.Windows.Forms.Button]@{Text='Remove Selected';Location=[Drawing.Point]::new(0,45);Size=[Drawing.Size]::new(130,26)}
$lblIntervalC = [System.Windows.Forms.Label]@{Text='Interval (s):';AutoSize=$true;Location=[Drawing.Point]::new(220,50)}
$numIntervalC = New-Object System.Windows.Forms.NumericUpDown
$numIntervalC.Location=[Drawing.Point]::new(300,45)
$numIntervalC.Minimum = 5
$numIntervalC.Maximum = 900
$numIntervalC.Value = 30
$numIntervalC.Width = 70
$numIntervalC.Increment = 5
$compPanel.Controls.AddRange(@($lblNameC,$txtNameC,$lblIPC,$txtIPC,$lblGroupC,$txtGroupC,$btnAddC,$btnRemoveC,$lblIntervalC,$numIntervalC))

# Device data and helpers
$compJsonPath = Join-Path $PSScriptRoot 'devices.json'
$compPingCount = 3
if (-not (Test-Path $compJsonPath)) { '[]' | Set-Content $compJsonPath -Encoding UTF8 }
$compDevices = Get-Content $compJsonPath -Raw | ConvertFrom-Json | ForEach-Object {
    $_ | Add-Member -NotePropertyName ConsecutiveFailures -NotePropertyValue 0 -Force
    $_
}
if (-not $compDevices) { $compDevices = @() }

function Save-CompDevices {
    $compDevices | Select-Object Name,Address,Group,Status,ConsecutiveFailures |
        ConvertTo-Json -Depth 3 | Set-Content $compJsonPath -Encoding UTF8
}

function Show-CompToast($title,$text) {
    try {
        if (-not (Get-Module -ListAvailable -Name BurntToast)) { throw 'BurntToast missing' }
        Import-Module BurntToast -ErrorAction Stop | Out-Null
        New-BurntToastNotification -Text $title,$text | Out-Null
    } catch {
        # fallback: no-op
    }
    [System.Media.SystemSounds]::Exclamation.Play()
}

function Invoke-CompPingBatch([System.Collections.IList]$deviceRows) {
    $pool=[runspacefactory]::CreateRunspacePool(1,10); $pool.Open(); $jobs=@()
    foreach ($row in $deviceRows) {
        $addr=$row.Cells[1].Value; $ps=[powershell]::Create(); $ps.RunspacePool=$pool
        $null=$ps.AddScript("Test-Connection -ComputerName '$addr' -Count 1 -Quiet -TimeoutSeconds 2")
        $jobs += [pscustomobject]@{Row=$row;PS=$ps;Handle=$ps.BeginInvoke()}
    }
    foreach ($j in $jobs) {
        $online=[bool]($j.PS.EndInvoke($j.Handle)); $j.PS.Dispose(); $row=$j.Row
        $name=$row.Cells[0].Value; $device=$compDevices | Where-Object Name -eq $name; if (-not $device){continue}
        if ($online){$device.ConsecutiveFailures=0;$status='Online'}else{$device.ConsecutiveFailures++;$status=($device.ConsecutiveFailures -ge $compPingCount)?'Offline':'Online'}
        $prev=$row.Tag; $row.Cells[3].Value=$status
        $row.Cells[3].Style.ForeColor= if($status -eq 'Online'){[Drawing.Color]::ForestGreen}elseif($status -eq 'Offline'){[Drawing.Color]::Red}else{[Drawing.Color]::Orange}
        $row.Tag=$status; $device.Status=$status
        if ($prev -eq 'Offline' -and $status -eq 'Online') { Show-CompToast 'Device Online' "$name ($addr) is now online." }
    }
    $pool.Close();$pool.Dispose()
}

# Seed grid
foreach ($d in $compDevices) {
    $row=$compGrid.Rows.Add($d.Name,$d.Address,$d.Group,$d.Status); $compGrid.Rows[$row].Tag=$d.Status }

# Add device
$btnAddC.Add_Click({
    $name=$txtNameC.Text.Trim(); if (-not $name) { return }
    $addr=$txtIPC.Text.Trim(); if (-not $addr) { $addr=$name }
    $grp=$txtGroupC.Text.Trim()
    $rowIdx = $compGrid.Rows.Add($name,$addr,$grp,'Unknown')
    $compGrid.Rows[$rowIdx].Tag='Unknown'
    # Defensive: Ensure $compDevices is always an array
    if ($compDevices -is [PSCustomObject] -and -not ($compDevices -is [System.Collections.IEnumerable])) { $compDevices = @($compDevices) }
    if ($null -eq $compDevices) { $compDevices = @() }
    $compDevices += [PSCustomObject]@{Name=$name;Address=$addr;Group=$grp;Status='Unknown';ConsecutiveFailures=0}
    Save-CompDevices
    $txtNameC.Clear();$txtIPC.Clear();$txtGroupC.Clear()
})

# Remove device
$btnRemoveC.Add_Click({
    $toRemove = @()
    $rowsToRemove = @($compGrid.SelectedRows)
    foreach ($row in $rowsToRemove) {
        $name = $row.Cells[0].Value
        $toRemove += $name
    }
    foreach ($row in $rowsToRemove) {
        $compGrid.Rows.Remove($row)
    }
    # Remove from $compDevices in-place
    for ($i = $compDevices.Count - 1; $i -ge 0; i--) {
        if ($toRemove -contains $compDevices[$i].Name) {
            $compDevices.RemoveAt($i)
        }
    }
    Save-CompDevices
})

# Timer and interval
$compTimer=New-Object System.Windows.Forms.Timer; $compTimer.Interval=($numIntervalC.Value)*1000
$compTimer.Add_Tick({ Invoke-CompPingBatch $compGrid.Rows; Save-CompDevices }); $compTimer.Start()
$numIntervalC.Add_ValueChanged({ $compTimer.Interval=($numIntervalC.Value)*1000 })

# Cleanup on close
$form.Add_FormClosing({ $compTimer.Stop(); Save-CompDevices })
#endregion

#region ► CONFIG LOAD / SAVE ◄
# Function to import configuration from JSON file
function Import-Config {
    if (!(Test-Path $ConfigPath)){ return }
    try {
        $json = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        $grid.SuspendLayout()
        $grid.Rows.Clear()
        # Ensure $json is always treated as an array (fix for single object and null)
        if ($null -eq $json) {
            $json = @()
        } elseif ($json -is [PSCustomObject] -and -not ($json -is [System.Collections.IEnumerable])) {
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
        Refresh-Groups
    } catch {
        Log-Error "Failed to import config: $_"
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
                Log-Error "Failed to export config: $_"
            }
            $global:ExportConfigPending = $false
        })
    } | Out-Null
}

# Helper to refresh group dropdown based on current grid
function Refresh-Groups {
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
    if ([string]::IsNullOrWhiteSpace($nick)) { $nick = '[Unnamed]' }
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

#region ► APP LAUNCH ◄
# Function to start an application from the specified row
function Start-App ($row){
    $path  = $row.Cells[7].Value  # Path is column 7
    if (-not [System.IO.File]::Exists($path)){
        $row.Cells[0].Value = '✗ Missing'  # Status column
        Log-Error "File not found: $path"
        return
    }
    $row.Cells[0].Value = 'Launching…'  # Status column
    try{
        if (Test-IsAdmin){
            $p = Start-Process -FilePath $path -PassThru -WindowStyle Normal
        }else{
            $p = Start-Process -FilePath $path -Verb RunAs -PassThru -WindowStyle Normal
        }
        Start-Sleep -Milliseconds 500
        if ($p.HasExited) {
            $row.Cells[0].Value = '✗ Failed (Exited)'
        } else {
            $row.Cells[0].Value = '✓ Launched'
        }
    }catch{
        $row.Cells[0].Value = '✗ Failed'
        Log-Error ('Failed to launch ' + $path + ': ' + $_.ToString())
    }
}
#endregion

#region ► CONTEXT MENU (edit/remove) ◄
# Define the context menu for row actions
$ctx = [Windows.Forms.ContextMenuStrip]::new()
$itemEdit   = $ctx.Items.Add('Edit…')
$itemRemove = $ctx.Items.Add('Remove')
$grid.ContextMenuStrip = $ctx

# Handle right-clicks on the grid to show the context menu
$grid.Add_MouseDown({ param($s,$e) if($e.Button -eq 'Right'){
        $rowIndex = $grid.HitTest($e.X,$e.Y).RowIndex
        $grid.ClearSelection()
        if($rowIndex -ge 0){
            $grid.Rows[$rowIndex].Selected = $true
            $grid.CurrentCell = $grid.Rows[$rowIndex].Cells[1]
        }
    }})

# Edit menu item action (standardized: prompt for new values, update row, refresh groups, save config)
$itemEdit.Add_Click({
    if(!$grid.CurrentRow){ return }
    $row = $grid.CurrentRow
    $oldNick = $row.Cells[1].Value
    $oldGroup = $row.Cells[2].Value
    $oldDelay = $row.Cells[3].Value
    $newNick = [Microsoft.VisualBasic.Interaction]::InputBox('Edit Nickname:', 'Edit', $oldNick)
    if([string]::IsNullOrWhiteSpace($newNick)){ return }
    $newGroup = [Microsoft.VisualBasic.Interaction]::InputBox('Edit Group (optional):', 'Edit', $oldGroup)
    $delayInput = [Microsoft.VisualBasic.Interaction]::InputBox('Edit Delay in seconds (0 for none):', 'Edit', $oldDelay)
    $newDelay = 0
    if ($delayInput -match '^[0-9]+$') { $newDelay = [int]$delayInput }
    $row.Cells[1].Value = $newNick
    $row.Cells[2].Value = $newGroup
    $row.Cells[3].Value = $newDelay
    Refresh-Groups
    Export-Config
})

# Remove menu item action (standardized: remove, refresh groups, save config)
$itemRemove.Add_Click({
    if($grid.CurrentRow){ $grid.Rows.Remove($grid.CurrentRow); Refresh-Groups; Export-Config }
})
#endregion

#region ► DRAG‑AND‑DROP support ◄
# Handle file drag-and-drop into the grid
$grid.Add_DragEnter({ param($s,$e)
    if($e.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)){
        $e.Effect = 'Copy'
    }})

$grid.Add_DragDrop({ param($s,$e)
    $files = $e.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    foreach($file in $files){
        if($file -match '\\.(lnk|exe)$'){
            $target = if($file.ToLower().EndsWith('.lnk')){
                try {
                    $sh = New-Object -ComObject WScript.Shell
                    $sh.CreateShortcut($file).TargetPath
                } catch {
                    Log-Error "Failed to resolve shortcut: $file - $_"
                    $file
                }
            }else{ $file }
            $nick = [System.IO.Path]::GetFileNameWithoutExtension($target)
            Add-Row $nick '' 0 $target
        }
    }
    Export-Config
})
#endregion

#region ► BUTTON EVENTS ◄
# Add application button event (standardized style)
$btnAdd.Add_Click({
    try {
        $dlg = [Windows.Forms.OpenFileDialog]::new()
        $dlg.Filter = 'Executables (*.exe)|*.exe|Shortcuts (*.lnk)|*.lnk|All files (*.*)|*.*'
        if($dlg.ShowDialog() -ne 'OK'){ return }
        $target = if($dlg.FileName.ToLower().EndsWith('.lnk')){
            try {
                (New-Object -ComObject WScript.Shell).CreateShortcut($dlg.FileName).TargetPath
            } catch {
                Log-Error "Failed to resolve shortcut: $($dlg.FileName) - $_"
                $dlg.FileName
            }
        }else{ $dlg.FileName }

        $defaultNick = [IO.Path]::GetFileNameWithoutExtension($target)
        $nick = [Microsoft.VisualBasic.Interaction]::InputBox('Nickname:', 'Add application', $defaultNick)
        if([string]::IsNullOrWhiteSpace($nick)){ return }

        $group = [Microsoft.VisualBasic.Interaction]::InputBox('Group (optional):', 'Group', '')
        $delayInput = [Microsoft.VisualBasic.Interaction]::InputBox('Delay in seconds (0 for none):', 'Delay', '0')
        $delay = 0
        if ($delayInput -match '^[0-9]+$') { $delay = [int]$delayInput }
        Add-Row $nick $group $delay $target
        Refresh-Groups
        Export-Config
    } catch {
        $errorMessage = "An error occurred while adding the file: $_"
        Log-Error $errorMessage
        # No user dialog for non-critical error
    }
})

# Import button event (standardized style)
$btnImport.Add_Click({
    $dlg = [Windows.Forms.OpenFileDialog]::new()
    $dlg.Filter = 'JSON files (*.json)|*.json|All files (*.*)|*.*'
    if($dlg.ShowDialog() -ne 'OK'){ return }
    try{ Copy-Item $dlg.FileName $ConfigPath -Force; Import-Config; Export-Config }catch{ Log-Error $_ }
})

# Export button event (standardized style)
$btnExport.Add_Click({
    $dlg = [Windows.Forms.SaveFileDialog]::new()
    $dlg.Filter = 'JSON files (*.json)|*.json'
    $dlg.FileName = 'appconfig_export.json'
    if($dlg.ShowDialog() -ne 'OK'){ return }
    try{ Export-Config; Copy-Item $ConfigPath $dlg.FileName -Force }catch{ Log-Error $_ }
})

# Start selected button event (standardized style)
$btnStartSel.Add_Click({
    # Launch selected rows ordered by Delay ascending
    $rows = $grid.Rows | Where-Object { $_.Cells[0].Value -eq $true -and -not $_.IsNewRow }
    $ordered = $rows | Sort-Object { [int]$_.Cells[3].Value }
    foreach($row in $ordered){
        $delay = [int]$row.Cells[3].Value
        if($delay -gt 0){ $row.Cells[6].Value = "Waiting $delay s…"; $form.Refresh(); Start-Sleep -Seconds $delay }
        Start-App $row
    }
})
#endregion

#region ► GRID BUTTON (per‑row start) ◄
# Handle clicks on the grid's action button column
$grid.Add_CellContentClick({ param($s,$e)
    if($e.RowIndex -lt 0){ return }
    if($e.ColumnIndex -eq 2){ Start-App $grid.Rows[$e.RowIndex] }
})
#endregion

#region ► INIT & RUN ◄
# Add error logging function
function Log-Error {
    param ([string]$Message)
    $LogFile = Join-Path $PSScriptRoot 'error.log'
    $Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    "$Timestamp - $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

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
$sitePanel = [System.Windows.Forms.Panel]::new()
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
    Save-SiteList
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

[System.Windows.Forms.Application]::Run($form)
#endregion