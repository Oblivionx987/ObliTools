import tkinter as tk
from tkinter import filedialog, messagebox
import requests
from bs4 import BeautifulSoup
from markdownify import markdownify as md
import re

def fetch_html_content(url):
    """
    Fetch the HTML content of the given URL, returning the raw byte content.
    
    Raises:
        requests.RequestException: If there's an issue fetching the content.
    """
    # Set a custom User-Agent header to reduce risk of being blocked by certain websites
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                      "AppleWebKit/537.36 (KHTML, like Gecko) "
                      "Chrome/58.0.3029.110 Safari/537.3"
    }
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    return response.content

def convert_html_to_markdown(html_content):
    """
    Convert HTML content into Markdown using markdownify.
    Configures heading style to use ATX (#).
    """
    soup = BeautifulSoup(html_content, 'html.parser')
    # You can customize markdownify behavior with additional parameters:
    # https://github.com/matthewwithanm/python-markdownify
    markdown_content = md(
        str(soup),
        heading_style="ATX",    # Use #, ## etc. for headings
        bullets="*",            # Use '*' for list bullets
        strip=["script", "style"]  # Example: strip script and style tags
    )
    return markdown_content

def save_markdown_file(markdown_content):
    """
    Prompt the user for a save location and write the markdown content to disk.
    """
    save_location = filedialog.asksaveasfilename(
        defaultextension=".md",
        filetypes=[("Markdown files", "*.md"), ("All files", "*.*")]
    )
    if save_location:
        try:
            with open(save_location, 'w', encoding='utf-8') as file:
                file.write(markdown_content)
            messagebox.showinfo("Success", f"Markdown file saved to {save_location}")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to save file: {e}")

def is_valid_url(url: str) -> bool:
    """
    Quick check to see if the user input is in a likely valid URL format.
    This is a superficial check and not a guarantee.
    """
    # Simple regex to check URL format (http or https)
    pattern = re.compile(r"^https?://.+\..+")
    return bool(pattern.match(url))

def fetch_and_convert():
    url = url_entry.get().strip()
    if not url:
        messagebox.showerror("Error", "Please enter a URL.")
        return
    
    if not is_valid_url(url):
        messagebox.showwarning("Warning", "The URL might not be valid. Continue anyway?")
        # We can either stop here or let the request proceed:
        # return

    try:
        html_content = fetch_html_content(url)
    except requests.RequestException as e:
        messagebox.showerror("Error", f"Failed to fetch the webpage:\n{e}")
        return
    
    markdown_content = convert_html_to_markdown(html_content)

    # -------------------------------------------------------------------------
    # OPTIONAL: If you want to preview the Markdown in a separate window:
    #
    # preview_window = tk.Toplevel(root)
    # preview_window.title("Markdown Preview")
    #
    # text_area = tk.Text(preview_window, wrap="word")
    # text_area.pack(expand=True, fill="both")
    # text_area.insert("1.0", markdown_content)
    #
    # # Button to save from preview window
    # save_btn = tk.Button(preview_window, text="Save", command=lambda: save_markdown_file(markdown_content))
    # save_btn.pack(pady=10)
    # -------------------------------------------------------------------------
    
    # Directly prompt to save
    save_markdown_file(markdown_content)

# --------------------
# Build the GUI
# --------------------
root = tk.Tk()
root.title("Webpage to Markdown Converter")

# Create and place the URL input field
url_label = tk.Label(root, text="Enter URL:")
url_label.pack(pady=5)

url_entry = tk.Entry(root, width=50)
url_entry.pack(pady=5)

# Create and place the Convert button
convert_button = tk.Button(root, text="Convert to Markdown", command=fetch_and_convert)
convert_button.pack(pady=20)

# Run the application
root.mainloop()
