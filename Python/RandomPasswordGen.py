import random
import string

def generate_password(length=16):
    # Define the character set for password generation
    characters = string.ascii_letters + string.digits + string.punctuation

    # Generate a password by randomly selecting characters from the defined character set
    password = ''.join(random.choice(characters) for _ in range(length))
    
    return password

# Prompt the user to specify the length of the password they want to generate
password_length = int(input("Enter desired password length: "))

# Generate and print a strong password of specified length
print("Generated Password:", generate_password(password_length))