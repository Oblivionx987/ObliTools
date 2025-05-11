Clear-Host

$CCMComObject = New-Object -ComObject 'UIResource.UIResourceMgr'
$CacheInfo    = $($CCMComObject.GetCacheInfo().GetCacheElements())

$EnforcePreference = @{
0 = "Immediate"
1 = "NonBusinessHours"
2 = "AdminSchedule"
}

$EvaluationSate = @{
0 = "No state information is available."
1 = "Application is enforced to desired/resolved state."
2 = "Application is not required on the client."
3 = "Application is available for enforcement (install or uninstall based on resolved state). Content may/may not have been downloaded."
4 = "Application last failed to enforce (install/uninstall)."
5 = "Application is currently waiting for content download to complete."
6 = "Application is currently waiting for content download to complete."
7 = "Application is currently waiting for its dependencies to download."
8 = "Application is currently waiting for a service (maintenance) window."
9 = "Application is currently waiting for a previously pending reboot."
10 = "Application is currently waiting for serialized enforcement."
11 = "Application is currently enforcing dependencies."
12 = "Application is currently enforcing."
13 = "Application install/uninstall enforced and soft reboot is pending."
14 = "Application installed/uninstalled and hard reboot is pending."
15 = "Update is available but pending installation."
16 = "Application failed to evaluate."
17 = "Application is currently waiting for an active user session to enforce."
18 = "Application is currently waiting for all users to logoff."
19 = "Application is currently waiting for a user logon."
20 = "Application in progress, waiting for retry."
21 = "Application is waiting for presentation mode to be switched off."
22 = "Application is pre-downloading content (downloading outside of install job)."
23 = "Application is pre-downloading dependent content (downloading outside of install job)."
24 = "Application download failed (downloading during install job)."
25 = "Application pre-downloading failed (downloading outside of install job)."
26 = "Download success (downloading during install job)."
27 = "Post-enforce evaluation."
28 = "Waiting for network connectivity."
}

ForEach ($Application in (Get-CimInstance -Namespace "Root\ccm\ClientSDK" -ClassName 'CCM_Application'))
 {
  $AppDTS = ($Application | Get-CimInstance).AppDTs
  ForEach ($AppDT in $AppDTs)
   {
     ForEach ($ActionType in $AppDT.AllowedActions)
      {
                            $Arguments = [hashtable]@{
                            'AppDeliveryTypeID' = [string]$($AppDT.ID)
                            'Revision'          = [uint32]$($AppDT.Revision)
                            'ActionType'        = [string]$($ActionType)}
        $AppContentID = (Invoke-CimMethod -Namespace 'Root\ccm\cimodels' -ClassName 'CCM_AppDeliveryType' -MethodName 'GetContentInfo' -Arguments $Arguments -Verbose:$false).ContentID
        Write-Host "Application: Name:                 $($Application.Name)"
        Write-Host "Application: Enforce preference:   $($EnforcePreference.Item([int]$($Application.EnforcePreference)))"
        Write-Host "Application: Evaluation:           $($EvaluationSate.Item([int]$($Application.EvaluationState)))"
        Write-Host "Application: Deployment Type name: $($AppDT.Name)"
        Write-Host "Application: Action:               $($ActionType)"
        $AppCacheInfo = $CacheInfo | Where-Object { $($_.ContentID) -eq $AppContentID }
        if($AppCacheInfo)
         {
          Write-Host "Application: Content ID:           $($AppCacheInfo.ContentID)"
          Write-Host "Application: Location:             $($AppCacheInfo.Location)"
          Write-Host "Application: Content size:         $('{0:N2}' -f $($AppCacheInfo.ContentSize / 1KB))Mb"
          Write-Host "Application: Last Reference time:  $($AppCacheInfo.LastReferenceTime)"
         }
        Write-Host "---------------------------------------------------------------------------------------"
      }
   }
 }




 ## Last Tested On 3-11-2024
 ## Status : WORKING