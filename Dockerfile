FROM cirrusci/flutter:dev

RUN apt-get update -y

RUN apt-get install -y --no-install-recommends gnupg

# Copy app source code and run it.
COPY . $GITHUB_WORKSPACE/app/

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
