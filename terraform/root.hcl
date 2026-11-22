locals {
  common_locals = yamldecode(file(find_in_parent_folders("common_locals.yaml")))
}

remote_state {
  backend = "gcs"
  config = {
    project  = local.common_locals.project_id
    location = "europe-west1"
    bucket   = local.common_locals.state_bucket
    prefix   = "fleetdm/${path_relative_to_include()}"
  }
}

inputs = {
  project_id = local.common_locals.project_id
}
