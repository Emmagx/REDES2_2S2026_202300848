# Script: SW2-SOPORTE

```text
enable
configure terminal
hostname SW2-SOPORTE
interface range f0/1-2
 channel-group 1 mode passive
 exit
interface port-channel 1
 switchport mode trunk
 exit
```
