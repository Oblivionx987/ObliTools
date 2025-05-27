Start-Process powershell `
    -ArgumentList '-NoProfile','-WindowStyle','Hidden','-File','C:\Scripts\MyTask.ps1' `
    -Verb RunAs           # optional: elevate
