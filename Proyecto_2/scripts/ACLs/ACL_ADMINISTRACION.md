# Administración — SIN ACL (decisión de diseño)

> **ISP 1 — FibraNet GT** · Departamento **Administración** (`172.16.18.0/25`)
> Equipo: `T1R4` · Interfaz LAN: `g0/1` · **Sin ACL aplicada**

## Regla del enunciado

| Regla | Resultado |
| :--- | :--- |
| Administración → Cualquier depto (ICMP, TCP/80, TCP/443) | ✅ Bidireccional, Exitoso |
| Cualquier depto → Seguridad | 🚫 Bloqueado *(se resuelve en `CF-R3` con `SEC_OUT`)* |

## Por qué no lleva ACL

La regla de Administración es **"habla y escucha a todos los departamentos"**, sin ninguna restricción
de destino. Un ACL solo tiene sentido cuando hay algo que **negar**; si se aplicara una lista con
`permit ip any any` al final, se gastaría CPU del router evaluando una lista que no restringe nada y
se añadiría un punto único de fallo innecesario.

Por eso la restricción hacia Seguridad **no** se implementa aquí: se implementa en el destino, con
`SEC_OUT` aplicada en sentido `out` sobre la LAN de Seguridad (ver [ACL_SEGURIDAD.md](ACL_SEGURIDAD.md)).

## Verificación

```text
show ip access-lists            ! no debe aparecer ninguna ACL en T1R4
show ip interface g0/1         ! no debe tener "ip access-group"
```

## Qué decir en la evaluación oral si preguntan

> *"Administración y Soporte tienen la regla de comunicarse con todos los departamentos, así que sus
> interfaces se dejan libres: la red fluye naturalmente y las restricciones se aplican en el origen de
> los departamentos que sí las necesitan. La única restricción que los afecta —no entrar a
> Seguridad— se resuelve en el destino con `SEC_OUT`, que solo permite tráfico de retorno."*
