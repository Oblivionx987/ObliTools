import ctypes
import time
import psutil

# Function to move window to the specified position
def move_window(hwnd, x, y):
    ctypes.windll.user32.SetWindowPos(hwnd, -1, x, y, 0, 0, 0x0002)

# Function to find the window handle of the "launcher.exe" process
def find_window_handle(process_name):
    for proc in psutil.process_iter():
        if proc.name() == process_name:
            if psutil.WINDOWS:  # Check if the current platform is Windows
                for window in proc.windows():
                    if window.name() == process_name:
                        return window.hwnd
            else:
                print("This script only supports Windows.")
                return None
    return None

# Main function
def main():
    process_name = "launcher.exe"
    target_hwnd = find_window_handle(process_name)

    if target_hwnd is not None:
        # Bring the window to the front
        ctypes.windll.user32.SetForegroundWindow(target_hwnd)

        # Move the window to the specified position
        move_window(target_hwnd, 100, 100)

    else:
        print(f"No window found for process: {process_name}")

if __name__ == "__main__":
    main()