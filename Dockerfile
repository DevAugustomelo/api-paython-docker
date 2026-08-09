# Ativa recursos modernos de cache do BuildKit

# --- ESTÁGIO 1: Compilação e Dependências ---
FROM python:3.12-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Instala ferramentas necessárias para compilar pacotes Python (se houver)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copia apenas o requirements para aproveitar o cache de camadas
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt


# --- ESTÁGIO 2: Ambiente de Execução Limpo e Seguro ---
FROM python:3.12-slim AS runner

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH=/home/appuser/.local/bin:$PATH

WORKDIR /app

# SEGURANÇA: Cria usuário sem privilégios administrativos
RUN useradd --create-home appuser && chown -R appuser:appuser /app
USER appuser

# Copia as dependências limpas do estágio builder
COPY --from=builder /root/.local /home/appuser/.local

# Copia o código fonte do Python (main.py, etc.) com as permissões do usuário
COPY --chown=appuser:appuser . .

# Porta interna do FastAPI
EXPOSE 8000

# Executa o servidor de produção Uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
