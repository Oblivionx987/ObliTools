ECHO Off

cd C:\Program Files (x86)\Dell\CommandUpdate

dcu-cli /version

dcu-cli /configure -biosPassword="Tiosccpw" -silent

dcu-cli.exe /configure -scheduleAuto -silent

DellCommandUpdate.exe

Exit