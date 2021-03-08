#building stage

FROM maven:3.6.3-jdk-8-slim as maven_builder

WORKDIR /app 

RUN apt-get update && apt-get install git -y && git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git

WORKDIR /app/boxfuse-sample-java-war-hello

RUN ["mvn", "package"]

#deploy stage

FROM tomcat:10.0.2-jdk8-corretto

COPY --from=maven_builder /app/boxfuse-sample-java-war-hello/target/hello-1.0.war /usr/local/tomcat/webapps