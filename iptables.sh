#!/bin/bash

ip=$1
ports=$2
proto=$3
dport=$4

install_req() {
    clear
    # Check OS and set release variable
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        release=$ID
    elif [[ -f /usr/lib/os-release ]]; then
        source /usr/lib/os-release
        release=$ID
    else
        echo "Failed to check the system OS, please contact the author!" >&2
        exit 1
    fi
    echo "The OS release is: $release"
    case "${release}" in
    centos | fedora | almalinux)
        yum upgrade && yum install -y -q net-tools
        touch epfinstalled
        ;;
    arch | manjaro)
        pacman -Sy --noconfirm net-tools inetutils
        touch epfinstalled
        ;;
    *)
        apt update && apt install -y -q net-tools iptables-persistent
        touch epfinstalled
        ;;
    esac
    clear
}

usage() {
    echo -e "Usage: iptables.sh 1 2 3\n1: Destination IP\n2: Desired Ports | Example Array of ports: 443,80,2083\n3: Protocol TCP/UDP lowercase."
}

modify() {
    clear
    echo -e "Easy Port Forwarder By Incognito Coder\nGithub Page: https://github.com/Incognito-Coder"
    publicIP=$(hostname -I | awk '{print $1}')
    interface=$(route | grep '^default' | grep -o '[^ ]*$')
    echo "Enabling IP Forwarding"
    sysctl net.ipv4.ip_forward=1 >/dev/null 2>&1
    if iptables --table nat --list | grep -q "ssh"; then
        echo "No need to forward SSH Port,Already Exist!"
    else
        echo "Forwarding SSH Port to $publicIP"
        iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination $publicIP
    fi
    for i in $(echo $ports | tr "," "\n"); do
        echo "Moving Port $i to $ip:$i"
        iptables -t nat -A PREROUTING -p $proto --dport $i -j DNAT --to-destination $ip
    done
    echo "Finalizing Changes in IP Tables."
    iptables -t nat -A POSTROUTING -j MASQUERADE -o $interface
}

modify_nat() {
    clear
    echo -e "Easy Port Forwarder By Incognito Coder\nGithub Page: https://github.com/Incognito-Coder"
    publicIP=$(hostname -I | awk '{print $1}')
    interface=$(route | grep '^default' | grep -o '[^ ]*$')
    echo "Enabling IP Forwarding"
    sysctl net.ipv4.ip_forward=1 >/dev/null 2>&1
    if iptables --table nat --list | grep -q "ssh"; then
        echo "No need to forward SSH Port,Already Exist!"
    else
        echo "Forwarding SSH Port to $publicIP"
        iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination $publicIP
    fi
    echo "Moving NAT to $ip"
    iptables -t nat -A PREROUTING -j DNAT --to-destination $ip
    echo "Finalizing Changes in IP Tables."
    iptables -t nat -A POSTROUTING -j MASQUERADE -o $interface
    menu
}

port_to_port() {
    clear
    echo -e "Easy Port Forwarder By Incognito Coder\nGithub Page: https://github.com/Incognito-Coder"
    publicIP=$(hostname -I | awk '{print $1}')
    interface=$(route | grep '^default' | grep -o '[^ ]*$')
    echo "Enabling IP Forwarding"
    sysctl net.ipv4.ip_forward=1 >/dev/null 2>&1
    if iptables --table nat --list | grep -q "ssh"; then
        echo "No need to forward SSH Port,Already Exist!"
    else
        echo "Forwarding SSH Port to $publicIP"
        iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination $publicIP
    fi
    echo "Moving Port $ports to $ip:$dport"
    iptables -t nat -A PREROUTING -p $proto --dport $ports -j DNAT --to-destination $ip:$dport
    echo "Finalizing Changes in IP Tables."
    iptables -t nat -A POSTROUTING -j MASQUERADE -o $interface
    menu
}

6to4() {
    clear
    echo "Local Tunnel ipv6 to ipv4"
    publicIP=$(hostname -I | awk '{print $1}')
    PS3='Your current session is? '
    options=("Sender" "Receiver" "Reset Network" "Back")
    select opt in "${options[@]}"; do
        case $opt in
        "Sender")
            read -p "Enter Dest(receiver) IP: " ip
            # Clean last tunnel
            ip tunnel del 6to4_To_KH >/dev/null 2>&1
            ip -6 tunnel del ipip6Tun_To_KH >/dev/null 2>&1
            # Do new job
            ip tunnel add 6to4_To_KH mode sit remote $ip local $publicIP
            ip -6 addr add fc00::1/64 dev 6to4_To_KH
            ip link set 6to4_To_KH mtu 1480
            ip link set 6to4_To_KH up
            ip -6 tunnel add ipip6Tun_To_KH mode ipip6 remote fc00::2 local fc00::1
            ip addr add 192.168.13.1/30 dev ipip6Tun_To_KH
            ip link set ipip6Tun_To_KH mtu 1440
            ip link set ipip6Tun_To_KH up
            sysctl net.ipv4.ip_forward=1 >/dev/null 2>&1
            iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 192.168.13.1
            iptables -t nat -A PREROUTING -j DNAT --to-destination 192.168.13.2
            interface=$(route | grep '^default' | grep -o '[^ ]*$')
            iptables -t nat -A POSTROUTING -j MASQUERADE
            echo "IP $publicIP moved to $ip"
            sleep 3
            menu
            break
            ;;
        "Receiver")
            read -p "Enter Target(sender) IP: " ip
            # Clean last tunnel
            ip tunnel del 6to4_To_IR >/dev/null 2>&1
            ip -6 tunnel del ipip6Tun_To_IR >/dev/null 2>&1
            # Do new job
            ip tunnel add 6to4_To_IR mode sit remote $ip local $publicIP
            ip -6 addr add fc00::2/64 dev 6to4_To_IR
            ip link set 6to4_To_IR mtu 1480
            ip link set 6to4_To_IR up
            ip -6 tunnel add ipip6Tun_To_IR mode ipip6 remote fc00::1 local fc00::2
            ip addr add 192.168.13.2/30 dev ipip6Tun_To_IR
            ip link set ipip6Tun_To_IR mtu 1440
            ip link set ipip6Tun_To_IR up
            echo "IP $publicIP moved to $ip"
            sleep 3
            menu
            break
            ;;
        "Reset Network")
            if ip tunnel show | grep -q '6to4'; then
                echo "Reseting 6TO4 tunnel"
                ip tunnel del 6to4_To_KH >/dev/null 2>&1
                ip -6 tunnel del ipip6Tun_To_KH >/dev/null 2>&1
                ip tunnel del 6to4_To_IR >/dev/null 2>&1
                ip -6 tunnel del ipip6Tun_To_IR >/dev/null 2>&1
                echo "all tunnels deleted"
                sleep 1
                menu
            else
                echo "No tunnel found,returing to menu..."
                sleep 2
                menu
            fi
            break
            ;;
        "Back")
            menu
            break
            ;;
        *) echo "invalid option $REPLY" ;;
        esac
    done
}

flush() {
    clear
    echo "Stopping IPv4 firewall and allowing everyone..."
    ipt="/sbin/iptables"
    [ ! -x "$ipt" ] && {
        echo "$0: \"${ipt}\" command not found."
        exit 1
    }
    $ipt -P INPUT ACCEPT
    $ipt -P FORWARD ACCEPT
    $ipt -P OUTPUT ACCEPT
    $ipt -F
    $ipt -X
    $ipt -t nat -F
    $ipt -t nat -X
    $ipt -t mangle -F
    $ipt -t mangle -X
    $ipt -t raw -F
    $ipt -t raw -X
    sleep 3
    menu
}

menu() {
    clear
    echo "Welcome to Easy Port Forwarder"
    PS3='Please enter your choice: '
    options=("Port Forward" "NAT Forward" "Port to Port" "Tunnel 6TO4" "Flush Rules" "Save Rules" "Restore Rules" "Show Rules" "Print Usage" "Quit")
    select opt in "${options[@]}"; do
        case $opt in
        "Port Forward")
            read -p "Enter Dest IP: " ip
            read -p "Enter Dest Port/Ports separated: " ports
            read -p "Enter ProtocolType TCP/UDP: " proto
            modify
            break
            ;;
        "NAT Forward")
            read -p "Enter Dest IP: " ip
            modify_nat
            break
            ;;
        "Port to Port")
            read -p "Enter Dest IP: " ip
            read -p "Enter IN Port: " ports
            read -p "Enter OUT Port: " dport
            read -p "Enter ProtocolType TCP/UDP: " proto
            port_to_port
            break
            ;;
        "Tunnel 6TO4")
            6to4
            break
            ;;
        "Flush Rules")
            flush
            break
            ;;
        "Save Rules")
            sudo /sbin/iptables-save >/etc/iptables/rules.v4
            echo "Saved."
            ;;
        "Restore Rules")
            sudo /sbin/iptables-restore </etc/iptables/rules.v4
            echo "Restored."
            ;;
        "Show Rules")
            iptables -t nat --list
            read -n1 -r -p "Press any key to continue..."
            ;;
        "Print Usage")
            usage
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY" ;;
        esac
    done
}

if [[ $# -eq 0 ]]; then
    usage
    exit 0
else
    if [[ $1 == "flush" ]]; then
        flush
        exit 0
    elif [[ $1 == "menu" ]]; then
        if ! [ -f epfinstalled ]; then
            install_req
        fi
        menu
    else
        if ! [ -f epfinstalled ]; then
            install_req
        fi
        modify
    fi
fi
