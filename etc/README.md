# x — drop-ins de /etc

Este arbol se vuelca sobre `/etc` durante la fase de configuracion del sistema
(`install/config.sh`). Cada subdirectorio replica una ruta de `/etc`:

- `sysctl.d/` — parametros de kernel.
- `tmpfiles.d/` — ficheros/permisos temporales.
- `sudoers.d/` — reglas de sudo.
- `pacman.d/hooks/` — hooks de pacman propios.

Regla: no pisar ficheros de paquetes; usar siempre drop-ins. Un fichero ya
modificado por el administrador no se sobrescribe.
