# Stage 1: get the Flex Template launcher binary
FROM gcr.io/dataflow-templates-base/python310-template-launcher-base:latest AS template_launcher

# Stage 2: use the Beam SDK image as the actual runtime base
FROM apache/beam_python3.10_sdk:2.69.0

# Copy the Flex Template launcher binary into the runtime image
COPY --from=template_launcher /opt/google/dataflow/python_template_launcher /opt/google/dataflow/python_template_launcher

# Copy your pipeline files
COPY ingestion.py /template/ingestion.py
COPY requirements.txt /template/requirements.txt

# Install dependencies into the global environment
RUN pip install --no-cache-dir -r /template/requirements.txt \
    && pip check

# Flex Template launcher config
ENV FLEX_TEMPLATE_PYTHON_PY_FILE="/template/ingestion.py"

# Optional workaround for Beam custom-container env behavior
ENV RUN_PYTHON_SDK_IN_DEFAULT_ENVIRONMENT=1
