# Use AWS Lambda Python 3.12 base image
FROM public.ecr.aws/lambda/python:3.12

# Copy function code
COPY app.py ${LAMBDA_TASK_ROOT}

# Set the handler (file.function_name)
CMD ["app.lambda_handler"]


