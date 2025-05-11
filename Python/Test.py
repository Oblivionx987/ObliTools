import tkinter as tk
import subprocess

class NetworkToolGUI:
    def __init__(self, master):
        self.master = master
        master.title("Network Tools")

        self.ip_address_label = tk.Label(master, text="IP Address:")
        self.ip_address_label.pack()

        self.ip_address_entry = tk.Entry(master)
        self.ip_address_entry.pack()

        self.ping_button = tk.Button(master, text="Ping", command=self.ping)
        self.ping_button.pack()

        self.traceroute_button = tk.Button(master, text="Traceroute", command=self.traceroute)
        self.traceroute_button.pack()

    def ping(self):
        ip_address = self.ip_address_entry.get()
        output = subprocess.check_output(f"ping -c 4 {ip_address}", shell=True)
        print(output.decode())

    def traceroute(self):
        ip_address = self.ip_address_entry.get()
        output = subprocess.check_output(f"traceroute {ip_address}", shell=True)
        print(output.decode())

root = tk.Tk()
my_gui = NetworkToolGUI(root)
root.mainloop()