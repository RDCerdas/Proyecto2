# Proyecto2

## Link del git

https://github.com/RDCerdas/Proyecto2

## Codigo para correrlo

Existen cuatro alternativas para correr el código:

### Corrida única
La primera es una corrida simple, para esto se utiliza:`source comando.sh`

Lo que hace es cargar las herramientas, compila el código con vcs y lo corre, si además se quiere obtener la covertura se puede correr: `verdi -cov -covdir salida.vdb&`

### Corrida para cálculo de bandwidth
Esta permite hacer multiples corridas del test 1.2 y 1.2 que generan los datos de ancho de banda. Al finalizar genera las gráficas.
Se corre con el comando: `source comando_bandwidth.sh`

### Corrida con parámetros aleatorias
Esta corre todas las pruebas variando los parámetros de forma aleatoria. Para correrla se utiliza el comando: `source comando_corridas.sh`


### Corrida para covertura
Esta corre todas las pruebas con los parámetros dados. Al final hacer un merge de todas las bases de datos de cobertura y hacer el visualizar de verdi. Para correrla se utiliza el comando: `source comando_covertura.sh`

## Visualización de los resultados
Cada prueba genera un csv llamado `report.csv` con todos los paquetes transmitidos junto con si completaron exitosamente o no. Además, las pruebas de ancho de banda también añaden sus resultados a dos archivos llamados `min_bandwidth.csv` y `max_bandwidth.csv`. Esto son utilizados para graficar los resultados en los scripts `min.gnuplot` y `max.gnuplot`
