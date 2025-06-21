# IPv6 and IPv4 numeric tools, for Linux Shell
#### Tools to convert between numbers and IP, both IPv4 and IPv6.
These tools supply the lack of numeric capability Linux shell has over IPv6 and IPv4 addresses directly, converting them to numbers, so, they can be easily operated inside a shell script as a number, and also convert numbers back to IPv6/IPv4 if needed.
The main application for these binaries (ip6tonum, numtoip6, ip4tonum and numtoip4) is inside an administrative shell script, that converts or uses IP addresses (or IP ranges).

Some basic examples:
---
> Adding IPv4 number to a NAT64 address space, and then ping:
```
─ ❯ ping $(numtoip6 $(expr $(ip6tonum 64:ff9b::) + $(ip4tonum 203.0.113.255)))
Debug: 0064 FF9B 0000 0000 0000 0000 0000 0000 
Debug: 0064 FF9B 0000 0000 0000 0000 CB00 71FF 
PING 64:ff9b::cb00:71ff (64:ff9b::cb00:71ff) 56 bytes de dados
64 bytes de 64:ff9b::cb00:71ff: icmp_seq=1 ttl=107 tempo=50.6 ms
64 bytes de 64:ff9b::cb00:71ff: icmp_seq=2 ttl=107 tempo=47.6 ms
64 bytes de 64:ff9b::cb00:71ff: icmp_seq=3 ttl=107 tempo=35.1 ms
64 bytes de 64:ff9b::cb00:71ff: icmp_seq=4 ttl=107 tempo=41.7 ms

--- 64:ff9b::cb00:71ff estatísticas de ping ---
4 pacotes transmitidos, 4 recebidos, 0% packet loss, time 3002ms
rtt min/avg/max/mdev = 35.098/43.733/50.562/5.917 ms
```
---
> Stripping away NAT64 from IPv4 address, and then ping IPv4 address:
```
─ ❯ ping -4 $(numtoip4 $(expr $(ip6tonum 64:ff9b::cb00:71ff) - $(ip6tonum 64:ff9b::)))
Debug: 0064 FF9B 0000 0000 0000 0000 CB00 71FF 
Debug: 0064 FF9B 0000 0000 0000 0000 0000 0000 
PING 203.0.113.255 (203.0.113.255) 56(84) bytes de dados.
64 bytes de 203.0.113.255: icmp_seq=1 ttl=106 tempo=66.9 ms
64 bytes de 203.0.113.255: icmp_seq=2 ttl=106 tempo=63.6 ms
64 bytes de 203.0.113.255: icmp_seq=3 ttl=106 tempo=43.7 ms
64 bytes de 203.0.113.255: icmp_seq=4 ttl=106 tempo=62.7 ms

--- 203.0.113.255 estatísticas de ping ---
4 pacotes transmitidos, 4 recebidos, 0% packet loss, time 2997ms
rtt min/avg/max/mdev = 43.659/59.221/66.882/9.117 ms
```
---
> Converting IPv6 or IPv4 address to the corresponding number:
```
─ ❯ ip6tonum 2001:db8::1
42540766411282592856903984951653826561
Debug: 2001 0DB8 0000 0000 0000 0000 0000 0001

─ ❯ ip4tonum 198.51.100.127
3325256831
```

> Converting number to the corresponding IPv6 or IPv4 address:
```
─ ❯ numtoip6 338963523518870617245727861364146307074
ff02::2
Debug: FF02 0000 0000 0000 0000 0000 0000 0002 

─ ❯ numtoip4 3221226049
192.0.2.65
```
---

> Generate a list of IP addresses (or do something with a list of IP addresses):
```
─ ❯ for i in {0..255}
do
numtoip4 $(expr $(ip4tonum 192.168.128.0) + $i)
sleep 0.2
done

192.168.128.0
192.168.128.1
192.168.128.2
192.168.128.3
192.168.128.4
192.168.128.5
192.168.128.6
...
192.168.128.255
```
---

> 'ip6tonum' command also supports IPv6 address that has an IPv4 portion at the end of address. But numtoip6 does only convert back to the full IPv6 address syntax:
```
─ ❯ ip6tonum 64:ff9b::192.0.2.8
524413980667603649783483184533471752
Debug: 0064 FF9B 0000 0000 0000 0000 C000 0208

─ ❯ numtoip6 524413980667603649783483184533471752
64:ff9b::c000:208
Debug: 0064 FF9B 0000 0000 0000 0000 C000 0208 

```
---
**Note:** *The debug message doesn't go to stdout, don't worry about it. It goes to stderr, so, no interference with numeric values passed inside a script, and this debug message will be turned off on release v0.1 (not rc).*

One used to know how powerfull numbers are in shell scripts may already noticed that the possibilities over working IPs as numbers are almost endless. Hence my motivation to make these tools alive. They're not the perfect solution (native handling IPs as numbers will be it), but they do their job as expected.
The IPv4 tools are highly optimized, and the whole conversion goes inside the binary (no library function for that, only to output), so, they should be the preferred method for working with IPv4 addresses or numbers that has 32 bit size. Because it is rather easy to process 32 bit number when the hardware is fully capable of. IPv6 uses libgmp as an auxiliary 128 bit arithmetic "ALU", which delivers it very well, too, but not as much as the simple 32 bit numbers for IPv4. Also because processing an IPv6 string has some complexity, and I made these tools "fire-proof", hardening the error handlers to avoid any possible bug that could exist otherwise. So, if you find one, please rise an issue, or a pull request.
