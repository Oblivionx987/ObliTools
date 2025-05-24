
$live = "WIP"
$bmgr = "WIP"
$Author = "Seth Burns - System Administarator II - Service Center"
$description = "Script for Installing all RSAT tools from internal repository"
$version = "1.0.0"


Get-WindowsCapability -Online -Name RSAT* | Add-WindowsCapability -Online -LimitAccess -Source "\\salpsccmpss01\cmsource$\core\Windows 10 FeaturesOnDemand\Win11 24H2\SW_DVD9_Win_11_24H2_x64_MultiLang_LangPackAll_LIP_LoF_X23-69888\LanguagesAndOptionalFeatures"