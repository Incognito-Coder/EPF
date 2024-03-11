#!/bin/bash

ip=$1
ports=$2
proto=$3

install_req(){
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
        centos|fedora)
            yum install -y -q net-tools
            touch epfinstalled
        ;;
        *)
            apt install -y -q net-tools iptables-persistent
            touch epfinstalled
        ;;
    esac
    clear
}
usage(){
    echo -e "Usage: iptables.sh 1 2 3\n1: Destination IP\n2: Desired Ports | Example Array of ports: 443,80,2083\n3: Protocol TCP/UDP lowercase."
}

modify(){
    echo -e "Easy Port Forwarder By Incognito Coder\nGithub Page: https://github.com/Incognito-Coder"
    publicIP=$(hostname -I | awk '{print $1}')
    interface=$(route | grep '^default' | grep -o '[^ ]*$')
    echo "Enabling IP Forwarding"
    sysctl net.ipv4.ip_forward=1 > /dev/null 2>&1
    if iptables --table nat --list | grep -q "ssh"; then
        echo "No need to forward SSH Port,Already Exist!"
    else
        echo "Forwarding SSH Port to $publicIP"
        iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination $publicIP
    fi
    for i in $(echo $ports | tr "," "\n")
    do
        echo "Moving Port $i to $ip:$i"
        iptables -t nat -A PREROUTING -p $proto --dport $i -j DNAT --to-destination $ip
    done
    echo "Finalizing Changes in IP Tables."
    iptables -t nat -A POSTROUTING -j MASQUERADE -o $interface
}

modify_nat(){
    echo -e "Easy Port Forwarder By Incognito Coder\nGithub Page: https://github.com/Incognito-Coder"
    publicIP=$(hostname -I | awk '{print $1}')
    interface=$(route | grep '^default' | grep -o '[^ ]*$')
    echo "Enabling IP Forwarding"
    sysctl net.ipv4.ip_forward=1 > /dev/null 2>&1
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
}

flush(){
    echo "Stopping IPv4 firewall and allowing everyone..."
    ipt="/sbin/iptables"
    [ ! -x "$ipt" ] && { echo "$0: \"${ipt}\" command not found."; exit 1; }
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
}

menu(){
    echo "Welcome to Easy Port Forwarder"
    PS3='Please enter your choice: '
    options=("Port Forward" "NAT Forward" "Port to Port" "Flush Rules" "Save Rules" "Restore Rules" "Print Usage" "Quit")
    select opt in "${options[@]}"
    do
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
                echo "you chose choice $REPLY which is $opt"
            ;;
            "Flush Rules")
                flush
                break
            ;;
            "Save Rules")
                sudo /sbin/iptables-save > /etc/iptables/rules.v4
                echo "Saved."
            ;;
            "Restore Rules")
                sudo /sbin/iptables-restore < /etc/iptables/rules.v4
                echo "Restored."
            ;;
            "Print Usage")
                usage
                break
            ;;
            "Quit")
                break
            ;;
            *) echo "invalid option $REPLY";;
        esac
    done
}

if [[ $# -eq 0 ]] ; then
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
