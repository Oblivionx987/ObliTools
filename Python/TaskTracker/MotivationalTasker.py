#!/usr/bin/env python3
import json
import os
import random

# Name of the JSON file that stores tasks
TASKS_FILE = "tasks.json"

# Some fun motivational quotes and facts
MOTIVATION_QUOTES = [
    "Believe you can and you're halfway there! — Theodore Roosevelt",
    "Your limitation—it’s only your imagination.",
    "Push yourself, because no one else is going to do it for you.",
    "Great things never come from comfort zones.",
    "Dream it. Wish it. Do it.",
    "Sometimes later becomes never. Do it now.",
    "Don’t stop when you’re tired. Stop when you’re done!",
    "Wake up with determination. Go to bed with satisfaction.",
    "Little fun fact: Flamingos bend their legs at the ankle, not the knee!",
    "Fun fact: Honey never spoils, so that jar in your kitchen might be centuries old."
]

def load_tasks():
    """Load tasks from the JSON file or return an empty list if the file doesn't exist."""
    if os.path.exists(TASKS_FILE):
        with open(TASKS_FILE, 'r') as file:
            try:
                return json.load(file)
            except json.JSONDecodeError:
                # If file is empty or corrupted, return empty list
                return []
    else:
        return []

def save_tasks(tasks):
    """Save tasks to the JSON file."""
    with open(TASKS_FILE, 'w') as file:
        json.dump(tasks, file, indent=4)

def display_tasks(tasks):
    """Print out all tasks in a user-friendly format."""
    if not tasks:
        print("No tasks at the moment. Add some!")
        return
    
    print("\nYour To-Do List:")
    print("=" * 20)
    for index, task in enumerate(tasks, start=1):
        status = "✓ Completed" if task["completed"] else "✗ In Progress"
        due_date = task["due_date"] if task["due_date"] else "None"
        print(f"{index}. {task['title']} | Due: {due_date} | Status: {status}")
    print("=" * 20)

def add_task(tasks):
    """Prompt user for task details and add it to the list."""
    title = input("Enter the task title/description: ").strip()
    due_date = input("Enter due date (optional): ").strip() or None
    tasks.append({
        "title": title,
        "due_date": due_date,
        "completed": False
    })
    save_tasks(tasks)
    
    # Print a random motivational quote
    print_random_motivation()

def complete_task(tasks):
    """Prompt user to select a task to mark as completed."""
    if not tasks:
        print("No tasks to mark complete! Try adding some first.")
        return
    
    display_tasks(tasks)
    choice = input("Enter the task number you have completed: ")
    
    # Validate choice
    if not choice.isdigit():
        print("Invalid input. Please enter a valid task number.")
        return
    
    task_index = int(choice) - 1
    if 0 <= task_index < len(tasks):
        tasks[task_index]["completed"] = True
        save_tasks(tasks)
        print(f"Task '{tasks[task_index]['title']}' marked as completed!")
        print_random_motivation()
    else:
        print("Task number out of range. Please try again.")

def print_random_motivation():
    """Print a random motivational quote/fun fact."""
    quote = random.choice(MOTIVATION_QUOTES)
    print("\n" + "="*50)
    print(quote)
    print("="*50 + "\n")

def main():
    tasks = load_tasks()
    
    while True:
        print("""
        What would you like to do?
        1. View all tasks
        2. Add a new task
        3. Mark a task as completed
        4. Exit
        """)
        
        choice = input("Enter your choice (1-4): ")
        
        if choice == "1":
            display_tasks(tasks)
        elif choice == "2":
            add_task(tasks)
        elif choice == "3":
            complete_task(tasks)
        elif choice == "4":
            print("Goodbye! Keep up the great work!")
            break
        else:
            print("Invalid choice. Please try again.")

if __name__ == "__main__":
    main()
