# New Custom Image
FROM public.ecr.aws/docker/library/python:3.13

# Set Working Directory
RUN mkdir /usr/src/demo_app
WORKDIR /usr/src/demo_app

# Set Environment Variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install Dependencies
RUN apt-get update && \
    apt-get install -y curl nginx postgresql-client && \
    apt-get clean

# Copy Files
COPY ./pyproject.toml .
COPY ./poetry.lock .
COPY . /usr/src/demo_app

RUN apt-get update && \
    apt-get install -y dos2unix && \
    dos2unix /usr/src/demo_app/entrypoint.sh

# Install Poetry
RUN pip install --upgrade pip && \
    pip install poetry

# Configure Poetry
RUN poetry config virtualenvs.create false
RUN poetry config installer.max-workers 10

# Install Project Dependencies (without dev dependencies for staging/prod)
ARG STAGE=prod
RUN if [ "$STAGE" = "dev" ] ; then \
        poetry install ; \
    else \
        poetry install --without dev ; \
    fi

# Create media directory and set permissions
RUN mkdir -p /usr/src/demo_app/media && \
    chmod 755 /usr/src/demo_app/media

# Configure Nginx
COPY nginx.conf /etc/nginx/conf.d
RUN mkdir -p /run/nginx

# Open Ports
EXPOSE 8000

# Run Project
RUN cd /usr/src/demo_app
RUN chmod +x /usr/src/demo_app/entrypoint.sh
# RUN chmod +x entrypoint.sh
ENTRYPOINT [ "./entrypoint.sh" ]
