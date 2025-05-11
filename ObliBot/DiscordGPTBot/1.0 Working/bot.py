import os
import discord
from discord.ext import commands
from dotenv import load_dotenv
from datetime import datetime
import tkinter as tk
from threading import Thread

load_dotenv()
TOKEN = os.getenv('DISCORD_TOKEN')
intents = discord.Intents.default()
intents.messages = True
intents.message_content = True
intents.guilds = True

client = commands.Bot(command_prefix="!", intents=intents)

# Dictionary to keep track of AFK users
afk_users = {}

# Set up the GUI for logging
def setup_gui(queue):
    root = tk.Tk()
    root.title("ObliBot Monitoring")

    # Text widget for log messages
    text = tk.Text(root, state='disabled', wrap='word')
    text.grid(row=0, column=0, sticky="nsew")

    # Scrollbar for the text widget
    scrollb = tk.Scrollbar(root, command=text.yview)
    scrollb.grid(row=0, column=1, sticky='nse')
    text['yscrollcommand'] = scrollb.set

    # Update the GUI with messages from the bot
    def update_text():
        while True:
            message = queue.get()
            text.config(state='normal')
            text.insert('end', message + '\n')
            text.yview('end')
            text.config(state='disabled')

    # Start the thread that will update the GUI
    thread = Thread(target=update_text)
    thread.daemon = True
    thread.start()

    root.mainloop()

# Queue for passing messages to the GUI
from queue import Queue
log_queue = Queue()

# Start the GUI in a separate thread
gui_thread = Thread(target=setup_gui, args=(log_queue,))
gui_thread.start()

@client.event
async def on_ready():
    log_queue.put(f'{client.user} has connected to Discord!')

@client.event
async def on_message(message):
    if message.author == client.user:
        return

    # Log each user message with timestamp, channel, and user details
    current_time = datetime.now().strftime("%m-%d %H:%M:%S")
    log_message = f'[{current_time}] {message.channel} - {message.author.display_name}: {message.content}'
    log_queue.put(log_message)

    # Remove AFK status if user sends a message
    if message.author.id in afk_users:
        welcome_back_msg = f'Welcome back, {message.author.display_name}! I have removed your AFK status.'
        await message.channel.send(welcome_back_msg)
        log_queue.put(f'Bot response: {welcome_back_msg}')
        del afk_users[message.author.id]

    # Respond to mentions of AFK users
    for user in message.mentions:
        if user.id in afk_users:
            afk_response = f'{user.display_name} is currently AFK: {afk_users[user.id]}'
            await message.channel.send(afk_response)
            log_queue.put(f'Bot response: {afk_response}')

    # Command to set AFK status
    if message.content.startswith('!afk'):
        afk_msg = message.content[len('!afk'):].strip() or "AFK"
        afk_users[message.author.id] = afk_msg
        afk_set_msg = f'{message.author.display_name} is now AFK: {afk_msg}'
        await message.channel.send(afk_set_msg)
        log_queue.put(f'Bot response: {afk_set_msg}')

    # Check if the bot is mentioned
    if client.user in message.mentions:
        bot_response = f'{message.author.mention}, Hello Boss, How can I assist?'
        log_queue.put(f'Bot response: {bot_response}')

    await client.process_commands(message)

client.run(TOKEN)
