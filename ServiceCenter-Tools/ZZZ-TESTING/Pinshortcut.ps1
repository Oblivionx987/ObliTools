$shortcutpath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

$shell = New-Object -ComObject "Shell.Application"
$toolbarPath = $shell.Namespace(0x1c).Self.$path
$folderItem = $shell.Namespace($toolbarpath).ParseName((Split-Path - Leaf $shortcutPath))

## Check if shortcut already exists in the toolbar
if ($folderItem -ne $null) { 
    Write-Host "Shortcut already exists in the toolbar"
}
else {
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $folder = $shell.Namespace($toolbarPath)
    $folder.CopyHere($shortcut.path)
    Write-Host "Shortcut pinned to the toolbar successfully"
}


