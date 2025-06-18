import os
import re
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
import webbrowser

try:
    import pandas as pd
except ImportError:
    pd = None

# Metadata extraction patterns for PowerShell and Python scripts
PS1_PATTERNS = {
    'Description': re.compile(r'^\s*\$Description\s*=\s*"([^"]*)"', re.IGNORECASE),
    'Author': re.compile(r'^\s*\$Author\s*=\s*"([^"]*)"', re.IGNORECASE),
    'Version': re.compile(r'^\s*\$Version\s*=\s*"([^"]*)"', re.IGNORECASE),
    'Live': re.compile(r'^\s*\$Live\s*=\s*"([^"]*)"', re.IGNORECASE),
    'BMGR': re.compile(r'^\s*\$BMGR\s*=\s*"([^"]*)"', re.IGNORECASE),
    'Last Tested': re.compile(r'^\s*\$Last_Tested\s*=\s*"([^"]*)"', re.IGNORECASE),
    'Source': re.compile(r'^\s*\$Source\s*=\s*"([^"]*)"', re.IGNORECASE),
    'Zip File Name': re.compile(r'^\s*\$ZipFileName\s*=\s*"([^"]*)"', re.IGNORECASE),
}
PY_PATTERNS = {
    'Description': re.compile(r'^\s*#\s*Description\s*:\s*(.*)', re.IGNORECASE),
    'Author': re.compile(r'^\s*#\s*Author\s*:\s*(.*)', re.IGNORECASE),
    'Version': re.compile(r'^\s*#\s*Version\s*:\s*(.*)', re.IGNORECASE),
}

COLUMNS = ['Type', 'Live', 'BMGR', 'Folder Name', 'File Name', 'Version', 'Last Tested', 'Author', 'Description', 'Path', 'Source', 'Zip File Name']

class ScriptManagerGUI:
    def __init__(self, root):
        self.root = root
        self.root.title('Script Manager')
        self.root.geometry('1200x600')
        self.create_widgets()
        self.scripts = []

    def create_widgets(self):
        frame = tk.Frame(self.root)
        frame.pack(fill=tk.X, padx=10, pady=5)
        tk.Button(frame, text='Select Directory', command=self.select_directory).pack(side=tk.LEFT)
        tk.Button(frame, text='Export to HTML', command=self.export_html).pack(side=tk.LEFT, padx=5)
        self.hide_retired_var = tk.BooleanVar(value=False)
        tk.Checkbutton(frame, text='Hide Retired', variable=self.hide_retired_var, command=self.refresh_table).pack(side=tk.LEFT, padx=5)
        self.dir_label = tk.Label(frame, text='No directory selected')
        self.dir_label.pack(side=tk.LEFT, padx=10)

        self.tree = ttk.Treeview(self.root, columns=COLUMNS, show='headings')
        # Set custom widths for each column for better fit
        column_widths = {
            'Type': 40,
            'Live': 60,
            'BMGR': 60,
            'Folder Name': 100,
            'File Name': 140,
            'Version': 60,
            'Last Tested': 90,
            'Author': 120,
            'Description': 200,
            'Path': 220,
            'Source': 80,
            'Zip File Name': 100
        }
        for col in COLUMNS:
            width = column_widths.get(col, 80)
            self.tree.heading(col, text=col, command=lambda c=col: self.sort_by(c, False))
            self.tree.column(col, width=width, anchor='w', stretch=True)  # Shrink columns and allow stretching
        self.tree.pack(fill=tk.BOTH, expand=True)
        self.tree.bind('<Double-1>', self.open_script)

        # Add horizontal scrollbar for wide tables
        xscrollbar = ttk.Scrollbar(self.root, orient='horizontal', command=self.tree.xview)
        self.tree.configure(xscroll=xscrollbar.set)
        xscrollbar.pack(side='bottom', fill='x')

        scrollbar = ttk.Scrollbar(self.tree, orient='vertical', command=self.tree.yview)
        self.tree.configure(yscroll=scrollbar.set)
        scrollbar.pack(side='right', fill='y')

    def select_directory(self):
        directory = filedialog.askdirectory()
        if directory:
            self.dir_label.config(text=directory)
            self.scan_scripts(directory)

    def scan_scripts(self, directory):
        self.scripts.clear()
        for rootdir, _, files in os.walk(directory):
            for fname in files:
                if fname.endswith('.ps1') or fname.endswith('.py'):
                    fpath = os.path.join(rootdir, fname)
                    meta = self.extract_metadata(fpath)
                    folder = os.path.basename(os.path.dirname(fpath))
                    row = [
                        'PS1' if fname.endswith('.ps1') else 'PY',
                        meta.get('Live', ''),
                        meta.get('BMGR', ''),
                        folder,
                        fname,
                        meta.get('Version', ''),
                        meta.get('Last Tested', ''),
                        meta.get('Author', ''),
                        meta.get('Description', ''),
                        fpath,
                        meta.get('Source', ''),
                        meta.get('Zip File Name', ''),
                    ]
                    self.scripts.append(row)
        self.refresh_table()

    def extract_metadata(self, filepath):
        meta = {}
        try:
            with open(filepath, encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
            patterns = PS1_PATTERNS if filepath.endswith('.ps1') else PY_PATTERNS
            for line in lines:
                for key, pat in patterns.items():
                    m = pat.match(line)
                    if m:
                        meta[key] = m.group(1).strip()
            # Fallbacks
            if 'Description' not in meta:
                meta['Description'] = None
            if 'Author' not in meta:
                meta['Author'] = None
            if 'Version' not in meta:
                meta['Version'] = None
            if filepath.endswith('.ps1'):
                for k in ['Live', 'BMGR', 'Last Tested', 'Source', 'Zip File Name']:
                    if k not in meta:
                        meta[k] = None
        except Exception as e:
            meta['Description'] = f'Error: {e}'
        return meta

    def refresh_table(self):
        for row in self.tree.get_children():
            self.tree.delete(row)
        hide_retired = getattr(self, 'hide_retired_var', None)
        for row in self.scripts:
            # Safely handle None values for live and bmgr
            live = (row[1] or '').strip().lower()
            bmgr = (row[2] or '').strip().lower()
            if hide_retired and hide_retired.get():
                if live == 'retired' or bmgr == 'retired':
                    continue
            tags = []
            if live == 'restricted':
                tags.append('live_restricted')
            elif live == 'wip':
                tags.append('live_wip')
            elif live == 'test':
                tags.append('live_test')
            elif live == 'retired':
                tags.append('live_retired')
            elif live == 'live':
                tags.append('live_live')
            if bmgr == 'restricted':
                tags.append('bmgr_restricted')
            elif bmgr == 'wip':
                tags.append('bmgr_wip')
            elif bmgr == 'test':
                tags.append('bmgr_test')
            elif bmgr == 'retired':
                tags.append('bmgr_retired')
            elif bmgr == 'live':
                tags.append('bmgr_live')
            self.tree.insert('', 'end', values=row, tags=tags)

        # Remove row-wide coloring, use custom tag for each column
        # Set tag styles for live column (index 1)
        self.tree.tag_configure('live_restricted', foreground='red')
        self.tree.tag_configure('live_wip', foreground='deepskyblue')
        self.tree.tag_configure('live_test', foreground='orange')
        self.tree.tag_configure('live_retired', foreground='salmon')
        self.tree.tag_configure('live_live', foreground='green')
        # Set tag styles for bmgr column (index 2)
        self.tree.tag_configure('bmgr_restricted', background='', foreground='red')
        self.tree.tag_configure('bmgr_wip', background='', foreground='deepskyblue')
        self.tree.tag_configure('bmgr_test', background='', foreground='orange')
        self.tree.tag_configure('bmgr_retired', background='', foreground='salmon')
        self.tree.tag_configure('bmgr_live', background='', foreground='green')

    def sort_by(self, col, descending):
        idx = COLUMNS.index(col)
        data = [(self.tree.set(child, col), child) for child in self.tree.get_children('')]
        data.sort(reverse=descending)
        for i, (val, child) in enumerate(data):
            self.tree.move(child, '', i)
        self.tree.heading(col, command=lambda: self.sort_by(col, not descending))

    def open_script(self, event):
        item = self.tree.selection()
        if item:
            values = self.tree.item(item[0])['values']
            path = values[8] if len(values) > 8 else None
            if path and isinstance(path, str):
                folder = os.path.abspath(os.path.dirname(path))
                if os.path.isdir(folder):
                    try:
                        if os.name == 'nt':
                            os.startfile(folder)
                        else:
                            import subprocess
                            subprocess.call(['xdg-open', folder])
                    except Exception as e:
                        # Try opening the parent directory as a fallback
                        parent = os.path.dirname(folder)
                        if os.path.isdir(parent):
                            try:
                                if os.name == 'nt':
                                    os.startfile(parent)
                                else:
                                    import subprocess
                                    subprocess.call(['xdg-open', parent])
                                messagebox.showinfo('Info', f'Could not open folder: {folder}\nOpened parent folder instead.')
                            except Exception as e2:
                                messagebox.showerror('Error', f'Cannot open folder: {folder}\nTried parent: {parent}\n{e2}')
                        else:
                            messagebox.showerror('Error', f'Cannot open folder: {folder}\n{e}')
                else:
                    messagebox.showerror('Error', f'Folder does not exist or path is invalid: {folder}')
            else:
                messagebox.showerror('Error', 'No valid file path found in the selected row.')

    def export_html(self):
        if not self.scripts:
            messagebox.showinfo('No Data', 'No scripts to export.')
            return
        html = ['<html><head><title>Script Summary</title></head><body>']
        html.append(f'<h1>Summary of scripts</h1>')
        html.append('<table border="1"><tr>' + ''.join(f'<th>{col}</th>' for col in COLUMNS) + '</tr>')
        for row in self.scripts:
            # Highlight Author column if missing
            author = row[7]
            author_style = "background-color:yellow;" if (not author or author == 'No author found.') else ""
            # Highlight Live and BMGR columns
            live = row[1].strip().lower()
            bmgr = row[2].strip().lower()
            live_color = {
                'restricted': 'red',
                'wip': 'lightblue',
                'test': 'orange',
                'retired': 'salmon',
                'live': 'green',
            }.get(live, '')
            bmgr_color = {
                'restricted': 'red',
                'wip': 'lightblue',
                'test': 'orange',
                'retired': 'salmon',
                'live': 'green',
            }.get(bmgr, '')
            html.append('<tr>' +
                f'<td style="background-color:{live_color};">{row[1]}</td>' +
                f'<td style="background-color:{bmgr_color};">{row[2]}</td>' +
                ''.join([
                    f'<td>{row[3]}</td>',
                    f'<td>{row[4]}</td>',
                    f'<td>{row[5]}</td>',
                    f'<td>{row[6]}</td>',
                    f'<td style="{author_style}">{row[7]}</td>',
                    f'<td>{row[8]}</td>',
                    f'<td>{row[9]}</td>',
                    f'<td>{row[10]}</td>',
                    f'<td>{row[11]}</td>',
                ]) + '</tr>')
        html.append('</table>')
        html.append(f'<p>Report generated on: {pd.Timestamp.now() if pd else ""}</p>')
        html.append('</body></html>')
        save_path = filedialog.asksaveasfilename(defaultextension='.html', filetypes=[('HTML files', '*.html')])
        if save_path:
            with open(save_path, 'w', encoding='utf-8') as f:
                f.write('\n'.join(html))
            webbrowser.open(save_path)

if __name__ == '__main__':
    root = tk.Tk()
    app = ScriptManagerGUI(root)
    root.mainloop()
