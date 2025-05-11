#!/usr/bin/env python3

import subprocess
import tkinter as tk
from tkinter import messagebox

def network_scan():
    network = "192.168.1.0/24"  # Change this to the desired network range
    result = subprocess.run(
        ["nmap", "-sn", network],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        messagebox.showerror(title="Error", message=result.stderr)
        return

    online_ips = []
    for line in result.stdout.split("\n"):
        if "report for " in line:
            ip = line.split()[-1].strip('"')
            online_ips.append(ip)

    messagebox.showinfo(title="Online IPs", message="\n".join(online_ips))

# Create the main window
root = tk.Tk()
root.title("Network Scanner")

# Create the button
scan_button = tk.Button(
    root,
    text="Scan Network",
    command=network_scan,
)
scan_button.pack(padx=10, pady=10)

# Run the main loop
root.mainloop()