Clear-Host
$CCMComObject = New-Object -ComObject 'UIResource.UIResourceMgr'
$CacheInfo    = $($CCMComObject.GetCacheInfo().GetCacheElements())
$Packages     = Get-CimInstance -Namespace 'ROOT\ccm\Policy\Machine\RequestedConfig' -ClassName 'CCM_SoftwareDistribution' -Verbose:$false

ForEach ($Package in $Packages)
 {
  Write-Host "Package: Name:                 $($Package.PKG_MIFName)"
  Write-Host "Package: Progam:               $($Package.PRG_ProgramID)"
  $PkgCacheInfo = $CacheInfo | Where-Object { $_.ContentID -eq $Package.PKG_PackageID }

  if(($($PkgCacheInfo | Measure-Object).Count) -gt 1){$PkgCacheInfo1 = $PkgCacheInfo[-1]} else {$PkgCacheInfo1 = $PkgCacheInfo}

  ForEach ($CacheItem in $PkgCacheInfo1)
   {
    If ($CacheItem) 
     {
      #  Set content size to 0 if null to avoid division by 0
     If ($CacheItem.ContentSize -eq 0) { [int]$PkgContentSize = 0 } Else { [int]$PkgContentSize = $($CacheItem.ContentSize) }
        Write-Host "Package: Content ID:           $($CacheItem.ContentID)"
        Write-Host "Package: Location:             $($CacheItem.Location)"
        Write-Host "Package: Content size          $('{0:N2}' -f $($PkgContentSize / 1KB))Mb"
        Write-Host "Package: Last reference time:  $($CacheItem.LastReferenceTime)"
     }
    }
    Write-Host "------------------"
    
   }