import pyautogui
import cv2
import numpy as np

def find_and_click(image_path):
    # Take a screenshot
    screenshot = pyautogui.screenshot()
    screenshot = np.array(screenshot)
    screenshot = cv2.cvtColor(screenshot, cv2.COLOR_RGB2BGR)

    # Load the image you are looking for
    template = cv2.imread(image_path, cv2.IMREAD_COLOR)

    # Perform template matching
    res = cv2.matchTemplate(screenshot, template, cv2.TM_CCOEFF_NORMED)
    threshold = 0.8
    loc = np.where(res >= threshold)

    for pt in zip(*loc[::-1]):  # Switch collumns and rows
        # Calculate the center of the found image
        center_x = pt[0] + template.shape[1] // 2
        center_y = pt[1] + template.shape[0] // 2

        # Click the center of the image
        pyautogui.click(center_x, center_y)
        return True

    return False

# Usage
image_path = 'C:/Users/Zeth9/Pictures/AllinaceCenHelp.png'  # Replace with your image's file path
if find_and_click(image_path):
    print("Image found and clicked.")
else:
    print("Image not found.")
