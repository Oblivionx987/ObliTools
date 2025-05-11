## Begining Application
print("Starting Up")


import subprocess
import time

def launch_exe(exe_path):
    subprocess.call(exe_path, shell=True)

def get_process_duration(pid):
    try:
        proc_info = subprocess.check_output(['wmic', 'process', 'where', f'ProcessId={pid}', 'get', 'CreationDate'])
        proc_start_time = proc_info.decode('utf-8').strip().split('\n')[1].strip()
        proc_start_time = time.strptime(proc_start_time, "%Y%m%d%H%M%S.%f")
        proc_start_time = time.mktime(proc_start_time)
        return time.time() - proc_start_time
    except subprocess.CalledProcessError:
        return None

def format_time(seconds):
    hours, remainder = divmod(seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    return "{:02}:{:02}:{:02}".format(int(hours), int(minutes), int(seconds))

if __name__ == "__main__":
    exe_path = r"C:\Program Files (x86)\Call of Dragons\Call of Dragons Game\CALLOFDRAGONS.exe"
    launch_exe(exe_path)

    while True:
        time.sleep(30)  # 30-second delay
        proc = subprocess.Popen(["tasklist", "/FI", f"IMAGENAME eq {exe_path}"], stdout=subprocess.PIPE)
        output = proc.stdout.read().decode("utf-8")
        if exe_path in output:
            pid = int(output.split()[1])
            exe_duration = get_process_duration(pid)
            print(f"Python script running for: {format_time(time.time())}")
            print(f"{exe_path} running for: {format_time(exe_duration)}")
        else:
            print(f"{exe_path} not running. Launching...")
            launch_exe(exe_path)
