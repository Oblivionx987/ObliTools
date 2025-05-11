import pytesseract
from pytesseract import Output
from PIL import Image
import pandas as pd
import os
import re
from concurrent.futures import ProcessPoolExecutor

# Configure the path to the Tesseract executable
pytesseract.pytesseract.tesseract_cmd = r'C:\Users\Zeth9\AppData\Local\Programs\Tesseract-OCR\tesseract.exe'  # Adjust this path

# Set the TESSDATA_PREFIX environment variable
os.environ['TESSDATA_PREFIX'] = r'C:\Users\Zeth9\AppData\Local\Programs\Tesseract-OCR\tessdata'  # Adjust this path

# Function to extract data from a specific area of the image
def extract_data_from_image(image_path):
    img = Image.open(image_path)

    # Define the bounding boxes (left, upper, right, lower) for each data variable
    player_id_box = (600, 170, 660, 185)  # Adjust these values
    name_box = (70, 188, 210, 210)       # Adjust these values
    power_box = (70, 330, 200, 358)     # Adjust these values
    merits_box = (525, 330, 665, 358)    # Adjust these values

    # Crop the image to the bounding box
    player_id_img = img.crop(player_id_box)
    name_img = img.crop(name_box)
    power_img = img.crop(power_box)
    merits_img = img.crop(merits_box)

    # Extract text from each cropped section with improved configuration
    custom_config = r'--oem 3 --psm 6'
    player_id = pytesseract.image_to_string(player_id_img, config=custom_config).strip()
    name = pytesseract.image_to_string(name_img, config=custom_config).strip()
    power = pytesseract.image_to_string(power_img, config=custom_config).strip()
    merits = pytesseract.image_to_string(merits_img, config=custom_config).strip()

    # Use regular expression to keep only numeric characters in player_id
    player_id = re.sub(r'\D', '', player_id)

    # Use regular expression to keep only alphabetic characters, numbers, and spaces in name
    name = re.sub(r'[^a-zA-Z0-9 ]', '', name)

    # Remove the words "Power" and "Merits" from the extracted text
    power = power.replace('Power', '').strip()
    merits = merits.replace('Merits', '').strip()

    # Log extracted values for debugging
    print(f"Extracted Player ID: {player_id}")
    print(f"Extracted Name: {name}")
    print(f"Extracted Power: {power}")
    print(f"Extracted Merits: {merits}")

    return name, player_id, power, merits

# Process images in parallel
def process_images_in_parallel(folder_path):
    extracted_data = []
    with ProcessPoolExecutor() as executor:
        futures = {executor.submit(extract_data_from_image, os.path.join(folder_path, filename)): filename 
                   for filename in os.listdir(folder_path) if filename.endswith('.png')}
        for future in futures:
            try:
                result = future.result()
                name, player_id, power, merits = result
                if player_id or name:
                    extracted_data.append((name, player_id, power, merits))
                    # Rename the file
                    old_filename = futures[future]
                    new_filename = f"{name}-{player_id}.png"
                    old_path = os.path.join(folder_path, old_filename)
                    new_path = os.path.join(folder_path, new_filename)
                    os.rename(old_path, new_path)
                else:
                    print(f"Could not extract player ID or name from {futures[future]}")
            except Exception as e:
                print(f"Error processing image: {e}")
    return extracted_data

if __name__ == '__main__':
    # Folder containing the images
    folder_path = r'G:\Other computers\My Computer\HP Data\DataStorage - DONT TOUCH\PlayerProfiles\07-22-PlayerProfiles'  # Adjust this path

    # Extract data from images
    extracted_data = process_images_in_parallel(folder_path)

    # Create a DataFrame
    df = pd.DataFrame(extracted_data, columns=['Name', 'Player ID', 'Power', 'Merits'])

    # Export the DataFrame to an Excel file
    df.to_excel(r'G:\Other computers\My Computer\HP Data\DataStorage - DONT TOUCH\PlayerProfiles\07-22-PlayerProfiles\extracted_data.xlsx', index=False)

    print('Data extraction complete. The file is saved as extracted_data.xlsx.')
