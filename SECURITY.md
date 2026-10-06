# Política de segurança

As imagens deste repositório são para **desenvolvimento local**. Elas vêm, de
propósito, com configurações inseguras para produção:

- **Xdebug ativo** em todas as requisições (`xdebug.start_with_request=yes`);
- `display_errors = On`;
- um certificado e uma **chave privada SSL auto-assinados e públicos**
  (`src/config/ssl/localhost.*`), adicionados às CAs confiáveis da imagem.

Esses pontos são conhecidos e **não** são considerados vulnerabilidades. Não use
estas imagens expostas à internet nem em produção sem removê-los.

## Como reportar uma vulnerabilidade

**Não** abra uma issue pública. Use o relatório privado de vulnerabilidades do
GitHub (botão "Report a vulnerability" na aba **Security** do repositório) e informe:

- o Dockerfile afetado (versão do PHP, Apache ou Nginx);
- os passos para reproduzir, ou uma prova de conceito;
- o commit usado no build.

Você deve receber uma resposta em alguns dias. A correção é publicada na `main`;
reconstrua a imagem para recebê-la.

## Versões suportadas

Apenas a branch `main` recebe correções. Imagens geradas a partir de commits
antigos devem ser reconstruídas.

## Escopo

Dentro do escopo, por exemplo: pacotes baixados de fontes não confiáveis ou sem
verificação de assinatura, configurações do Apache/Nginx/Supervisor que exponham
mais do que o necessário, ou scripts de build inseguros.

Fora do escopo:

- vulnerabilidades no PHP, Apache, Nginx, drivers ODBC da Microsoft ou nas
  imagens base oficiais — reporte a quem os mantém e reconstrua a imagem quando
  houver correção;
- os pontos de desenvolvimento listados acima;
- PHP 7.4, que não recebe mais correções de segurança do projeto PHP.

## Para usar fora do ambiente local

- Gere seu próprio certificado (veja o README) e não reutilize `localhost.key`.
- Remova o Xdebug (`docker-php-ext-enable xdebug` e a seção `[xdebug]` do
  `99-custom_overrides.ini`) e use `display_errors = Off`.
- Prefira versões do PHP ainda suportadas e reconstrua as imagens com
  frequência para receber atualizações do sistema.
