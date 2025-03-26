<#
.SYNOPSIS
    Importa um certificado SSL de um servidor remoto para o Java Truststore.
.DESCRIPTION
    Este script obtém o certificado SSL de um domínio especificado e o importa para
    o Java Truststore, permitindo conexões SSL sem erros PKIX.
.PARAMETER Domain
    O domínio do servidor que você deseja acessar (ex: exemplo.com)
.PARAMETER JavaTruststorePath
    Caminho completo para o arquivo cacerts (truststore do Java)
    Padrão: $env:JAVA_HOME\lib\security\cacerts
.PARAMETER Alias
    Nome do alias para o certificado no truststore
.PARAMETER TruststorePassword
    Senha do truststore (padrão: 'changeit')
.EXAMPLE
    .\Import-JavaCertificate.ps1 -Domain "api.meuservico.com" -Alias "meuservico-api"
.EXAMPLE
    .\Import-JavaCertificate.ps1 -Domain "outro.servidor.com" -JavaTruststorePath "C:\java\cacerts" -Alias "outro-servidor" -TruststorePassword "minhasenha"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$Domain,
    
    [string]$JavaTruststorePath = "$env:JAVA_HOME\lib\security\cacerts",
    
    [Parameter(Mandatory=$true)]
    [string]$Alias,
    
    [string]$TruststorePassword = "changeit"
)

# Verifica se o OpenSSL está disponível
try {
    $opensslVersion = & openssl version 2>$null
    if (-not $opensslVersion) {
        throw "OpenSSL não encontrado"
    }
} catch {
    Write-Host "Erro: OpenSSL não está instalado ou não está no PATH." -ForegroundColor Red
    Write-Host "Instale o OpenSSL ou adicione-o ao PATH e tente novamente." -ForegroundColor Yellow
    exit 1
}

# Verifica se o keytool está disponível
try {
    $keytoolVersion = & keytool -help 2>$null
    if (-not $keytoolVersion) {
        throw "Keytool não encontrado"
    }
} catch {
    Write-Host "Erro: Keytool (do JDK) não está instalado ou não está no PATH." -ForegroundColor Red
    Write-Host "Verifique sua instalação do JDK e tente novamente." -ForegroundColor Yellow
    exit 1
}

# Verifica se o arquivo truststore existe
if (-not (Test-Path $JavaTruststorePath)) {
    Write-Host "Erro: Truststore não encontrado no caminho especificado: $JavaTruststorePath" -ForegroundColor Red
    exit 1
}

# Cria um nome de arquivo temporário para o certificado
$certFile = "$env:TEMP\$Domain-cert.pem"

Write-Host "Obtendo certificado SSL de $Domain..." -ForegroundColor Cyan
try {
    # Comando para obter o certificado
    & openssl s_client -connect ${Domain}:443 -servername $Domain -showcerts < $null 2>$null | openssl x509 -outform PEM > $certFile
    
    if (-not (Test-Path $certFile) -or (Get-Item $certFile).Length -eq 0) {
        throw "Falha ao obter o certificado"
    }
    
    Write-Host "Certificado obtido com sucesso e salvo em $certFile" -ForegroundColor Green
} catch {
    Write-Host "Erro ao obter o certificado de $Domain`: $_" -ForegroundColor Red
    exit 1
}

Write-Host "Importando certificado para o truststore Java..." -ForegroundColor Cyan
try {
    # Comando para importar o certificado
    & keytool -importcert -noprompt -trustcacerts -alias $Alias -file $certFile -keystore $JavaTruststorePath -storepass $TruststorePassword
    
    Write-Host "Certificado importado com sucesso para o truststore Java!" -ForegroundColor Green
    Write-Host "Local do truststore: $JavaTruststorePath" -ForegroundColor Green
    Write-Host "Alias usado: $Alias" -ForegroundColor Green
} catch {
    Write-Host "Erro ao importar o certificado: $_" -ForegroundColor Red
    exit 1
} finally {
    # Remove o arquivo temporário do certificado
    if (Test-Path $certFile) {
        Remove-Item $certFile -Force
    }
}

Write-Host "Processo concluído com sucesso!" -ForegroundColor Green