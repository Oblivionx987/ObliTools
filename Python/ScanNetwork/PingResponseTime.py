import subprocess
import ipaddress
from concurrent.futures import ThreadPoolExecutor, as_completed

def ping_ip(ip_address):
    try:
        # Pinging the IP address (Windows command)
        output = subprocess.check_output(["ping", "-n", "1", "-w", "1000", str(ip_address)], stderr=subprocess.STDOUT, universal_newlines=True)
        return ip_address, True, output
    except subprocess.CalledProcessError:
        return ip_address, False, None

def scan_network(network, max_threads=50):
    responsive_ips = []
    counter = 0

    with ThreadPoolExecutor(max_workers=max_threads) as executor:
        futures = {executor.submit(ping_ip, ip): ip for ip in ipaddress.IPv4Network(network)}
        for future in as_completed(futures):
            ip, is_responsive, output = future.result()
            counter += 1
            if is_responsive:
                responsive_ips.append((counter, str(ip), output))
                print(f"IP Address {ip} is responsive")
                print(f"Output: {output}")
                print("--------------------------------")

    return responsive_ips

# Example usage: Scanning the network 10.0.0.0/24
responsive_ips = scan_network("10.0.0.0/24")
print("\nResponsive IP Addresses:")
for _, ip, output in responsive_ips:
    print(f"{ip}: {output}")