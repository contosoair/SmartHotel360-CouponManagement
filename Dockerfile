FROM tomcat:9-jre8-alpine as base
WORKDIR /app

RUN apk --update add curl ca-certificates tar 
RUN set -x \
    && mkdir /home/mysql \
    && curl -fSL https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.40.tar.gz -o /home/mysql/mysql-connector.jar \
    && cd /home/mysql \
    && tar -xzvf mysql-connector.jar \
    && pwd \
    && mkdir -p /usr/share/java \
    && mv /home/mysql/mysql-connector-java-5.1.40/mysql-connector-java-5.1.40-bin.jar /usr/share/java/mysql-connector-java.jar \
    && cd /home \
    && rm -R *
    RUN export CLASSPATH=$CLASSPATH:/usr/share/java/mysql-connector-java.jar

FROM tomcat:9-jre8-alpine AS maven
WORKDIR ./
COPY . .
RUN chmod +x ./mvnw
RUN sed -i 's/\r$//' mvnw
RUN ./mvnw install

FROM maven as build
WORKDIR ./
RUN ./mvnw package

FROM base as final
WORKDIR /app
COPY --from=build /target/ROOT.war /usr/local/tomcat/webapps/
EXPOSE 8080
ENTRYPOINT exec java -Djava.security.egd=file:/dev/./urandom -jar /app/ROOT.war
