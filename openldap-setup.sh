#!/bin/bash

# Solicitar dominio de LDAP
echo "Ingrese el dominio de su LDAP (ejemplo: example.com):"
read domain
base_dn="dc=$(echo $domain | sed 's/\./,dc=/g')"

# Archivo de texto con la estructura LDAP
txt_file="estructura_ldap.txt"
ldif_file="estructura_ldap.ldif"


echo "Convirtiendo a formato LDIF..."
echo "dn: $base_dn" > $ldif_file
echo "objectClass: top" >> $ldif_file
echo "objectClass: dcObject" >> $ldif_file
echo "objectClass: organization" >> $ldif_file
echo "o: Example Corp" >> $ldif_file
echo "" >> $ldif_file

while read -r line; do
  indent_count=$(echo "$line" | sed 's/[^ ]//g' | wc -c)
  clean_line=$(echo "$line" | sed 's/^ *//')
  if [[ $clean_line == OU=* ]]; then
    ou_name=${clean_line#OU=}
    parent_dn="$base_dn"
    if (( indent_count > 2 )); then
      parent_ou=$(echo "$line" | sed -E 's/^ +//; s/ .*//')
      parent_dn="ou=$parent_ou,$parent_dn"
    fi
    echo "dn: ou=$ou_name,$parent_dn" >> $ldif_file
    echo "objectClass: organizationalUnit" >> $ldif_file
    echo "ou: $ou_name" >> $ldif_file
    echo "" >> $ldif_file
  fi
done < $txt_file

echo "Importando estructura en LDAP..."
ldapadd -x -D "cn=admin,$base_dn" -W -f $ldif_file

echo "Estructura LDAP creada exitosamente."
