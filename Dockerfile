FROM python:2

ENV WHITELIST null
ENV SG_ID null
ENV AWS_ACCESS_KEY_ID null
ENV AWS_SECRET_ACCESS_KEY null

RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
    apt-get update && \
    apt-get install -y curl jq ipcalc && \
    pip install awscli && \
    rm -rf /var/lib/apt/lists/*

COPY crontab /etc/cron.d/openshift-blocker
RUN chmod 0644 /etc/cron.d/openshift-blocker
RUN touch /var/log/cron.log

CMD cron && tail -f /var/log/cron.log
