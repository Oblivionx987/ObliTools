import tkinter as tk
from tkinter import ttk

def calculate_pay():
    try:
        hourly_rate = float(hourly_rate_entry.get())
        bi_weekly_pay = hourly_rate * 40 * 2
        monthly_pay = bi_weekly_pay * 2
        yearly_pay = bi_weekly_pay * 26

        bi_weekly_pay_var.set(f"${bi_weekly_pay:.2f}")
        monthly_pay_var.set(f"${monthly_pay:.2f}")
        yearly_pay_var.set(f"${yearly_pay:.2f}")
    except ValueError:
        bi_weekly_pay_var.set("Invalid input")
        monthly_pay_var.set("Invalid input")
        yearly_pay_var.set("Invalid input")

# Create the main window
root = tk.Tk()
root.title("Paycheck Calculator")

# Create and grid the main frame
frame = ttk.Frame(root, padding="10 10 20 20")
frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

# Add widgets
ttk.Label(frame, text="Hourly Rate:").grid(column=1, row=1, sticky=tk.W)
hourly_rate_entry = ttk.Entry(frame, width=15)
hourly_rate_entry.grid(column=2, row=1, sticky=(tk.W, tk.E))

calculate_button = ttk.Button(frame, text="Calculate", command=calculate_pay)
calculate_button.grid(column=2, row=2, sticky=tk.W)

ttk.Label(frame, text="Bi-Weekly Pay:").grid(column=1, row=3, sticky=tk.W)
bi_weekly_pay_var = tk.StringVar()
bi_weekly_pay_label = ttk.Label(frame, textvariable=bi_weekly_pay_var)
bi_weekly_pay_label.grid(column=2, row=3, sticky=(tk.W, tk.E))

ttk.Label(frame, text="Monthly Pay:").grid(column=1, row=4, sticky=tk.W)
monthly_pay_var = tk.StringVar()
monthly_pay_label = ttk.Label(frame, textvariable=monthly_pay_var)
monthly_pay_label.grid(column=2, row=4, sticky=(tk.W, tk.E))

ttk.Label(frame, text="Yearly Pay:").grid(column=1, row=5, sticky=tk.W)
yearly_pay_var = tk.StringVar()
yearly_pay_label = ttk.Label(frame, textvariable=yearly_pay_var)
yearly_pay_label.grid(column=2, row=5, sticky=(tk.W, tk.E))

# Add padding to all children of the frame
for child in frame.winfo_children():
    child.grid_configure(padx=5, pady=5)

# Set focus to the hourly_rate_entry
hourly_rate_entry.focus()

# Start the Tkinter event loop
root.mainloop()
