import pytesseract
from PIL import Image
import pandas as pd
import re

# Path to the Tesseract executable
pytesseract.pytesseract.tesseract_cmd = r'C:\Users\Jessica\AppData\Local\Programs\Tesseract-OCR\tesseract.exe'

def image_to_text(image_path):
    """Extracts text from an image."""
    try:
        img = Image.open(image_path)
        text = pytesseract.image_to_string(img)
        return text
    except Exception as e:
        print(f"Error reading image {image_path}: {e}")
        return None

def parse_text_to_structure(text):
    """Parses extracted text to a structured format."""
    # Define the regex patterns or delimiters to extract specific data
    # Example structure: {"Name": "John Doe", "Date": "2024-07-14", "Value": "1234"}
    data = []

    # Regex to find specific patterns (example)
    pattern = re.compile(r'Name: (.+)\nDate: (.+)\nValue: (.+)')
    matches = pattern.findall(text)
    
    for match in matches:
        name, date, value = match
        data.append({"Name": name.strip(), "Date": date.strip(), "Value": value.strip()})

    return data

def data_to_excel(data, excel_path):
    """Writes structured data to an Excel file."""
    try:
        # Creating a DataFrame
        df = pd.DataFrame(data)
        # Writing to Excel
        df.to_excel(excel_path, index=False)
        print(f"Structured data has been written to {excel_path}")
    except Exception as e:
        print(f"Error writing to Excel {excel_path}: {e}")

def main(image_path, excel_path):
    text = image_to_text(image_path)
    if text:
        structured_data = parse_text_to_structure(text)
        if structured_data:
            data_to_excel(structured_data, excel_path)

if __name__ == "__main__":
    image_path = r'C:\Users\Jessica\Pictures\2024-07-14_17-35-41.png'  # Update this path to your image file
    excel_path = r'C:\Users\Jessica\Desktop\test2.xlsx'   # Update this path to your desired Excel file
    main(image_path, excel_path)
