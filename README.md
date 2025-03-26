# Scripts úteis para Windows utilizando Powershell

## 1. Importando certificado JAVA

### Exemplo básico (usando padrões):
```powershell
.\Import-JavaCertificate.ps1 -Domain "api.exemplo.com" -Alias "exemplo-api"
```

### Exemplo completo:
```powershell
.\Import-JavaCertificate.ps1 -Domain "servidor.producao.com" `
    -JavaTruststorePath "C:\Program Files\Java\jdk-21\lib\security\cacerts" `
    -Alias "servidor-producao" `
    -TruststorePassword "outrasenha"
```

### Pré-requisitos
- OpenSSL - Deve estar instalado e no PATH
- Java JDK - O keytool deve estar disponível no PATH
- Permissões - Você precisa ter permissão para modificar o arquivo cacerts

