FROM debian:jessie-slim
RUN apt-get update
RUN apt-get -y install build-essential bc
RUN apt-get -y install libssl-dev
RUN apt-get -y install openssl
