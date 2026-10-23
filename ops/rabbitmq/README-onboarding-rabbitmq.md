# Onboarding de RabbitMQ para G6

## Solicitar el instalador individual

Solicita al responsable de infraestructura de G6 tu instalador individual. Recibirás el archivo asignado a tu perfil y la passphrase por canales separados. No compartas ninguno de los dos.

## Requisitos locales

Necesitas Windows, PowerShell 7, OpenSSH Client y Node.js con npm para ejecutar el smoke de autenticación incluido en el paquete.

## Instalar y conectarse

1. Abre PowerShell 7 y ejecuta de forma privada el instalador que recibiste. Escribe la passphrase solo cuando el instalador la solicite:

   ```powershell
   pwsh.exe -NoProfile -File .\<instalador-asignado>.ps1
   ```

2. Sigue el `README.txt` instalado para iniciar el túnel SSH. Mantén la sesión del túnel abierta mientras uses RabbitMQ.
3. Usa el helper instalado para configurar `RABBITMQ_URL` en el `.env` local de tu microservicio. No publiques ese valor ni lo agregues a archivos versionados.
4. Ejecuta el smoke incluido para validar túnel, conexión y autenticación del perfil. Un resultado correcto no acredita que los handlers comerciales o la integración NestJS estén terminados.

Si la instalación o la validación fallan, comunica el error al responsable de infraestructura de G6. No envíes passphrases, claves privadas, URLs con credenciales ni archivos `.env` en el reporte.
