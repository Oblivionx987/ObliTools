import subprocess
import ipaddress
from concurrent.futures import ThreadPoolExecutor, as_completed

def ping_ip(ip_address):
    try:
        # Pinging the IP address (Windows command)
        output = subprocess.check_output(["ping", "-n", "1", "-w", "1000", str(ip_address)], stderr=subprocess.STDOUT, universal_newlines=True)
        return ip_address, True
    except subprocess.CalledProcessError:
        return ip_address, False

def scan_network(network, max_threads=50):
    responsive_ips = []
    counter = 0

    with ThreadPoolExecutor(max_workers=max_threads) as executor:
        futures = {executor.submit(ping_ip, ip): ip for ip in ipaddress.IPv4Network(network)}
        for future in as_completed(futures):
            ip, is_responsive = future.result()
            counter += 1
            if is_responsive:
                responsive_ips.append((counter, str(ip)))
                print(f"IP Address {ip} is responsive")

    # Sort the results by the counter to maintain the order
    sorted_responsive_ips = sorted(responsive_ips, key=lambda x: x[0])
    return [ip_addr for _, ip_addr in sorted_responsive_ips]

# Example usage: Scanning the network 10.0.0.0/24
responsive_ips = scan_network("10.0.0.0/24")
print("\nResponsive IP Addresses:")
print("\n".join(responsive_ips))