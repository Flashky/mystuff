#---------------------------------------------------------------------------
# Crear un repositorio remoto
#---------------------------------------------------------------------------

# En primer lugar, es importante que la variable de proxy esté seteada.
git config --global http.proxy cachevgd.igrupobbva:8080

# Creamos el remoto, y subimos los fuentes que tengamos en local.
git remote add origin https://github.com/Flashky/mystuff.git
git push -u origin master

#---------------------------------------------------------------------------
#Bajada de un repositorio remoto
#---------------------------------------------------------------------------
# Copia de repositorio remoto
git clone https://github.com/Flashky/mystuff.git

# Bajada de cambios (repositorio remoto -> repositorio local)
git pull

#---------------------------------------------------------------------------
# Subida de cambios desde el workspace hasta el repositorio remoto
#---------------------------------------------------------------------------

# Ver cambios actuales
git status

# Commit de cambios (workspace -> repositorio local)
git add 'fichero_a_subir'
git commit -m 'Mensaje'

# Subida de cambios (repositorio local -> repositorio remoto)
git push origin master


#---------------------------------------------------------------------------
# Gestión de ramas
#---------------------------------------------------------------------------

# Creación de una rama
git checkout -b nombre_rama

# Volver a la rama principal
git checkout master

# Cambiar a la rama nueva de nuevo
git checkout nombre_rama

# Importante: Si hacemos checkout en local, veremos que las modificaciones se siguen manteniendo en todos lados aunque cambiemos de rama.
# Lo que realmente queremos es tener dos ramas con códigos diferentes, de tal forma que al hacer checkout de una o de otra, nos cambie el código.
# Para poder hacer esto, hay que subir la rama al repositorio remoto antes de empezar a subir cambios:
git push origin nombre_rama

# Fusionar una rama con la rama principal
git checkout master
git merge nombre_rama

# Subir la rama fusionada a remoto 
git push origin master

# Borrar una rama local
git branch -d nombre_rama

# Borrar una rama remota (cuando hayamos terminado, fusionado a master y subido a remoto).
git push origin -d nombre_rama