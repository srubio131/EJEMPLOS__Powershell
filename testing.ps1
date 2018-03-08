<#
.DESCRIPTION
    Este script lanza todo el proceso de testing con maven
    Sigue los siguientes pasos:
      1. Arranca el servidor jasmine.
      2. Lanza el explorador jasmine en el navegador por defecto.
      3. Queda a la espera. Si se teclea una "s" entonces compila y muestra la cobertura. Se queda en bucle hasta que pulsamos una tecla distinta a "s", en este caso finaliza.

.NOTES
    File Name      : testing.ps1
    Author         : srubio131
    Prerequisite   : PowerShell V1 over Vista and upper.
#>

# Variables globales
$SIMBPENDIENTE = "-"
$SIMBENPROCESO = "."
$SIMBTERMINADO = "+"
$SIMBERROR = "X"
$PASOS = "Arrancar servidor jasmine","Lanzar explorador de jasmine","Compilar"
$CURRDIR = (Get-Item -Path ".\" -Verbose).FullName
$PUERTOJASMINE = 8234
$URLSERVIDORJASMINE = "http://localhost:$($PUERTOJASMINE)/"

##################
##   Funciones
##################
# $numPaso El numero de paso por el que va el proceso. Empieza en 1.
function imprimirPasos($numPaso) {
  clear
  for ($i=1; $i -le $PASOS.Length; $i++) {
    if ($i -lt $numPaso) {
      Write-Host -ForegroundColor Green "[$($SIMBTERMINADO)] $($PASOS[$i-1])"
    } elseif ($i -eq $numPaso) {
      Write-Host -ForegroundColor Yellow "[$($SIMBENPROCESO)] $($PASOS[$i-1])"
    } else {
      Write-Host "[$($SIMBPENDIENTE)] $($PASOS[$i-1])"
    }
  }  
}

function estaArrancadoServidorJasmine {
  $puerto = (Get-NetTCPConnection -State Listen).LocalPort | Where-Object { $_ -in  $PUERTOJASMINE }
  if ($puerto -eq $PUERTOJASMINE) {
    return $TRUE
  } else {
    return $FALSE
  }
}

function arrancarServidorJasmine {
  $cmd = Start-Process -FilePath "cmd" -ArgumentList "/k mvn jasmine:bdd" -WindowStyle Minimized -PassThru

  # Esperar a quede arrancado el servidor
  $arrancado = $FALSE
  while($arrancado -eq $FALSE) {
    $hayConexion = estaArrancadoServidorJasmine
    if ($hayConexion -eq $TRUE) {
      $arrancado = $TRUE
    }
  }

  return $cmd.Id
  
}

function lanzarExploradorJasmine {
  start chrome $URLSERVIDORJASMINE
}

function mostrarProgreso {
  Write-Host "      Ejecutando..."
}

function compilar {
  $opcion = Read-Host -Prompt "    Quieres compilar? [s/n]"
  if ($opcion -eq "s") {
    mostrarProgreso
    # Ejecuta la compilación, ejecuta los tests y guarda la salida en una variable, y envia a null los mensajes SDTERR
    $output = & mvn install 2>&1
    if ($output -like '*<<< FAILURE!*') { # Algún tests tiene error
      Write-Host -ForegroundColor Red "      [$($SIMBERROR)] Hay tests con errores. Revisa los resultados de jasmine en: localhost:8234/"
    } elseif ($output -like '*BUILD SUCCESS*') { # Todo ha ido bien
      Write-Host -ForegroundColor Green "      [$($SIMBTERMINADO)] Todo correcto ^_^"
      & "$CURRDIR\target\coverage\total-report.html"
    } else {
      Write-Host -ForegroundColor Red "[$($SIMBERROR)] Se ha producido un error al compilar :("
      Write-Host $output
    }
    compilar
  }
}

function cerrarServidorJasmine($cmdId) {
  # Cerrar el servidor jasmine
  $id = (Get-NetTCPConnection -State Listen | Where-Object { $_.LocalPort -in  $PUERTOJASMINE }).OwningProcess
  if ($id -ne "") {
    Stop-Process $id
  }

  # Cerrar el cmd
  if ($cmdId -ne "") {
    Stop-Process $cmdId
  }
}

##################
##   Main
##################

imprimirPasos 1

# Arrancar servidor jasmine
$hayConexion = estaArrancadoServidorJasmine
if ($hayConexion -eq $TRUE) {
  cerrarServidorJasmine($cmdId)
}
$cmdId = arrancarServidorJasmine

# Lanzar explorador jasmine
imprimirPasos 2
lanzarExploradorJasmine

# Compilar
imprimirPasos 3
compilar

# Terminar
imprimirPasos 4
clear
cerrarServidorJasmine($cmdId)
