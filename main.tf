# =========================================================
# Terraform Lab – Vertex AI Edition
# Provisions:
#   1. A Cloud Storage bucket  (model artifacts / datasets)
#   2. A Vertex AI Dataset     (managed tabular dataset)
#   3. A Vertex AI Endpoint    (ready to serve predictions)
# =========================================================

# ---------------------------------------------------------
# Variables – values are loaded from your .env file via
# TF_VAR_ prefixed environment variables. Never hardcode
# these values directly in this file.
# ---------------------------------------------------------
variable "project_id" {
  description = "Your GCP project ID"
  type        = string
}

variable "bucket_suffix" {
  description = "A unique suffix for the Cloud Storage bucket name (e.g. your initials + date)"
  type        = string
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

# ---------------------------------------------------------
# 1. Cloud Storage bucket – stores CSVs, model artifacts,
#    or any files Vertex AI needs to read/write.
# ---------------------------------------------------------
resource "google_storage_bucket" "vertex_ai_bucket" {
  name          = "vertex-ai-lab-bucket-${var.bucket_suffix}"
  location      = "us-central1"
  force_destroy = true

  labels = {
    environment = "development"
    owner       = "team-terraform"
  }
}

# ---------------------------------------------------------
# 2. Vertex AI Dataset – a managed dataset resource.
#    We are creating a tabular dataset (CSV-backed).
#    display_name is how it appears in the GCP Console.
# ---------------------------------------------------------
resource "google_vertex_ai_dataset" "tabular_dataset" {
  display_name        = "terraform-lab-dataset"
  metadata_schema_uri = "gs://google-cloud-aiplatform/schema/dataset/metadata/tabular_1.0.0.yaml"
  region              = "us-central1"

  labels = {
    environment = "development"
    owner       = "team-terraform"
  }
}

# ---------------------------------------------------------
# 3. Vertex AI Endpoint – the serving endpoint that a
#    trained model gets deployed to. Think of this as
#    creating the "stage" before the performer arrives.
#    A model can be deployed to it in a later lab.
# ---------------------------------------------------------
resource "google_vertex_ai_endpoint" "prediction_endpoint" {
  name         = "terraform-lab-endpoint"
  display_name = "Terraform Lab Prediction Endpoint"
  location     = "us-central1"

  labels = {
    environment = "development"
    owner       = "team-terraform"
  }
}
