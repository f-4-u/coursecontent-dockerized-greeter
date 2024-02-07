# Stage 1: Build stage
FROM alpine:latest AS builder

# Install git
RUN apk add --update --no-cache \
    git \
    sed \
    && rm -rf /var/cache/apk/*

# Set working directory
WORKDIR /app

# Clone the repository containing the greeter script
RUN git clone https://github.com/f-4-u/coursecontent-greeter.git /app

# Quick and dirty hack to address the issue of the script expecting commands at specific absolute paths that are not available in the Alpine Linux environment.
# Each sed command is used to replace hardcoded absolute paths to commands in the script (greeter.sh) with the corresponding paths found in the Alpine Linux environment.
# For example, /usr/bin/touch is replaced with /bin/touch, /usr/bin/grep is replaced with /bin/grep, and so on.
# This is a workaround to ensure that the script runs correctly in the Alpine Linux environment.
RUN sed -i "s|/usr/bin/touch|/bin/touch|g" /app/greeter.sh \
    && sed -i "s|/usr/bin/grep|/bin/grep|g" /app/greeter.sh \
    && sed -i "s|/usr/bin/chmod|/bin/chmod|g" /app/greeter.sh \
    && sed -i "s|/usr/bin/date|/bin/date|g" /app/greeter.sh \
    && sed -i "s|/usr/bin/sed|/bin/sed|g" /app/greeter.sh

# Make the greeter script executable
RUN chmod u+x /app/greeter.sh

# Stage 2: Final stage
FROM alpine:latest AS final

# Define environment variables with default values
ARG USER=greatuser
ARG GROUP=nobody

# Install required tools and binaries
RUN apk add --update --no-cache \
    bash \
    coreutils \
    grep \
    sed \
    sudo \
    && rm -rf /var/cache/apk/*

# Create a non-root user
RUN adduser -D $USER

# Set working directory
WORKDIR /app

# Copy the greeter script from the builder stage
COPY --from=builder /app/greeter.sh /app/greeter

# Set ownership of files to the non-root user
RUN chown -R $USER:$USER /app

# Switch to the non-root user
USER $USER

# Set the PATH environment variable to include the /app directory
ENV PATH="/app:/bin:$PATH"

# Define the default command to execute when the container starts
CMD ["/bin/bash", "-c", "greeter"]