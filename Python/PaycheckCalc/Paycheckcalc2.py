import tkinter as tk
from tkinter import ttk
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg

def calculate_pay():
    try:
        hourly_rate = float(hourly_rate_entry.get())
        state_tax_rate = float(state_tax_entry.get()) / 100
        federal_tax_rate = float(federal_tax_entry.get()) / 100

        gross_bi_weekly_pay = hourly_rate * 40 * 2
        net_bi_weekly_pay = gross_bi_weekly_pay * (1 - state_tax_rate - federal_tax_rate)
        net_monthly_pay = net_bi_weekly_pay * 2
        net_yearly_pay = net_bi_weekly_pay * 26

        bi_weekly_pay_var.set(f"${net_bi_weekly_pay:.2f}")
        monthly_pay_var.set(f"${net_monthly_pay:.2f}")
        yearly_pay_var.set(f"${net_yearly_pay:.2f}")

        # Plot income growth
        years = list(range(1, 31))
        savings = [net_yearly_pay * year for year in years]

        fig, ax = plt.subplots()
        ax.plot(years, savings, marker='o')
        ax.set_title("Income Growth Over Time")
        ax.set_xlabel("Years")
        ax.set_ylabel("Total Savings ($)")
        
        canvas = FigureCanvasTkAgg(fig, master=root)
        canvas.draw()
        canvas.get_tk_widget().grid(column=1, row=8, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S))
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

ttk.Label(frame, text="State Tax Rate (%):").grid(column=1, row=2, sticky=tk.W)
state_tax_entry = ttk.Entry(frame, width=15)
state_tax_entry.grid(column=2, row=2, sticky=(tk.W, tk.E))

ttk.Label(frame, text="Federal Tax Rate (%):").grid(column=1, row=3, sticky=tk.W)
federal_tax_entry = ttk.Entry(frame, width=15)
federal_tax_entry.grid(column=2, row=3, sticky=(tk.W, tk.E))

calculate_button = ttk.Button(frame, text="Calculate", command=calculate_pay)
calculate_button.grid(column=2, row=4, sticky=tk.W)

ttk.Label(frame, text="Bi-Weekly Pay:").grid(column=1, row=5, sticky=tk.W)
bi_weekly_pay_var = tk.StringVar()
bi_weekly_pay_label = ttk.Label(frame, textvariable=bi_weekly_pay_var)
bi_weekly_pay_label.grid(column=2, row=5, sticky=(tk.W, tk.E))

ttk.Label(frame, text="Monthly Pay:").grid(column=1, row=6, sticky=tk.W)
monthly_pay_var = tk.StringVar()
monthly_pay_label = ttk.Label(frame, textvariable=monthly_pay_var)
monthly_pay_label.grid(column=2, row=6, sticky=(tk.W, tk.E))

ttk.Label(frame, text="Yearly Pay:").grid(column=1, row=7, sticky=tk.W)
yearly_pay_var = tk.StringVar()
yearly_pay_label = ttk.Label(frame, textvariable=yearly_pay_var)
yearly_pay_label.grid(column=2, row=7, sticky=(tk.W, tk.E))

# Add padding to all children of the frame
for child in frame.winfo_children():
    child.grid_configure(padx=5, pady=5)

# Set focus to the hourly_rate_entry
hourly_rate_entry.focus()

# Start the Tkinter event loop
root.mainloop()
