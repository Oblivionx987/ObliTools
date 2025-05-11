import pyautogui

# Get the screen resolution
screen_width, screen_height = pyautogui.size()

# Specify the coordinates where you want to click
x = screen_width // 2
y = screen_height // 2

# Emulate a mouse click at the specified coordinates
pyautogui.click(x, y)