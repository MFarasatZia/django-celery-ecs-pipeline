#!/bin/bash

# Set the correct settings module based on environment
if [[ "$STAGE" == "prod" ]]; then
    export DJANGO_SETTINGS_MODULE=demo_backend.settings.prod
elif [[ "$STAGE" == "staging" ]]; then
    export DJANGO_SETTINGS_MODULE=demo_backend.settings.staging
elif [[ "$STAGE" == "dev" ]]; then
    export DJANGO_SETTINGS_MODULE=demo_backend.settings.dev
else
    export DJANGO_SETTINGS_MODULE=demo_backend.settings.local
fi

# Run celery in the foreground
celery -A demo_backend worker --loglevel=info --statedb=
