#Requires -Version 7.5

<#! 
    Quick Notes GUI — v1.4.0  (2025‑05‑10)
    --------------------------------------
    • Updated for PowerShell 7.5+ compatibility.
    • Replaced Add-Type with using statements for assemblies.
!#>

# ─────────────────────────────────────────────────────────────────────────────
# Assemblies & native interop
# ─────────────────────────────────────────────────────────────────────────────
using namespace System.Windows.Forms
using namespace System.Drawing
using namespace System.Runtime.InteropServices

if (-not ([System.Windows.Forms.Form] -as [type])) {
    throw "System.Windows.Forms is not available. Ensure you are running this script in PowerShell 7.5+ with Windows compatibility."
}

# Hotkey‑enabled custom form (Ctrl + Shift + N)
Add-Type @"
using System;
using System.Windows.Forms;
using System.Runtime.InteropServices;

public class QuickNotesForm : Form
{
    private const int  WM_HOTKEY  = 0x0312;
    private const uint MOD_CTRL   = 0x2;
    private const uint MOD_SHIFT  = 0x4;
    private const int  HOTKEY_ID  = 1;

    [DllImport("user32.dll")] static extern bool RegisterHotKey(IntPtr hWnd,int id,uint fsMods,int vk);
    [DllImport("user32.dll")] static extern bool UnregisterHotKey(IntPtr hWnd,int id);

    protected override void OnHandleCreated(EventArgs e)
    {
        base.OnHandleCreated(e);
        if (!RegisterHotKey(this.Handle, HOTKEY_ID, MOD_CTRL | MOD_SHIFT, (int)Keys.N))
        {
            MessageBox.Show("Failed to register hotkey (Ctrl+Shift+N). It might already be in use.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
    protected override void OnHandleDestroyed(EventArgs e)
    {
        try
        {
            UnregisterHotKey(this.Handle, HOTKEY_ID);
        }
        finally
        {
            base.OnHandleDestroyed(e);
        }
    }
    protected override void WndProc(ref Message m)
    {
        base.WndProc(ref m);
        if (m.Msg == WM_HOTKEY && m.WParam.ToInt32() == HOTKEY_ID)
        {
            if (this.Visible && this.WindowState != FormWindowState.Minimized)
            {
                this.Hide();
            }
            else
            {
                this.Show();
                this.WindowState = FormWindowState.Normal;
                this.Activate();
            }
        }
    }
}
"@ -ReferencedAssemblies @('System.Windows.Forms','System.Drawing')

# ─────────────────────────────────────────────────────────────────────────────
# Data‑persistence helpers
# ─────────────────────────────────────────────────────────────────────────────
$notesFile = 'C:\Users\Oblivion\OneDrive\Seth\Oblivion Vault\Scripts\Templates\Noter\notes.json'

function Load-Notes {
    if (Test-Path $notesFile) {
        try {
            $json = Get-Content $notesFile -Raw | ConvertFrom-Json
            switch ($json) {
                { $_ -eq $null }                                                          { @()  }
                { $_ -is [System.Collections.IEnumerable] -and $_.GetType().Name -ne 'String' } { ,$json }
                default                                                                   { @($json) }
            }
        } catch {
            Write-Warning "Failed to load notes: $_"
            @()
        }
    } else { @() }
}

function Save-Notes ([object[]]$noteList) {
    $dir = Split-Path $notesFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $noteList | ConvertTo-Json -Depth 6 | Set-Content -Path $notesFile -Force -Encoding UTF8
}

$global:Notes       = Load-Notes          # always an array
$global:EditingNote = $null               # note currently being edited

# ─────────────────────────────────────────────────────────────────────────────
# Theme & font helpers
# ─────────────────────────────────────────────────────────────────────────────
function Set-Theme([System.Windows.Forms.Control]$root,[bool]$dark){
    $bg = if ($dark){[System.Drawing.Color]::FromArgb(45,45,48)}
          else {[System.Windows.Forms.SystemColors]::Control}
    $fg = if ($dark){[System.Drawing.Color]::White}
          else {[System.Windows.Forms.SystemColors]::ControlText}
    $root.BackColor,$root.ForeColor = $bg,$fg
    foreach($c in $root.Controls){ Set-Theme $c $dark }
}

function Set-FontSize([System.Windows.Forms.Control]$root, [int]$size) {
    if ($size -lt 8 -or $size -gt 16) {
        Write-Warning "Font size must be between 8 and 16. Defaulting to 10."
        $size = 10
    }
    $root.Font = New-Object System.Drawing.Font($root.Font.FontFamily, [float]$size, $root.Font.Style)
    foreach ($c in $root.Controls) { Set-FontSize $c $size }
}

# ─────────────────────────────────────────────────────────────────────────────
# UI‑helper functions
# ─────────────────────────────────────────────────────────────────────────────
function Refresh-List {
    param([string]$Filter='')

    if (-not $listBox) {
        Write-Warning "ListBox control is not initialized."
        return
    }

    $listBox.Items.Clear()
    $filtered = if ([string]::IsNullOrWhiteSpace($Filter)){
        $global:Notes
    } else {
        $global:Notes | Where-Object {
            $_.Text -match [regex]::Escape($Filter) -or
            ($_.Tags -join ',') -match [regex]::Escape($Filter)
        }
    }
    $listBox.Tag = $filtered   # map UI rows ➜ note objects

    foreach ($n in $filtered) {
        $tagStr  = if ($n.Tags){ ' [' + ($n.Tags -join ',') + ']' } else { '' }
        $display = '{0:yyyy-MM-dd HH:mm} : {1}{2}' -f ([datetime]$n.Timestamp),$n.Text,$tagStr
        [void]$listBox.Items.Add($display)
    }
    $btnEdit.Enabled = $btnDelete.Enabled = $false
}

function Add-Or-UpdateNote {
    if (-not $txtNote -or -not $txtTags) {
        Write-Warning "TextBox controls are not initialized."
        return
    }

    $text     = $txtNote.Text.Trim()
    $tagInput = $txtTags.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($text)) {
        [System.Windows.Forms.MessageBox]::Show('Note cannot be empty.', 'Validation', 'OK', 'Warning') | Out-Null
        $txtNote.Focus()
        return
    }

    $tagArray = if ($tagInput){
        ($tagInput -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    } else { @() }

    if ($global:EditingNote){
        $global:EditingNote.Text      = $text
        $global:EditingNote.Tags      = $tagArray
        $global:EditingNote.Timestamp = Get-Date
        $global:EditingNote = $null
        $btnSave.Text = 'Save Note (Ctrl+S)'
    } else {
        $note = [pscustomobject]@{
            Id        = [guid]::NewGuid().ToString()
            Timestamp = Get-Date
            Text      = $text
            Tags      = $tagArray
        }
        $global:Notes = @($global:Notes) + $note
    }

    Save-Notes $global:Notes
    $txtNote.Clear(); $txtTags.Clear()
    Refresh-List $txtSearch.Text
}

function Delete-SelectedNote {
    if (-not $listBox) {
        Write-Warning "ListBox control is not initialized."
        return
    }

    if ($listBox.SelectedIndex -lt 0) { return }
    $note = $listBox.Tag[$listBox.SelectedIndex]
    $confirm = [System.Windows.Forms.MessageBox]::Show('Delete the selected note?','Confirm','YesNo','Warning')
    if ($confirm -eq 'Yes') {
        $global:Notes = $global:Notes | Where-Object { $_.Id -ne $note.Id }
        Save-Notes $global:Notes
        Refresh-List $txtSearch.Text
    }
}

function Edit-SelectedNote {
    if (-not $listBox -or -not $txtNote -or -not $txtTags) {
        Write-Warning "Controls are not initialized."
        return
    }

    if ($listBox.SelectedIndex -lt 0) { return }
    $note           = $listBox.Tag[$listBox.SelectedIndex]
    $txtNote.Text   = $note.Text
    $txtTags.Text   = $note.Tags -join ', '
    $txtNote.Focus(); $txtNote.SelectAll()
    $global:EditingNote = $note
    $btnSave.Text   = 'Update Note (Ctrl+S)'
}

# ─────────────────────────────────────────────────────────────────────────────
# Build the GUI
# ─────────────────────────────────────────────────────────────────────────────
$form               = [QuickNotesForm]::new()
$form.Text          = 'Quick Notes'
$form.Size          = [System.Drawing.Size]::new(720,560)
$form.StartPosition = 'CenterScreen'
$form.KeyPreview    = $true
$form.DoubleBuffered= $true

# New / Edit label
$lblNote            = [System.Windows.Forms.Label]::new()
$lblNote.Text       = 'New / Edit Note:'
$lblNote.Location   = [System.Drawing.Point]::new(10,10)
$form.Controls.Add($lblNote)

# Note textbox
$txtNote            = [System.Windows.Forms.TextBox]::new()
$txtNote.Multiline  = $true
$txtNote.Size       = [System.Drawing.Size]::new(550,110)
$txtNote.Location   = [System.Drawing.Point]::new(10,30)
$form.Controls.Add($txtNote)

# Tags label
$lblTags            = [System.Windows.Forms.Label]::new()
$lblTags.Text       = 'Tags (comma‑separated):'
$lblTags.Location   = [System.Drawing.Point]::new(10,145)
$form.Controls.Add($lblTags)

# Tags textbox
$txtTags            = [System.Windows.Forms.TextBox]::new()
$txtTags.Size       = [System.Drawing.Size]::new(550,20)
$txtTags.Location   = [System.Drawing.Point]::new(10,165)
$form.Controls.Add($txtTags)

# Save / Update button
$btnSave            = [System.Windows.Forms.Button]::new()
$btnSave.Text       = 'Save Note (Ctrl+S)'
$btnSave.Location   = [System.Drawing.Point]::new(580,30)
$btnSave.Size       = [System.Drawing.Size]::new(120,30)
$btnSave.Add_Click({ Add-Or-UpdateNote })
$form.Controls.Add($btnSave)

# Edit button
$btnEdit            = [System.Windows.Forms.Button]::new()
$btnEdit.Text       = 'Edit Selected'
$btnEdit.Location   = [System.Drawing.Point]::new(580,70)
$btnEdit.Size       = [System.Drawing.Size]::new(120,30)
$btnEdit.Enabled    = $false
$btnEdit.Add_Click({ Edit-SelectedNote })
$form.Controls.Add($btnEdit)

# Delete button
$btnDelete          = [System.Windows.Forms.Button]::new()
$btnDelete.Text     = 'Delete Selected'
$btnDelete.Location = [System.Drawing.Point]::new(580,110)
$btnDelete.Size     = [System.Drawing.Size]::new(120,30)
$btnDelete.Enabled  = $false
$btnDelete.Add_Click({ Delete-SelectedNote })
$form.Controls.Add($btnDelete)

# Dark‑mode checkbox
$chkDark            = [System.Windows.Forms.CheckBox]::new()
$chkDark.Text       = 'Dark mode'
$chkDark.Location   = [System.Drawing.Point]::new(580,160)
$chkDark.Add_CheckedChanged({ Set-Theme $form $chkDark.Checked })
$form.Controls.Add($chkDark)

# Font‑size selector
$lblFont            = [System.Windows.Forms.Label]::new()
$lblFont.Text       = 'Font size:'
$lblFont.Location   = [System.Drawing.Point]::new(580,195)
$form.Controls.Add($lblFont)

$cmbFont            = [System.Windows.Forms.ComboBox]::new()
$cmbFont.Location   = [System.Drawing.Point]::new(580,215)
$cmbFont.Size       = [System.Drawing.Size]::new(120,22)
$cmbFont.DropDownStyle = 'DropDownList'
8..16 | ForEach-Object { [void]$cmbFont.Items.Add($_) }
$cmbFont.SelectedItem = 10
$cmbFont.Add_SelectedIndexChanged({
    if (-not $cmbFont) {
        Write-Warning "ComboBox control is not initialized."
        return
    }
    Set-FontSize $form [int]$cmbFont.SelectedItem
})
$form.Controls.Add($cmbFont)

# Search label
$lblSearch          = [System.Windows.Forms.Label]::new()
$lblSearch.Text     = 'Search:'
$lblSearch.Location = [System.Drawing.Point]::new(10,200)
$form.Controls.Add($lblSearch)

# Search textbox
$txtSearch          = [System.Windows.Forms.TextBox]::new()
$txtSearch.Size     = [System.Drawing.Size]::new(550,20)
$txtSearch.Location = [System.Drawing.Point]::new(10,220)
$txtSearch.Add_TextChanged({
    if (-not $txtSearch) {
        Write-Warning "Search TextBox control is not initialized."
        return
    }
    Refresh-List $txtSearch.Text
})
$form.Controls.Add($txtSearch)

# Notes listbox
$listBox                    = [System.Windows.Forms.ListBox]::new()
$listBox.Size               = [System.Drawing.Size]::new(690,270)
$listBox.Location           = [System.Drawing.Point]::new(10,250)
$listBox.HorizontalScrollbar= $true
$listBox.Add_Click({
    $btnEdit.Enabled = $btnDelete.Enabled = ($listBox.SelectedIndex -ge 0)
})
$listBox.Add_DoubleClick({
    if ($listBox.SelectedIndex -ge 0) { Edit-SelectedNote }
})
$form.Controls.Add($listBox)

# Add tooltips
$toolTip = [System.Windows.Forms.ToolTip]::new()
$toolTip.SetToolTip($btnSave, "Save or update the current note.")
$toolTip.SetToolTip($btnEdit, "Edit the selected note.")
$toolTip.SetToolTip($btnDelete, "Delete the selected note.")
$toolTip.SetToolTip($chkDark, "Toggle dark mode.")
$toolTip.SetToolTip($cmbFont, "Select the font size.")

# Set default font
$form.Font = [System.Drawing.Font]::new("Segoe UI", 10)

# Keyboard shortcut Ctrl+S for save/update
$form.Add_KeyDown({
    param($sender,$e)
    if ($e.Control -and $e.KeyCode -eq 'S'){
        Add-Or-UpdateNote
        $e.Handled = $true
    }
})

# Initial theme/font & populate
Set-FontSize $form 10
$form.Add_Shown({
    if (-not $form) {
        Write-Warning "Form is not initialized."
        return
    }
    Refresh-List
})

# ─────────────────────────────────────────────────────────────────────────────
# Start the event loop
# ─────────────────────────────────────────────────────────────────────────────
[void]$form.ShowDialog()
