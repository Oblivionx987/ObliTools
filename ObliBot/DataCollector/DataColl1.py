import pyautogui
from PIL import Image
import pytesseract
import pandas as pd
from datetime import datetime
import os

# Configure the path to the Tesseract executable
pytesseract.pytesseract.tesseract_cmd = r'C:\Users\Jessica\AppData\Local\Programs\Tesseract-OCR\tesseract.exe'

# Function to capture a screenshot of the game window
def capture_screenshot(region):
    screenshot = pyautogui.screenshot(region=region)
    return screenshot

# Function to extract text from an image using OCR
def extract_text_from_image(image):
    text = pytesseract.image_to_string(image)
    return text

# Function to process the extracted text
def process_text(text):
    # Example processing - split lines and extract relevant data
    lines = text.split('\n')
    members_data = []
    for line in lines:
        if line.strip():
            parts = line.split()  # Assuming the data is space-separated
            if len(parts) >= 8:  # Ensure there are enough parts to unpack
                member_data = {
                    'Name': parts[0],
                    'Personal Power': parts[1],
                    'Personal Merit': parts[2],
                    'Glory Points': parts[3],
                    'Alliance Donation': parts[4],
                    'Build Time': parts[5],
                    'Alliance Help': parts[6],
                    'Resource Assistance': parts[7]
                }
                members_data.append(member_data)
            else:
                print(f"Skipping line due to insufficient data: {line}")
    return members_data

# Function to update the Excel file
def update_excel_file(data):
    file_path = r'C:\Users\Jessica\Desktop\test1.xlsx'
    
    try:
        existing_df = pd.read_excel(file_path)
    except FileNotFoundError:
        existing_df = pd.DataFrame()

    new_df = pd.DataFrame(data)
    new_df['Date'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    updated_df = pd.concat([existing_df, new_df], ignore_index=True)
    updated_df.to_excel(file_path, index=False)
    print(f'Data updated successfully in {file_path}')

# Main function to run the bot
def run_bot():
    # Define the region of the screen to capture (left, top, width, height)
    region = (1145, 206, 816, 639)  # Adjust these values to match the game window
    screenshot = capture_screenshot(region)
    
    # Optionally save the screenshot for debugging
    screenshot_path = os.path.join(os.path.expanduser('~'), 'screenshot.png')
    screenshot.save(screenshot_path)
    print(f'Screenshot saved at {screenshot_path}')
    
    text = extract_text_from_image(screenshot)
    print(f"Extracted text: {text}")
    
    game_data = process_text(text)
    print(f"Processed data: {game_data}")
    
    update_excel_file(game_data)

if __name__ == '__main__':
    run_bot()
