
<#
.SYNOPSIS
    Graphical tool that watches a list of devices and pops a notification when a device that was offline comes online.

.DESCRIPTION
    * Maintains a JSON file (devices.json) beside the script to persist the list.
    * Lets you add‑or‑remove devices by name or IP from the GUI.
    * Pings every 30 seconds, shows current status, and raises a balloon‑tip when the state changes from Offline → Online.
    * Written entirely with Windows Forms so it runs anywhere PowerShell 5+ is available (no external modules required).
    * Forward‑looking: all data is saved automatically so the next time you start the tool it picks up right where you left off.

.NOTES
    Author: ChatGPT  |  Date: 2025‑04‑25
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$JsonPath = Join-Path $PSScriptRoot 'devices.json'
if (-not (Test-Path $JsonPath)) { '[]' | Set-Content -Path $JsonPath -Encoding UTF8 }

# Load the persisted list --------------------------------------------------------------------
$devices = Get-Content -Path $JsonPath -Raw | ConvertFrom-Json
if (-not $devices) { $devices = @() }

# ---------------------------------------------------------------------------------------------------------------------
#   GUI CONSTRUCTION
# ---------------------------------------------------------------------------------------------------------------------
$form                   = New-Object System.Windows.Forms.Form
$form.Text              = 'Device Status Monitor'
$form.Size              = New-Object System.Drawing.Size(620, 420)
$form.StartPosition     = 'CenterScreen'
$form.Topmost           = $true

# Data grid -----------------------------------------------------------------------------------
$dgv                    = New-Object System.Windows.Forms.DataGridView
$dgv.Location           = New-Object System.Drawing.Point(10,10)
$dgv.Size               = New-Object System.Drawing.Size(580,260)
$dgv.AllowUserToAddRows = $false
$dgv.RowHeadersVisible  = $false
$dgv.SelectionMode      = 'FullRowSelect'

[void]$dgv.Columns.Add('Name',   'Name')
[void]$dgv.Columns.Add('Address','IP / Hostname')
$statusCol              = $dgv.Columns.Add('Status','Status')
$dgv.Columns[$statusCol].ReadOnly = $true

$form.Controls.Add($dgv)

# Input controls ------------------------------------------------------------------------------
$lblName                = New-Object System.Windows.Forms.Label
$lblName.Text           = 'Name:'
$lblName.Location       = New-Object System.Drawing.Point(10,285)
$form.Controls.Add($lblName)

$txtName                = New-Object System.Windows.Forms.TextBox
$txtName.Location       = New-Object System.Drawing.Point(60,282)
$txtName.Size           = New-Object System.Drawing.Size(140,22)
$form.Controls.Add($txtName)

$lblIP                  = New-Object System.Windows.Forms.Label
$lblIP.Text             = 'IP / Hostname:'
$lblIP.Location         = New-Object System.Drawing.Point(220,285)
$form.Controls.Add($lblIP)

$txtIP                  = New-Object System.Windows.Forms.TextBox
$txtIP.Location         = New-Object System.Drawing.Point(320,282)
$txtIP.Size             = New-Object System.Drawing.Size(140,22)
$form.Controls.Add($txtIP)

$btnAdd                 = New-Object System.Windows.Forms.Button
$btnAdd.Text            = 'Add Device'
$btnAdd.Location        = New-Object System.Drawing.Point(480,280)
$form.Controls.Add($btnAdd)

$btnRemove              = New-Object System.Windows.Forms.Button
$btnRemove.Text         = 'Remove Selected'
$btnRemove.Location     = New-Object System.Drawing.Point(10,320)
$form.Controls.Add($btnRemove)

# System tray / balloon‑tip -------------------------------------------------------------------
$notify                 = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon            = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Command powershell).Source)
$notify.Visible         = $true

# ---------------------------------------------------------------------------------------------------------------------
function Save-Devices {
    param([Array]$list)
    $list | ConvertTo-Json -Depth 3 | Set-Content -Path $JsonPath -Encoding UTF8
}

# Seed the grid with the last‑known list -------------------------------------------------------
foreach ($dev in $devices) {
    $rowIdx              = $dgv.Rows.Add($dev.Name, $dev.Address, $dev.Status)
    $dgv.Rows[$rowIdx].Tag = $dev.Status  # Track previous status per row
}

# ADD ---------------------------------------------------------------------------------------------------------------
$btnAdd.Add_Click({
    $name = $txtName.Text.Trim()
    $addr = $txtIP.Text.Trim()
    if ($name -and $addr) {
        $rowIdx              = $dgv.Rows.Add($name,$addr,'Unknown')
        $dgv.Rows[$rowIdx].Tag = 'Unknown'
        $devices += [PSCustomObject]@{Name=$name;Address=$addr;Status='Unknown'}
        Save-Devices $devices
        $txtName.Clear(); $txtIP.Clear()
    }
})

# REMOVE ------------------------------------------------------------------------------------------------------------
$btnRemove.Add_Click({
    foreach ($row in @($dgv.SelectedRows)) {
        $name = $row.Cells[0].Value
        $dgv.Rows.Remove($row)
        $devices = $devices | Where-Object { $_.Name -ne $name }
    }
    Save-Devices $devices
})

# ------------------------------------------------------------------------------------------------------------------
#   MONITOR LOOP (30‑second ping cycle)
# ------------------------------------------------------------------------------------------------------------------
$timer           = New-Object System.Windows.Forms.Timer
$timer.Interval  = 30000  # milliseconds

$timer.Add_Tick({
    for ($i=0; $i -lt $dgv.Rows.Count; $i++) {
        $row      = $dgv.Rows[$i]
        $name     = $row.Cells[0].Value
        $addr     = $row.Cells[1].Value
        $online   = $false
        try {
            $online = Test-Connection -ComputerName $addr -Count 1 -Quiet -TimeoutSeconds 2
        } catch {}

        $status   = $online ? 'Online' : 'Offline'
        $prev     = $row.Tag

        # Colour code & text update ---------------------------------------------------------------------
        $row.Cells[2].Value            = $status
        $row.Cells[2].Style.ForeColor  = if ($online) { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Red }
        $row.Tag                       = $status

        # Persist current status in the backing array ---------------------------------------------------
        for ($d=0; $d -lt $devices.Count; $d++) {
            if ($devices[$d].Name -eq $name) { $devices[$d].Status = $status; break }
        }

        # Notify on OFFLINE → ONLINE transition ---------------------------------------------------------
        if ($prev -eq 'Offline' -and $status -eq 'Online') {
            $notify.BalloonTipTitle = 'Device Online'
            $notify.BalloonTipText  = "$name ($addr) is now online."
            $notify.ShowBalloonTip(5000)
        }
    }
    Save-Devices $devices
})

$timer.Start()

$form.Add_FormClosing({
    $notify.Dispose()
    $timer.Stop()
    Save-Devices $devices
})

[void]$form.ShowDialog()
