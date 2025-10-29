# Stage 1: Builder
# Use a slim Python image based on Debian Bookworm (Debian 12)
FROM python:3.11-slim-bookworm AS builder

# Set the working directory
WORKDIR /app

# Install any system-level dependencies required for building Python packages
# For PyTorch, often none are strictly necessary if using pre-built wheels,
# but 'gcc' and 'g++' might be needed for other scientific Python packages
# that compile C/C++ extensions. Keep it minimal.
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    # You might not need 'build-essential' for pre-compiled PyTorch wheels,
    # but it's often a good general-purpose inclusion for other packages.
    # build-essential \
    # libgl1-mesa-glx \ # if you need any GUI/rendering libraries (unlikely for this script)
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy only the requirements file first to leverage Docker's build cache.
COPY requirements.txt .

# Install Python dependencies.
# '--no-cache-dir' prevents pip from storing downloaded packages, saving space.
# Ensure you specify the CPU-only version of PyTorch if you don't need GPU.
RUN pip install --no-cache-dir -r requirements.txt \
	--index-url https://download.pytorch.org/whl/cpu \
	--extra-index-url https://pypi.org/simple/

# Copy your application code
COPY clipthelandscape-processor.py .

# -----------------------------------------------------------------------------

# Stage 2: Final (Runtime) Image
# Start a new, even leaner Python image based on Bookworm.
FROM python:3.11-slim-bookworm

# Set the working directory for the final image
WORKDIR /app

# Copy the installed Python packages from the builder stage.
# This ensures only the necessary libraries are included.
# Adjust the path to 'site-packages' if your Python version differs.
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# Copy your application code from the builder stage.
COPY --from=builder /app/clipthelandscape-processor.py /app/clipthelandscape-processor.py

# Define the entrypoint to run your Python script
CMD ["python", "clipthelandscape-processor.py"]
