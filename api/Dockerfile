FROM public.ecr.aws/docker/library/python:3.9-slim

WORKDIR /app

# Copiar Pipenv
COPY Pipfile Pipfile.lock ./

# Dependencias del sistema
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libc-dev libpq-dev curl && \
    rm -rf /var/lib/apt/lists/*

# Instalar pipenv y dependencias
RUN pip install --no-cache-dir pipenv && \
    pipenv install --deploy --ignore-pipfile && \
    pipenv install newrelic

# Copiar código del microservicio
COPY . /app

# ===============================
# Generar newrelic.ini (placeholder)
# NO pongas tu licencia aquí.
# La licencia real se pasa por variables de entorno.
# ===============================
RUN NEW_RELIC_LICENSE_KEY="REPLACE_ME" \
    pipenv run newrelic-admin generate-config $NEW_RELIC_LICENSE_KEY newrelic.ini

# Variables de Flask
ENV FLASK_APP=src/app.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_RUN_PORT=3000

# Variables New Relic (se sobrescriben en ECS/local)
ENV NEW_RELIC_APP_NAME="blacklist-microservice"
ENV NEW_RELIC_LOG=stdout
ENV NEW_RELIC_DISTRIBUTED_TRACING_ENABLED=true
ENV NEW_RELIC_LOG_LEVEL=info

EXPOSE 3000

# ===============================
# Script de diagnóstico (opcional)
# ===============================
RUN echo '#!/bin/bash' > /app/diagnose.sh && \
    echo 'echo "=== Diagnóstico New Relic ==="' >> /app/diagnose.sh && \
    echo 'echo "App Name: $NEW_RELIC_APP_NAME"' >> /app/diagnose.sh && \
    echo 'echo ""' >> /app/diagnose.sh && \
    echo 'echo "Probando collector..."' >> /app/diagnose.sh && \
    echo 'curl -v https://${NEW_RELIC_HOST:-collector.newrelic.com} 2>&1 | head -20' >> /app/diagnose.sh && \
    chmod +x /app/diagnose.sh

# ===============================
# Ejecutar Flask con New Relic
# ===============================
ENTRYPOINT ["pipenv", "run", "newrelic-admin", "run-program"]
CMD ["flask", "run", "--host=0.0.0.0", "--port=3000"]