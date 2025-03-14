import subprocess
import platform
import os

def main():
    # Get the absolute path of the current script
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Construct the absolute path for run_app.bat
    bat_file_path = os.path.join(script_dir, "lib", "config", "run_app.bat")

    # Check the operating system
    os_name = platform.system()

    # For Windows
    if os_name == "Windows":
        # Execute the .bat file using its absolute path
        subprocess.run(bat_file_path, shell=True)

    # For macOS
    elif os_name == "Darwin":
        # Run the Python script
        python_script_path = os.path.join(script_dir, "lib", "config", "getip.py")
        subprocess.run(["python3", python_script_path], check=True)

        # Then run the Flutter app
        subprocess.run(["flutter", "run"], check=True)

if __name__ == "__main__":
    main()
