import imaplib
import email
from email.header import decode_header
import re
from bs4 import BeautifulSoup
import os

# Configuration - Update with your email details
IMAP_SERVER = "imap.gmail.com"  # Change for Outlook/Yahoo/etc.
EMAIL_USER = "Zeth987@gmail.com"
EMAIL_PASS = "xbhy xioe vkpg bopp"  # Use an app password for security
MAILBOX = "INBOX"
OUTPUT_FILE = "C:/temp/unsubscribe_links.html"

def get_unsubscribe_links():
    try:
        # Connect to email server
        mail = imaplib.IMAP4_SSL(IMAP_SERVER)
        mail.login(EMAIL_USER, EMAIL_PASS)
        mail.select(MAILBOX)

        # Search for all emails
        status, messages = mail.search(None, "ALL")
        if status != "OK":
            print("No emails found.")
            return []

        mail_ids = messages[0].split()
        unsubscribe_links = []

        for mail_id in mail_ids[-50:]:  # Process last 50 emails
            status, msg_data = mail.fetch(mail_id, "(RFC822)")
            if status != "OK":
                continue

            for response_part in msg_data:
                if isinstance(response_part, tuple):
                    msg = email.message_from_bytes(response_part[1])
                    subject, encoding = decode_header(msg["Subject"])[0]
                    if isinstance(subject, bytes):
                        subject = subject.decode(encoding or "utf-8")

                    # Extract email body
                    body = ""
                    if msg.is_multipart():
                        for part in msg.walk():
                            content_type = part.get_content_type()
                            content_disposition = str(part.get("Content-Disposition"))
                            if content_type == "text/html" and "attachment" not in content_disposition:
                                body = part.get_payload(decode=True).decode(errors="ignore")
                                break
                    else:
                        body = msg.get_payload(decode=True).decode(errors="ignore")

                    # Parse HTML to find unsubscribe links
                    soup = BeautifulSoup(body, "html.parser")
                    links = [a["href"] for a in soup.find_all("a", href=True) if "unsubscribe" in a["href"].lower()]
                    
                    if links:
                        unsubscribe_links.append({"subject": subject, "links": links})

        mail.logout()
        return unsubscribe_links

    except Exception as e:
        print(f"Error: {e}")
        return []

def save_to_html(unsubscribe_links):
    if not unsubscribe_links:
        print("No unsubscribe links found.")
        return

    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

    html_content = "<html><head><title>Unsubscribe Links</title></head><body>"
    html_content += "<h2>Unsubscribe Links Found in Emails</h2><ul>"

    for email_data in unsubscribe_links:
        html_content += f"<li><strong>{email_data['subject']}</strong><ul>"
        for link in email_data["links"]:
            html_content += f'<li><a href="{link}" target="_blank">{link}</a></li>'
        html_content += "</ul></li>"

    html_content += "</ul></body></html>"

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(html_content)

    print(f"Unsubscribe links saved to {OUTPUT_FILE}")

# Run script
if __name__ == "__main__":
    links = get_unsubscribe_links()
    save_to_html(links)
