# x — migraciones

Las migraciones son scripts bash **idempotentes**, uno por cambio de configuracion
del usuario, nombrados `migrations/<timestamp>-<nombre>.sh`.

## Contrato

- Se ejecutan por usuario (`x migrate`) y tambien al final de `x update`.
- Una migracion aplicada con exito se marca en
  `~/.local/state/x/migrations/<nombre>` y no se vuelve a ejecutar.
- Deben ser seguras de repetir (aunque el marker ya exista, no romper) y no
  depender de red ni de infraestructura externa.
- Si una migracion falla, `x migrate` detiene el informe con error y no marca.

## Como anadir una

```bash
# migrations/20260905120000-config-x.sh
mkdir -p "$HOME/.config/x"
# ... cambio idempotente ...
```

Creadas bajo `x/reboot` del repo; se empaquetan con el resto del payload.
