
<#
.SYNOPSIS
    Device Status Monitor – vNext (layout & stability fixes).

.DESCRIPTION
    * Fixes control visibility on high‑DPI displays.
    * Ensures Add/Remove operations persist by referencing the script‑scope $devices variable.
    * Anchors/auto‑sizes the grid so it resizes properly.
    * Minor layout tweaks for clarity.

    Feature set retained:
      • Configurable polling interval
      • Toast / fallback balloon notifications + sound cue
      • Multi‑ping confirmation (3 consecutive fails)
      • Parallel ping engine (runspace pool)
      • Group / Location column

.REQUIREMENTS
    PowerShell 5.1+. Toasts use BurntToast if installed.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -----------------------------------------------------------------------------
# Globals & constants
# -----------------------------------------------------------------------------
$script:JsonPath  = Join-Path $PSScriptRoot 'devices.json'
$PingCount        = 3   # multi‑ping threshold

if (-not (Test-Path $JsonPath)) { '[]' | Set-Content $JsonPath -Encoding UTF8 }

$script:devices   = Get-Content $JsonPath -Raw | ConvertFrom-Json | ForEach-Object {
    $_ | Add-Member -NotePropertyName ConsecutiveFailures -NotePropertyValue 0 -Force
    $_
}
if (-not $devices) { $script:devices = @() }

# -----------------------------------------------------------------------------
#   GUI – Windows Forms
# -----------------------------------------------------------------------------
$form                       = [System.Windows.Forms.Form]@{
    Text          = 'Device Status Monitor'
    Size          = [Drawing.Size]::new(760,540)   # taller for input visibility
    StartPosition = 'CenterScreen'
    Topmost       = $true
    AutoScaleMode = 'Dpi'
}

# DataGridView -----------------------------------------------------------------
$dgv                        = New-Object System.Windows.Forms.DataGridView
$dgv.Location               = [Drawing.Point]::new(10,10)
$dgv.Size                   = [Drawing.Size]::new(720,320)
$dgv.AllowUserToAddRows     = $false
$dgv.RowHeadersVisible      = $false
$dgv.SelectionMode          = 'FullRowSelect'
$dgv.Anchor                 = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$dgv.AutoSizeColumnsMode    = 'Fill'

[void]$dgv.Columns.Add('Name','Name')
[void]$dgv.Columns.Add('Address','IP / Hostname')
[void]$dgv.Columns.Add('Group','Group')
$statusCol                  = $dgv.Columns.Add('Status','Status')
$dgv.Columns[$statusCol].ReadOnly = $true

$form.Controls.Add($dgv)

# --------------------------- Input row ---------------------------------------
$yBase   = 350   # unified Y start

$lblName = [System.Windows.Forms.Label]@{Text='Name:';Location=[Drawing.Point]::new(10,$yBase+3)}
$txtName = [System.Windows.Forms.TextBox]@{Location=[Drawing.Point]::new(60,$yBase);Size=[Drawing.Size]::new(140,22)}

$lblIP   = [System.Windows.Forms.Label]@{Text='IP / Host:';Location=[Drawing.Point]::new(220,$yBase+3)}
$txtIP   = [System.Windows.Forms.TextBox]@{Location=[Drawing.Point]::new(290,$yBase);Size=[Drawing.Size]::new(140,22)}

$lblGroup= [System.Windows.Forms.Label]@{Text='Group:';Location=[Drawing.Point]::new(450,$yBase+3)}
$txtGroup= [System.Windows.Forms.TextBox]@{Location=[Drawing.Point]::new(505,$yBase);Size=[Drawing.Size]::new(120,22)}

$btnAdd  = [System.Windows.Forms.Button]@{Text='Add';Location=[Drawing.Point]::new(640,$yBase-1);Width=70}

# Second row (remove & interval) ------------------------------------------------
$y2 = $yBase + 35
$btnRemove   = [System.Windows.Forms.Button]@{Text='Remove Selected';Location=[Drawing.Point]::new(10,$y2);Width=120}
$lblInterval = [System.Windows.Forms.Label]@{Text='Interval (s):';Location=[Drawing.Point]::new(220,$y2+3)}
$numInterval = New-Object System.Windows.Forms.NumericUpDown
$numInterval.Location = [Drawing.Point]::new(310,$y2)
$numInterval.SetRange(5,900)
$numInterval.Value   = 30
$numInterval.Increment=5
$numInterval.Width   = 70

$form.Controls.AddRange(@($lblName,$txtName,$lblIP,$txtIP,$lblGroup,$txtGroup,$btnAdd,$btnRemove,$lblInterval,$numInterval))

# Tray icon --------------------------------------------------------------------
$notify                 = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon            = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Command powershell).Source)
$notify.Visible         = $true

# --------------------------- Helpers ------------------------------------------
function Save-Devices {
    $script:devices | Select-Object Name,Address,Group,Status,ConsecutiveFailures |
        ConvertTo-Json -Depth 3 | Set-Content $JsonPath -Encoding UTF8
}

function Show-Toast {
    param($title,$text)
    try {
        if (-not (Get-Module -ListAvailable -Name BurntToast)) { throw 'BurntToast missing' }
        Import-Module BurntToast -ErrorAction Stop | Out-Null
        New-BurntToastNotification -Text $title,$text | Out-Null
    } catch {
        $notify.BalloonTipTitle = $title
        $notify.BalloonTipText  = $text
        $notify.ShowBalloonTip(5000)
    }
    [System.Media.SystemSounds]::Exclamation.Play()
}

# --------------------------- Seed grid ----------------------------------------
foreach ($d in $devices) {
    $row=$dgv.Rows.Add($d.Name,$d.Address,$d.Group,$d.Status)
    $dgv.Rows[$row].Tag=$d.Status
}

# --------------------------- Add device ---------------------------------------
$btnAdd.Add_Click({
    $name=$txtName.Text.Trim(); $addr=$txtIP.Text.Trim(); $grp=$txtGroup.Text.Trim()
    if (-not ($name -and $addr)) { return }
    $row=$dgv.Rows.Add($name,$addr,$grp,'Unknown')
    $dgv.Rows[$row].Tag='Unknown'
    $script:devices += [PSCustomObject]@{Name=$name;Address=$addr;Group=$grp;Status='Unknown';ConsecutiveFailures=0}
    Save-Devices
    $txtName.Clear();$txtIP.Clear();$txtGroup.Clear()
})

# --------------------------- Remove device ------------------------------------
$btnRemove.Add_Click({
    foreach ($row in @($dgv.SelectedRows)) {
        $name=$row.Cells[0].Value
        $dgv.Rows.Remove($row)
        $script:devices = $script:devices | Where-Object { $_.Name -ne $name }
    }
    Save-Devices
})

# --------------------------- Parallel ping ------------------------------------
function Invoke-PingBatch {
    param([System.Collections.IList]$deviceRows)
    $pool     = [runspacefactory]::CreateRunspacePool(1,10)
    $pool.Open()
    $jobs     = @()
    foreach ($row in $deviceRows) {
        $addr=$row.Cells[1].Value
        $ps   = [powershell]::Create()
        $ps.RunspacePool=$pool
        [void]$ps.AddScript("Test-Connection -ComputerName '$addr' -Count 1 -Quiet -TimeoutSeconds 2")
        $jobs += [pscustomobject]@{Row=$row;PS=$ps;Handle=$ps.BeginInvoke()}
    }
    foreach ($j in $jobs) {
        $online=[bool]($j.PS.EndInvoke($j.Handle))
        $j.PS.Dispose()
        $row=$j.Row
        $name=$row.Cells[0].Value
        $device=$script:devices | Where-Object Name -eq $name
        if (-not $device) { continue }

        if ($online) {
            $device.ConsecutiveFailures=0; $status='Online'
        } else {
            $device.ConsecutiveFailures++
            $status= if ($device.ConsecutiveFailures -ge $PingCount) {'Offline'} else {'Online'}
        }
        $prev=$row.Tag
        $row.Cells[3].Value=$status
        $row.Cells[3].Style.ForeColor = if ($status -eq 'Online') {[Drawing.Color]::ForestGreen} elseif ($status -eq 'Offline') {[Drawing.Color]::Red} else {[Drawing.Color]::Orange}
        $row.Tag=$status
        $device.Status=$status

        if ($prev -eq 'Offline' -and $status -eq 'Online') {
            Show-Toast 'Device Online' "$name ($addr) is now online."
        }
    }
    $pool.Close();$pool.Dispose()
}

# --------------------------- Timer --------------------------------------------
$timer               = New-Object System.Windows.Forms.Timer
$timer.Interval      = ($numInterval.Value)*1000
$timer.Add_Tick({ Invoke-PingBatch $dgv.Rows; Save-Devices })
$timer.Start()

$numInterval.Add_ValueChanged({ $timer.Interval = ($numInterval.Value)*1000 })

# --------------------------- Cleanup ------------------------------------------
$form.Add_FormClosing({ $timer.Stop(); Save-Devices; $notify.Dispose() })

[void]$form.ShowDialog()
