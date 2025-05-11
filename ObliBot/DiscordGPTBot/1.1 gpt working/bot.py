import os
import discord
from discord.ext import commands
from dotenv import load_dotenv
from datetime import datetime, timedelta
import tkinter as tk
from threading import Thread
import openai
from queue import Queue, Empty

load_dotenv()
TOKEN = os.getenv('DISCORD_TOKEN')
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
openai.api_key = OPENAI_API_KEY

intents = discord.Intents.default()
intents.messages = True
intents.message_content = True
intents.guilds = True

client = commands.Bot(command_prefix="!", intents=intents)
maintenance_mode = False  # Track the maintenance status
afk_users = {}  # Dictionary to keep track of AFK users
start_time = datetime.now()  # Start time for runtime calculation

def setup_gui(queue):
    root = tk.Tk()
    root.title("ObliBot Monitoring")
    root.geometry("800x600")  # Default size of the window

    current_time_label = tk.Label(root, text='', font=('Helvetica', 12), fg='blue')
    current_time_label.pack(side='top', anchor='w')
    runtime_label = tk.Label(root, text='', font=('Helvetica', 12), fg='green')
    runtime_label.pack(side='top', anchor='e')

    text = tk.Text(root, state='disabled', wrap='word')
    text.pack(expand=True, fill='both')
    scrollb = tk.Scrollbar(root, command=text.yview)
    scrollb.pack(side='right', fill='y')
    text['yscrollcommand'] = scrollb.set

    def update_time():
        current_time = datetime.now().strftime("%H:%M:%S")
        elapsed_time = datetime.now() - start_time
        elapsed_str = str(timedelta(seconds=int(elapsed_time.total_seconds())))
        current_time_label.config(text=f'Current Time: {current_time}')
        runtime_label.config(text=f'Uptime: {elapsed_str}')
        root.after(1000, update_time)

    def update_gui():
        try:
            while True:
                message = queue.get_nowait()
                if message.startswith('LOG:'):
                    text.config(state='normal')
                    text.insert('end', message[4:] + '\n')
                    text.yview('end')
                    text.config(state='disabled')
        except Empty:
            pass
        root.after(100, update_gui)

    root.after(100, update_gui)
    root.after(1000, update_time)
    root.mainloop()

log_queue = Queue()
gui_thread = Thread(target=setup_gui, args=(log_queue,))
gui_thread.start()

@client.event
async def on_ready():
    log_queue.put('LOG:' + f'{client.user} has connected to Discord!')

async def generate_response(prompt):
    try:
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=150,
            stop=None
        )
        return response['choices'][0]['message']['content'].strip()
    except Exception as e:
        return f"Error: {str(e)}"

@client.event
async def on_message(message):
    await client.process_commands(message)
    if message.author == client.user:
        return

    log_queue.put('LOG:' + f'[{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}] {message.channel} - {message.author.display_name}: {message.content}')

    if message.author.id in afk_users:
        await message.channel.send(f'Welcome back, {message.author.display_name}! I have removed your AFK status.')
        del afk_users[message.author.id]

    if message.content.startswith('!afk'):
        afk_msg = message.content[len('!afk'):].strip() or "AFK"
        afk_users[message.author.id] = afk_msg
        await message.channel.send(f'{message.author.display_name} is now AFK: {afk_msg}')

    if client.user in message.mentions:
        if maintenance_mode:
            await message.channel.send("Boss Obli is working on my brain at the moment, check back later")
        else:
            response = await generate_response(message.content.replace(f'<@!{client.user.id}>', '').strip())
            await message.channel.send(response)

client.run(TOKEN)
