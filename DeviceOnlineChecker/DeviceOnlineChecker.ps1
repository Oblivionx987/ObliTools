

$author = "Seth Burns - System Administrator II - Service Center"
$description = "This script will launch a gui for inputing devices to check if they are online"
$live = "Test"
$Version = "1.0.1"





<#
.SYNOPSIS
    Device Status Monitor – name-only add support + minor UX tweaks.

.DESCRIPTION
    * You can now add a device with **just the Name field**. If the IP/Host box is left
      blank, the script assumes the host address equals the Name you entered.
    * Label updated to clarify “IP/Host (optional)”.
    * All prior features preserved (bottom-docked panel, parallel pings, etc.).

    Example: Type **`fileserver01`** in Name, leave IP/Host blank → row added with
    Name = fileserver01 | Address = fileserver01.

.REQUIREMENTS
    PowerShell 5.1+. Toasts use BurntToast if installed.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -----------------------------------------------------------------------------
# Globals & constants
# -----------------------------------------------------------------------------
$script:JsonPath = Join-Path $PSScriptRoot 'devices.json'
$PingCount       = 3   # multi-ping threshold

if (-not (Test-Path $JsonPath)) { '[]' | Set-Content $JsonPath -Encoding UTF8 }

$script:devices  = Get-Content $JsonPath -Raw | ConvertFrom-Json | ForEach-Object {
    $_ | Add-Member -NotePropertyName ConsecutiveFailures -NotePropertyValue 0 -Force
    $_
}
if (-not $devices) { $script:devices = @() }

# -----------------------------------------------------------------------------
#   GUI – Windows Forms
# -----------------------------------------------------------------------------
$form = [System.Windows.Forms.Form]@{
    Text='Device Status Monitor'; Size=[Drawing.Size]::new(800,600);
    MinimumSize=[Drawing.Size]::new(760,560); StartPosition='CenterScreen';
    AutoScaleMode='Dpi'; Topmost=$true }

# DataGridView -----------------------------------------------------------------
$dgv            = New-Object System.Windows.Forms.DataGridView
$dgv.Dock       = 'Fill'
$dgv.AllowUserToAddRows=$false; $dgv.RowHeadersVisible=$false; $dgv.SelectionMode='FullRowSelect'
$dgv.AutoSizeColumnsMode='Fill'
[void]$dgv.Columns.Add('Name','Name')
[void]$dgv.Columns.Add('Address','IP / Hostname')
[void]$dgv.Columns.Add('Group','Group')
$statusCol=$dgv.Columns.Add('Status','Status'); $dgv.Columns[$statusCol].ReadOnly=$true
$form.Controls.Add($dgv)

# Input panel ------------------------------------------------------------------
$panel      = New-Object System.Windows.Forms.Panel
$panel.Dock='Bottom'; $panel.Height=110; $panel.Padding='10,10,10,10'
$form.Controls.Add($panel)

$lblName  = [System.Windows.Forms.Label]@{Text='Name:';AutoSize=$true;Location=[Drawing.Point]::new(0,5)}
$txtName  = [System.Windows.Forms.TextBox]@{Location=[Drawing.Point]::new(50,2);Size=[Drawing.Size]::new(150,22)}

$lblIP    = [System.Windows.Forms.Label]@{Text='IP/Host (opt):';AutoSize=$true;Location=[Drawing.Point]::new(220,5)}
$txtIP    = [System.Windows.Forms.TextBox]@{Location=[Drawing.Point]::new(310,2);Size=[Drawing.Size]::new(150,22)}

$lblGroup = [System.Windows.Forms.Label]@{Text='Group:';AutoSize=$true;Location=[Drawing.Point]::new(480,5)}
$txtGroup = [System.Windows.Forms.TextBox]@{Location=[Drawing.Point]::new(530,2);Size=[Drawing.Size]::new(120,22)}

$btnAdd   = [System.Windows.Forms.Button]@{Text='Add';Location=[Drawing.Point]::new(660,0);Size=[Drawing.Size]::new(80,26)}

# Second row
$btnRemove   = [System.Windows.Forms.Button]@{Text='Remove Selected';Location=[Drawing.Point]::new(0,45);Size=[Drawing.Size]::new(130,26)}
$lblInterval = [System.Windows.Forms.Label]@{Text='Interval (s):';AutoSize=$true;Location=[Drawing.Point]::new(220,50)}
$numInterval = New-Object System.Windows.Forms.NumericUpDown
$numInterval.Location=[Drawing.Point]::new(300,45); $numInterval.SetRange(5,900); $numInterval.Value=30; $numInterval.Width=70; $numInterval.Increment=5

$panel.Controls.AddRange(@($lblName,$txtName,$lblIP,$txtIP,$lblGroup,$txtGroup,$btnAdd,$btnRemove,$lblInterval,$numInterval))

# Tray icon --------------------------------------------------------------------
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon=[System.Drawing.Icon]::ExtractAssociatedIcon((Get-Command powershell).Source); $notify.Visible=$true

# --------------------------- Helpers ------------------------------------------
function Save-Devices {
    $script:devices | Select-Object Name,Address,Group,Status,ConsecutiveFailures |
        ConvertTo-Json -Depth 3 | Set-Content $JsonPath -Encoding UTF8
}

function Show-Toast($title,$text) {
    try {
        if (-not (Get-Module -ListAvailable -Name BurntToast)) { throw 'BurntToast missing' }
        Import-Module BurntToast -ErrorAction Stop | Out-Null
        New-BurntToastNotification -Text $title,$text | Out-Null
    } catch {
        $notify.BalloonTipTitle=$title; $notify.BalloonTipText=$text; $notify.ShowBalloonTip(5000)
    }
    [System.Media.SystemSounds]::Exclamation.Play()
}

# --------------------------- Seed grid ----------------------------------------
foreach ($d in $devices) {
    $row=$dgv.Rows.Add($d.Name,$d.Address,$d.Group,$d.Status); $dgv.Rows[$row].Tag=$d.Status }

# --------------------------- Add device ---------------------------------------
$btnAdd.Add_Click({
    $name=$txtName.Text.Trim(); if (-not $name) { return }
    $addr=$txtIP.Text.Trim(); if (-not $addr) { $addr=$name }
    $grp=$txtGroup.Text.Trim()

    $row=$dgv.Rows.Add($name,$addr,$grp,'Unknown'); $dgv.Rows[$row].Tag='Unknown'
    $script:devices += [PSCustomObject]@{Name=$name;Address=$addr;Group=$grp;Status='Unknown';ConsecutiveFailures=0}
    Save-Devices
    $txtName.Clear();$txtIP.Clear();$txtGroup.Clear()
})

# --------------------------- Remove device ------------------------------------
$btnRemove.Add_Click({
    foreach ($row in @($dgv.SelectedRows)) {
        $name=$row.Cells[0].Value; $dgv.Rows.Remove($row)
        $script:devices = $script:devices | Where-Object { $_.Name -ne $name }
    }
    Save-Devices
})

# --------------------------- Parallel ping ------------------------------------
function Invoke-PingBatch([System.Collections.IList]$deviceRows) {
    $pool=[runspacefactory]::CreateRunspacePool(1,10); $pool.Open(); $jobs=@()
    foreach ($row in $deviceRows) {
        $addr=$row.Cells[1].Value; $ps=[powershell]::Create(); $ps.RunspacePool=$pool
        $null=$ps.AddScript("Test-Connection -ComputerName '$addr' -Count 1 -Quiet -TimeoutSeconds 2")
        $jobs += [pscustomobject]@{Row=$row;PS=$ps;Handle=$ps.BeginInvoke()}
    }
    foreach ($j in $jobs) {
        $online=[bool]($j.PS.EndInvoke($j.Handle)); $j.PS.Dispose(); $row=$j.Row
        $name=$row.Cells[0].Value; $device=$script:devices | Where-Object Name -eq $name; if (-not $device){continue}
        if ($online){$device.ConsecutiveFailures=0;$status='Online'}else{$device.ConsecutiveFailures++;$status=($device.ConsecutiveFailures -ge $PingCount)?'Offline':'Online'}
        $prev=$row.Tag; $row.Cells[3].Value=$status
        $row.Cells[3].Style.ForeColor= if($status -eq 'Online'){[Drawing.Color]::ForestGreen}elseif($status -eq 'Offline'){[Drawing.Color]::Red}else{[Drawing.Color]::Orange}
        $row.Tag=$status; $device.Status=$status
        if ($prev -eq 'Offline' -and $status -eq 'Online') { Show-Toast 'Device Online' "$name ($addr) is now online." }
    }
    $pool.Close();$pool.Dispose()
}

# --------------------------- Timer --------------------------------------------
$timer=New-Object System.Windows.Forms.Timer; $timer.Interval=($numInterval.Value)*1000
$timer.Add_Tick({ Invoke-PingBatch $dgv.Rows; Save-Devices }); $timer.Start()
$numInterval.Add_ValueChanged({ $timer.Interval=($numInterval.Value)*1000 })

# --------------------------- Cleanup ------------------------------------------
$form.Add_FormClosing({ $timer.Stop(); Save-Devices; $notify.Dispose() })

[void]$form.ShowDialog()
