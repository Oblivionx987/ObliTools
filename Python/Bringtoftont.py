import pygetwindow as gw
import pyautogui

title = "Call of Dragons"  # Replace with the title of your window
window = gw.getWindowsWithTitle(title)[0]  # Find the window by title
if window:
    window.activate()  # Bring the window to the front
    print("Located Window, Brought To Front")
else:
    print("Window not found!")
