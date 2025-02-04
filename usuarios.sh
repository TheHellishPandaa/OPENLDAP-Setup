!/bin/bash

# Configuracion
archivo_usuarios="usuarios.txt" #Cambia por tu archivo .txt de usuarios
archivo_ldif="usuarios.ldif" #Archivo .ldif que va a devolver
base_dn="dc=jgalvez,dc=ies" #Nombre del dominio

# Verificar que el archivo de usuarios existe
if [ ! -f "$archivo_usuarios" ]; then
    echo "Error: El archivo $archivo_usuarios no existe."
    exit 1
fi

# Verificar si el archivo LDIF ya existe y evitar sobrescribirlo
if [ -f "$archivo_ldif" ]; then
    echo "Advertencia: El archivo $archivo_ldif ya existe. Deseas sobrescribirlo? (s/n)"
    read respuesta
    if [[ "$respuesta" != "s" && "$respuesta" != "S" ]]; then
        echo "Operación cancelada. No se sobrescribió el archivo LDIF."
        exit 1
    fi
fi

# Crear el archivo LDIF
echo "# Archivo LDIF generado para OpenLDAP" > "$archivo_ldif"

# Generar entradas LDIF para cada usuario
uid_number=2000  # Número de inicio para UID
gid_number=2000  # Grupo de usuarios

default_password="password123" #Contraseña por defecto
hashed_password="{SSHA}$(echo -n "$default_password" | sha1sum | awk '{print $1}')" #Esto hashea la contraseña por defecto en SSHA

while IFS=, read -r usuario ou; do
    # Escribir la entrada en el archivo LDIF, utilizando la OU correspondiente
    cat <<EOF >> "$archivo_ldif"

dn: uid=$usuario,$ou,$base_dn
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: $usuario
sn: $usuario
uid: $usuario
uidNumber: $uid_number
gidNumber: $gid_number
homeDirectory: /home/$usuario
loginShell: /bin/bash
userPassword: $hashed_password

EOF

    # Incrementar UID y GID para el siguiente usuario
    ((uid_number++))
    ((gid_number++))

done < "$archivo_usuarios"

echo "Archivo LDIF generado y guardado como $archivo_ldif"

ldapadd -x -D cn=admin,$base_dn -W -f "$archivo_ldif"
