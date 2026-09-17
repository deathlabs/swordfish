FROM alpine:3.24
LABEL image.authors="Victor Fernandez III, @cyberphor"
WORKDIR /home/swordfish/
COPY entrypoint.sh entrypoint.sh
RUN apk add --no-cache postgresql postgresql-contrib libpq-dev &&\
    (apk del wget || true) &&\
    chmod u+x /home/swordfish/entrypoint.sh &&\
    mkdir /var/lib/postgresql/data &&\
    mkdir /run/postgresql &&\
    chown -R postgres:postgres /var/lib/postgresql/data &&\
    chown -R postgres:postgres /run/postgresql
USER postgres
EXPOSE 5432
CMD [ "./entrypoint.sh" ]
