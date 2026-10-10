# Script: SW1-VENTAS

```text
enable
configure terminal
hostname SW1-VENTAS
interface range f0/1-2
 channel-group 1 mode active
 exit
interface port-channel 1
 switchport mode trunk
 exit
```
