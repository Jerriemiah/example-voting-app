# base defines a base stage that uses the official python runtime base image
# ---------- Build dependencies ----------
FROM python:3.13-slim-trixie@sha256:57b29a7c050c4e679e4bea572e14b3965cf4b5839de2da49d55e49ffc4024f39 AS builder

WORKDIR /usr/local/app

COPY requirements.txt ./requirements.txt

RUN python -m venv /opt/venv && \
    /opt/venv/bin/python -m pip install --no-cache-dir --upgrade \
        pip \
        setuptools \
        wheel && \
    /opt/venv/bin/python -m pip install --no-cache-dir \
        -r requirements.txt


# ---------- Development image ----------
FROM builder AS dev

COPY . .

ENV PATH="/opt/venv/bin:${PATH}"
ENV FLASK_ENV=development

RUN /opt/venv/bin/python -m pip install --no-cache-dir watchdog

CMD ["python", "app.py"]


# ---------- Production image ----------
FROM python:3.13-slim-trixie@sha256:57b29a7c050c4e679e4bea572e14b3965cf4b5839de2da49d55e49ffc4024f39 AS final

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/app

RUN useradd -u 10001 -U --create-home --shell /bin/false app

COPY --from=builder /opt/venv /opt/venv

# Remove old globally-installed package metadata from the base image.
# The current, patched packages are in /opt/venv.
RUN rm -rf \
    /usr/local/lib/python3.13/site-packages/msgpack \
    /usr/local/lib/python3.13/site-packages/msgpack-*.dist-info \
    /usr/local/lib/python3.13/site-packages/setuptools \
    /usr/local/lib/python3.13/site-packages/setuptools-*.dist-info \
    /usr/local/lib/python3.13/site-packages/urllib3 \
    /usr/local/lib/python3.13/site-packages/urllib3-*.dist-info

COPY --chown=app:app . .

ENV PATH="/opt/venv/bin:${PATH}"

USER app

EXPOSE 80

CMD ["gunicorn", "app:app", "-b", "0.0.0.0:80", "--log-file", "-", "--access-logfile", "-", "--workers", "4", "--keep-alive", "0"]