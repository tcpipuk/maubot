FROM node:20-bookworm-slim AS frontend-builder

COPY ./maubot/management/frontend /frontend
RUN cd /frontend && yarn --prod && yarn build

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-setuptools python3-wheel \
    ca-certificates \
    curl \
    gosu \
    jq \
    python3-aiohttp \
    python3-attr \
    python3-bcrypt \
    python3-cffi \
    python3-ruamel.yaml \
    python3-jinja2 \
    python3-click \
    python3-packaging \
    python3-markdown \
    python3-alembic \
    python3-cssselect \
    python3-commonmark \
    python3-pygments \
    python3-tz \
    python3-regex \
    python3-wcwidth \
    # encryption
    python3-olm \
    python3-cryptography \
    python3-unpaddedbase64 \
    python3-future \
    # plugin deps
    python3-pillow \
    python3-magic \
    python3-feedparser \
    python3-dateutil \
    python3-lxml \
    python3-semver \
    && curl -L https://github.com/mikefarah/yq/releases/download/v4.6.3/yq_linux_amd64 -o /usr/bin/yq \
    && chmod +x /usr/bin/yq \
    && pip3 install uv --break-system-packages \
    && rm -rf /var/lib/apt/lists/*
# TODO remove pillow, magic, feedparser, lxml, gitlab and semver when maubot supports installing dependencies

COPY requirements.txt /opt/maubot/requirements.txt
COPY optional-requirements.txt /opt/maubot/optional-requirements.txt
WORKDIR /opt/maubot
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-dev build-essential git \
    && uv pip install --system --break-system-packages -r requirements.txt -r optional-requirements.txt \
    dateparser langdetect python-gitlab pyquery tzlocal \
    && apt-get remove --purge -y python3-dev build-essential git \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*
# TODO also remove dateparser, langdetect and pyquery when maubot supports installing dependencies

COPY . /opt/maubot
RUN cp maubot/example-config.yaml .
COPY ./docker/mbc.sh /usr/local/bin/mbc
COPY --from=frontend-builder /frontend/build /opt/maubot/frontend
ENV UID=1337 GID=1337 XDG_CONFIG_HOME=/data
VOLUME /data

CMD ["/opt/maubot/docker/run.sh"]
