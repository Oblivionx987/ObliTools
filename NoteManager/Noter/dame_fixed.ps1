<#  Note-Manager.ps1  —  revised 2025‑05‑10
    ░█▄─░█ ░█▀▀▀█ ░█▄─░█ ░█▀▄▀█ ▀▀█▀▀ ░█▀▀█ ░█─░█ ░█▄─░█ ░█▀▀▀ ░█▀▀▀█
    ░█░█░█ ░█──░█ ░█░█░█ ░█░█░█ ─░█── ░█▄▄█ ░█─░█ ░█░█░█ ░█▀▀▀ ░█──░█
    ░█──▀█ ░█▄▄▄█ ░█──▀█ ░█──░█ ─░█── ░█─── ─▀▄▄▀ ░█──▀█ ░█▄▄▄ ░█▄▄▄█

    Unified persistence: notes now live in a rich text markdown format and configuration in JSON files.
#>

Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Windows.Forms

#───────────────────────────────────────────────────────────────────────────────
#  Paths & data
#───────────────────────────────────────────────────────────────────────────────
$dataFile     = Join-Path -path "C:\Users\Oblivion\OneDrive\Seth\Oblivion Vault\Scripts\Templates\Noter" -childpath "NoteManager_Notes.md"
$configFile   = Join-Path -path "C:\Users\Oblivion\OneDrive\Seth\Oblivion Vault\Scripts\Templates\Noter" -childpath "NoteManager_Config.json"

function Import-Config {
    if (Test-Path $configFile) {
        try {
            return Get-Content $configFile -Raw | ConvertFrom-Json
        } catch {
            [System.Windows.MessageBox]::Show("Corrupted config file at $configFile – starting fresh.","Note Manager")
        }
    }
    return [ordered]@{ DarkMode = $false }
}

function Export-Config {
    $script:config | ConvertTo-Json -Depth 2 | Set-Content -LiteralPath $configFile -Encoding UTF8
}

function Import-Notes {
    if (Test-Path $dataFile) {
        return Get-Content $dataFile -Raw
    }
    return ""
}

function Export-Notes {
    $notesMarkdown = ""
    foreach ($note in $script:notes) {
        $notesMarkdown += "### $($note.Timestamp)`n"
        if ($note.Category) { $notesMarkdown += "**Category:** $($note.Category)`n" }
        if ($note.Reminder) { $notesMarkdown += "**Reminder:** $($note.Reminder)`n" }
        $notesMarkdown += "$($note.Content)`n`n"
    }
    Set-Content -LiteralPath $dataFile -Value $notesMarkdown -Encoding UTF8
}

$script:config = Import-Config
$script:notes = @()
$notesMarkdown = Import-Notes
if ($notesMarkdown) {
    $notesMarkdown -split "`n`n" | ForEach-Object {
        $lines = $_ -split "`n"
        $timestamp = $lines[0] -replace "### ", ""
        $category = ($lines | Where-Object { $_ -like "**Category:*" }) -replace "\*\*Category:\*\* ", ""
        $reminder = ($lines | Where-Object { $_ -like "**Reminder:*" }) -replace "\*\*Reminder:\*\* ", ""
        $content = ($lines | Where-Object { ($_ -notlike "###*") -and ($_ -notlike "**Category:*") -and ($_ -notlike "**Reminder:*") }) -join "`n"
        $script:notes += [pscustomobject]@{
            Timestamp = $timestamp
            Content   = $content
            Category  = $category
            Reminder  = $reminder
        }
    }
}

#───────────────────────────────────────────────────────────────────────────────
#  XAML
#───────────────────────────────────────────────────────────────────────────────
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Note Manager" Height="650" Width="850">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Input -->
        <StackPanel Grid.Row="0" Orientation="Vertical" Margin="0,0,0,10">
            <TextBox Name="NoteInput" Height="100" AcceptsReturn="True"
                     TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
            <StackPanel Orientation="Horizontal" Margin="0,5,0,0">
                <TextBox Name="CategoryInput" Width="150" Margin="0,0,5,0"/>
                <TextBox Name="ReminderInput" Width="200" Margin="0,0,5,0"
                         ToolTip="yyyy-MM-dd HH:mm (optional)"/>
                <Button Name="BoldButton"    Content="Bold"    Width="60" Margin="0,0,5,0"/>
                <Button Name="ItalicsButton" Content="Italics" Width="60" Margin="0,0,5,0"/>
                <Button Name="BulletButton"  Content="Bullet"  Width="60"/>
            </StackPanel>
        </StackPanel>

        <!-- Search & list -->
        <StackPanel Grid.Row="1" Orientation="Vertical">
            <TextBox Name="SearchBox" Height="25" ToolTip="Search notes..."/>
            <ListBox Name="NotesList" Height="350"/>
        </StackPanel>

        <!-- Action buttons -->
        <StackPanel Name="ActionButtonsPanel" Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,10,0,0">
            <Button Name="AddNoteButton"        Content="Add Note"         Width="100" Margin="5"/>
            <Button Name="OrganizeNotesButton"  Content="Organize Notes"   Width="120" Margin="5"/>
            <Button Name="ExportButton"         Content="Export Notes"     Width="120" Margin="5"/>
            <Button Name="ToggleDarkModeButton" Content="Toggle Dark Mode" Width="150" Margin="5"/>
            <Button Name="ShowDashboardButton"  Content="Show Dashboard"   Width="150" Margin="5"/>
        </StackPanel>
    </Grid>
</Window>
"@

#───────────────────────────────────────────────────────────────────────────────
#  Wire‑up
#───────────────────────────────────────────────────────────────────────────────
$reader  = New-Object System.Xml.XmlNodeReader $xaml
$window  = [Windows.Markup.XamlReader]::Load($reader)

$noteInput            = $window.FindName('NoteInput')
$categoryInput        = $window.FindName('CategoryInput')
$reminderInput        = $window.FindName('ReminderInput')
$searchBox            = $window.FindName('SearchBox')
$notesList            = $window.FindName('NotesList')
$addNoteButton        = $window.FindName('AddNoteButton')
$organizeButton       = $window.FindName('OrganizeNotesButton')
$exportButton         = $window.FindName('ExportButton')
$boldButton           = $window.FindName('BoldButton')
$italicsButton        = $window.FindName('ItalicsButton')
$bulletButton         = $window.FindName('BulletButton')
$toggleDarkModeButton = $window.FindName('ToggleDarkModeButton')
$showDashboardButton  = $window.FindName('ShowDashboardButton')
$actionButtonsPanel   = $window.FindName('ActionButtonsPanel')

#───────────────────────────────────────────────────────────────────────────────
#  Helpers
#───────────────────────────────────────────────────────────────────────────────
function Update-NotesList {
    $notesList.Items.Clear()
    foreach ($note in $notes) {
        $catTxt = if ($note.Category) { " [$($note.Category)]" } else { '' }
        $remTxt = if ($note.Reminder) { " (Reminder: $($note.Reminder))" } else { '' }
        $notesList.Items.Add("$($note.Timestamp)$catTxt$remTxt – $($note.Content)")
    }
}
Update-NotesList

function Set-Theme([bool]$isDark) {
    $bg = if ($isDark) { 'Black' } else { 'White' }
    $fg = if ($isDark) { 'White' } else { 'Black' }
    foreach ($ctrl in @($window,$noteInput,$categoryInput,$reminderInput,$searchBox,$notesList)) {
        $ctrl.Background = $bg
        $ctrl.Foreground = $fg
    }
}
Set-Theme ($script:config.DarkMode)

#───────────────────────────────────────────────────────────────────────────────
#  Event handlers
#───────────────────────────────────────────────────────────────────────────────
$addNoteButton.Add_Click({
    $noteText     = $noteInput.Text.Trim()
    $categoryText = $categoryInput.Text.Trim()
    $reminderText = $reminderInput.Text.Trim()
    if ($noteText) {
        $script:notes += [pscustomobject]@{
            Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
            Content   = $noteText
            Category  = $categoryText
            Reminder  = $reminderText
        }
        Export-Notes
        Update-NotesList
        $noteInput.Clear(); $categoryInput.Clear(); $reminderInput.Clear()
    }
})

$searchBox.Add_TextChanged({
    $q = $searchBox.Text.Trim().ToLower()
    $notesList.Items.Clear()
    foreach ($note in $notes) {
        $hit = ($note.Content.ToLower() -like "*$q*") -or (($note.Category) -and ($note.Category.ToLower() -like "*$q*"))
        if ($hit) {
            $catTxt = if ($note.Category) { " [$($note.Category)]" } else { '' }
            $remTxt = if ($note.Reminder) { " (Reminder: $($note.Reminder))" } else { '' }
            $notesList.Items.Add("$($note.Timestamp)$catTxt$remTxt – $($note.Content)")
        }
    }
})

$organizeButton.Add_Click({
    $script:notes = $notes | Sort-Object Category, { [datetime]$_.Timestamp }
    Update-NotesList
    Export-Notes
})

$exportButton.Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = 'Markdown (*.md)|*.md|Text (*.txt)|*.txt'
    $dlg.Title  = 'Export Notes'
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $sb = [System.Text.StringBuilder]::new()
        foreach ($note in $notes) {
            if ($note.Category) { $null = $sb.AppendLine("**Category:** $($note.Category)") }
            if ($note.Reminder) { $null = $sb.AppendLine("**Reminder:** $($note.Reminder)") }
            $null = $sb.AppendLine("### $($note.Timestamp)")
            $null = $sb.AppendLine($note.Content)
            $null = $sb.AppendLine()
        }
        $sb.ToString() | Set-Content -LiteralPath $dlg.FileName -Encoding UTF8
        [System.Windows.MessageBox]::Show("Notes exported to $($dlg.FileName)",'Export Complete')
    }
})

$boldButton.Add_Click({
    if ($noteInput.SelectionLength -gt 0) {
        $s = $noteInput.SelectionStart
        $l = $noteInput.SelectionLength
        $noteInput.Text = $noteInput.Text.Insert($s + $l, '**').Insert($s, '**')
        $noteInput.Select($s, $l + 4)
    }
})

$italicsButton.Add_Click({
    if ($noteInput.SelectionLength -gt 0) {
        $s = $noteInput.SelectionStart
        $l = $noteInput.SelectionLength
        $noteInput.Text = $noteInput.Text.Insert($s + $l, '_').Insert($s, '_')
        $noteInput.Select($s, $l + 2)
    }
})

$bulletButton.Add_Click({
    $noteInput.Text = "$( [char]0x2022) $($noteInput.Text)"
})

$toggleDarkModeButton.Add_Click({
    $script:config.DarkMode = -not ($script:config.DarkMode)
    Set-Theme ($script:config.DarkMode)
    Export-Config
})

$showDashboardButton.Add_Click({
    $total   = $notes.Count
    $byCat   = $notes | Group-Object Category |
               ForEach-Object { "{0}: {1}" -f ($_.Name ?? '<none>'), $_.Count } |
               Sort-Object
    $byMonth = $notes | Group-Object { $_.Timestamp.Substring(0,7) } |
               ForEach-Object { "{0}: {1}" -f $_.Name, $_.Count } |
               Sort-Object

    $byCatText = if ($byCat) { $byCat -join "`n" } else { "<none>" }
    $byMonthText = if ($byMonth) { $byMonth -join "`n" } else { "<none>" }

    $msg = "Total Notes: $total`n`nNotes by Category:`n$byCatText`n`nNotes by Month:`n$byMonthText"
    [System.Windows.MessageBox]::Show($msg,'Dashboard Analytics')
})

# Refined the logic for selecting and editing a note to ensure proper matching.
$notesList.Add_SelectionChanged({
    if ($notesList.SelectedItem) {
        $selectedNote = $notes | Where-Object {
            "$($_.Timestamp) [$($_.Category)] (Reminder: $($_.Reminder)) – $($_.Content)" -eq $notesList.SelectedItem
        } | Select-Object -First 1
        if ($selectedNote) {
            $noteInput.Text = $selectedNote.Content
            $categoryInput.Text = $selectedNote.Category
            $reminderInput.Text = $selectedNote.Reminder
        }
    }
})

$editNoteButton = New-Object System.Windows.Controls.Button
$editNoteButton.Content = "Edit Note"
$editNoteButton.Width = 100
$editNoteButton.Margin = "5"
$editNoteButton.Add_Click({
    if ($notesList.SelectedItem) {
        $selectedNote = $notes | Where-Object {
            "$($_.Timestamp) [$($_.Category)] (Reminder: $($_.Reminder)) – $($_.Content)" -eq $notesList.SelectedItem
        } | Select-Object -First 1
        if ($selectedNote) {
            $selectedNote.Content = $noteInput.Text.Trim()
            $selectedNote.Category = $categoryInput.Text.Trim()
            $selectedNote.Reminder = $reminderInput.Text.Trim()
            Export-Notes
            Update-NotesList
            $noteInput.Clear(); $categoryInput.Clear(); $reminderInput.Clear()
        }
    }
})

# Add the Edit Note button to the existing action buttons panel.
$actionButtonsPanel = $window.FindName('ActionButtonsPanel')
if ($actionButtonsPanel) {
    $actionButtonsPanel.Children.Add($editNoteButton)
} else {
    $toggleDarkModeButton.Parent.Children.Add($editNoteButton)
}

# Reminder timer (checks every 60 s)
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(60)
$timer.Add_Tick({
    $now   = Get-Date
    $dirty = $false
    foreach ($note in $notes) {
        if ($note.Reminder -and -not $note.Alerted) {
            $parsed = [datetime]::MinValue
            if ([datetime]::TryParse($note.Reminder,[ref]$parsed) -and $parsed -le $now) {
                [System.Windows.MessageBox]::Show("Reminder Due:`n$($note.Content)", 'Reminder')
                $note.Alerted = $true
                $dirty = $true
            }
        }
    }
    if ($dirty) { Export-Notes }
})

$timer.Start()

#───────────────────────────────────────────────────────────────────────────────
#  Run
#───────────────────────────────────────────────────────────────────────────────
$window.ShowDialog() | Out-Null
