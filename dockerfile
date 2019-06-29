FROM alpine:3.10 as builder
LABEL maintainer "Morph1904 <morph1904@gmail.com>"

RUN apk add --no-cache \
        curl \
        tar
RUN curl -sLO https://github.com/mholt/caddy/releases/download/v1.0.0/caddy_v1.0.0_linux_amd64.tar.gz && tar -xzf caddy_v1.0.0_linux_amd64.tar.gz && mv caddy /usr/bin/caddy && chmod 755 /usr/bin/caddy && rm -rf caddy*

RUN /usr/bin/caddy -version

FROM node:8.16-alpine as nodebuild
COPY ./frontend /frontend
WORKDIR /frontend
RUN npm install
RUN npm run build

FROM python:3.7-alpine as Tyger2

ENV APPS_DIR=/apps
ENV TYGER_ROOT=$APPS_DIR/Tyger2
ENV TYGER_DIR=$TYGER_ROOT/backend
ENV TYGER_DATA=$TYGER_ROOT/data

RUN apk add --no-cache \
    git \
    uwsgi-python3 \
    bash && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools 

RUN apk add --no-cache --virtual build-dependencies gcc libc-dev linux-headers python3-dev && \
    pip3 install --upgrade pip setuptools

RUN mkdir -p $APPS_DIR
COPY --from=nodebuild /frontend/dist $TYGER_ROOT
COPY ./backend $TYGER_ROOT
COPY ./builder $TYGER_ROOT
COPY ./certs $TYGER_ROOT
COPY ./data $TYGER_ROOT
COPY ./newrequirements.txt $TYGER_ROOT

RUN pip3 install -r $TYGER_ROOT/newrequirements.txt

RUN apk del build-dependencies

RUN chmod -R 0775 $TYGER_ROOT

EXPOSE 80 443 9090 9091

VOLUME ["/apps/Tyger2/data", "/root/.caddy"]

COPY builder/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["run"]

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Tyger2" \
      org.label-schema.description="Caddy based reverse proxy app with web GUI " \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.version=$VERSION \
      org.label-schema.vcs-url="https://github.com/morph1904/Tyger2"