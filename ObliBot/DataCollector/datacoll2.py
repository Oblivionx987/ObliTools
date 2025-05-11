import pytesseract
from PIL import Image
import pandas as pd

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

def text_to_excel(text, excel_path):
    """Writes text data to an Excel file."""
    try:
        # Splitting text into lines
        lines = text.split('\n')
        # Creating a DataFrame
        df = pd.DataFrame(lines, columns=['Extracted Text'])
        # Writing to Excel
        df.to_excel(excel_path, index=False)
        print(f"Text data has been written to {excel_path}")
    except Exception as e:
        print(f"Error writing to Excel {excel_path}: {e}")

def main(image_path, excel_path):
    text = image_to_text(image_path)
    if text:
        text_to_excel(text, excel_path)

if __name__ == "__main__":
    image_path = r'C:\Users\Jessica\Pictures\2024-07-14_17-35-41.png'  # Update this path to your image file
    excel_path = r'C:\Users\Jessica\Desktop\test2.xlsx'    # Update this path to your desired Excel file
    main(image_path, excel_path)
