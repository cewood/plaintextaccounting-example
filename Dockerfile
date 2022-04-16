FROM python:3.8.3-alpine3.11

RUN apk add \
  bash \
  build-base \
  libxml2-dev \
  libxslt-dev \
  make

RUN pip3 install \
  beancount==2.3.4 \
  fava==1.19
