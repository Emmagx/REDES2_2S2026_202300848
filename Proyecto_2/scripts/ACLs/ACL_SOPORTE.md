# Soporte — SIN ACL (decisión de diseño)

> **ISP 3 — MoonLink** · Departamento **Soporte** (`172.16.32.0/26`)
> Equipo: `CF-R2` · Interfaz LAN: `g0/1` · **Sin ACL aplicada**

## Regla del enunciado

| Regla | Resultado |
| :--- | :--- |
| Soporte → Cualquier depto (ICMP, TCP/80, TCP/443) | ✅ Bidireccional, Exitoso |
| Soporte → Seguridad | 🚫 Bloqueado *(se resuelve en `CF-R3` con `SEC_OUT`)* |
| Cualquier depto → Soporte | ✅ Exitoso |

## Por qué no lleva ACL

Igual que Administración: la regla de Soporte es **"habla y escucha a todos"**, así que no hay nada
que negar en su origen. La restricción hacia Seguridad se implementa en el destino con `SEC_OUT`
(véase [ACL_SEGURIDAD.md](ACL_SEGURIDAD.md)), lo que además evita el conflicto entre las dos reglas
del enunciado.

## ⚠️ Conflicto de reglas y su resolución

La tabla del enunciado dice a la vez:

- *"Soporte → Cualquier depto: bidireccional, Exitoso"*
- *"Cualquier depto → Seguridad: Bloqueado"*

Ambas no pueden cumplirse para el par **Soporte ↔ Seguridad**. Se resuelve **dando prioridad a la
regla más restrictiva** (la de Seguridad), que es el criterio estándar de firewall, coincide con el
orden en que el enunciado lista las reglas y es coherente con la naturaleza aislada del departamento
de Seguridad.

**Evidencia en la matriz de pruebas:** `PC1-SOPORTE → PC1-SEGURIDAD = Failed`.

> Esta justificación hay que explicarla en la evaluación oral: es una de las preguntas más probables.

## Verificación

```text
show ip access-lists            ! no debe aparecer ninguna ACL en CF-R2
show ip interface g0/1
```
