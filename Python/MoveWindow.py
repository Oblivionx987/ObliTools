import pygetwindow as gw

def move_window_by_pid(pid, x, y):
    # Find the window based on the PID
    window = gw.getWindowsWithTitle(pid=pid)
    if window:
        # Move the window to the desired position
        window[0].move(x, y)
    else:
        print("Window with PID {} not found.".format(pid))

# Example usage: Move window with PID 1234 to coordinates (100, 100)
move_window_by_pid(16080, 100, 100)
