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

PGPASSWORD=$PASSWORD psql -U "$USER" -h "$HOST" -p "$PORT" -d postgres -c "CREATE DATABASE $NAME;"

python manage.py migrate
python manage.py collectstatic --noinput
python manage.py loaddata country_data
python manage.py loaddata currency_data

if [[ "$STAGE" == "dev" || "$STAGE" == "staging" ]]
then
    # Seed data into the database (safe demo fixtures)
    FROM_FIXTURE=1 python manage.py loaddata user_data
    python manage.py loaddata account_data
    # python manage.py loaddata role_data
    # python manage.py loaddata responsibility_data
    # python manage.py loaddata badge_data
    python manage.py loaddata position_data
    python manage.py loaddata employee_data
    # python manage.py loaddata assignment_data
    python manage.py fix_positions
    python manage.py add_chatters
fi

# Start gunicorn
nginx
gunicorn -c gunicorn.conf.py demo_backend.wsgi:application --access-logfile '-'
