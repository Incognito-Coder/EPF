# Easy Port Forwarder
A bash script to set up port forwarding in `iptables` on Linux operating systems automatically and easily,It also supports `6to4` tunnel.
## Usage
OneClick command to download script:
```bash
curl -o epf.sh -L https://raw.githubusercontent.com/Incognito-Coder/EPF/master/iptables.sh && chmod +x epf.sh
```
then you must see `epf.sh` in your current dir.
### Example
```bash
bash epf.sh 185.132.80.187 443,8080,2083,2096 tcp
```
> First arg is your destination server. \
> Second arg is Specific port,it can be single [443] or array [1234,8745,8585]. \
> Third arg is Protocol mode TCP/UDP pass lowercase string **tcp** , **udp** .
## Cleaning IPTable Rules
this command flush all chain rules in iptables.
```bash
./epf.sh flush
```
## Using Menu
u can access to shell based menu with this command
```bash
sudo ./epf.sh menu
```
```
root@fakemind:~$ sudo ./epf.sh menu
Welcome to Easy Port Forwarder
1) Port Forward     3) Port to Port    5) Flush Rules     7) Restore Rules   9) Print Usage
2) NAT Forward      4) Tunnel 6TO4     6) Save Rules      8) Show Rules     10) Quit
Please enter your choice:
```

## Supported OSes
* Ubuntu|Debian
* CentOS
* ArchLinux
* AlmaLinux
## Stargazers over time
[![Stargazers over time](https://starchart.cc/Incognito-Coder/EPF.svg?variant=adaptive)](https://starchart.cc/Incognito-Coder/EPF)
