import pyautogui
import time
import random

def random_click(x, y):
    # Remember the current mouse position
    current_mouse_x, current_mouse_y = pyautogui.position()

    # Wait for a random time between 10 and 40 seconds
    time.sleep(random.uniform(10, 40))

    # Move the mouse to the specified location and click
    pyautogui.click(x, y)

    # Move the mouse back to its original position
    pyautogui.moveTo(current_mouse_x, current_mouse_y)

# Loop indefinitely
while True:
    random_click(1671, 936)  # Replace 1754, 972 with your desired x and y coordinates
