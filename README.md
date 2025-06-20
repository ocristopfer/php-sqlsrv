# PHP Multi-Version Docker Environment

Este repositório contém arquivos Docker para múltiplas versões do PHP com Apache, além de scripts para automação de builds.

## 📋 Visão Geral

O projeto oferece uma solução completa para trabalhar com diferentes versões do PHP em containers Docker, incluindo:

- **Múltiplas versões do PHP**: 7.4, 8.3, 8.4 e outras
- **Ambiente completo**: Apache, extensões PHP, ODBC, SSL
- **Automação de builds**: Script bash para gerar todas as imagens
- **Configuração padronizada**: Mesma estrutura para todas as versões

## 🚀 Versões Suportadas

- **PHP 7.4** - Versão LTS estável
- **PHP 8.3** - Versão atual recomendada
- **PHP 8.4** - Versão mais recente

## 📁 Estrutura do Projeto

```
.
├── README.md
├── build-images.sh           # Script para automação de builds
├── php7-4.Dockerfile         # Docker para PHP 7.4
├── php8-3.Dockerfile         # Docker para PHP 8.3
├── php8-4.Dockerfile         # Docker para PHP 8.4
├── config/
│   ├── apache/
│   │   └── 000-default.conf  # Configuração do Apache
│   ├── php/
│   │   └── 99-custom_overrides.ini  # Configurações customizadas do PHP
│   ├── ssl/
│   │   ├── localhost.crt     # Certificado SSL
│   │   └── localhost.key     # Chave privada SSL
│   └── odbc/
│       └── odbcinst.ini      # Configuração ODBC
└── index.php                 # Arquivo de exemplo
```

## 🔧 Recursos Incluídos

### Extensões PHP

- **bcmath** - Cálculos matemáticos de precisão arbitrária
- **exif** - Leitura de metadados de imagens
- **gd** - Manipulação de imagens
- **imagick** - Processamento avançado de imagens
- **intl** - Internacionalização
- **opcache** - Cache de bytecode
- **pcntl** - Controle de processos
- **pdo_sqlsrv** - Conexão com SQL Server
- **redis** - Conexão com Redis
- **sqlsrv** - Driver SQL Server
- **zip** - Compressão de arquivos
- **odbc** - Conectividade ODBC
- **xdebug** - Debug e profiling

### Componentes do Sistema

- **Apache** com SSL e mod_rewrite habilitados
- **Microsoft ODBC Driver** para SQL Server
- **Certificados SSL** para desenvolvimento local
- **Configurações customizadas** do PHP

## 🛠️ Instalação e Uso

### Pré-requisitos

- Docker instalado
- Git (para clonar o repositório)

### Clonando o Repositório

```bash
git clone <url-do-repositorio>
cd php-multi-version-docker
```

### Construindo as Imagens

#### Construir todas as versões

```bash
# Com logs completos
./build-images.sh build-all

# Modo silencioso (sem logs do Docker)
./build-images.sh build-all --quiet
```

#### Construir versão específica

```bash
./build-images.sh build 8.3
./build-images.sh build 7.4
```

#### Listar Dockerfiles disponíveis

```bash
./build-images.sh list
```

#### Ver imagens construídas

```bash
./build-images.sh images
```

### Executando um Container

```bash
# PHP 8.3
docker run -d -p 80:80 -p 443:443 --name php8.3-app my-php-app:php8.3

# PHP 7.4
docker run -d -p 8074:80 -p 8443:443 --name php7.4-app my-php-app:php7.4

# Com volume para desenvolvimento
docker run -d -p 80:80 -p 443:443 \
  -v $(pwd)/src:/var/www/html \
  --name php-dev my-php-app:php8.3
```

## ⚙️ Configuração

### Personalizando o Build

Edite o script `build-images.sh` para alterar:

```bash
IMAGE_NAME="my-php-app"      # Nome base das imagens
BUILD_CONTEXT="."            # Contexto de build
REGISTRY=""                  # Registry Docker (opcional)
```

### Configurações PHP

Edite `config/php/99-custom_overrides.ini` para personalizar configurações do PHP:

```ini
memory_limit = 256M
upload_max_filesize = 50M
post_max_size = 50M
max_execution_time = 300
```

### Configurações Apache

Edite `config/apache/000-default.conf` para personalizar o Apache:

```apache
<VirtualHost *:80>
    DocumentRoot /var/www/html
    ServerName localhost
    # Suas configurações
</VirtualHost>
```

## 🔍 Comandos Úteis

### Verificar versão do PHP no container

```bash
docker exec -it <container-name> php -v
```

### Verificar extensões instaladas

```bash
docker exec -it <container-name> php -m
```

### Acessar logs do Apache

```bash
docker exec -it <container-name> tail -f /var/log/apache2/error.log
```

### Executar comandos no container

```bash
docker exec -it <container-name> bash
```

## 🧪 Testando a Instalação

Após executar um container, acesse:

- **HTTP**: http://localhost
- **HTTPS**: https://localhost (aceite o certificado auto-assinado)

O arquivo `index.php` mostrará informações do PHP e extensões instaladas.

## 🚨 Troubleshooting

### Problemas Comuns

#### Erro de permissão no script

```bash
chmod +x build-images.sh
```

#### Conflito de portas

```bash
# Verificar portas em uso
docker ps

# Usar portas diferentes
docker run -p 8080:80 -p 8443:443 my-php-app:php8.3
```

#### Problemas de SSL

```bash
# Gerar novos certificados
openssl req -x509 -newkey rsa:4096 -keyout config/ssl/localhost.key \
  -out config/ssl/localhost.crt -days 365 -nodes
```

### Limpeza do Sistema

```bash
# Remover todas as imagens construídas
./build-images.sh cleanup

# Remover containers parados
docker container prune

# Remover imagens não utilizadas
docker image prune
```

## 📚 Documentação Adicional

### Microsoft ODBC Driver

- [Documentação oficial](https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server)

### PHP Extensions

- [PHP Manual](https://www.php.net/manual/en/)
- [Xdebug Documentation](https://xdebug.org/docs/)

### Docker

- [Docker Documentation](https://docs.docker.com/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Crie um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 📞 Suporte

Para questões e suporte:

- Abra uma [issue](../../issues) no GitHub
- Verifique a [documentação](#-documentação-adicional)
- Consulte o [troubleshooting](#-troubleshooting)

---

**Desenvolvido com ❤️ para a comunidade PHP**
