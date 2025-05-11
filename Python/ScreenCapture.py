import numpy as np
from PIL import ImageGrab
import time

def capture_screen():
    # Capture the screen
    screenshot = ImageGrab.grab()
    return np.array(screenshot)

def compare_screens(screen1, screen2):
    # Compare two screens
    if not np.array_equal(screen1, screen2):
        return True
    return False

def main():
    # Initial screenshot
    last_screen = capture_screen()

    while True:
        time.sleep(5)  # Delay in seconds
        current_screen = capture_screen()

        if compare_screens(last_screen, current_screen):
            print("Screen has changed!")

        last_screen = current_screen

if __name__ == "__main__":
    main()
