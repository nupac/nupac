FROM python:3.9
WORKDIR /usr/src/server
COPY . .
EXPOSE 12345
RUN apt update && apt install strace -y
ENTRYPOINT ["python", "./server.py"]