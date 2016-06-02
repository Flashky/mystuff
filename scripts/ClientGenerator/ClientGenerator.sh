#!/bin/ksh

# Parámetros de entrada:
#
# $1 entorno del cual se quiere generar un cliente.
#  	Ejemplo, para generar el cliente de DC1:
#   ./ClientGenerator.sh dc1
#		

# Comentarios:
# - Todos los entornos menos PI y QA tienen rutas de configuración con este aspecto:
# /usr/local/de/dc1/appl/batch/conf
#
# - PI y QA tienen rutas diferentes:
# /usr/local/ei/appl/batch/conf
# /usr/local/qa/appl/batch/conf
#
# Por lo tanto, lo ideal sería que haya dos constantes declaradas para los distintos tipos de ruta.
# - El parámetro de entrada debería ser convertido siempre a minúsculas.
# - Se evaluará si dicho parámetro vale pi o qa para poner una ruta u otra.
# - PI es también conocido como ei, así que se evaluará también tanto 'ei' como 'pi'.


# 1. Captura de parámetros.
# 2. Convertir a minúsculas.
# 3. Establecer que ruta ha de leer.
# 4. Leer el fichero de mb_usuario.cfg para obtener ciertos parámetros
# 5. Ejecutar sustitución sobre las plantillas.
# 6. ¿Hacer ftp?




# Config paths
CONF_PI=/usr/local/ei
CONF_QA=/usr/local/qa
CONF_OTHERS=/usr/local/de
CONF_RELATIVE_PATH=appl/batch/conf

# Tool paths
TOOL_PATH=/usr/local/de/mantoei/bruiz/tools/ClientGenerator
LOG_PATH=${TOOL_PATH}/log/
TEMPLATES_PATH=${TOOL_PATH}/templates/
UTIL_PATH=${TOOL_PATH}/utils/
OUTPUT_PATH=${TOOL_PATH}/output/
TMP_PATH=${TOOL_PATH}/tmp/

# Log files
LOG_FILE=ClientGenerator_$1_$$.log

# Temporary path
TMP_CLIENTS_FOLDER=${TMP_PATH}clients_$$/



############################
# DEFINICION DE FUNCIONES: #
############################
F_LOG()
{
        # Obtenemos la hora
        HORA_ACTUAL=`date +"%d %b %Y %H:%M"`

        # Escribimos en el log
        echo "${HORA_ACTUAL} - ${1}" >> ${LOG_PATH}${LOG_FILE}
}


F_ERROR()
{
        # ${1} Valor del error
        # ${2} Mensaje de error

        # Escribimos en el log
        F_LOG "ERROR: ${1} - ${2}"
}


F_EXIT()
{
        # ${1} Valor del error
        # Escribimos el error y salimos con dicho error
		F_LOG ""
        F_LOG ESTADO-${1}-
		
		if [ $1 -ne 0 ]
		then
			echo ""
			echo "Errors have been detected. Please, check log:"
			echo "${LOG_PATH}${LOG_FILE}"
			echo ""
		fi
		
        echo "ESTADO-${1}-"
		echo "" 
		
        exit ${1}
}


# -------------------------------------------------------------------------------------
# F_GENERATE_DBCLIENT()
# -------------------------------------------------------------------------------------
#
# Generates a zip file containing the TEST and X bat files for database connection
# for the environment specified as a parameter.
#
# -------------------------------------------------------------------------------------
#
# Input parameters:
# 	$1 -> Environment (examples: pi, QA, dc1, RP2)
#
# -------------------------------------------------------------------------------------
#
# Error codes:
# 	2 - Environment doesn't exist or the $BATCH/conf/mb_usuario.cfg path is invalid.
#	3 - Error while generating any of the bat files.
# 	4 - Error on database client compression. (zip).
# -------------------------------------------------------------------------------------

F_GENERATE_DBCLIENT()
{
	F_LOG "--------------------------------------------------------"
	F_LOG "Database client generation"
	F_LOG "--------------------------------------------------------"
	F_LOG ""
	
	# Convert the input data to lowercase and to uppercase.
	ENVIRONMENT_LOWER=`echo $1 | tr '[:upper:]' '[:lower:]'`
	ENVIRONMENT_UPPER=`echo $1 | tr '[:lower:]' '[:upper:]'`
	
	# Create a temporary folder
	TMP_DB_FOLDER=${TMP_CLIENTS_FOLDER}DATABASE_${ENVIRONMENT_UPPER}/
	mkdir ${TMP_DB_FOLDER}
	
	# Template files
	TEMPLATE_TEST_FILE=Template_TEST.txt
	TEMPLATE_X_FILE=Template_X.txt

	# Conf files
	CONF_FILENAME=mb_usuario.cfg



	# Evaluate the different cases of environment to obtain the real $BATCH/conf path
	# This is because PI and QA have a different path pattern from other environments.
	case ${ENVIRONMENT_LOWER} in
		"ei"|"pi")
		CONFIG_PATH=${CONF_PI}/${CONF_RELATIVE_PATH}
		;;
		"qa")
		CONFIG_PATH=${CONF_QA}/${CONF_RELATIVE_PATH}
		;;
		*)
		CONFIG_PATH=${CONF_OTHERS}/${ENVIRONMENT_LOWER}/${CONF_RELATIVE_PATH}
		;;
	esac
	
	# Check if environment or path exists.
	if [ ! -d ${CONFIG_PATH} ]
	then
		F_LOG "Environment ${ENVIRONMENT_UPPER} doesn't exist. Please check conf path:"
		F_LOG "${CONFIG_PATH}"
		F_EXIT 2
	fi
	
	# Initialize database values
	.  ${CONFIG_PATH}/${CONF_FILENAME}

	# Generate output file names.

	# Sometimes, (but not always) the environment name (ie: TEST23) is included at the mb_usuario.conf file.
	# If so, we use that name to create the filename. Otherwise, we just add "TEST" or "X" without specifying number.
	if [ "X${BBDD_M}" = "X" ]
	then
		ENV_TEST="TEST"
	else
		ENV_TEST=${BBDD_M}
	fi

	if [ "X${BBDD_X}" = "X" ]
	then
		ENV_X="X"
	else
		ENV_X=${BBDD_X}
	fi


	
	# Finally, generate the output file names.
	OUTPUT_TEST="${TMP_DB_FOLDER}${ENV_TEST} - ${ENVIRONMENT_UPPER}.bat"
	OUTPUT_X="${TMP_DB_FOLDER}${ENV_X} - ${ENVIRONMENT_UPPER}.bat"


	# Generate the TEST client bat file by searching and replacing the test template file using the values from mb_usuario.cfg.
	F_LOG "Generating TEST client bat file..."
	sed -e "s/DBMANAGER/${BSER}/g" -e "s/USERNAME/${BUSR}/g" -e "s/PASSWORD/${BPWD}/g" ${TEMPLATES_PATH}${TEMPLATE_TEST_FILE} >  ${OUTPUT_TEST}

	if [ $? -ne 0 ]
	then
		F_LOG "Substitution couldn't be made at the TEST file."
		F_EXIT 3
	else
		F_LOG "TEST client: OK"
	fi

	# Generate the X client bat file by searching and replacing the test template file using the values from mb_usuario.cfg.
	F_LOG ""
	F_LOG "Generating X client bat file..."
	sed -e "s/DBMANAGER/${BSER}/g" -e "s/USERNAME/${BXUSR}/g" -e "s/PASSWORD/${BXPWD}/g" -e "s/NUMBER/${BBDD_X}/g" ${TEMPLATES_PATH}${TEMPLATE_X_FILE} > ${OUTPUT_X}

	if [ $? -ne 0 ]
	then
		F_LOG "Substitution couldn't be made at the X file."
		F_EXIT 3
	else
		F_LOG "X client: OK"
	fi

	# Zip the database clients:
	ZIP_FILE=${OUTPUT_PATH}database_client_${ENVIRONMENT_UPPER}_$$.zip
	
	F_LOG ""
	F_LOG "Compressing database client..."
	
	zip -j -r ${ZIP_FILE} ${TMP_DB_FOLDER} > /dev/null
	
	if [ $? -ne 0 ]
	then
		F_LOG "Error while compressing the files:"
		F_LOG " ${OUTPUT_TEST}"
		F_LOG " ${OUTPUT_X}"
	
		F_EXIT 4
	fi
	
	F_LOG "Compression: OK"
	F_LOG ""
	F_LOG "Database client:"
	F_LOG "${ZIP_FILE}"
	F_LOG ""
	
	echo ""
	echo "Database client:"
	echo "${ZIP_FILE}"
	echo ""
	
	# Remove temporary folder if everything is ok.
	rm -r ${TMP_DB_FOLDER} > /dev/null
}

# -------------------------------------------------------------------------------------
# F_GENERATE_MXCLIENT()
# -------------------------------------------------------------------------------------
#
# Generates a zip file containing the basic files needed for the Murex application 
# for the environment specified as a parameter:
# - client.cmd
# - monit.cmd
# - config.cmd
# - client.xml
# - mxjboot.jar
#
# -------------------------------------------------------------------------------------
#
# Input parameters:
# 	$1 -> Environment (examples: pi, QA, dc1, RP2)
#
# -------------------------------------------------------------------------------------
#
# Error codes:
# 	5 - Error generating any of the needed files.
#   6 - Error on murex client compression. (zip).
# -------------------------------------------------------------------------------------

F_GENERATE_MXCLIENT()
{
	F_LOG "--------------------------------------------------------"
	F_LOG "Murex client generation"
	F_LOG "--------------------------------------------------------"
	F_LOG ""
	
	# Convert the input data to lowercase and to uppercase.
	ENVIRONMENT_LOWER=`echo $1 | tr '[:upper:]' '[:lower:]'`
	ENVIRONMENT_UPPER=`echo $1 | tr '[:lower:]' '[:upper:]'`
	
	# Create a temporary folder

	SUFFIX_MX=MXG2000_${ENVIRONMENT_UPPER}/
	TMP_MX_FOLDER=${TMP_CLIENTS_FOLDER}${SUFFIX_MX}
	mkdir ${TMP_MX_FOLDER}
	
	# Template files
	TEMPLATE_CONFIG_FILE=config_template.txt
	TEMPLATE_CLIENT_FILE=client_template.txt
	TEMPLATE_XMLCLIENT_FILE=client_template.xml
	TEMPLATE_MONITOR_FILE=monit_template.txt
	
	# Output files
	CONFIG_FILE=config.cmd
	CLIENT_FILE=client.cmd
	XMLCLIENT_FILE=client.xml
	MONIT_FILE=monit.cmd
	MXJBOOT_FILE=mxjboot.jar
	
	
	# Finally, generate the output file names.
	OUTPUT_CONFIG="${TMP_MX_FOLDER}${CONFIG_FILE}"
	OUTPUT_CLIENT="${TMP_MX_FOLDER}${CLIENT_FILE}"
	OUTPUT_XMLCLIENT="${TMP_MX_FOLDER}${XMLCLIENT_FILE}"
	OUTPUT_MONITOR="${TMP_MX_FOLDER}${MONIT_FILE}"
	OUTPUT_MXJBOOT="${TMP_MX_FOLDER}${MXJBOOT_FILE}"
	

	
	# Generate config.cmd
	F_LOG "Generating ${CONFIG_FILE} file..."
	
	# Obtain the hostname
	HOSTNAME=`hostname`
	
	if [ "X${HOSTNAME}" = "X" ]
	then
		HOSTNAME=sdmrx102
	fi
	
	# Obtain the client port
	
	# Evaluate the different cases of environment to obtain the port
	# This is because some environments doesn't have a murex-file port description.
	case ${ENVIRONMENT_LOWER} in
		"ei"|"pi")
		PORT=10000
		ENVIRONMENT_UPPER="PI"
		;;
		"us")
		PORT=10100
		;;
		*)
		PORT=`grep -i murex-file-$1 /etc/services | cut -d' ' -f2 | cut -d'/' -f1`
		;;
	esac
	
	# In case the port cannot be found, cancel the generation.
	if [ "X${PORT}" = "X" ]
	then
		F_LOG "Substitution couldn't be made at the ${CONFIG_FILE} file:"
		F_LOG "No port has been found for ${ENVIRONMENT_UPPER} environment."
		F_EXIT 5
	fi
	
	sed -e "s/VARIABLE_HOST/${HOSTNAME}/g" -e "s/VARIABLE_PORT/${PORT}/g" ${TEMPLATES_PATH}${TEMPLATE_CONFIG_FILE} >  ${OUTPUT_CONFIG}

	if [ $? -ne 0 ]
	then
		F_LOG "Substitution couldn't be made at the ${CONFIG_FILE} file."
		F_EXIT 5
	else
		F_LOG "${CONFIG_FILE}: OK"
	fi
	
	# Generate the client.xml
	F_LOG ""
	F_LOG "Generating ${XMLCLIENT_FILE} file..."
	sed -e "s/ENVIRONMENT/${ENVIRONMENT_UPPER}/g"  ${TEMPLATES_PATH}${TEMPLATE_XMLCLIENT_FILE} >  ${OUTPUT_XMLCLIENT}
	
	if [ $? -ne 0 ]
	then
		F_LOG "Substitution couldn't be made at the ${XMLCLIENT_FILE} file."
		F_EXIT 5
	else
		F_LOG "${XMLCLIENT_FILE}: OK"
	fi
	
	# Copy the client file.
	F_LOG ""
	F_LOG "Generating ${CLIENT_FILE} file..."
	cp ${TEMPLATES_PATH}${TEMPLATE_CLIENT_FILE} ${OUTPUT_CLIENT}
	
	if [ $? -ne 0 ]
	then
		F_LOG "Error while generating the file:"
		F_LOG "${OUTPUT_CLIENT}"
		F_EXIT 5
	else
		F_LOG "${CLIENT_FILE}: OK"
	fi
	
	
	# Copy the monit file.
	F_LOG ""
	F_LOG "Generating ${MONIT_FILE} file..."
	cp ${TEMPLATES_PATH}${TEMPLATE_MONITOR_FILE} ${OUTPUT_MONITOR}
	
	if [ $? -ne 0 ]
	then
		F_LOG "Error while generating the file:"
		F_LOG "${OUTPUT_MONITOR}"
		F_EXIT 5
	else
		F_LOG "${MONIT_FILE}: OK"
	fi
	
	# Copy the mxjboot.jar
	F_LOG ""
	F_LOG "Generating ${MXJBOOT_FILE} file..."
	cp ${UTIL_PATH}${MXJBOOT_FILE} ${OUTPUT_MXJBOOT}
	
	if [ $? -ne 0 ]
	then
		F_LOG "Error while generating the file:"
		F_LOG "${OUTPUT_MXJBOOT}"
		F_EXIT 5
	else
		F_LOG "${MXJBOOT_FILE}: OK"
	fi
	
	# Zip the database clients:
	ZIP_FILE=${OUTPUT_PATH}murex_client_${ENVIRONMENT_UPPER}_$$.zip
	
	F_LOG ""
	F_LOG "Compressing murex client..."
	
	cd ${TMP_CLIENTS_FOLDER}
	zip -r ${ZIP_FILE} ${SUFFIX_MX} > /dev/null
	cd ..
	
	if [ $? -ne 0 ]
	then
		F_LOG "Error while compressing the files:"
		F_LOG "${OUTPUT_CONFIG}"
		F_LOG "${OUTPUT_CLIENT}"
		F_LOG "${OUTPUT_XMLCLIENT}"
		F_LOG "${OUTPUT_MONITOR}"
		F_LOG "${OUTPUT_MXJBOOT}"
	
		F_EXIT 6
	fi
	
	F_LOG "Compression: OK"
	F_LOG ""
	F_LOG "Murex client:"
	F_LOG "${ZIP_FILE}"
	
	echo "Murex client:"
	echo "${ZIP_FILE}"
	echo ""
	
	# Remove temporary folder if everything is ok.
	rm -r ${TMP_MX_FOLDER} > /dev/null
}


# 
# Evaluate input data
if [ $# -lt 1 ]
then
	echo "Invalid parameters. Parameters expected: environment"
	F_LOG "Invalid parameters. Parameters expected: environment"
	F_EXIT 1
fi

# Create a temporary folder
mkdir ${TMP_CLIENTS_FOLDER}

# Proceed on generating the TEST and X bat files.
F_GENERATE_DBCLIENT $1

# Proceed on generating the MX client files.
F_GENERATE_MXCLIENT $1

# Remove tmp folder if everything is ok
rm -r ${TMP_CLIENTS_FOLDER} > /dev/null

F_EXIT 0

