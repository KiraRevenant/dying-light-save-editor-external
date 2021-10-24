FROM ubuntu:20.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive ( \
        apt-get upgrade -y && apt-get install -y libgtk-3-dev \
    )
