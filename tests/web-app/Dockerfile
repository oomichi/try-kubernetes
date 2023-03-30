FROM python:3.9-slim

RUN pip install --upgrade pip --no-cache-dir \
 && pip install flask

COPY flask-web.py flask-web.py

CMD ["python", "flask-web.py"]
