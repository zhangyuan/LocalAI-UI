FROM node:20-buster AS build

WORKDIR /app

COPY package-lock.json /app

RUN npm ci

COPY . /app

RUN npm build

FROM nginx:alpine3.18

COPY --from=build /app/dist /var/www/html/