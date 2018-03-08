<#
.DESCRIPTION
    Este script automatiza la conexión/desconexión a una VPN. Hasta que no se conecta no deja de intentar conectarse.

.NOTES
    File Name      : vpn.ps1
    Author         : srubio131
    Prerequisite   : PowerShell V1 over Vista and upper.
#>

# Parámetros de entrada al script
param(
  [string]$user="",
  [string]$pass=""
)

# Variables globales
$PATHNCLAUNCHER = "C:\Program Files (x86)\Juniper Networks\Network Connect 8.1\nclauncher"
$URLVPN = "https://mivpn.molona.es"


##################
##   Main
##################

if ([string]::IsNullOrEmpty($user) -or [string]::IsNullOrEmpty($pass)) {
  Write-Host -ForegroundColor Red "[X] Es necesario indicar usuario y contraseña. Uso: vpn.ps1 -user <mi_user> -pass <mi_pass>" 
  pause
} else {
  cls 
  Write-Host -ForegroundColor Yellow " . . . conectando con VPN" 
  $isConnected = $FALSE 
  while($isConnected -eq $FALSE) {
    $output = & $PATHNCLAUNCHER -url $URLVPN -u $user -p $pass -r EXTERNAL_USER 2>&1
    if ($output -like '*Ha iniciado Network Connect.*') { # Se ha conectado correctamente
      $isConnected = $TRUE
      Write-Host -ForegroundColor Green "[+] Te has conectado a VPN" 
    } elseif ($output -like '*Network Connect is already running*') {
      $isConnected = $TRUE
      Write-Host -ForegroundColor Green "[+] Ya estabas conectado a VPN" 
    } else { # No se ha conectado
      Write-Host -ForegroundColor Red "[X] No se ha podido conectar a VPN. Reintentando..." 
    }
  } 
  exit
}