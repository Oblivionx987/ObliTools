import psutil

def get_pid_by_name(process_name):
    for proc in psutil.process_iter(['pid', 'name']):
        if proc.info['name'].lower() == process_name.lower():
            return proc.pid
    return None

# Example usage: Get the PID of "notepad.exe"
launcherpid = get_pid_by_name("launcher.exe")
if launcherpid:
    print("PID of Launcher:", launcherpid)
else:
    print("Launcher is not running.")


launcher2pid = get_pid_by_name("CALLOFDRAGONS.exe")
if launcher2pid:
    print("PID of Launcher 2:", launcher2pid)
else:
    print("Laumcher 2 is not running")