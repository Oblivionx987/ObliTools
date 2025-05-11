# Load required assemblies
Add-Type -AssemblyName PresentationFramework

# Create the WPF window
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Robocopy GUI" Height="400" Width="600">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <TextBlock Grid.Row="0" Grid.Column="0" Margin="10" VerticalAlignment="Center">Source Path:</TextBlock>
        <TextBox Name="SourcePath" Grid.Row="0" Grid.Column="1" Margin="10"/>

        <TextBlock Grid.Row="1" Grid.Column="0" Margin="10" VerticalAlignment="Center">Destination Path:</TextBlock>
        <TextBox Name="DestinationPath" Grid.Row="1" Grid.Column="1" Margin="10"/>

        <StackPanel Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="2" Margin="10">
            <CheckBox Name="ChkMirror" Content="Mirror (Deletes files not in the source)" ToolTip="Mirrors a directory tree (deletes files not in the source)."/>
            <CheckBox Name="ChkMove" Content="Move (Move files and directories)" ToolTip="Moves files and directories, deleting them from the source after they are copied."/>
            <CheckBox Name="ChkPurge" Content="Purge (Delete destination files/dirs that no longer exist in source)" ToolTip="Deletes destination files/dirs that no longer exist in the source."/>
            <CheckBox Name="ChkCopyAll" Content="CopyAll (Copy all file info)" ToolTip="Copies all file information (equivalent to /COPYALL)."/>
            <CheckBox Name="ChkE" Content="E (Copies subdirectories, including empty ones)" ToolTip="Copies all subdirectories, including empty ones."/>
            <CheckBox Name="ChkXO" Content="XO (Excludes older files)" ToolTip="Excludes older files (files that are older in the destination)."/>
            <CheckBox Name="ChkXN" Content="XN (Excludes newer files)" ToolTip="Excludes newer files (files that are newer in the destination)."/>
            <CheckBox Name="ChkR" Content="R (Retries on failed copies)" ToolTip="Specifies the number of retries on failed copies."/>
        </StackPanel>

        <Button Name="BtnRun" Grid.Row="3" Grid.Column="1" Margin="10" HorizontalAlignment="Right">Run</Button>
    </Grid>
</Window>
"@

# Load the XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Assign variables to the controls
$SourcePath = $window.FindName("SourcePath")
$DestinationPath = $window.FindName("DestinationPath")
$ChkMirror = $window.FindName("ChkMirror")
$ChkMove = $window.FindName("ChkMove")
$ChkPurge = $window.FindName("ChkPurge")
$ChkCopyAll = $window.FindName("ChkCopyAll")
$ChkE = $window.FindName("ChkE")
$ChkXO = $window.FindName("ChkXO")
$ChkXN = $window.FindName("ChkXN")
$ChkR = $window.FindName("ChkR")
$BtnRun = $window.FindName("BtnRun")

# Define the event handler for the Run button
$BtnRun.Add_Click({
    $src = $SourcePath.Text
    $dst = $DestinationPath.Text

    # Construct the Robocopy command
    $options = ""
    if ($ChkMirror.IsChecked) { $options += "/MIR " }
    if ($ChkMove.IsChecked) { $options += "/MOV " }
    if ($ChkPurge.IsChecked) { $options += "/PURGE " }
    if ($ChkCopyAll.IsChecked) { $options += "/COPYALL " }
    if ($ChkE.IsChecked) { $options += "/E " }
    if ($ChkXO.IsChecked) { $options += "/XO " }
    if ($ChkXN.IsChecked) { $options += "/XN " }
    if ($ChkR.IsChecked) { $options += "/R:5 " }

    $command = "Robocopy `"$src`" `"$dst`" $options"
    Write-Output "Executing: $command"

    # Execute the Robocopy command
    Start-Process -NoNewWindow -FilePath "powershell" -ArgumentList "-Command $command"
})

# Show the window
$window.ShowDialog()
