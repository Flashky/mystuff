#Ejecución de cvj70100 (maduros operaciones
touch cvj70100_execution.log
rm cvj70100_execution.log && touch cvj70100_execution.log && $BINBATCH/cvj70100 $DATOS_CNX4 $FECHA_PROC MAD 0 0 >> cvj70100_execution.log
