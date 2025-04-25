
<#
.SYNOPSIS
    Device Status Monitor – enhanced edition.

.DESCRIPTION
    Adds the following upgrades:
        • Configurable polling interval (seconds)
        • Windows 10/11 Toast notifications (falls back to balloon‑tip) + sound cue
        • Multi‑ping confirmation (3 consecutive failures → Offline)
        • Parallel ping engine for scalability
        • Group / Location column so devices can be categorised

    The script persists the device list (with group) plus live status & failure counters in devices.json.
    Requires **PowerShell 5.1+**. Toasts use the BurntToast module if available, otherwise classic balloon tips.

.NOTES
    Author: ChatGPT | Rev: 2025‑04‑25
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Paths & constants -----------------------------------------------------------------------------
$JsonPath   = Join-Path $PSScriptRoot 'devices.json'
$PingCount  = 3                # multi‑ping threshold

# Ensure JSON file exists -----------------------------------------------------------------------
if (-not (Test-Path $JsonPath)) { '[]' | Set-Content $JsonPath -Encoding UTF8 }

# Load persisted list ---------------------------------------------------------------------------
$devices = Get-Content $JsonPath -Raw | ConvertFrom-Json | ForEach-Object {
    $_ | Add-Member -NotePropertyName ConsecutiveFailures -NotePropertyValue 0 -Force
    $_
}
if (-not $devices) { $devices = @() }

# ------------------------------------------------------------------------------------------------
#   GUI BUILD (Windows Forms)
# ------------------------------------------------------------------------------------------------
$form               = New-Object System.Windows.Forms.Form
$form.Text          = 'Device Status Monitor'
$form.Size          = [Drawing.Size]::new(720,470)
$form.StartPosition = 'CenterScreen'
$form.Topmost       = $true

# DataGrid --------------------------------------------------------------------------------------
$dgv                = New-Object System.Windows.Forms.DataGridView
$dgv.Location       = [Drawing.Point]::new(10,10)
$dgv.Size           = [Drawing.Size]::new(680,300)
$dgv.AllowUserToAddRows = $false
$dgv.RowHeadersVisible  = $false
$dgv.SelectionMode      = 'FullRowSelect'

[void]$dgv.Columns.Add('Name','Name')
[void]$dgv.Columns.Add('Address','IP / Hostname')
[void]$dgv.Columns.Add('Group','Group')
$statusCol          = $dgv.Columns.Add('Status','Status')
$dgv.Columns[$statusCol].ReadOnly = $true

$form.Controls.Add($dgv)

# Input controls --------------------------------------------------------------------------------
$lblName        = New-Object System.Windows.Forms.Label -Property @{Text='Name:';Location=[Drawing.Point]::new(10,325)}
$txtName        = New-Object System.Windows.Forms.TextBox -Property @{Location=[Drawing.Point]::new(60,322);Size=[Drawing.Size]::new(120,22)}
$lblIP          = New-Object System.Windows.Forms.Label -Property @{Text='IP/Host:';Location=[Drawing.Point]::new(200,325)}
$txtIP          = New-Object System.Windows.Forms.TextBox -Property @{Location=[Drawing.Point]::new(260,322);Size=[Drawing.Size]::new(120,22)}
$lblGroup       = New-Object System.Windows.Forms.Label -Property @{Text='Group:';Location=[Drawing.Point]::new(400,325)}
$txtGroup       = New-Object System.Windows.Forms.TextBox -Property @{Location=[Drawing.Point]::new(450,322);Size=[Drawing.Size]::new(120,22)}
$btnAdd         = New-Object System.Windows.Forms.Button -Property @{Text='Add';Location=[Drawing.Point]::new(590,320)}
$btnRemove      = New-Object System.Windows.Forms.Button -Property @{Text='Remove Selected';Location=[Drawing.Point]::new(10,355)}

# Polling interval selector ---------------------------------------------------------------------
$lblInterval    = New-Object System.Windows.Forms.Label -Property @{Text='Interval (s):';Location=[Drawing.Point]::new(200,355)}
$numInterval    = New-Object System.Windows.Forms.NumericUpDown -Property @{
                        Location=[Drawing.Point]::new(280,352);
                        Minimum=5;Maximum=900;Value=30;Increment=5;Width=60 }
$form.Controls.AddRange(@($lblName,$txtName,$lblIP,$txtIP,$lblGroup,$txtGroup,$btnAdd,$btnRemove,$lblInterval,$numInterval))

# Tray icon -------------------------------------------------------------------------------------
$notify             = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon        = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Command powershell).Source)
$notify.Visible     = $true

# Helpers ---------------------------------------------------------------------------------------
function Save-Devices {
    $devices | Select-Object Name,Address,Group,Status,ConsecutiveFailures |
        ConvertTo-Json -Depth 3 | Set-Content $JsonPath -Encoding UTF8
}

function Show-Toast {
    param($title,$text)
    try {
        if (-not (Get-Module -ListAvailable -Name BurntToast)) { throw 'BurntToast missing' }
        Import-Module BurntToast -ErrorAction Stop | Out-Null
        New-BurntToastNotification -Text $title,$text
    } catch {
        # fallback balloon tip
        $notify.BalloonTipTitle = $title
        $notify.BalloonTipText  = $text
        $notify.ShowBalloonTip(5000)
    }
    [System.Media.SystemSounds]::Exclamation.Play()
}

# Seed grid -------------------------------------------------------------------------------------
foreach ($d in $devices) {
    $row=$dgv.Rows.Add($d.Name,$d.Address,$d.Group,$d.Status)
    $dgv.Rows[$row].Tag=$d.Status
}

# Add device ------------------------------------------------------------------------------------
$btnAdd.Add_Click({
    $name=$txtName.Text.Trim(); $addr=$txtIP.Text.Trim(); $grp=$txtGroup.Text.Trim()
    if ($name -and $addr) {
        $row=$dgv.Rows.Add($name,$addr,$grp,'Unknown')
        $dgv.Rows[$row].Tag='Unknown'
        $devices += [PSCustomObject]@{Name=$name;Address=$addr;Group=$grp;Status='Unknown';ConsecutiveFailures=0}
        Save-Devices
        $txtName.Clear();$txtIP.Clear();$txtGroup.Clear()
    }
})

# Remove ----------------------------------------------------------------------------------------
$btnRemove.Add_Click({
    foreach ($row in @($dgv.SelectedRows)) {
        $name=$row.Cells[0].Value
        $dgv.Rows.Remove($row)
        $devices = $devices | Where-Object { $_.Name -ne $name }
    }
    Save-Devices
})

# Parallel ping engine --------------------------------------------------------------------------
function Invoke-PingBatch {
    param([System.Collections.IList]$deviceRows)
    $runspaces = [runspacefactory]::CreateRunspacePool(1,10); $runspaces.Open()
    $jobs = @()
    foreach ($row in $deviceRows) {
        $addr=$row.Cells[1].Value
        $ps = [powershell]::Create()
        $ps.RunspacePool=$runspaces
        [void]$ps.AddScript("Test-Connection -ComputerName '$addr' -Count 1 -Quiet -TimeoutSeconds 2")
        $jobs += [pscustomobject]@{Row=$row;PS=$ps;Handle=$ps.BeginInvoke()}
    }
    foreach ($j in $jobs) {
        $result=$j.PS.EndInvoke($j.Handle)
        $j.PS.Dispose()
        $online=[bool]$result
        # device object lookup --------------------------------------------------------------
        $name=$j.Row.Cells[0].Value
        $device=$devices | Where-Object Name -eq $name
        if (-not $device) { continue }
        if ($online) {
            $device.ConsecutiveFailures=0
            $status='Online'
        } else {
            $device.ConsecutiveFailures++
            $status= if ($device.ConsecutiveFailures -ge $PingCount) {'Offline'} else {'Online'}
        }
        $prev=$j.Row.Tag
        $j.Row.Cells[3].Value=$status
        $j.Row.Cells[3].Style.ForeColor = if ($status -eq 'Online') {[System.Drawing.Color]::Green} elseif ($status -eq 'Offline'){[System.Drawing.Color]::Red} else {[System.Drawing.Color]::Orange}
        $j.Row.Tag=$status
        $device.Status=$status
        # Notification on Offline→Online ----------------------------------------------------
        if ($prev -eq 'Offline' -and $status -eq 'Online') {
            Show-Toast 'Device Online' "$name ($addr) is now online."
        }
    }
    $runspaces.Close();$runspaces.Dispose()
}

# Timer -----------------------------------------------------------------------------------------
$timer          = New-Object System.Windows.Forms.Timer
$timer.Interval = ($numInterval.Value) * 1000
$timer.Add_Tick({ Invoke-PingBatch $dgv.Rows; Save-Devices })
$timer.Start()

# Dynamic interval change -----------------------------------------------------------------------
$numInterval.Add_ValueChanged({ $timer.Interval = ($numInterval.Value)*1000 })

# On close --------------------------------------------------------------------------------------
$form.Add_FormClosing({ $timer.Stop(); Save-Devices; $notify.Dispose() })

[void]$form.ShowDialog()
