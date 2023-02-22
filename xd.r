library(tidyverse) # Manejo de datos
library(lubridate) # Manejo de fechas
library(dplyr)
library(RPostgres) # Manejo database
library(DBI) # realizar consultas sql


#extrae uso del servidor actual
uso_ram_servidor <- read.table(text = system(paste0(
    "smem -wp -c 'area used' |",
    " grep 'userspace memory'"
),
intern = TRUE
))

#convierte a numero el uso % del servidor
uso_ram_servidor <- as.numeric(substr(uso_ram_servidor$V3, 1, 4))


#calcula la fecha y hora actual
fecha_hoy <- with_tz(now(), tz = "America/Santiago")

#separa solo la fecha
fecha <- substr(fecha_hoy, 1, 10)
#separa solo la hora
hora <- substr(fecha_hoy, 12, 19)


# extraemos el dia de la semana
dia_semana <- wday(today(), label = TRUE)
# cambiamos el nombre de la semana a espaniol
dia_semana <- case_when(
    dia_semana == "Mon" ~ "lunes",
    dia_semana == "Tue" ~ "martes",
    dia_semana == "Wed" ~ "miercoles",
    dia_semana == "Thu" ~ "jueves",
    dia_semana == "Fri" ~ "viernes",
    dia_semana == "Sat" ~ "sabado",
    dia_semana == "Sun" ~ "domingo"
)



#configuracion para la conexion a la base de datos
config <- config::get(
    value = "agentetopo", #conexion yml
    config = "postgres", #nombre configuracion
    file = "/oradisk/config_db/config.yml", #ruta archivo confgiuracion
    use_parent = FALSE #escanea directorios principales
 )


#creamos la conexion a la base de datos
conn <- DBI::dbConnect(Postgres(),
                      host = config$server,
                      dbname = config$database,
                      user = config$uid,
                      password = config$pwd)

#construimos la consulta
query <- paste0("INSERT INTO scanner.uso_ram_produccion
          SELECT '", uso_ram_servidor,
          "', '", fecha,
          "','", hora,
          "','", dia_semana, "';")

#insertamos los datos en la base de datos
dbSendQuery(conn, query)
#cerramos la conexion a la base de datos
dbDisconnect(conn)