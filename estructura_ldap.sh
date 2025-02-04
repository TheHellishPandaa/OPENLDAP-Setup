#!/bin/bash

# Solicitar dominio de LDAP
echo "Ingrese el dominio de su LDAP (ejemplo: example.com):"
read domain

# Convertimos el dominio en formato Base DN (Distinguished Name)
# Por ejemplo, si el usuario ingresa "example.com", se convierte en "dc=example,dc=com"
base_dn="dc=$(echo $domain | sed 's/\./,dc=/g')"

echo "Base DN generado: $base_dn"

# Archivo de texto con la estructura LDAP pasado como argumento
if [ -z "$1" ]; then
  echo "Uso: $0 <archivo_estructura_ldap.txt>"
  exit 1
fi

# Guardamos el nombre del archivo de entrada y el de salida
txt_file="$1"
ldif_file="estructura_ldap.ldif"

# Verificar si el usuario pasó un archivo de estructura LDAP como argumento
if [ ! -f "$txt_file" ]; then
  echo "Error: El archivo $txt_file no existe."
  exit 1
fi


echo "Convirtiendo a formato LDIF..."
echo "dn: $base_dn" > $ldif_file
echo "objectClass: top" >> $ldif_file
echo "objectClass: dcObject" >> $ldif_file
echo "objectClass: organization" >> $ldif_file
echo "o: Example Corp" >> $ldif_file
echo "" >> $ldif_file

declare -A parent_map
parent_map[0]="$base_dn"

while read -r line; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue  # Omitir líneas vacías y comentarios
  indent_count=$(echo "$line" | sed 's/[^ ]//g' | wc -c)
  clean_line=$(echo "$line" | sed 's/^ *//')
  if [[ $clean_line == OU=* ]]; then
    ou_name=${clean_line#OU=}
    ou_name=$(echo "$ou_name" | tr -d ' ')  # Eliminar espacios en blanco extra
    level=$((indent_count / 2))  # Determinar el nivel de indentación
    parent_dn="${parent_map[$((level-1))]}"
    if [ -z "$parent_dn" ]; then
      parent_dn="$base_dn"
    fi
    full_dn="ou=$ou_name,$parent_dn"
    echo "dn: $full_dn" >> $ldif_file
    echo "objectClass: organizationalUnit" >> $ldif_file
    echo "ou: $ou_name" >> $ldif_file
    echo "" >> $ldif_file
    parent_map[$level]="$full_dn"
  fi
done < "$txt_file"

echo "Verificando archivo LDIF generado..."
cat $ldif_file

echo "Importando estructura en LDAP..."
ldapadd -x -D "cn=admin,$base_dn" -W -f $ldif_file

echo "-------------------------------------------------------"
echo "--------------------------------------"

echo "Archivo de texto, convertido a formato ldif. se guardo en el mismo directorio de trabajo como $ldif_file"
echo "Ahora, utilize ldapadd -x -D cn=admin,dc=tudominio,dc=com -W -f $ldif_file, para importar el archivo LDAP al servidor"
echo "introduzca cn=admin,dc=tudominio,dc=com entre comillas"

echo "--------------------------------------"
echo "-------------------------------------------------------"





