Script para la Creación de Unidades Organizativas y Usuarios en LDAP

Descripción

Este script en Bash automatiza la creación de Unidades Organizativas (OU) y usuarios en un servidor LDAP. Permite definir la estructura organizativa de una institución educativa, incluyendo departamentos, cursos y cuentas de usuario para profesores, alumnos y administrativos.

Características

Solicita interactivamente el dominio LDAP y la contraseña de administrador.

Permite definir el directorio base y el shell predeterminado para los usuarios.

Crea de manera automática:

Unidades Organizativas (OU) según una estructura predefinida.

Grupos dentro de algunas unidades organizativas.

Cuentas de usuario con credenciales definidas por el usuario.

Aplica los cambios en el servidor LDAP y permite el inicio de sesión de los usuarios en el dominio.

Requisitos

Un servidor LDAP funcionando (por ejemplo, OpenLDAP).

Acceso administrativo al servidor LDAP.

Paquete ldap-utils instalado en el sistema.

OpenSSL para el cifrado de contraseñas.

Instalación

Clonar este repositorio:

git clone https://github.com/tuusuario/tu-repositorio.git
cd tu-repositorio

Asegurar permisos de ejecución:

chmod +x crear_ou_ldap.sh

Uso

Ejecutar el script:

./crear_ou_ldap.sh

Ingresar la información solicitada:

Dominio LDAP

Contraseña del administrador LDAP

Directorio base de usuarios

Shell por defecto

Confirmar la creación de la estructura LDAP.

Ingresar los nombres y contraseñas de los usuarios cuando sea solicitado.

El script generará y aplicará la configuración en LDAP.

Estructura de LDAP Creada

El script genera la siguiente estructura de Unidades Organizativas:

OU_EQUIPODIRECTIVO
    ├── GP_JefeEstudiosAdjunto (Grupo)
OU_PROFESORES
    ├── OU_DPTOINFORMATICA
        ├── OU_INFORMATICA
        ├── OU_SISTEMAS
    ├── OU_DPTOCIENCIAS
        ├── OU_CIENCIASFISICAS
        ├── OU_BIOLOGIA
    ├── OU_DPTOINGLES
    ├── OU_DPTOLENGUA
    ├── OU_DPTOMATEMATICAS
    ├── OU_DPTOFOL
    ├── OU_DPTOGEOGRAFIA
    ├── OU_DPTOTECNOLOGIA
OU_ADMINISTRACION
OU_SECRETARIO
OU_DPTOTECNICO
OU_ESO
    ├── OU_PRIMEROESO
    ├── OU_SEGUNDOESO
    ├── OU_TERCEROESO
    ├── OU_PRIMEROBCH
    ├── OU_SEGUNDOBCH
OU_FP
    ├── OU_DAW
    ├── OU_DAM
    ├── OU_SMR
    ├── OU_ASIR
    ├── OU_POC
    ├── OU_PED
    ├── OU_AF

Contribuciones

Las contribuciones son bienvenidas. Puedes abrir un issue o hacer un pull request con mejoras o correcciones.

Licencia

Este proyecto está bajo la licencia GNU General Public License. Puedes ver más detalles en el archivo LICENSE.

Autor: Jaime Galvez Fecha: 2025

