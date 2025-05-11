Clear-Host
$CCMComObject = New-Object -ComObject 'UIResource.UIResourceMgr'
$CacheInfo    = $($CCMComObject.GetCacheInfo().GetCacheElements())
$Updates      = (Get-CimInstance -Namespace 'Root\ccm\SoftwareUpdates\UpdatesStore' -ClassName 'CCM_UpdateStatus' -Verbose:$False) | Sort-Object -Property Title

$ClassificationType = @{
"5C9376AB-8CE6-464A-B136-22113DD69801" = "Application"
"434DE588-ED14-48F5-8EED-A15E09A991F6" = "Connectors"
"E6CF1350-C01B-414D-A61F-263D14D133B4" = "CriticalUpdates"
"E0789628-CE08-4437-BE74-2495B842F43B" = "DefinitionUpdates"
"E140075D-8433-45C3-AD87-E72345B36078" = "DeveloperKits"
"B54E7D24-7ADD-428F-8B75-90A396FA584F" = "FeaturePacks"
"9511D615-35B2-47BB-927F-F73D8E9260BB" = "Guidance"
"0FA1201D-4330-4FA8-8AE9-B877473B6441" = "SecurityUpdates"
"68C5B0A3-D1A6-4553-AE49-01D3A7827828" = "ServicePacks"
"B4832BD8-E735-4761-8DAF-37F882276DAB" = "Tools"
"28BC880E-0592-4CBF-8F95-C79B17911D5F" = "UpdateRollups"
"CD5FFD1E-E932-4E3A-BF74-18BF0B1BBD83" = "Updates"} 

ForEach ($Update in $Updates)
 {
   Write-Host "Updates: Bulletin ID:                $($Update.Article)"
   Write-Host "Updates: Title:                      $($Update.Title)"
   Write-Host "Updates: Status:                     $($Update.Status)"
   Write-Host "Updates: ProductID:                  $($Update.ProductID)"
   Write-Host "Updates: Revision number:            $($Update.RevisionNumber)"
   Write-Host "Updates: Unqiue ID:                  $($Update.UniqueID)"
   Write-Host "Updates: Classification:             $($ClassificationType.Item($($Update.UpdateClassification)))"
   $UpdateCacheInfo = $CacheInfo | Where-Object { $_.ContentID -eq $Update.UniqueID}
   if( $UpdateCacheInfo)
    {
     Write-Host "Updates: Content ID:                 $($UpdateCacheInfo.ContentID)"
     Write-Host "Updates: Location:                   $($UpdateCacheInfo.Location)"
     Write-Host "Updates: Content size:               $('{0:N2}' -f $($UpdateCacheInfo.ContentSize / 1KB))"
     Write-Host "Updates: Last Reference Time:        $($UpdateCacheInfo.LastReferenceTime)"
     }
    Write-Host "--------------------"

 }