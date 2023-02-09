# Python的构建与部署

## 一. 编写示例应用

如需使用 Python 编写应用，请执行以下操作：

1. 创建名为 `helloworld` 的新目录，并转到此目录中：

   ```shell
   mkdir helloworld
   cd helloworld
   ```

2. 创建名为 `main.py` 的文件，并将以下代码粘贴到其中：

   此代码使用我们的“Hello World”问候语响应请求。HTTP 处理由容器中的 Gunicorn Web 服务器进行。当直接调用以供本地使用时，此代码会创建一个基本 Web 服务器，该服务器侦听 [`PORT` 环境变量](https://cloud.google.com/run/docs/reference/container-contract?hl=zh-cn#port)定义的端口。

   ```python
   import os
   
   from flask import Flask
   
   app = Flask(__name__)
   
   @app.route("/")
   def hello_world():
       name = os.environ.get("NAME", "World")
       return "Hello {}!".format(name)
   
   if __name__ == "__main__":
       app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
   ```

3. 创建名为 `requirements.txt` 的文件，并将以下代码粘贴到其中：

   ```python
   Flask==2.0.2
   gunicorn==20.1.0
   ```

   这会添加示例所需的软件包。

4. 添加包含以下内容的 Dockerfile

   ```dockerfile
   
   # Use the official lightweight Python image.
   # https://hub.docker.com/_/python
   FROM python:3.10-slim
   
   # Allow statements and log messages to immediately appear in the Knative logs
   ENV PYTHONUNBUFFERED True
   
   # Copy local code to the container image.
   ENV APP_HOME /app
   WORKDIR $APP_HOME
   COPY . ./
   
   # Install production dependencies.
   RUN pip install --no-cache-dir -r requirements.txt
   
   # Run the web service on container startup. Here we use the gunicorn
   # webserver, with one worker process and 8 threads.
   # For environments with multiple CPU cores, increase the number of workers
   # to be equal to the cores available.
   # Timeout is set to 0 to disable the timeouts of the workers to allow Cloud Run to handle instance scaling.
   CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
   ```

   这将启动 Gunicorn 网络服务器，该服务器会侦听 PORT 环境变量定义的端口。

5. 添加一个 `.dockerignore` 文件，以从容器映像中排除文件

   ```dockerfile
   Dockerfile
   README.md
   *.pyc
   *.pyo
   *.pyd
   __pycache__
   .pytest_cache
   ```

   您的应用已编写完毕，可以进行部署。

