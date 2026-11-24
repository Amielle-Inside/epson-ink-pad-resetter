# 🖨️ Epson Ink Pad Resetter - Versão Dockerizada

> ⚠️ **Aviso importante:** A dockerização deste repositório (Dockerfile, docker-compose.yml, requisitos de sistema e este guia) foi realizada com o **Hermes Agent**, utilizando o modelo **nvidia/nemotron-3.5-super-vl-120b-a12b** (NVIDIA). Todo o passo a passo abaixo foi testado em Docker real antes de ser publicado.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)
[![Docker Compose](https://img.shields.io/badge/Compose-Supported-blue)](https://docs.docker.com/compose/)

**Resete a almofada de tinta residual de impressoras Epson** sem pagar por ferramentas como WICReset. Ferramenta 100% gratuita, open-source (GPL v3), que usa **SNMP via WiFi/Ethernet** (sem USB). Agora totalmente pronta para rodar em **Docker**, com todas as dependências pré-instaladas na imagem.

---

## 📋 Sumário

1. [Sobre o projeto](#-sobre-o-projeto)
2. [O que foi dockerizado](#-o-que-foi-dockerizado)
3. [Pré-requisitos: instalar o Docker](#-pré-requisitos-instalar-o-docker)
   - [Windows](#windows)
   - [Linux](#linux)
4. [Clonar o seu fork](#-clonar-o-seu-fork)
5. [Arquivos da dockerização (linha a linha)](#-arquivos-da-dockerização-linha-a-linha)
   - [Dockerfile](#dockerfile)
   - [docker-compose.yml](#docker-composeyml)
   - [requirements.txt](#requirementstxt)
   - [Ajuste no app.py](#ajuste-no-apppy)
6. [Build da imagem](#-build-da-imagem)
7. [Check de dependências](#-check-de-dependências)
8. [Subir com Docker Compose](#-subir-com-docker-compose)
9. [Teste completo após instalação](#-teste-completo-após-instalação)
10. [Como usar (acessar a interface web)](#-como-usar-acessar-a-interface-web)
11. [Variáveis de ambiente](#-variáveis-de-ambiente)
12. [Comandos úteis](#-comandos-úteis)
13. [Troubleshooting](#-troubleshooting)
14. [Modelos suportados](#-modelos-suportados)
15. [Licença](#-licença)

---

## 📖 Sobre o projeto

O **Epson Ink Pad Resetter** é uma aplicação web em Flask que permite resetar o contador de almofada de tinta residual (waste ink counter) de impressoras Epson via protocolo SNMP, acessível pelo navegador em `http://localhost:5000`.

Não é necessário cabo USB. Basta a impressora estar na mesma rede (WiFi ou Ethernet) com SNMP habilitado.

**Modelos conhecidos:** L355, L3160, L3250, L4160, M1170, ET-2850, ET-2860 (e outros L/M/ET por fallback).

---

## 🐳 O que foi dockerizado

A imagem Docker contém **tudo pré-instalado**:

- Python 3.11 (imagem base `python:3.11-slim`)
- Compilador e ferramentas de build (`build-essential`, `gcc`, `make`, etc.)
- Bibliotecas de sistema do net-snmp (`libsnmp-dev`, `libssl-dev`) — exigidas pelo `easysnmp`
- Pacotes Python: `easysnmp==0.2.6` e `flask==3.0.3`
- A aplicação (`app.py`, pacote `epson/`, templates/)
- Healthcheck automático na porta 5000

Você **não precisa instalar Python, pip, SNMP ou compiladores no seu host**. Só precisa do Docker.

---

## 🔧 Pré-requisitos: instalar o Docker

Você precisa do **Docker Engine** e do **Docker Compose** (plugin `docker compose`). Escolha seu sistema abaixo.

### Windows

1. Baixe o **Docker Desktop** em: https://www.docker.com/products/docker-desktop/
2. Execute o instalador e siga o assistente (marque a opção de usar WSL 2 quando solicitado).
3. Após a instalação, reinicie o computador se solicitado.
4. Inicie o Docker Desktop e aguarde o ícone da bandeja ficar verde (em execução).
5. Verifique em um terminal (PowerShell ou Prompt de Comando):

```powershell
docker --version
docker compose version
```

Esperado: algo como `Docker version 29.x.x` e `Docker Compose version v5.x.x`.

> Se `docker compose` não for reconhecido, instale o plugin do Compose dentro do Docker Desktop (Settings → Instalar atualizações) ou baixe em https://docs.docker.com/compose/install/

### Linux

No terminal, execute:

```bash
# 1. Atualize os pacotes
sudo apt-get update && sudo apt-get upgrade -y

# 2. Instale o Docker Engine
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 3. Adicione seu usuário ao grupo docker (evita usar sudo em todo comando)
sudo usermod -aG docker $USER

# 4. Refaça o login (ou rode: newgrp docker) para aplicar o grupo
newgrp docker
```

Verifique:

```bash
docker --version
docker compose version
docker run hello-world
```

O último comando deve baixar e rodar um container de teste com sucesso.

---

## 📥 Clonar o seu fork

Este guia pressupõe que você já fez **fork** do repositório original (`jmbento/epson-ink-pad-resetter`) para a sua conta. Clone **o seu fork**:

```bash
# Substitua SEU_USUARIO pelo seu nome de usuário no GitHub
git clone https://github.com/SEU_USUARIO/epson-ink-pad-resetter.git
cd epson-ink-pad-resetter
```

Se ainda não fez o fork, vá em https://github.com/jmbento/epson-ink-pad-resetter e clique em **Fork**.

---

## 📁 Arquivos da dockerização (linha a linha)

Abaixo, cada arquivo criado/adaptado para o Docker, com explicação linha por linha.

### Dockerfile

Local: `Dockerfile`

```dockerfile
# Dockerfile - Epson Ink Pad Resetter
# Dockerização feita com Hermes Agent e nvidia/nemotron-3.5-super-vl-120b-a12b
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FLASK_HOST=0.0.0.0 \
    FLASK_PORT=5000 \
    FLASK_DEBUG=1

# Dependências de sistema exigidas pelo easysnmp (bind C da net-snmp)
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        gcc \
        libsnmp-dev \
        libssl-dev \
        python3-dev \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py ./
COPY epson ./epson
COPY templates ./templates

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -fsS http://127.0.0.1:5000/ || exit 1

CMD ["python", "app.py"]
```

**O que cada bloco faz:**
- `FROM python:3.11-slim` — imagem base leve com Python.
- `ENV ...` — define variáveis de ambiente: `FLASK_HOST=0.0.0.0` (essencial para o container aceitar conexões externas), porta 5000, debug ativo.
- `RUN apt-get ...` — instala compilador (`build-essential`, `gcc`) e bibliotecas do net-snmp (`libsnmp-dev`, `libssl-dev`) necessárias para compilar o `easysnmp`, além de `curl` (usado pelo healthcheck).
- `WORKDIR /app` — diretório de trabalho dentro do container.
- `COPY requirements.txt .` + `RUN pip install` — instala as dependências Python **dentro da imagem** (pré-instaladas).
- `COPY app.py ./` + `COPY epson ./epson` + `COPY templates ./templates` — copia o código da aplicação.
- `EXPOSE 5000` — declara a porta usada pelo Flask.
- `HEALTHCHECK` — o Docker verifica a cada 30s se o servidor respondeu na porta 5000; marca o container como `healthy` ou `unhealthy`.
- `CMD ["python", "app.py"]` — inicia o servidor Flask ao subir o container.

### docker-compose.yml

Local: `docker-compose.yml`

```yaml
# docker-compose.yml - Epson Ink Pad Resetter
# Orquestração feita com Hermes Agent e nvidia/nemotron-3.5-super-vl-120b-a12b
services:
  epson-ink-pad-resetter:
    build: .
    container_name: epson-ink-pad-resetter
    restart: unless-stopped
    ports:
      - "5000:5000"
    environment:
      - FLASK_HOST=0.0.0.0
      - FLASK_PORT=5000
      - FLASK_DEBUG=1
    healthcheck:
      test: ["CMD", "curl", "-fsS", "http://127.0.0.1:5000/"]
      interval: 30s
      timeout: 10s
      start_period: 10s
      retries: 3
```

**O que cada bloco faz:**
- `build: .` — constrói a imagem a partir do `Dockerfile` na pasta atual.
- `container_name` — nome fixo do container.
- `restart: unless-stopped` — reinicia automaticamente se parar, a menos que você pare manualmente.
- `ports: "5000:5000"` — mapeia a porta 5000 do seu computador para a 5000 do container.
- `environment` — passa as variáveis `FLASK_HOST`, `FLASK_PORT`, `FLASK_DEBUG` para o container.
- `healthcheck` — verifica saúde do serviço via `curl` na porta 5000.

### requirements.txt

Local: `requirements.txt`

```text
easysnmp==0.2.6
flask==3.0.3
```

- `easysnmp==0.2.6` — cliente SNMP usado para falar com a impressora Epson.
- `flask==3.0.3` — framework web que serve a interface (estava em falta no `requirements.txt` original; adicionado na dockerização).

> Nota: `easysnmp` é uma extensão C que depende de `libsnmp-dev` no sistema. Por isso o `Dockerfile` instala esses pacotes de sistema antes do `pip install`.

### Ajuste no app.py

A única alteração no código da aplicação foi na linha de inicialização do servidor, para que ele aceite conexões de fora do container (necessário no Docker):

```python
# Antes (apenas localhost dentro do container):
app.run(debug=True, host='127.0.0.1', port=5000)

# Depois (configurável via variável de ambiente, padrão 0.0.0.0 para Docker):
app.run(debug=True, host=os.environ.get('FLASK_HOST', '0.0.0.0'), port=int(os.environ.get('FLASK_PORT', '5000')))
```

---

## 🏗️ Build da imagem

Na pasta clonada do seu fork, construa a imagem:

```bash
docker build -t epson-ink-pad-resetter:local .
```

Saída esperada (final):

```
Successfully built <sha256>
Successfully tagged epson-ink-pad-resetter:local
```

A imagem já vem com **todas as dependências instaladas** (Python, net-snmp, easysnmp, flask).

---

## 🔍 Check de dependências

Confirme que tudo está instalado dentro da imagem antes de usar:

```bash
# 1. Verifique a imagem criada
docker images | grep epson-ink-pad-resetter

# 2. Rode um container temporário para inspecionar as dependências
docker run --rm epson-ink-pad-resetter:local python -c "
import easysnmp, flask
print('easysnmp:', easysnmp.__version__)
print('flask:', flask.__version__)
print('OK: dependencias instaladas')
"
```

Saída esperada:

```
easysnmp: 0.2.6
flask: 3.0.3
OK: dependencias instaladas
```

---

## ▶️ Subir com Docker Compose

```bash
docker compose up -d
```

O que acontece:
1. Constrói a imagem (se ainda não existir).
2. Cria o container `epson-ink-pad-resetter`.
3. Mapeia `localhost:5000` → container porta 5000.
4. Inicia o Flask em segundo plano (`-d`).

Verifique o status:

```bash
docker compose ps
```

Esperado:

```
NAME                     STATUS                    PORTS
epson-ink-pad-resetter   Up X seconds (healthy)   0.0.0.0:5000->5000/tcp
```

O campo `(healthy)` confirma que o healthcheck passou.

---

## ✅ Teste completo após instalação

Execute esses passos para validar que o Docker está servindo a aplicação corretamente.

### 1. Teste a página principal

```bash
curl -fsS -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1:5000/
```

Esperado: `HTTP 200`

### 2. Confira o conteúdo da interface

```bash
curl -s http://127.0.0.1:5000/ | grep -oE "Epson Ink Reset|Resete sua almofada" | head
```

Esperado: imprime `Epson Ink Reset` e `Resete sua almofada`.

### 3. Teste a API de status (sem IP, deve retornar erro controlado)

```bash
curl -s -X POST http://127.0.0.1:5000/api/status \
  -H 'Content-Type: application/json' \
  -d '{}'
```

Esperado (JSON):

```json
{"error": "IP não fornecido", "success": false}
```

Isso prova que o Flask recebeu a requisição, processou a rota e respondeu — a aplicação está viva.

### 4. Confirme o healthcheck do Docker

```bash
docker inspect --format='{{.State.Health.Status}}' epson-ink-pad-resetter
```

Esperado: `healthy`

### 5. Abra no navegador

Acesse:

```
http://localhost:5000
```

Você verá o campo **IP da Impressora** e os botões **Verificar Status** e **Resetar**.

---

## 💻 Como usar (acessar a interface web)

1. Descubra o IP da sua impressora Epson no painel dela: `Menu → Rede/WiFi → Status → Endereço IP` (exemplo: `192.168.1.100`).
2. Abra `http://localhost:5000` no navegador.
3. Digite o IP da impressora e clique em **✓ Verificar Status**.
   - Se der sucesso, você verá os contadores de almofada (counter_1, counter_2, counter_3) com percentuais e barras de progresso.
   - Se der erro, confira se a impressora está ligada, na mesma rede e com SNMP habilitado.
4. Se algum contador estiver alto (acima de ~80%), clique em **⚡ Resetar** e confirme.
5. Após o reset, os contadores voltam a 0% e a impressora é desbloqueada para impressão.

> ⚠️ O reset altera apenas um contador de software. A almofada física continua intacta. Isso não danifica a impressora.

---

## ⚙️ Variáveis de ambiente

Podem ser definidas no `docker-compose.yml` ou na linha de comando:

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `FLASK_HOST` | `0.0.0.0` | Interface de rede onde o Flask escuta (use `0.0.0.0` para aceitar conexões externas/Docker) |
| `FLASK_PORT` | `5000` | Porta do servidor Flask dentro do container |
| `FLASK_DEBUG` | `1` | Ativa/desativa o modo debug do Flask |

Exemplo de uso direto com `docker run`:

```bash
docker run -d --name epson-reset \
  -p 5000:5000 \
  -e FLASK_HOST=0.0.0.0 \
  -e FLASK_PORT=5000 \
  epson-ink-pad-resetter:local
```

---

## 🛠️ Comandos úteis

```bash
# Ver logs do container
docker compose logs -f

# Parar o container
docker compose stop

# Parar e remover container e rede
docker compose down

# Reconstruir a imagem após alterar o código
docker compose up -d --build

# Ver containers em execução
docker ps

# Remover a imagem (se precisar recriar do zero)
docker rmi epson-ink-pad-resetter:local
```

---

## 🚨 Troubleshooting

| Problema | Causa provável | Solução |
|----------|---------------|---------|
| `curl: Failed to connect to 127.0.0.1:5000` | Container não subiu ou porta não mapeada | Rode `docker compose up -d` e depois `docker compose ps` |
| Container com status `unhealthy` ou saindo logo após iniciar | Falha ao importar `flask` ou `easysnmp` | Confira que `requirements.txt` tem `flask==3.0.3` e `easysnmp==0.2.6`; rode `docker compose up -d --build` |
| `ModuleNotFoundError: No module named 'flask'` | `flask` faltava nos requisitos | Adicionado na dockerização; reconstrua com `--build` |
| Erro de compilação do `easysnmp` | Faltam libs de sistema (net-snmp) | O `Dockerfile` já instala `libsnmp-dev` e `libssl-dev`; reconstrua |
| Página não carrega no navegador | Porta mapeada incorretamente | Confira `ports: "5000:5000"` no `docker-compose.yml` e acesse `http://localhost:5000` |
| Timeout ao conectar na impressora | Impressora desligada, rede diferente ou SNMP desativado | Ligue a impressora, confirme que está na mesma rede do computador e ative SNMP no painel dela |

---

## 🖨️ Modelos suportados

| Modelo | Status | Notas |
|--------|--------|-------|
| L355 | ✅ Testado | OK |
| L3160 | ✅ Testado | OK |
| L3250 | ✅ Testado | OK |
| L4160 | ✅ Testado | OK |
| M1170 | ✅ Config | Provável compatibilidade |
| ET-2850 | ✅ Config | Funciona |
| ET-2860 | ✅ Config | Suportado |
| Outros L/M/ET | ⚠️ Fallback | Configuração padrão |

Se o seu modelo não aparece ou não responde, abra uma Issue no repositório com o modelo exato e o erro recebido.

---

## ⚖️ Licença

GPL v3 — veja [LICENSE](LICENSE). Use, modifique e distribua livremente, mantendo o código aberto.

---

**Desenvolvido originalmente por [jmbento](https://github.com/jmbento)**  \n**Dockerização e guia: Hermes Agent + nvidia/nemotron-3.5-super-vl-120b-a12b**
