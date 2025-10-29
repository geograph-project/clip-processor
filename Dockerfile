# Stage 1: Builder
# Use a slim Python image as the base for building/installing dependencies.
# 'slim-buster' provides a good balance of size and compatibility for PyTorch.
FROM python:3.9-slim-buster AS builder

# Set the working directory
WORKDIR /app

# Install any system-level dependencies required for building Python packages
# For PyTorch, often none are strictly necessary if using pre-built wheels,
# but 'gcc' and 'g++' might be needed for other scientific Python packages
# that compile C/C++ extensions. Keep it minimal.
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Add any specific system dependencies here if your other packages require them
    # For a minimal PyTorch CPU build, often these are not needed:
    # build-essential \
    # libgl1-mesa-glx \ # if you need any GUI/rendering libraries
    && rm -rf /var/lib/apt/lists/*

# Copy only the requirements file first to leverage Docker's build cache.
# If requirements.txt doesn't change, this layer is cached.
COPY requirements.txt .

# Install Python dependencies.
# '--no-cache-dir' prevents pip from storing downloaded packages, saving space.
# Ensure you specify the CPU-only version of PyTorch if you don't need GPU.
RUN pip install --no-cache-dir -r requirements.txt

# Copy your application code
COPY clipthelandscape-processor.py .

# Stage 2: Final (Runtime) Image
# Start a new, even leaner Python image.
# We only copy the necessary files from the builder stage, leaving behind
# build tools, cached files, and intermediate artifacts.
FROM python:3.9-slim-buster

# Set the working directory for the final image
WORKDIR /app

# Copy the installed Python packages from the builder stage.
# This ensures only the necessary libraries are included.
# Adjust the path to 'site-packages' if your Python version differs.
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages

# Copy your application code from the builder stage.
COPY --from=builder /app/clipthelandscape-processor.py /app/clipthelandscape-processor.py

# Define the entrypoint to run your Python script
# This ensures that when the container starts, your script is executed.
CMD ["python", "clipthelandscape-processor.py"]
