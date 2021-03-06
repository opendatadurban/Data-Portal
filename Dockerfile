FROM debian:stretch
MAINTAINER Gordon Inggs, Riaz Arbi, Derek Strong, Matthew Adendorff, Wasim Moosa
# With thanks to the main CKAN dockerfile - https://github.com/ckan/ckan/blob/ckan-2.8.3/Dockerfile

# Install required system packages
RUN apt-get -q -y update \
    && DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade \
    && apt-get -q -y install \
        python-dev \
        python-pip \
        python-virtualenv \
        python-wheel \
        libpq-dev \
        libxml2-dev \
        libxslt-dev \
        libgeos-dev \
        libssl-dev \
        libffi-dev \
        postgresql-client \
        build-essential \
        git-core \
        vim \
        wget \
    && apt-get -q clean \
    && rm -rf /var/lib/apt/lists/*

# Define environment variables
ENV CKAN_HOME /usr/lib/ckan
ENV CKAN_VENV $CKAN_HOME/venv
ENV CKAN_CONFIG /etc/ckan
ENV CKAN_STORAGE_PATH=/var/lib/ckan

# Create ckan user
RUN useradd -r -u 900 -m -c "ckan account" -d $CKAN_HOME -s /bin/false ckan

# Setup virtual environment for CKAN
RUN mkdir -p $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH && \
    virtualenv $CKAN_VENV && \
    ln -s $CKAN_VENV/bin/pip /usr/local/bin/ckan-pip &&\
    ln -s $CKAN_VENV/bin/paster /usr/local/bin/ckan-paster

# Setup CKAN
RUN git clone https://github.com/ckan/ckan.git $CKAN_VENV/src/ckan/
# Locking the version to 2.8.3
RUN cd $CKAN_VENV/src/ckan/ && git checkout tags/ckan-2.9.0
RUN ckan-pip install -U pip && \
    ckan-pip install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/requirement-setuptools.txt && \
    ckan-pip install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/requirements.txt && \
    ckan-pip install -e $CKAN_VENV/src/ckan/ && \
    ln -s $CKAN_VENV/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini && \
    cp -v $CKAN_VENV/src/ckan/contrib/docker/ckan-entrypoint.sh /ckan-entrypoint.sh && \
    chmod +x /ckan-entrypoint.sh && \
    chown -R ckan:ckan $CKAN_HOME $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH

# Setting up extensions
# Private Datasets extension
RUN ckan-pip install ckanext-privatedatasets

## Resource authorisation extension
RUN ckan-pip install git+https://github.com/etri-odp/ckanext-resourceauthorizer.git

## Custom Schema extension
RUN ckan-pip install -r https://raw.githubusercontent.com/ckan/ckanext-scheming/master/requirements.txt && \
    ckan-pip install git+https://github.com/ckan/ckanext-scheming.git

## Extra security extension
RUN ckan-pip install git+https://github.com/data-govt-nz/ckanext-security.git Beaker==1.6.4

# S3 filestore extension
RUN ckan-pip install git+https://github.com/okfn/ckanext-s3filestore boto3>=1.4.4 ckantoolkit

# Collaborators extension
#RUN ckan-pip install git+https://github.com/okfn/ckanext-collaborators.git

# Hierarchy extension
RUN ckan-pip install git+https://github.com/ckan/ckanext-hierarchy.git

# CCT Metadata extension
#RUN ckan-pip install git+https://github.com/cityofcapetown/ckanext-cct_metadata.git

# And back to getting things up
ENTRYPOINT ["/ckan-entrypoint.sh"]

USER ckan
EXPOSE 5000

CMD ["ckan-paster","serve","/etc/ckan/production.ini"]
