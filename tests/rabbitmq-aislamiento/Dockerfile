FROM python:3.13.7-slim@sha256:5f55cdf0c5d9dc1a415637a5ccc4a9e18663ad203673173b8cda8f8dcacef689
WORKDIR /suite
COPY requirements.txt ./
RUN pip install --no-cache-dir --requirement requirements.txt
COPY test_isolation.py ./
ENTRYPOINT ["python", "-m", "unittest", "-v", "test_isolation"]
