import pyautogui
import time
from PIL import ImageGrab
import os

## Resolution - 1,366 x 768 Positioned top right


# Define the areas to click (x, y coordinates)
click_areas = [
    (1275, 200), (1250, 265), (575, 55),  # R5 Seat 0 - 0 1 2
    (1275, 340), (1250, 400), (575, 55),  # R4 Seat 1 - 3 4 5 
    (1545, 340), (1515, 400), (575, 55),  # R4 Seat 2 - 5 6 7
    (1275, 415), (1240, 475), (575, 55),  # R4 Seat 3 - 8 9 10
    (1545, 415), (1515, 475), (575, 55),  # R4 Seat 4 - 11 12 13
    (1275, 490), (1240, 550), (575, 55),  # R4 Seat 5 - 14 15 16
    (1545, 490), (1515, 550), (575, 55),  # R4 Seat 6 - 17 18 19
    (1275, 565), (1240, 625), (575, 55),  # R4 Seat 7 - 20 21 22
    (1545, 565), (1515, 625), (575, 55),  # R4 Seat 8 - 23 24 25
]  # Modify these coordinates as needed

# Define the folder to save the screenshot
save_folder = r"C:\Users\Zeth9\Pictures\DataColl"  # Modify this path as needed
if not os.path.exists(save_folder):
    os.makedirs(save_folder)

# Define the bounding box for the area to capture (left, top, right, bottom)
capture_box = (550, 100, 1918, 800)  # Modify these values as needed

def take_screenshot(filename):
    """
    Takes a screenshot of the specified area and saves it with the given filename.
    
    :param filename: Name of the file to save the screenshot as (including .png extension)
    """
    try:
        screenshot = ImageGrab.grab(bbox=capture_box)
        screenshot.save(os.path.join(save_folder, filename))
        print(f"Screenshot saved as {filename}")
    except Exception as e:
        print(f"Failed to take screenshot: {e}")

def click_and_capture(click_indices, filename):
    """
    Clicks on specified areas and takes a screenshot between the second and third clicks.
    
    :param click_indices: List of indices in the click_areas array
    :param filename: Name of the file to save the screenshot as (including .png extension)
    """
    try:
        for i, index in enumerate(click_indices):
            pyautogui.click(click_areas[index])
            time.sleep(1.5)  # Adding delay to ensure the action is completed
            if i == 1:  # Take a screenshot after the second click
                take_screenshot(filename)
    except Exception as e:
        print(f"Failed to click or capture: {e}")

# Example usage
click_and_capture([0, 1, 2], "1.png")
#click_and_capture([3, 4, 5], "2.png")
click_and_capture([6, 7, 8], "3.png")
click_and_capture([9, 10, 11], "4.png")
click_and_capture([12, 13, 14], "5.png")
click_and_capture([15, 16, 17], "6.png")
click_and_capture([18, 19, 20], "7.png")
click_and_capture([21, 22, 23], "8.png")
click_and_capture([24, 25, 26], "9.png")

# Scroll wheel down (if needed)
pyautogui.scroll(-500)  # Adjust the value for the amount of scrolling

print("Script completed successfully.")
