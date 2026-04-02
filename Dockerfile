FROM eclipse-temurin:25-jdk AS build
WORKDIR /app
COPY . .
RUN chmod +x mvnw && ./mvnw -B -DskipTests clean package

FROM eclipse-temurin:25-jre
RUN apt-get update && apt-get install -y build-essential perl && \
    cd /tmp && \
    curl -LO https://github.com/openssl/openssl/releases/download/openssl-3.5.5/openssl-3.5.5.tar.gz && \
    tar xzf openssl-3.5.5.tar.gz && \
    cd openssl-3.5.5 && \
    ./config --prefix=/opt/openssl --openssldir=/opt/openssl/ssl && \
    make -j$(nproc) && \
    make install_sw && \
    cd / && rm -rf /tmp/openssl* && \
    apt-get purge -y build-essential perl && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

ENV LD_LIBRARY_PATH=/opt/openssl/lib64
ENV PATH="/opt/openssl/bin:$PATH"

WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
ENTRYPOINT ["sh", "-c", "java -Dserver.port=$PORT -jar app.jar"]
