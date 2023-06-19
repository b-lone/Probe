import subprocess
import socket
import re
import os

current_dir = os.getcwd()
print("Current working directory:", current_dir)

host = '127.0.0.1'
port = 1234

server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_socket.bind((host, port))
server_socket.listen(1)

print("服务器已启动，等待客户端连接...")

def launch():
    print("launch")
    shell_command = "ios-deploy --justlaunch --noinstall --debug --bundle /Users/archie/Library/Developer/Xcode/DerivedData/bili-studio-bxzifbpjhtyddjhbhghkzowlryfb/Build/Products/Debug-iphoneos/bazel-out/applebin_ios-ios_arm64-dbg-ST-3a8ae290c50a/bin/bilistudio-universal/bili-studio.app"
    process = subprocess.Popen(shell_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()  
    output = (stdout + stderr).decode("utf-8")
    print(output)

def download(path):
    print("download")
    shell_command = f"ios-deploy --download={path} --bundle_id 'com.bilibili.studio' --to ."
    process = subprocess.Popen(shell_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()  
    output = (stdout + stderr).decode("utf-8")
    print(output)

flag = True
def onCommand(command, para_list):
    response = ''
    if command == "launch":
        launch()
        response = '{launch fininsh}'
    elif command == 'end':
        global flag
        flag = False
        response = '{end fininsh}'
    elif command == 'download':
        download(para_list[1])
        response = f"{{download finish:{para_list[0]}}}"
    else:
        response = '{unknown}'

    print(response)
    client_socket.send(response.encode('utf-8'))

while flag:
    client_socket, client_address = server_socket.accept()
    print("客户端已连接：", client_address)
    while True:
        print("recv")
        buffer = client_socket.recv(1024).decode('utf-8')
        print(buffer)
        if not buffer:
            break

        command = ""
        para_list = []
        while "{" in buffer and "}" in buffer:
            start_index = buffer.index("{")
            end_index = buffer.index("}")
            message = buffer[start_index:end_index + 1]
            print(message)
            buffer = buffer[end_index + 1:]
            pattern = r"{(\w+)(?::([^}]*))?}"
            matches = re.search(pattern, message)
            
            if matches:
                command = matches.group(1)
                paras = matches.group(2)
    
                if paras:
                    para_list = paras.split('&')
                    print("Command:", command)
                    print("Parameters:", para_list)
                else:
                    print("Command:", command)
                    print("No parameters")
            else:
                print("No match found")
            
            onCommand(command, para_list)

        

    client_socket.close()


