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

# Generar el contenido del archivo LDIF
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
    echo "Introduce el nombre de usuario para $1 en $2:"
    read USERNAME
    echo "Introduce la contraseña para $USERNAME:"
    read -s PASSWORD
    
    USER_DN="cn=$USERNAME,ou=$2,$BASE_DN"
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

# Crear las Unidades Organizativas principales
add_ou "OU_EQUIPODIRECTIVO" "$BASE_DN"
add_ou "OU_PROFESORES" "$BASE_DN"
add_ou "OU_ADMINISTRACION" "$BASE_DN"
add_ou "OU_SECRETARIO" "$BASE_DN"
add_ou "OU_DPTOTECNICO" "$BASE_DN"
add_ou "OU_ESO" "$BASE_DN"
add_ou "OU_FP" "$BASE_DN"

# Crear los grupos en OU_EQUIPODIRECTIVO
add_group "GP_JefeEstudiosAdjunto" "OU_EQUIPODIRECTIVO"

# Sub OU dentro de Profesores
for dept in DPTOINFORMATICA DPTOINGLES DPTOLENGUA DPTOMATEMATICAS DPTOFOL DPTOCIENCIAS DPTOGEOGRAFIA DPTOTECNOLOGIA; do
    add_ou "OU_$dept" "ou=OU_PROFESORES,$BASE_DN"
done

# Sub OU dentro de DPTOINFORMATICA
add_ou "OU_INFORMATICA" "ou=OU_DPTOINFORMATICA,ou=OU_PROFESORES,$BASE_DN"
add_ou "OU_SISTEMAS" "ou=OU_DPTOINFORMATICA,ou=OU_PROFESORES,$BASE_DN"

# Sub OU dentro de DPTOCIENCIAS
add_ou "OU_CIENCIASFISICAS" "ou=OU_DPTOCIENCIAS,ou=OU_PROFESORES,$BASE_DN"
add_ou "OU_BIOLOGIA" "ou=OU_DPTOCIENCIAS,ou=OU_PROFESORES,$BASE_DN"

# Sub OU dentro de ESO
for curso in PRIMEROESO SEGUNDOESO TERCEROESO PRIMEROBCH SEGUNDOBCH; do
    add_ou "OU_$curso" "ou=OU_ESO,$BASE_DN"
    for i in {1..3}; do
        add_user "Alumno $i" "OU_$curso"
    done
done

# Sub OU dentro de FP
for ciclo in DAW DAM SMR ASIR POC PED AF; do
    add_ou "OU_$ciclo" "ou=OU_FP,$BASE_DN"
    for i in {1..3}; do
        add_user "Alumno $i" "OU_$ciclo"
    done
done

# Usuarios en departamentos
for dept in DPTOINFORMATICA DPTOINGLES DPTOLENGUA DPTOMATEMATICAS DPTOFOL DPTOCIENCIAS DPTOGEOGRAFIA DPTOTECNOLOGIA; do
    for i in {1..3}; do
        add_user "Profesor $i" "OU_$dept"
    done
done

# Usuarios en administración
for i in {1..2}; do
    add_user "Admin $i" "OU_ADMINISTRACION"
done

# Usuarios en equipo directivo
for i in {1..4}; do
    add_user "Directivo $i" "OU_EQUIPODIRECTIVO"
done

# Usuario en departamento técnico
add_user "tecAdmin" "OU_DPTOTECNICO"

# Aplicar la configuración
ldapadd -x -H $LDAP_SERVER -D "$BIND_DN" -w "$LDAP_PASSWORD" -f $LDIF_FILE

# Limpiar el archivo temporal
rm $LDIF_FILE

echo "Estructura LDAP y cuentas de usuario creadas correctamente. Los usuarios pueden iniciar sesión en el dominio."
