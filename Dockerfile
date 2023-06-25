# Define the name of the image
# python 3.9 will be used
# the alpine is a lightweight version of linux that is ideal for running Docker container because it is stripped down
# and doesn't have anu unecessary dependencies
FROM python:3.9-alpine3.13
# Define the maintainer: who ever is taking care of the project
# This is a good practice
LABEL maintainer="osameh"
# Don't buffer python output, the output will be printed directly to console
ENV PYTHONUNBUFFERED 1
# copy files from our environment to hte container
# This is the requirement file for our container
COPY ./requirements.txt /tmp/requirements.txt
# This is the requirement file for our development environment
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
COPY ./app /app
# Set the default directory where the commands will be run from the Docker image
# This is where we copied our local app files to on the container 
WORKDIR /app
# Expose port 8000 from the container to our machine
EXPOSE 8000
# Define a build argument called DEV and set it to false
ARG DEV=false
# The command to be run on the alpine image in the conatiner
# Each of the lines in the RUN below can be executed using RUN at the beginning of the line
# However, an image layer will be created with evey single command that we run
# Try to reduce the image layers to keep our images as lightweight as possible
# So writing the command the way it was done below is more efficient
# Note that we added a user in the last command to avoid running our application as root
# Note that .tmp-build-deps below is used to group all the dependencies build-base postgresql-dev musl-dev
# These dependencies are needed to install postgresql-client but are not needed afterwards
# That is why they are removed later by apk del .tmp-build-deps && \
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client && \
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    rm -rf /tmp && \
    apk del .tmp-build-deps && \
    adduser \ 
        --disabled-password \
        --no-create-home \
        django-user
# Add the virtual env to alpine PATH
ENV PATH="/py/bin:$PATH"
# Specify the user that we are switching to. 
# Until the line below, everything is being done as the root user
# THIS SHOULD BE THE LAST LINE IN A DOCKERFILE BECAUSE USERS ARE GOING TO SWITCH ==> YOU ARE NO LONGER ROOT
USER django-user
