#-------------------------------------------------------------------------------------
# Ejecución por VS2010
#-------------------------------------------------------------------------------------

# SOLO VS2010 - Lanzamiento macros tras dar de alta/duplicar o hacer remove market de una operación.
# Es necesario lanzar las macros para que el lanzador batch ejecutado desde VS2010 pueda coger los datos necesarios.

# 1. Poner variable de ENTORNO de mb_usuario.cfg a TRADING o TRADING_BC dependiendo de donde queramos ejecutar.
# 2. Lanzar lo siguiente:
ksh -x ${BATCH}/scripts/mblanza.sh ${BATCH}/conf_param/mb086000_process.txt 2 300



#-------------------------------------------------------------------------------------
# Ejecución de TRADING por consola
#-------------------------------------------------------------------------------------

# 1. Poner variable de ENTORNO en mb_usuario.cfg a TRADING
# 2. Ejecutar:
ksh -x ${BATCH}/scripts/mb086000.sh

#-------------------------------------------------------------------------------------
# Ejecuciones de TRADING_BC por consola
#-------------------------------------------------------------------------------------

# 1. (SOLO PRIMERA VEZ): Copiar script a local (/usr/local/de/mantoei/bruiz/scripts) y cambiar la cola de Bancomer por la de Europa
# 2. Poner variable de ENTORNO de mb_usuario.cfg a TRADING_BC
# 3. Ejecutar:
/usr/local/de/mantoei/bruiz/scripts/mb086000.sh





ksh -x ${BATCH}/scripts/mb085900.sh