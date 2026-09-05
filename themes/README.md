# x — temas

Cada tema es un directorio `themes/<nombre>/` con una paleta `colors`
(formato `clave=hex`, una por linea).

## Comandos

- `x theme list` — lista los temas disponibles.
- `x theme set <nombre>` — instala la paleta como `~/.config/x/theme.conf`
  (con backup de la anterior) y registra el tema activo en
  `~/.local/state/x/theme`.

## Consumidores

La config de Hyprland real (repo externo) gestiona sus propias paletas
(`dock/palettes`) y se instala por separado. Este almacen es la paleta del
propio sistema x; los consumidores (shell, terminales, etc.) leen de
`~/.config/x/theme.conf`.
