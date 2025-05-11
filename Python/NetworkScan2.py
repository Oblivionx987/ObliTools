import subprocess
import ipaddress
import socket
from concurrent.futures import ThreadPoolExecutor, as_completed

def arp_scan(ip):
    try:
        # Get the MAC address using the arp command
        output = subprocess.check_output(["arp", "-a", ip], stderr=subprocess.STDOUT, universal_newlines=True)
        lines = output.split("\n")
        for line in lines:
            if ip in line:
                mac_address = line.split()[1]
                hostname = socket.gethostbyaddr(mac_address)[0]
                return ip, True, hostname
        return ip, False, None
    except subprocess.CalledProcessError:
        return ip, False, None

def scan_network(network, max_threads=50):
    responsive_ips = []

    with ThreadPoolExecutor(max_workers=max_threads) as executor:
        futures = {executor.submit(arp_scan, ip): ip for ip in ipaddress.IPv4Network(network)}
        for future in as_completed(futures):
            ip, is_responsive, hostname = future.result()
            if is_responsive:
                responsive_ips.append((ip, hostname))
                print(f"IP Address {ip} with hostname {hostname} is responsive")

    # Sort the results by the IP address
    sorted_responsive_ips = sorted(responsive_ips, key=lambda x: x[0])
    return [f"{ip} ({hostname})" for ip, hostname in sorted_responsive_ips]

# Example usage: Scanning the network 10.0.0.0/24
responsive_ips = scan_network("10.0.0.0/24")
print("\nResponsive IP Addresses with hostnames:")
print("\n".join(responsive_ips))