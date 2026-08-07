# syntax=docker/dockerfile:1
#
# SPDX-FileCopyrightText: 2019-2026 CERN.
# SPDX-FileCopyrightText: 2019-2020 Northwestern University.
# SPDX-License-Identifier: MIT
#
# Dockerfile that builds a fully functional image of your app.
#
# The base image (https://github.com/inveniosoftware/docker-invenio) provides
# Python 3.14, uv, Node.js and pnpm.

FROM ghcr.io/inveniosoftware/invenio:14-debian AS base

FROM base AS builder

COPY README.md pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

COPY ./docker/uwsgi/ ${INVENIO_INSTANCE_PATH}
COPY ./invenio.cfg ${INVENIO_INSTANCE_PATH}
COPY ./templates/ ${INVENIO_INSTANCE_PATH}/templates/
COPY ./app_data/ ${INVENIO_INSTANCE_PATH}/app_data/
COPY ./translations/ ${INVENIO_INSTANCE_PATH}/translations/
COPY ./assets/ ./assets/
COPY ./static/ ./static/

RUN cp -r ./static/. ${INVENIO_INSTANCE_PATH}/static/ && \
    cp -r ./assets/. ${INVENIO_INSTANCE_PATH}/assets/ && \
    invenio collect --verbose && \
    invenio webpack buildall && \
    rm -rf \
        /root/.cache \
        /tmp/* \
        ${INVENIO_INSTANCE_PATH}/assets

FROM base

COPY . .
COPY --from=builder ${WORKING_DIR}/src/.venv ./.venv
COPY --from=builder ${INVENIO_INSTANCE_PATH}/static/ ${INVENIO_INSTANCE_PATH}/static/
COPY ./docker/uwsgi/ ${INVENIO_INSTANCE_PATH}
COPY ./invenio.cfg ${INVENIO_INSTANCE_PATH}
COPY ./templates/ ${INVENIO_INSTANCE_PATH}/templates/
COPY ./app_data/ ${INVENIO_INSTANCE_PATH}/app_data/
COPY ./translations/ ${INVENIO_INSTANCE_PATH}/translations/

# application build args to be exposed as environment variables
ARG IMAGE_BUILD_TIMESTAMP
ARG SENTRY_RELEASE

# Expose random sha to uniquely identify this build
ENV INVENIO_IMAGE_BUILD_TIMESTAMP="'${IMAGE_BUILD_TIMESTAMP}'"
ENV SENTRY_RELEASE=${SENTRY_RELEASE}

RUN echo "Image build timestamp $INVENIO_IMAGE_BUILD_TIMESTAMP"

ENTRYPOINT [ "bash", "-c"]
