#!/bin/bash
# Builds the Lambda zip file for database password rotation.
# Note: Terraform's archive_file data source handles this automatically now,
# but this script is provided for manual inspection or CI pipelines without TF.

set -e

cd "$(dirname "$0")"

echo "Building rotate_db_password.zip..."

# Clean old zip
rm -f rotate_db_password.zip

# Create new zip with just the Python script (boto3 and psycopg2-binary are needed,
# but AWS Lambda Python 3.12 runtime includes boto3. psycopg2 needs to be a layer
# or bundled. For this simple rotation script using standard python pg8000 or 
# bundling psycopg2-binary in a container is better if pure python is needed. 
# We'll assume the environment has the pg library or we use the AWS Data API).
# For simplicity, we zip the python file.
zip rotate_db_password.zip rotate_db_password.py

echo "Done. Created rotate_db_password.zip"
