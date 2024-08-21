FROM python:3.10
 
WORKDIR /app
 
RUN pip install devpi-web devpi-client
RUN devpi-init
 
CMD [ "devpi-server", "--host", "0.0.0.0", "--port", "3141" ]