# Script: SW3-SEGURIDAD

```text
enable
configure terminal
hostname SW3-SEGURIDAD
interface range f0/1-2
 channel-group 1 mode active
 exit
interface port-channel 1
 switchport mode trunk
 exit
```
