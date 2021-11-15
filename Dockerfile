FROM cirrusci/flutter:dev

RUN apt-get update -y

RUN apt-get install -y --no-install-recommends gnupg

# Copy app source code and run it.
COPY . /app/

# Copy our code from the action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Indicate the file to execute when the docker container starts up
ENTRYPOINT ["/entrypoint.sh"]
