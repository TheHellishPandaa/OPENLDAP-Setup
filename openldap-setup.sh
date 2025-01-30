#!/bin/bash

# Solicitar configuración al usuario
echo "Introduce el dominio LDAP (ejemplo: example.com):"
read DOMAIN
echo "Introduce la contraseña del usuario admin de LDAP:"
read -s LDAP_PASSWORD

echo "Introduce la ruta del directorio base para los usuarios (ejemplo: /home):"
read HOME_BASE
echo "Introduce el shell por defecto para los usuarios (ejemplo: /bin/bash):"
read DEFAULT_SHELL

BASE_DN="dc=$(echo $DOMAIN | sed 's/\./,dc=/g')"
LDAP_SERVER="ldap://localhost"
BIND_DN="cn=admin,$BASE_DN"

# Confirmación del usuario
echo "Se instalará la estructura LDAP en el dominio: $DOMAIN"
echo "¿Deseas continuar? (s/n)"
read CONFIRMATION
if [[ "$CONFIRMATION" != "s" ]]; then
    echo "Operación cancelada."
    exit 1
fi

# Archivo temporal para las entradas LDIF
LDIF_FILE="ou_structure.ldif"

echo "" > $LDIF_FILE

add_ou() {
    echo "dn: ou=$1,$2" >> $LDIF_FILE
    echo "objectClass: organizationalUnit" >> $LDIF_FILE
    echo "ou: $1" >> $LDIF_FILE
    echo "" >> $LDIF_FILE
}

add_group() {
    echo "dn: cn=$1,ou=$2,$BASE_DN" >> $LDIF_FILE
    echo "objectClass: groupOfNames" >> $LDIF_FILE
    echo "cn: $1" >> $LDIF_FILE
    echo "member: cn=admin,$BASE_DN" >> $LDIF_FILE
    echo "" >> $LDIF_FILE
}

add_user() {
    echo "Introduce el nombre de usuario:"
    read USERNAME
    echo "Introduce la contraseña para $USERNAME:"
    read -s PASSWORD
    
    echo "Selecciona la OU donde guardar al usuario:"
    select OU in OU_EQUIPODIRECTIVO OU_PROFESORES OU_ADMINISTRACION OU_SECRETARIO OU_DPTOTECNICO OU_ESO OU_FP; do
        if [ -n "$OU" ]; then
            break
        else
            echo "Selección no válida. Inténtalo de nuevo."
        fi
    done
    
    USER_DN="cn=$USERNAME,ou=$OU,$BASE_DN"
    echo "dn: $USER_DN" >> $LDIF_FILE
    echo "objectClass: inetOrgPerson" >> $LDIF_FILE
    echo "objectClass: posixAccount" >> $LDIF_FILE
    echo "objectClass: shadowAccount" >> $LDIF_FILE
    echo "cn: $USERNAME" >> $LDIF_FILE
    echo "sn: Usuario" >> $LDIF_FILE
    echo "uid: $USERNAME" >> $LDIF_FILE
    echo "uidNumber: $(shuf -i 1000-9999 -n 1)" >> $LDIF_FILE
    echo "gidNumber: 1000" >> $LDIF_FILE
    echo "homeDirectory: $HOME_BASE/$USERNAME" >> $LDIF_FILE
    echo "loginShell: $DEFAULT_SHELL" >> $LDIF_FILE
    echo "userPassword: $(openssl passwd -crypt $PASSWORD)" >> $LDIF_FILE
    echo "" >> $LDIF_FILE
}

# Crear la estructura de OUs
for OU in OU_EQUIPODIRECTIVO OU_PROFESORES OU_ADMINISTRACION OU_SECRETARIO OU_DPTOTECNICO OU_ESO OU_FP; do
    add_ou "$OU" "$BASE_DN"
done

# Crear los grupos en OU_EQUIPODIRECTIVO
add_group "GP_JefeEstudiosAdjunto" "OU_EQUIPODIRECTIVO"

# Crear usuarios
echo "¿Cuántos usuarios deseas crear?"
read USER_COUNT

for (( i=1; i<=USER_COUNT; i++ )); do
    add_user
done

# Aplicar la configuración
ldapadd -x -H $LDAP_SERVER -D "$BIND_DN" -w "$LDAP_PASSWORD" -f $LDIF_FILE

# Limpiar el archivo temporal
rm $LDIF_FILE

echo "Estructura LDAP y cuentas de usuario creadas correctamente. Los usuarios pueden iniciar sesión en el dominio."
