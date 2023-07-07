import os
import shutil

source_file = './config.ini'
destination_folder = './config'
destination_file = os.path.join(destination_folder, os.path.basename(source_file))

if not os.path.exists(destination_file):
    shutil.copy(source_file, destination_folder)
    print("File copied successfully.")
else:
    print("Destination file already exists. Skipping copy operation.")