# Terraform Beginner Lab (GCP + Vertex AI Edition)

> **Addition:** Instead of provisioning a generic VM, this lab provisions AI/ML infrastructure on Vertex AI, which is the same kind of infrastructure used to build and serve production ML models on GCP. You will create a Cloud Storage bucket (for data and artifacts), a managed Vertex AI Dataset, and a Vertex AI prediction Endpoint.

---

## Objective
Learn the fundamentals of Terraform by creating, managing, and destroying GCP infrastructure for a machine learning workflow. By the end of this lab, students will:

- Understand the purpose of Terraform.
- Install and configure Terraform.
- Write and apply a Terraform configuration for Vertex AI resources.
- Use Terraform commands to manage infrastructure.
- You can follow along step by step, or you can run the commands using the code in `main.tf`.

---

## Prerequisites
- A GCP account with billing enabled.
- Google Cloud CLI installed and configured.
- A project set up in GCP with a linked billing account.
- Terraform installed on your local machine: https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli
- The following APIs must be enabled in your project:
  - `aiplatform.googleapis.com` (Vertex AI)
  - `storage.googleapis.com` (Cloud Storage)
  
  Enable them with:
  ```bash
  gcloud services enable aiplatform.googleapis.com storage.googleapis.com
  ```

### Create a Service Account and Key

1. Open the GCP Console.
2. Navigate to **IAM & Admin > Service Accounts**.
3. Click **Create Service Account**.
4. Enter a name (e.g., `terraform-service-account`).
5. Assign the following roles:
   - `Vertex AI Administrator` (for Vertex AI resources)
   - `Storage Admin` (for the Cloud Storage bucket)
6. Click **Create and Continue**.
7. Generate and download the JSON key file.

> **Addition:** In the original lab, `Editor` was enough for a simple VM. With Vertex AI, best practice is to use narrower, purpose-specific roles. This is a taste of real-world IAM hygiene.

### Set Environment Variables via .env

**Addition:** Rather than hardcoding your project ID and bucket suffix directly in `main.tf`, this lab uses Terraform's built-in support for `TF_VAR_` environment variables. Any environment variable prefixed with `TF_VAR_` is automatically picked up by Terraform and mapped to the matching `variable` block in your config.

1. Copy the provided `.env.example` file to `.env`:
    ```bash
    cp .env.example .env
    ```

2. Open `.env` and fill in your values:
    ```bash
    export TF_VAR_project_id="your-gcp-project-id"
    export TF_VAR_bucket_suffix="your-unique-suffix"  # e.g. your initials + date: "ab-20260218"
    export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your-key-file.json"
    ```

3. Source the file to load the variables into your current terminal session:
    ```bash
    source .env
    ```

4. Add both `.env` and your key file to `.gitignore` so they are never committed:
    ```bash
    echo ".env" >> .gitignore
    echo "*.json" >> .gitignore
    ```

> **Note:** `source .env` only applies to the current terminal session. You will need to re-run it each time you open a new terminal, or add the exports to your shell profile (e.g., `~/.bashrc` or `~/.zshrc`).

---

## Part 1: Setting Up Terraform

1. Verify Terraform is installed:
    ```bash
    terraform --version
    ```

2. Create a directory for your Terraform files:
    ```bash
    mkdir terraform-lab-vertexai
    cd terraform-lab-vertexai
    ```

3. Create a file named `main.tf` and add the following code:

    ```hcl
    variable "project_id" {
        description = "Your GCP project ID"
        type        = string
    }

    variable "bucket_suffix" {
        description = "A unique suffix for the Cloud Storage bucket name"
        type        = string
    }

    provider "google" {
        project = var.project_id
        region  = "us-central1"
    }

    resource "google_storage_bucket" "vertex_ai_bucket" {
        name          = "vertex-ai-lab-bucket-${var.bucket_suffix}"
        location      = "us-central1"
        force_destroy = true

        labels = {
            environment = "development"
            owner       = "team-terraform"
        }
    }

    resource "google_vertex_ai_dataset" "tabular_dataset" {
        display_name        = "terraform-lab-dataset"
        metadata_schema_uri = "gs://google-cloud-aiplatform/schema/dataset/metadata/tabular_1.0.0.yaml"
        region              = "us-central1"

        labels = {
            environment = "development"
            owner       = "team-terraform"
        }
    }

    resource "google_vertex_ai_endpoint" "prediction_endpoint" {
        name         = "terraform-lab-endpoint"
        display_name = "Terraform Lab Prediction Endpoint"
        location     = "us-central1"

        labels = {
            environment = "development"
            owner       = "team-terraform"
        }
    }
    ```

    > **Addition:** What are these three resources?
    > - **`google_storage_bucket`** is an object store for your CSVs, model artifacts, or anything Vertex AI needs to read/write. This is the same resource type as the original lab.
    > - **`google_vertex_ai_dataset`** is a managed dataset that Vertex AI uses for training. The `metadata_schema_uri` tells Vertex AI this is a *tabular* dataset (i.e., structured, CSV-style data). Think of it like telling your DAW which track type you are working with: MIDI vs. audio.
    > - **`google_vertex_ai_endpoint`** is the serving endpoint that a trained model gets deployed to. It is the "stage" that exists before the performer (your model) arrives. You are provisioning the infrastructure now; deploying a model to it is a future step.

4. Initialize Terraform:
    ```bash
    terraform init
    ```
    Terraform will download the Google Cloud provider plugin. You will see it fetch `hashicorp/google`.

---

## Part 2: Applying the Terraform Configuration

1. **Plan the infrastructure**: Preview what Terraform will create.
    ```bash
    terraform plan
    ```
    You should see 3 resources to be added: the bucket, the dataset, and the endpoint.

2. **Apply the infrastructure**:
    ```bash
    terraform apply
    ```
    Type `yes` at the prompt. The Vertex AI resources (dataset and endpoint) may take 1 to 3 minutes to provision, which is longer than a simple VM.

3. **View the changes in the GCP Console**:
    - **Cloud Storage** to confirm your bucket exists.
    - **Vertex AI > Datasets** to confirm `terraform-lab-dataset` appears.
    - **Vertex AI > Online prediction** to confirm `terraform-lab-endpoint` appears.

---

## Part 3: Modifying Resources

> **Addition:** Modifications in this lab target Vertex AI-specific attributes rather than VM machine types.

1. **Modify the dataset and bucket**: Change labels and update the endpoint display name.

    Update your `main.tf` with the following changes:

    ```hcl
    resource "google_storage_bucket" "vertex_ai_bucket" {
        name          = "vertex-ai-lab-bucket-${var.bucket_suffix}"
        location      = "us-central1"
        force_destroy = true

        labels = {
            environment = "staging"        # Changed from "development"
            owner       = "team-terraform"
            project     = "vertex-ai-lab"  # New label added
        }
    }

    resource "google_vertex_ai_endpoint" "prediction_endpoint" {
        name         = "terraform-lab-endpoint"
        display_name = "Terraform Lab Prediction Endpoint v2"  # Updated display name
        location     = "us-central1"

        labels = {
            environment = "staging"        # Changed from "development"
            owner       = "team-terraform"
        }
    }
    ```

2. **Apply the changes**:
    ```bash
    terraform apply
    ```
    Notice that Terraform shows which fields changed (labels, display name). It only modifies what is necessary, leaving other resources untouched.

3. **View the changes in the GCP Console**: Verify the updated labels on the bucket and the new display name on the endpoint.

---

## Part 4: Adding More Resources

> **Addition:** This part introduces the Vertex AI Feature Store, which is a managed store for ML features (computed values used as model inputs). Think of features like audio stems in a mix: pre-processed, reusable, and shared across multiple "tracks" (models).

1. **Add a Vertex AI Feature Store**:

    ```hcl
    resource "google_vertex_ai_featurestore" "feature_store" {
        name   = "terraform_lab_featurestore"
        region = "us-central1"

        online_serving_config {
            fixed_node_count = 1
        }

        labels = {
            environment = "development"
            owner       = "team-terraform"
        }
    }
    ```

    > Warning: Feature Stores incur cost while running. Make sure to destroy this resource when done with the lab (Part 5).

2. **Apply the changes**:
    ```bash
    terraform apply
    ```

3. **View the changes in the GCP Console**: Navigate to **Vertex AI > Feature Store** and confirm `terraform-lab-featurestore` appears.

---

## Part 5: Destroying Resources

1. **Destroy all resources**:
    ```bash
    terraform destroy
    ```
    Type `yes` at the prompt. Resources are destroyed in the correct dependency order automatically.

2. **Verify in the GCP Console**: Confirm the bucket, dataset, endpoint, and feature store no longer appear in their respective sections.

3. **Destroy a single resource**: To remove only the feature store without touching the rest, you can use:
    ```bash
    terraform destroy -target=google_vertex_ai_featurestore.feature_store
    ```
    > **Addition:** The `-target` flag is useful in ML workflows where some infrastructure (like a long-running endpoint) should stay up while you tear down experimental resources.

---

## Part 6: Understanding Different Terraform Files

1. **State file (`terraform.tfstate`)**:
    Terraform tracks all resources it manages in this JSON file. After applying, open it and find the Vertex AI endpoint entry. You will see GCP's internal IDs, the resource name, and all the attributes Terraform knows about.

    > **Addition:** State files become especially critical with Vertex AI. If you manually change an endpoint's display name in the GCP Console and then run `terraform apply`, Terraform will revert it. The state file is the source of truth.

    Never manually edit the state file. Store it remotely (e.g., in a GCS bucket) for team workflows.

2. **Terraform directory (`.terraform/`)**:
    Created by `terraform init`. Contains the downloaded `hashicorp/google` provider plugin. This directory should be added to `.gitignore` because it is large and fully reproducible via `terraform init`.

3. **`.env.example` and `.env`**:

    **Addition:** This lab introduces a `.env` pattern for injecting configuration values into Terraform without hardcoding them. `.env.example` is safe to commit (it has no real values), while `.env` should always stay in `.gitignore`. This mirrors how most production teams manage environment-specific configuration.
