import os

def change_extension(folder_path, old_ext, new_ext):
    # Loop through all files in the specified folder
    for filename in os.listdir(folder_path):
        # Check if the file has the old extension
        if filename.endswith(old_ext):
            # Create the new filename with the new extension
            new_filename = filename[:-len(old_ext)] + new_ext
            # Construct the full old and new file paths
            old_file = os.path.join(folder_path, filename)
            new_file = os.path.join(folder_path, new_filename)
            # Rename the file
            os.rename(old_file, new_file)
            print(f'Renamed: {old_file} to {new_file}')

# Example usage
folder_path = r'G:\Other computers\My Computer\HP Data\07-20-PlayerProfiles'
change_extension(folder_path, '.pdf', '.png')
