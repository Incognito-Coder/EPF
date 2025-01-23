#!/bin/bash

ip=$1
ports=$2
proto=$3
dport=$4

install_req() {
    clear
    # Check OS and set release variable
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        release=$ID
    elif [[ -f /usr/lib/os-release ]]; then
        # shellcheck disable=SC1091
        source /usr/lib/os-release
        release=$ID
    else
        echo "Failed to check the system OS, please contact the author!" >&2
        exit 1
    fi
    echo "The OS release is: $release"
    case "${release}" in
    centos | fedora | almalinux)
        yum upgrade && yum install -y -q net-tools iptables
        touch .epfinstalled
        ;;
    arch | manjaro)
        pacman -Sy --noconfirm net-tools inetutils iptables
        touch .epfinstalled
        ;;
    *)
        apt update && apt install -y -q net-tools iptables-persistent iptables
        touch .epfinstalled
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
        iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination "$publicIP"
    fi
    for i in $(echo "$ports" | tr "," "\n"); do
        echo "Moving Port $i to $ip:$i"
        iptables -t nat -A PREROUTING -p "$proto" --dport "$i" -j DNAT --to-destination "$ip"
    done
    echo "Finalizing Changes in IP Tables."
    iptables -t nat -A POSTROUTING -j MASQUERADE -o "$interface"
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
        iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination "$publicIP"
    fi
    echo "Moving NAT to $ip"
    iptables -t nat -A PREROUTING -j DNAT --to-destination "$ip"
    echo "Finalizing Changes in IP Tables."
    iptables -t nat -A POSTROUTING -j MASQUERADE -o "$interface"
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
        iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination "$publicIP"
    fi
    echo "Moving Port $ports to $ip:$dport"
    iptables -t nat -A PREROUTING -p "$proto" --dport "$ports" -j DNAT --to-destination "$ip:$dport"
    echo "Finalizing Changes in IP Tables."
    iptables -t nat -A POSTROUTING -j MASQUERADE -o "$interface"
    menu
}

6to4() {
    clear
    echo "Local Tunnel ipv6 to ipv4"
    publicIP=$(hostname -I | awk '{print $1}')
    PS3='Select an option? '
    options=("Sender" "Receiver" "Reset Network" "Remove Startup" "Back")
    select opt in "${options[@]}"; do
        case $opt in
        "Sender")
            read -p "Enter Dest(receiver) IP: " ip
            # Clean last tunnel
            ip tunnel del 6to4_To_KH >/dev/null 2>&1
            ip -6 tunnel del ipip6Tun_To_KH >/dev/null 2>&1
            # Do new job
            ip tunnel add 6to4_To_KH mode sit remote "$ip" local "$publicIP"
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
            iptables -t nat -A POSTROUTING -j MASQUERADE
            echo "IP $publicIP moved to $ip"
            sleep 3
            startup_prompt 1 "$ip" "$publicIP"
            menu
            break
            ;;
        "Receiver")
            read -p "Enter Target(sender) IP: " ip
            # Clean last tunnel
            ip tunnel del 6to4_To_IR >/dev/null 2>&1
            ip -6 tunnel del ipip6Tun_To_IR >/dev/null 2>&1
            # Do new job
            ip tunnel add 6to4_To_IR mode sit remote "$ip" local "$publicIP"
            ip -6 addr add fc00::2/64 dev 6to4_To_IR
            ip link set 6to4_To_IR mtu 1480
            ip link set 6to4_To_IR up
            ip -6 tunnel add ipip6Tun_To_IR mode ipip6 remote fc00::1 local fc00::2
            ip addr add 192.168.13.2/30 dev ipip6Tun_To_IR
            ip link set ipip6Tun_To_IR mtu 1440
            ip link set ipip6Tun_To_IR up
            echo "IP $publicIP moved to $ip"
            sleep 3
            startup_prompt 2 "$ip" "$publicIP"
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
                flush
            else
                echo "No tunnel found,returing to menu..."
                sleep 2
                menu
            fi
            break
            ;;
        "Remove Startup")
            if systemctl is-enabled epftunnel.service | grep -q 'enabled'; then
                systemctl disable epftunnel &> /dev/null
                echo "EPF Tunnel disabled at startup."
                sleep 2
                menu
            else
                echo "epftunnel.service already disabled"
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
show_rules() {
    iptables -t nat -L PREROUTING -n --line-numbers | awk '
    $1 ~ /^[0-9]+$/ {
        protocol = $3
        line_number = $1
        forwarding = ""
        port_type = ""
        ports = ""
        ip = ""
    
        for (i = 6; i <= NF; i++) {
            if ($i ~ /dpt:/ || $i ~ /dports/) {
                port_type = ($i ~ /dpt:/) ? "Port:" : "Ports:"
                ports = $i
                sub(/dpt:|dports /, "", ports)
                if (port_type == "Ports:") {
                    for (j = i + 1; j <= NF && $j !~ /to:/; j++) {
                        ports = ports "," $j
                    }
                    sub(/^,/, "", ports)
                    sub(/dports,/, "", ports)
                }
                for (j = i + 1; j <= NF; j++) {
                    if ($j ~ /to:/) {
                        ip = $j
                        for (k = j + 1; k <= NF; k++) {
                            ip = ip " " $k
                        }
                        sub(/to:/, "IP: ", ip)
                        break
                    }
                }
                break
            }
        }
        print line_number ") " ip " " port_type " " ports " Protocol: " protocol
    }'
}
remove_rules() {
    clear
    show_rules
    echo "*) Flush all Rules"
    echo "0) Back"
    read -p "Select a Remove option: " Choice
    case "$Choice" in
    "*")
        flush
        ;;
    "0")
        menu
        ;;
    [1-9]*)
        iptables -t nat -D PREROUTING "$Choice"
        iptables -t nat -D POSTROUTING "$Choice"
        netfilter-persistent save >/dev/null 2>&1
        echo "Rule $Choice removed successfully"
        read -p "Press Enter To Continue"
        ;;
    *)
        echo "Invalid Choice"
        sleep 1
        ;;
    esac
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

startup_prompt(){
    read -p "Would you like to run this tunnel at system boot? [y/n]: " choose
    if [[ "$choose" == "y" || "$choose" == "Y" ]]; then
        case $1 in
        "1")
            cat > /etc/epftunnel.sh <<EOF
#!/bin/bash

ip tunnel add 6to4_To_KH mode sit remote "$2" local "$3"
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
iptables -t nat -A POSTROUTING -j MASQUERADE
EOF
            echo "Tunnel setup script created at /etc/epftunnel.sh"
            chmod +x /etc/epftunnel.sh
            cat > /etc/systemd/system/epftunnel.service <<EOF
[Unit]
Description=EPF Tunnel
After=network.target

[Service]
ExecStart=/bin/bash /etc/epftunnel.sh

[Install]
WantedBy=multi-user.target
EOF
            systemctl daemon-reload &> /dev/null && systemctl enable epftunnel &> /dev/null
            ;;
        "2")
            cat > /etc/epftunnel.sh <<EOF
#!/bin/bash

ip tunnel add 6to4_To_IR mode sit remote "$2" local "$3"
ip -6 addr add fc00::2/64 dev 6to4_To_IR
ip link set 6to4_To_IR mtu 1480
ip link set 6to4_To_IR up
ip -6 tunnel add ipip6Tun_To_IR mode ipip6 remote fc00::1 local fc00::2
ip addr add 192.168.13.2/30 dev ipip6Tun_To_IR
ip link set ipip6Tun_To_IR mtu 1440
ip link set ipip6Tun_To_IR up
EOF
            echo "Tunnel setup script created at /etc/epftunnel.sh"
            chmod +x /etc/epftunnel.sh
            cat > /etc/systemd/system/epftunnel.service <<EOF
[Unit]
Description=EPF Tunnel
After=network.target

[Service]
ExecStart=/bin/bash /etc/epftunnel.sh

[Install]
WantedBy=multi-user.target
EOF
            systemctl daemon-reload &> /dev/null && systemctl enable epftunnel &> /dev/null
            ;;
        esac      
    fi

}

set_mtu(){
    PS3='Please select your desired MTU: '
    interface=$(route | grep '^default' | grep -o '[^ ]*$')
    options=("1300" "1420" "1480" "1500" "9000" "Back")
    select opt in "${options[@]}"; do
        case $opt in
        "1300")
            ip li set mtu 1300 dev "$interface"
            echo "MTU of $interface sets to 1300"
            sleep 2
            menu
            break
            ;;
        "1420")
            ip li set mtu 1420 dev "$interface"
            echo "MTU of $interface sets to 1420"
            sleep 2
            menu
            break
            ;;
        "1480")
            ip li set mtu 1480 dev "$interface"
            echo "MTU of $interface sets to 1480"
            sleep 2
            menu
            break
            ;;
        "1500")
            ip li set mtu 1500 dev "$interface"
            echo "MTU of $interface sets to 1500"
            sleep 2
            menu
            break
            ;;
        "9000")
            ip li set mtu 9000 dev "$interface"
            echo "MTU of $interface sets to 9000"
            sleep 2
            menu
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

update_script(){
    wget --no-check-certificate -O epf.sh https://raw.githubusercontent.com/Incognito-Coder/EPF/master/iptables.sh &> /dev/null
    chmod +x epf.sh
    if [[ $? == 0 ]]; then
        echo -e "Upgrade script succeeded, Please rerun the script"
        exit 0
    else
        echo -e "Failed to update the script."
        return 1
    fi
}

menu() {
    clear
    echo "Welcome to Easy Port Forwarder & Tunneling"
    PS3='Please enter your choice: '
    options=("Port Forward" "NAT Forward" "Port to Port" "Tunnel 6TO4" "Remove Rules" "Save Rules" "Restore Rules" "Set MTU" "Show Rules" "Update Script" "Print Usage" "Quit")
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
        "Remove Rules")
            remove_rules
            break
            ;;
        "Save Rules")
            /sbin/iptables-save >/etc/iptables/rules.v4
            echo "Saved."
            ;;
        "Restore Rules")
            /sbin/iptables-restore </etc/iptables/rules.v4
            echo "Restored."
            ;;
        "Set MTU")
            set_mtu
            break
            ;;
        "Show Rules")
            iptables -t nat --list
            read -n1 -r -p "Press any key to continue..."
            ;;
        "Update Script")
            update_script
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
        if ! [ -f .epfinstalled ]; then
            install_req
        fi
        menu
    else
        if ! [ -f .epfinstalled ]; then
            install_req
        fi
        modify
    fi
fi
