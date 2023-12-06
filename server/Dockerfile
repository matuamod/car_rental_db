FROM python:3.9-alpine

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

WORKDIR /server

COPY . .

RUN apk add bash

RUN pip install --upgrade pip setuptools \
    && pip install -r requirements.txt

