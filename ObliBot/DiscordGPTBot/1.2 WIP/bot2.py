import os
import discord
from discord.ext import commands
from discord.ext.commands import has_permissions, CommandOnCooldown, MissingRequiredArgument
from dotenv import load_dotenv
from datetime import datetime, timedelta
import tkinter as tk
from threading import Thread
import openai
from queue import Queue, Empty
import asyncio

# Load environment variables
load_dotenv()
TOKEN = os.getenv('DISCORD_TOKEN')
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
openai.api_key = OPENAI_API_KEY

# Set up Discord bot intents
intents = discord.Intents.default()
intents.messages = True
intents.message_content = True
intents.guilds = True

# Initialize the bot with a command prefix and the specified intents
client = commands.Bot(command_prefix="!", intents=intents)
maintenance_mode = False  # Variable to track if the bot is in maintenance mode
afk_users = {}  # Dictionary to track users who are AFK
start_time = datetime.now()  # Record the start time of the bot for uptime calculation

# Set up the GUI for monitoring the bot
def setup_gui(queue):
    root = tk.Tk()
    root.title("ObliBot Monitoring")
    root.geometry("1000x600")

    # Set up frame for time and runtime labels
    time_frame = tk.Frame(root)
    time_frame.pack(side='top', fill='x')
    current_time_label = tk.Label(time_frame, text='', font=('Helvetica', 12), fg='blue')
    current_time_label.pack(side='left', padx=(10, 0))
    runtime_label = tk.Label(time_frame, text='', font=('Helvetica', 12), fg='green')
    runtime_label.pack(side='left', padx=(10, 0))

    # Set up the main text area for logs
    text = tk.Text(root, state='disabled', wrap='word')
    text.pack(side='left', expand=True, fill='both')
    scrollb = tk.Scrollbar(root, command=text.yview)
    scrollb.pack(side='left', fill='y')
    text['yscrollcommand'] = scrollb.set

    # Set up a listbox for displaying AFK users
    afk_listbox = tk.Listbox(root, width=30)
    afk_listbox.pack(side='right', fill='y')

    # Function to update the AFK user list in the GUI
    def update_afk_list():
        afk_listbox.delete(0, 'end')
        for user_id, info in afk_users.items():
            nickname = info.get('nickname', 'Unknown')
            server = info.get('server', 'Unknown server')
            afk_listbox.insert('end', f'{nickname} ({server})')
        root.after(1000, update_afk_list)  # Schedule updates every second

    # Button to toggle maintenance mode
    def toggle_maintenance():
        global maintenance_mode
        maintenance_mode = not maintenance_mode
        button_color = 'red' if maintenance_mode else 'gray'
        maintenance_button.config(bg=button_color, text='Disable Maintenance' if maintenance_mode else 'Enable Maintenance')
        log_queue.put('LOG:Maintenance mode ' + ('enabled' if maintenance_mode else 'disabled'))

    maintenance_button = tk.Button(root, text='Enable Maintenance', bg='gray', command=toggle_maintenance)
    maintenance_button.pack(side='bottom')

    # Function to update the current time and runtime labels
    def update_time():
        current_time = datetime.now().strftime("%H:%M:%S")
        elapsed_time = datetime.now() - start_time
        elapsed_str = str(timedelta(seconds=int(elapsed_time.total_seconds())))
        current_time_label.config(text=f'Current Time: {current_time}')
        runtime_label.config(text=f'Uptime: {elapsed_str}')
        root.after(1000, update_time)

    # Function to update the log text area
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
    root.after(1000, update_afk_list)
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
    if message.author == client.user:
        return

    server_name = message.guild.name if message.guild else 'Direct Message'
    message_content = message.content
    if message.attachments:
        for attachment in message.attachments:
            if any(attachment.filename.lower().endswith(ext) for ext in ['.png', '.jpg', '.jpeg', '.gif']):
                message_content += ' [Image Posted]'
            elif any(attachment.filename.lower().endswith(ext) for ext in ['.mp3', '.wav', '.ogg']):
                message_content += ' [Audio Posted]'

    log_queue.put(f'LOG:[{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}] {server_name} - {message.channel} - {message.author.display_name}: {message_content}')

    await client.process_commands(message)

    if message.author.id in afk_users:
        await message.channel.send(f'Welcome back, {message.author.display_name}! I have removed your AFK status.')
        log_queue.put(f'LOG:[{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}] {ctx.guild.name} - {ctx.channel} - {ctx.bot.user.display_name}: {response_message}')
        del afk_users[message.author.id]

    if message.content.startswith('!afk'):
        afk_msg = message.content[len('!afk'):].strip() or "AFK"
        afk_users[message.author.id] = {'nickname': message.author.display_name, 'server': message.guild.name, 'message': afk_msg}
        await message.channel.send(f'{message.author.display_name} is now AFK: {afk_msg}')
        log_queue.put(f'LOG:[{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}] {ctx.guild.name} - {ctx.channel} - {ctx.bot.user.display_name}: {response_message}')

    if client.user in message.mentions:
        if maintenance_mode:
            await message.channel.send("Boss Obli is working on my brain at the moment, check back later")
            log_queue.put(f'LOG:[{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}] {ctx.guild.name} - {ctx.channel} - {ctx.bot.user.display_name}: {response_message}')

        else:
            response = await generate_response(message.content.replace(f'<@!{client.user.id}>', '').strip())
            await message.channel.send(response)
            log_queue.put(f'LOG:[{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}] {ctx.guild.name} - {ctx.channel} - {ctx.bot.user.display_name}: {response_message}')
# Adding new commands
@client.command(help="Returns the bot's latency")
async def ping(ctx):
    await ctx.send(f'Pong! {round(client.latency * 1000)}ms')

@client.command(help="Displays the bot's uptime")
async def uptime(ctx):
    elapsed_time = datetime.now() - start_time
    elapsed_str = str(timedelta(seconds=int(elapsed_time.total_seconds())))
    await ctx.send(f'Uptime: {elapsed_str}')

@client.command(help="Repeats the input back to the user")
async def echo(ctx, *, text: str):
    await ctx.send(text)

@client.command(help="Kicks a member from the server")
@has_permissions(kick_members=True)
async def kick(ctx, member: discord.Member, *, reason=None):
    await member.kick(reason=reason)
    await ctx.send(f'Kicked {member.display_name} for {reason}')

@client.command(help="Bans a member from the server")
@has_permissions(ban_members=True)
async def ban(ctx, member: discord.Member, *, reason=None):
    await member.ban(reason=reason)
    await ctx.send(f'Banned {member.display_name} for {reason}')

@client.command(help="Toggles maintenance mode")
@has_permissions(administrator=True)
async def maintenance(ctx):
    global maintenance_mode
    maintenance_mode = not maintenance_mode
    status = "enabled" if maintenance_mode else "disabled"
    await ctx.send(f'Maintenance mode has been {status}')

@client.command(help="Clears a specified number of messages")
@has_permissions(manage_messages=True)
async def clear(ctx, amount: int):
    await ctx.channel.purge(limit=amount+1)
    await ctx.send(f'Cleared {amount} messages', delete_after=5)

@client.command(help="Fetches a random inspirational quote")
async def quote(ctx):
    # Example function, replace with actual API call or quote generator
    await ctx.send("Be yourself; everyone else is already taken. — Oscar Wilde")
    log_queue.put(f'LOG:[{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}] {ctx.guild.name} - {ctx.channel} - {ctx.bot.user.display_name}: {response_message}')

@client.command(help="Displays information about a server member")
async def userinfo(ctx, member: discord.Member):
    await ctx.send(f'User Info for {member.display_name}: Join date: {member.joined_at.strftime("%Y-%m-%d")}, Roles: {", ".join([role.name for role in member.roles[1:]])}')

@client.command(help="Shuts down the bot")
@commands.is_owner()
async def shutdown(ctx):
    await ctx.send("Shutting down. Goodbye!")
    log_queue.put(f'LOG:[{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}] {ctx.guild.name} - {ctx.channel} - {ctx.bot.user.display_name}: {response_message}')
    await client.close()


@client.event
async def on_command_error(ctx, error):
    if isinstance(error, CommandOnCooldown):
        await ctx.send(f"This command is on cooldown. Please try again in {error.retry_after:.2f} seconds.")
    elif isinstance(error, MissingRequiredArgument):
        await ctx.send("Please provide all required arguments.")
    else:
        raise error

# Commands (ping, uptime, echo, kick, ban, maintenance, clear, quote, userinfo, shutdown) are to be included here...

client.run(TOKEN)
