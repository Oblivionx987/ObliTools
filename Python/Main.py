import pyautogui
import cv2
import numpy as np
import pygetwindow as gw
import time
import random

title = "Call of Dragons"  # Replace with the title of your window
def activate_window():
    window = gw.getWindowsWithTitle(title)[0]
    if window:
        window.activate()
        print("Window activated.")
        return True
    else:
        print("Window not found!")
        return False
## Compare help image to screen
def find_and_help_alliance(image_path_help):
    if not activate_window():
        return False
    # Take a screenshot
    screenshot = pyautogui.screenshot()
    screenshot = np.array(screenshot)
    screenshot = cv2.cvtColor(screenshot, cv2.COLOR_RGB2BGR)

    # Load the image you are looking for
    template = cv2.imread(image_path_help, cv2.IMREAD_COLOR)

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
image_path_help = 'C:/Users/Zeth9/Pictures/AllinaceCenHelp.png'  # Replace with your image's file path
if find_and_help_alliance(image_path_help):
    print("Helped the Alliance.")
else:
    print("Image not found. or No one to help.")
## Compare wood image to screen
def find_and_get_wood(image_path_wood):
    if not activate_window():
        return False
    # Take a screenshot
    screenshot = pyautogui.screenshot()
    screenshot = np.array(screenshot)
    screenshot = cv2.cvtColor(screenshot, cv2.COLOR_RGB2BGR)

    # Load the image you are looking for
    template = cv2.imread(image_path_wood, cv2.IMREAD_COLOR)

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
image_path_wood = 'C:/Users/Zeth9/Pictures/Wood.png'  # Replace with your image's file path
if find_and_get_wood(image_path_wood):
    print("Got Wood Boss.")
else:
    print("No Wood Found.")
## Compare gold image to screen
def find_and_get_gold(image_path_gold):
    if not activate_window():
        return False
    # Take a screenshot
    screenshot = pyautogui.screenshot()
    screenshot = np.array(screenshot)
    screenshot = cv2.cvtColor(screenshot, cv2.COLOR_RGB2BGR)

    # Load the image you are looking for
    template = cv2.imread(image_path_gold, cv2.IMREAD_COLOR)

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
image_path_gold = 'C:/Users/Zeth9/Pictures/Gold.png'  # Replace with your image's file path
if find_and_get_gold(image_path_gold):
    print("Got Gold Boss.")
else:
    print("No Gold Found.")
## Compare stone image to screen
def find_and_get_stone(image_path_stone):
    if not activate_window():
        return False
    # Take a screenshot
    screenshot = pyautogui.screenshot()
    screenshot = np.array(screenshot)
    screenshot = cv2.cvtColor(screenshot, cv2.COLOR_RGB2BGR)

    # Load the image you are looking for
    template = cv2.imread(image_path_stone, cv2.IMREAD_COLOR)

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
image_path_stone = 'C:/Users/Zeth9/Pictures/Stone.png'  # Replace with your image's file path
if find_and_get_stone(image_path_stone):
    print("Got Stone Boss.")
else:
    print("No Stone Found.")
## Compare mana image to screen
def find_and_get_mana(image_path_mana):
    if not activate_window():
        return False
    # Take a screenshot
    screenshot = pyautogui.screenshot()
    screenshot = np.array(screenshot)
    screenshot = cv2.cvtColor(screenshot, cv2.COLOR_RGB2BGR)

    # Load the image you are looking for
    template = cv2.imread(image_path_mana, cv2.IMREAD_COLOR)

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
image_path_mana = 'C:/Users/Zeth9/Pictures/Mana.png'  # Replace with your image's file path
if find_and_get_mana(image_path_mana):
    print("Got Mana Boss.")
else:
    print("No Mana Found.")

def main():
    last_time_wood = last_time_stone = last_time_gold = last_time_mana = time.time()
    help_interval = random.randint(10, 60)  # Random interval for help
    last_time_help = time.time() - help_interval  # Subtract to trigger immediately

    while True:
        current_time = time.time()

        # Check for help
        if current_time - last_time_help > help_interval:
            if find_and_help_alliance(image_path_help):
                print("Helped the Alliance.")
            else:
                print("Image not found. or No one to help.")
            help_interval = random.randint(10, 60)
            last_time_help = current_time

        # Check for resources every 30 minutes
        if current_time - last_time_wood > 1800:  # 1800 seconds = 30 minutes
            if find_and_get_wood(image_path_wood):
                print("Got Wood Boss.")
            else:
                print("No Wood Found.")
            last_time_wood = current_time

        if current_time - last_time_stone > 1800:
            if find_and_get_stone(image_path_stone):
                print("Got Stone Boss.")
            else:
                print("No Stone Found.")
            last_time_stone = current_time

        if current_time - last_time_gold > 1800:
            if find_and_get_gold(image_path_gold):
                print("Got Gold Boss.")
            else:
                print("No Gold Found.")
            last_time_gold = current_time

        if current_time - last_time_mana > 1800:
            if find_and_get_mana(image_path_mana):
                print("Got Mana Boss.")
            else:
                print("No Mana Found.")
            last_time_mana = current_time

        time.sleep(1)  # Sleep to prevent CPU overload

# Call the main function
if __name__ == "__main__":
    main()