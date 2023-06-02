import subprocess
import socket

host = '127.0.0.1'
port = 1234

server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_socket.bind((host, port))
server_socket.listen(1)

print("服务器已启动，等待客户端连接...")

def launch():
    print("launch")
    shell_command = "ios-deploy --justlaunch --noinstall --debug --bundle ./bili-studio.app"
    process = subprocess.Popen(shell_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()  
    output = (stdout + stderr).decode("utf-8")
    print(output)

flag = True

while flag:
    client_socket, client_address = server_socket.accept()
    print("客户端已连接：", client_address)
    while True:
        print("recv")
        data = client_socket.recv(1024).decode('utf-8')
        print(data)
        if not data:
            break
        if data == "{launch}":
            launch()
            response = '{launch fininsh}'
        elif data == '{end}':
            flag = False
            response = '{end fininsh}'
        else:
            response = '{unknown}'
    
        client_socket.send(response.encode('utf-8'))

    client_socket.close()


