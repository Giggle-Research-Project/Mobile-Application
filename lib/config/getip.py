import socket
import os
import platform

def get_ip_address():
    os_type = platform.system()
    if os_type == "Darwin":  # macOS
        # Running the 'ipconfig getifaddr en0' command and capturing its output
        ip_address = os.popen('ipconfig getifaddr en0').read().strip()
        return ip_address
    elif os_type == "Windows":
        # Getting the hostname and resolving its IP address
        hostname = socket.gethostname()
        ip_address = socket.gethostbyname(hostname)
        return ip_address
    else:
        raise Exception("Unsupported operating system")

def update_env_file(ip_address):
    # Get the directory where getip.py is located
    dir_path = os.path.dirname(os.path.realpath(__file__))

    # Construct the path to the .env file
    env_path = os.path.join(dir_path, '.env')

    try:
        with open(env_path, 'r') as file:
            lines = file.readlines()

        with open(env_path, 'w') as file:
            for line in lines:
                if line.startswith('MLIP='):
                    file.write(f'MLIP={ip_address}\n')
                else:
                    file.write(line)
    except FileNotFoundError:
        print(f"Error: '.env' file not found in {env_path}")
        # Handle the error, e.g., by creating a new .env file or exiting

if __name__ == "__main__":
    ip_address = get_ip_address()
    update_env_file(ip_address)
    print("==========================================================")
    print(f".env Updated with Below IP")
    print(ip_address)
    print("==========================================================")