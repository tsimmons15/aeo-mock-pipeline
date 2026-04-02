# Stage 1: Flex Template launcher binary
FROM gcr.io/dataflow-templates-base/python310-template-launcher-base:latest AS template_launcher

# Stage 2: Shared base — Beam SDK + shared transforms + common deps
FROM apache/beam_python3.10_sdk:2.69.0 AS pipeline_base

COPY --from=template_launcher /opt/google/dataflow/python_template_launcher /opt/google/dataflow/python_template_launcher

# Install shared library and constrained deps first — this layer is shared by both images
COPY constraints.txt /template/constraints.txt
COPY aeo_transforms/ /template/aeo_transforms/
COPY requirements.txt /template/requirements.txt

RUN pip install --no-cache-dir -c /template/constraints.txt /template/aeo_transforms/ \
    && pip install --no-cache-dir -c /template/constraints.txt -r /template/requirements.txt \
    && pip check

ENV RUN_PYTHON_SDK_IN_DEFAULT_ENVIRONMENT=1

# Stage 3: Pipeline-specific image, selected via build arg
FROM pipeline_base AS final

ARG PIPELINE_TYPE=batch

# Validate PIPELINE_TYPE before any COPY that depends on it
# Used primarily in case the Docker build is invoked directly
# dataflow-build.ps1 will already build batch and streaming images directly,
# so this is an unnecessary safeguard for dataflow-build.ps1
RUN case "$PIPELINE_TYPE" in \
      batch|streaming) echo "PIPELINE_TYPE=$PIPELINE_TYPE is valid" ;; \
      *) echo "ERROR: Invalid PIPELINE_TYPE '$PIPELINE_TYPE'. Must be one of: batch, streaming" && exit 1 ;; \
    esac

# Copy only the entrypoint for the selected pipeline type
COPY ${PIPELINE_TYPE}_pipeline/ingestion.py /template/pipeline.py

ENV FLEX_TEMPLATE_PYTHON_PY_FILE="/template/pipeline.py"
