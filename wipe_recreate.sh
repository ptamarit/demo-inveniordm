#!/usr/bin/env sh
# SPDX-FileCopyrightText: 2020-2023 CERN.
# SPDX-License-Identifier: MIT

# Quit on errors
set -o errexit

# Quit on unbound symbols
set -o nounset

# Prompt to confirm action
# NOTE: keep this POSIX sh; /bin/sh is dash in the Debian base image.
printf "Are you sure you want to wipe everything and create a new empty instance? [y/N] "
read -r response
case "${response}" in
    [yY]|[yY][eE][sS])
        ;;
    *)
        exit 0
        ;;
esac

instance_data="$(invenio shell --no-term-title -c "print(app.instance_path)")/data"

# Wipe
# ----
invenio shell --no-term-title -c "import redis; redis.StrictRedis.from_url(app.config['CACHE_REDIS_URL']).flushall(); print('Cache cleared')"
# NOTE: db destroy is not needed since DB keeps being created
#       Just need to drop all tables from it.
invenio db drop --yes-i-know
invenio index destroy --force --yes-i-know
invenio index queue init purge
# NOTE: contents only, the directory itself is a mounted volume.
if [ -d "$instance_data" ]; then
    find "$instance_data" -mindepth 1 -delete
    echo "Deposited files removed from $instance_data"
fi

# Recreate
# --------
# NOTE: db init is not needed since DB keeps being created
#       Just need to create all tables from it.
invenio db create
invenio files location create --default 'default-location' "$instance_data"
#
# Create roles
#
# Superuser role
invenio roles create admin
invenio access allow superuser-access role admin
# Administration access role
invenio roles create administration
invenio access allow administration-access role administration
# Administration moderation role
invenio roles create administration-moderation
invenio access allow administration-moderation role administration-moderation

invenio index init --force
invenio rdm-records custom-fields init
invenio communities custom-fields init

# Add demo and fixtures data
# -------------
# NOTE: run eagerly, otherwise this returns before Celery has written the rows
#       and the awards import below finds no funders.
INVENIO_CELERY_TASK_ALWAYS_EAGER=True \
INVENIO_CELERY_TASK_EAGER_PROPAGATES=True \
    invenio rdm-records fixtures
invenio rdm-records demo
# Import awards vocabulary
invenio vocabularies import --vocabulary awards --origin "app_data/vocabularies/awards_sample.tar"

# Enable admin user
invenio users activate admin@inveniosoftware.org
