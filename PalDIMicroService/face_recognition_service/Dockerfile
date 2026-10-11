FROM python:3.10-slim

WORKDIR /app

# Copy service code
COPY server.py /app/server.py

EXPOSE 5060

# Run lightweight biometric face recognition engine
CMD ["python", "server.py"]
