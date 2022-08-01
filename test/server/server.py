import socket

HOST = socket.gethostbyname('server')
PORT = 12345

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind((HOST, PORT))
    s.listen()
    connected, address = s.accept()
    with connected:
        while True:
            received = connected.recv(1024)
            if not received:
                break
            print(f"Received: {received.decode()}")