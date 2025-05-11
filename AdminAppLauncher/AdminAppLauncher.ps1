# AdminAppLauncher.ps1 – v2.0 (2025‑04‑19)
# -----------------------------------------------------------------------------
# A forward‑looking PowerShell WinForms GUI that lets an administrator launch
# multiple applications elevated.  This version folds in feature requests 1–10:
#   1.  Edit / remove entries in‑GUI   (context‑menu)
#   2.  Visual status feedback          (Status column)
#   3.  Sort & search                   (column sorting + live filter box)
#   4.  Import / export app lists       (JSON)
#   5.  Drag‑and‑drop add               (drop EXE/LNK onto grid)
#   6.  System‑tray mode                (notify‑icon)
#   7.  Color & icon cues               (row alt‑colors + app icons)
#   8.  Dark‑mode awareness             (registry check → theme switch)
#   9.  Group launch sets               (Group column + filter)
#  10.  Launch ordering with delays     (Delay column; sequential launch)
# -----------------------------------------------------------------------------

#region ► SET‑UP & PREREQS ◄
Add-Type -AssemblyName System.Windows.Forms, System.Drawing, Microsoft.VisualBasic

$ErrorActionPreference = 'Stop'
$currentUser = $env:USERNAME
$ConfigPath  = Join-Path $PSScriptRoot 'appconfig.json'

function Test-IsAdmin {
    $wp = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    $wp.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

#endregion

#region ► THEME (Dark / Light) ◄
$dpiAware = [System.Environment]::OSVersion.Version.Major -ge 10
function Get-IsDarkMode {
    try {
        $rk = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        (Get-ItemProperty -Path $rk -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme -eq 0
    } catch { $false }
}
$IsDark = Get-IsDarkMode
$BackColor = if ($IsDark) { [Drawing.Color]::FromArgb(30,30,30) } else { [Drawing.SystemColors]::Window }
$ForeColor = if ($IsDark) { [Drawing.Color]::WhiteSmoke } else { [Drawing.SystemColors]::ControlText }
#endregion

#region ► FORM & CONTROLS ◄
$form               = [Windows.Forms.Form]::new()
$form.Text          = "Admin App Launcher – $currentUser"
$form.Size          = [Drawing.Size]::new(960, 580)
$form.StartPosition = 'CenterScreen'
$form.BackColor     = $BackColor
$form.ForeColor     = $ForeColor
$form.MinimumSize   = $form.Size

# --- Search / filter box ------------------------------------------------------
$txtSearch               = [Windows.Forms.TextBox]::new()
$txtSearch.PlaceholderText = 'Search / filter…'
$txtSearch.Location      = [Drawing.Point]::new(10,10)
$txtSearch.Width         = 300
$form.Controls.Add($txtSearch)

# --- Group filter -------------------------------------------------------------
$cboGroup               = [Windows.Forms.ComboBox]::new()
$cboGroup.DropDownStyle = 'DropDownList'
$cboGroup.Items.Add('<All Groups>') | Out-Null
$cboGroup.SelectedIndex = 0
$cboGroup.Location      = [Drawing.Point]::new(320,10)
$cboGroup.Width         = 160
$form.Controls.Add($cboGroup)

# --- Data grid ----------------------------------------------------------------
$grid                 = [Windows.Forms.DataGridView]::new()
$grid.Location        = [Drawing.Point]::new(10,40)
$grid.Size            = [Drawing.Size]::new(920, 420)
$grid.AutoSizeRowsMode= 'AllCells'
$grid.AllowUserToAddRows = $false
$grid.RowHeadersVisible  = $false
$grid.SelectionMode      = 'FullRowSelect'
$grid.AllowDrop          = $true
$grid.EnableHeadersVisualStyles = $false
# ----- Dark‑mode styling -------------------------------------------------
if ($IsDark) {
    $grid.DefaultCellStyle.BackColor        = $BackColor      # 30,30,30
    $grid.DefaultCellStyle.ForeColor        = $ForeColor      # WhiteSmoke
    $grid.DefaultCellStyle.SelectionBackColor = [Drawing.Color]::FromArgb(70,70,70)
    $grid.DefaultCellStyle.SelectionForeColor = $ForeColor
}

$grid.BackgroundColor    = $BackColor
$grid.GridColor          = $ForeColor
$form.Controls.Add($grid)

# Alternating row style for readability
$alt = $grid.AlternatingRowsDefaultCellStyle
$alt.BackColor = if ($IsDark) { [Drawing.Color]::FromArgb(45,45,48) } else { [Drawing.Color]::FromArgb(235,235,235) }
$alt.ForeColor = $ForeColor

# Columns
$columns = @()
$columns += [Windows.Forms.DataGridViewCheckBoxColumn]@{HeaderText='Sel'; Width=35}
$columns += [Windows.Forms.DataGridViewTextBoxColumn]@{HeaderText='Nickname'; Width=160}
$columns += [Windows.Forms.DataGridViewTextBoxColumn]@{HeaderText='Group'; Width=110}
$columns += [Windows.Forms.DataGridViewTextBoxColumn]@{HeaderText='Delay (s)'; Width=70}
$columns += [Windows.Forms.DataGridViewImageColumn]@{HeaderText='Icon'; Width=40}
$columns += [Windows.Forms.DataGridViewTextBoxColumn]@{HeaderText='Path'; Width=360; ReadOnly=$true}
$columns += [Windows.Forms.DataGridViewTextBoxColumn]@{HeaderText='Status'; Width=90; ReadOnly=$true}
$columns += [Windows.Forms.DataGridViewButtonColumn]@{HeaderText='Action'; Text='Start'; UseColumnTextForButtonValue=$true; Width=60}
foreach ($c in $columns){ [void]$grid.Columns.Add($c) }

# --- Buttons ------------------------------------------------------------------
$btnAdd  = [Windows.Forms.Button]@{Text='Add application'; Location=[Drawing.Point]::new(10,470); Size=[Drawing.Size]::new(120,30)}
$btnImport = [Windows.Forms.Button]@{Text='Import'; Location=[Drawing.Point]::new(140,470); Size=[Drawing.Size]::new(70,30)}
$btnExport = [Windows.Forms.Button]@{Text='Export'; Location=[Drawing.Point]::new(220,470); Size=[Drawing.Size]::new(70,30)}
$btnStartSel = [Windows.Forms.Button]@{Text='Start selected'; Location=[Drawing.Point]::new(310,470); Size=[Drawing.Size]::new(110,30)}
$btnClose = [Windows.Forms.Button]@{Text='Close'; Location=[Drawing.Point]::new(430,470); Size=[Drawing.Size]::new(70,30)}
$form.Controls.AddRange(@($btnAdd,$btnImport,$btnExport,$btnStartSel,$btnClose))

# --- Notify (system‑tray) -----------------------------------------------------
$tray = [Windows.Forms.NotifyIcon]::new()
$tray.Icon   = [Drawing.SystemIcons]::Application
$tray.Text   = 'Admin App Launcher'
$tray.Visible= $false
$cmTray = [Windows.Forms.ContextMenuStrip]::new()
$exitItem = $cmTray.Items.Add('Exit')
$exitItem.Add_Click({ $tray.Visible=$false; $form.Close() })
$tray.ContextMenuStrip = $cmTray

#endregion

#region ► CONFIG LOAD / SAVE ◄
function Load-Config {
    if (!(Test-Path $ConfigPath)){ return }
    $json = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    $grid.Rows.Clear()
    foreach ($app in $json){ Add-Row $app.Nickname $app.Group $app.Delay $app.Path }
}

function Save-Config {
    $apps = foreach ($row in $grid.Rows){
        if ($row.IsNewRow){ continue }
        [pscustomobject]@{
            Nickname = $row.Cells[1].Value
            Group    = $row.Cells[2].Value
            Delay    = [int]($row.Cells[3].Value)
            Path     = $row.Cells[5].Value
        }
    }
    $apps | ConvertTo-Json -Depth 2 | Set-Content -Encoding UTF8 $ConfigPath
}
#endregion

#region ► ROW HELPERS ◄
function Get-AppIcon($path){
    try{ [Drawing.Icon]::ExtractAssociatedIcon($path) }catch{ [Drawing.SystemIcons]::Application }
}
function Add-Row([string]$nick,[string]$group,[int]$delay,[string]$path){
    $row = $grid.Rows.Add()
    $grid.Rows[$row].Cells[0].Value = $false  # selected
    $grid.Rows[$row].Cells[1].Value = $nick
    $grid.Rows[$row].Cells[2].Value = $group
    $grid.Rows[$row].Cells[3].Value = $delay
    $grid.Rows[$row].Cells[4].Value = Get-AppIcon $path
    $grid.Rows[$row].Cells[5].Value = $path
    $grid.Rows[$row].Cells[6].Value = ''
}
#endregion

#region ► APP LAUNCH ◄
function Start-App ($row){
    $path  = $row.Cells[5].Value
    if (![System.IO.File]::Exists($path)){
        $row.Cells[6].Value = '✗ Missing'
        return
    }
    $row.Cells[6].Value = 'Launching…'
    try{
        if (Test-IsAdmin){
            $p = Start-Process -FilePath $path -PassThru -WindowStyle Normal
        }else{
            $p = Start-Process -FilePath $path -Verb RunAs -PassThru -WindowStyle Normal
        }
        $null = $p.WaitForInputIdle(10000)
        $row.Cells[6].Value = '✓ Launched'
    }catch{
        $row.Cells[6].Value = '✗ Failed'
    }
}
#endregion

#region ► CONTEXT MENU (edit/remove) ◄
$ctx = [Windows.Forms.ContextMenuStrip]::new()
$itemEdit   = $ctx.Items.Add('Edit…')
$itemRemove = $ctx.Items.Add('Remove')
$grid.ContextMenuStrip = $ctx
$grid.Add_MouseDown({ param($s,$e) if($e.Button -eq 'Right'){
        $rowIndex = $grid.HitTest($e.X,$e.Y).RowIndex
        $grid.ClearSelection()
        if($rowIndex -ge 0){
            $grid.Rows[$rowIndex].Selected = $true
            $grid.CurrentCell = $grid.Rows[$rowIndex].Cells[1]
        }
    }})
$itemEdit.Add_Click({
    if(!$grid.CurrentRow){ return }
    $row=$grid.CurrentRow
    $row.ReadOnly=$false   # allow edits to nickname/group/delay
})
$itemRemove.Add_Click({
    if($grid.CurrentRow){ $grid.Rows.Remove($grid.CurrentRow); Save-Config }
})
#endregion

#region ► DRAG‑AND‑DROP support ◄
$grid.Add_DragEnter({ param($s,$e)
    if($e.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)){
        $e.Effect = 'Copy'
    }})
$grid.Add_DragDrop({ param($s,$e)
    $files = $e.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    foreach($file in $files){
        if($file -match '\\.(lnk|exe)$'){
            $target = if($file.ToLower().EndsWith('.lnk')){
                $sh = New-Object -ComObject WScript.Shell
                $sh.CreateShortcut($file).TargetPath
            }else{ $file }
            $nick = [System.IO.Path]::GetFileNameWithoutExtension($target)
            Add-Row $nick '' 0 $target
        }
    }
    Save-Config
})
#endregion

#region ► SEARCH & GROUP FILTER ◄
function Apply-Filter{
    $term  = $txtSearch.Text.Trim().ToLower()
    $grp   = if($cboGroup.SelectedIndex -eq 0){ $null } else { $cboGroup.SelectedItem }
    foreach($row in $grid.Rows){
        if($row.IsNewRow){ continue }
        $visible = $true
        if($term){
            $visible = ($row.Cells[1].Value -as [string]).ToLower().Contains($term) -or (($row.Cells[5].Value) -as [string]).ToLower().Contains($term)
        }
        if($grp){ $visible = $visible -and ($row.Cells[2].Value -eq $grp) }
        $row.Visible = $visible
    }
}
$txtSearch.Add_TextChanged({ Apply-Filter })
$cboGroup.Add_SelectedIndexChanged({ Apply-Filter })
#endregion

#region ► BUTTON EVENTS ◄
$btnAdd.Add_Click({
    $dlg = [Windows.Forms.OpenFileDialog]::new()
    $dlg.Filter = 'Executables (*.exe)|*.exe|Shortcuts (*.lnk)|*.lnk|All files (*.*)|*.*'
    if($dlg.ShowDialog() -ne 'OK'){ return }
    $target = if($dlg.FileName.ToLower().EndsWith('.lnk')){
        (New-Object -ComObject WScript.Shell).CreateShortcut($dlg.FileName).TargetPath
    }else{ $dlg.FileName }

    $defaultNick = [IO.Path]::GetFileNameWithoutExtension($target)
    $nick = [Microsoft.VisualBasic.Interaction]::InputBox('Nickname:', 'Add application', $defaultNick)
    if([string]::IsNullOrWhiteSpace($nick)){ return }

    $group = [Microsoft.VisualBasic.Interaction]::InputBox('Group (optional):', 'Group', '')
    $delay = [int][Microsoft.VisualBasic.Interaction]::InputBox('Delay in seconds (0 for none):', 'Delay', '0')
    Add-Row $nick $group $delay $target
    if($group -and !$cboGroup.Items.Contains($group)){ $null = $cboGroup.Items.Add($group) }
    Save-Config
})

$btnImport.Add_Click({
    $dlg=[Windows.Forms.OpenFileDialog]@{Filter='JSON files (*.json)|*.json|All files (*.*)|*.*'}
    if($dlg.ShowDialog() -ne 'OK'){ return }
    try{ Copy-Item $dlg.FileName $ConfigPath -Force; Load-Config; Save-Config }catch{ [Windows.Forms.MessageBox]::Show($_) }
})
$btnExport.Add_Click({
    $dlg=[Windows.Forms.SaveFileDialog]@{Filter='JSON files (*.json)|*.json'; FileName='appconfig_export.json'}
    if($dlg.ShowDialog() -ne 'OK'){ return }
    try{ Save-Config; Copy-Item $ConfigPath $dlg.FileName -Force }catch{ [Windows.Forms.MessageBox]::Show($_) }
})

$btnStartSel.Add_Click({
    # Launch selected rows ordered by Delay ascending
    $rows = $grid.Rows | Where-Object { $_.Cells[0].Value -eq $true -and -not $_.IsNewRow }
    $ordered = $rows | Sort-Object { [int]$_.Cells[3].Value }
    foreach($row in $ordered){
        $delay = [int]$row.Cells[3].Value
        if($delay -gt 0){ $row.Cells[6].Value = "Waiting $delay s…"; Start-Sleep -Seconds $delay }
        Start-App $row
    }
})

$btnClose.Add_Click({ Save-Config; $form.Close() })
#endregion

#region ► GRID BUTTON (per‑row start) ◄
$grid.Add_CellContentClick({ param($s,$e)
    if($e.RowIndex -lt 0){ return }
    if($e.ColumnIndex -eq 7){ Start-App $grid.Rows[$e.RowIndex] }
})
#endregion

#region ► MINIMIZE TO TRAY ◄
$form.Add_Resize({
    if($form.WindowState -eq 'Minimized'){
        $form.Hide(); $tray.Visible=$true; $tray.ShowBalloonTip(1000,'Admin App Launcher','Still running in tray.',[Windows.Forms.ToolTipIcon]::Info)
    }
})
$tray.Add_DoubleClick({ $form.Show(); $form.WindowState='Normal'; $tray.Visible=$false })
#endregion

#region ► INIT & RUN ◄
Load-Config
# Populate group dropdown
foreach($row in $grid.Rows){ if(-not $row.IsNewRow -and $row.Cells[2].Value -and -not $cboGroup.Items.Contains($row.Cells[2].Value)){ $null=$cboGroup.Items.Add($row.Cells[2].Value) } }

[void]$form.ShowDialog()
Save-Config
#endregion
