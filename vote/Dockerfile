# base defines a base stage that uses the official python runtime base image
# FROM python:3.11-slim AS base
FROM python:3.11-slim-trixie@sha256:e88e9763f943ec1834f992a4b51e0f24500486803e8bc534e5767af9ea65f6ce AS base
# Add curl for healthcheck
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Set the application directory
WORKDIR /usr/local/app

# Install our requirements.txt
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# dev defines a stage for development, where it'll watch for filesystem changes
FROM base AS dev
RUN pip install watchdog
ENV FLASK_ENV=development
CMD ["python", "app.py"]

# final defines the stage that will bundle the application for production
FROM base AS final

# 1. Create the user AND fix the folder permissions in one shot
RUN useradd -u 10001 -U --create-home --shell /bin/false app && \
    chown -R app:app /home/app 
    # && \ chown -R app:app /usr/local/app

# Copy our code from the current folder to the working directory inside the container
# COPY . .
COPY --chown=app:app . .

# 3. Switch to the non-root user
USER app

# Make port 80 available for links and/or publish
EXPOSE 80

# Define our command to be run when launching the container
CMD ["gunicorn", "app:app", "-b", "0.0.0.0:80", "--log-file", "-", "--access-logfile", "-", "--workers", "4", "--keep-alive", "0"]
