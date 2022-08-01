FROM python:3.9
WORKDIR /usr/src/client
COPY . .
EXPOSE 12345
RUN apt update && apt install strace -y
ENTRYPOINT ["strace"]
CMD ["python", "./client.py"]