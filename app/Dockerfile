# Use AWS Lambda Python 3.12 base image
FROM public.ecr.aws/lambda/python:3.12

# Amazon Linux 2023 pins packages to the image's release, so a plain update
# installs nothing. --releasever=latest pulls current security fixes.
RUN dnf -y upgrade --releasever=latest && dnf clean all

# Copy function code
COPY app.py ${LAMBDA_TASK_ROOT}

# Set the handler (file.function_name)
CMD ["app.lambda_handler"]
