FROM debian:stable-slim

RUN apt-get update && apt-get install -y \
  curl \
  dpkg-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY update-discord-repo.sh /app/update-discord-repo.sh

RUN chmod +x /app/update-discord-repo.sh

VOLUME ["/repo"]
# liked to host /var/local/discord-repo

ENTRYPOINT ["/app/update-discord-repo.sh"]