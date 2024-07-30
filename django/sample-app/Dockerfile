# Use the official Python image from the Docker Hub
FROM python:3.9

LABEL VERSION="0.0.5"

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set the working directory in the container
WORKDIR /app

# Copy the dependencies file to the working directory
COPY requirements.txt .

# Install any dependencies
RUN pip install -r requirements.txt

# Copy the content of the local src directory to the working directory
COPY . .

# Make port 8000 available to the world outside this container
EXPOSE 8000

USER x

# Command to run the application
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
