# -----------------------------------------------------------------------------
# Credentials for rds
# -----------------------------------------------------------------------------


resource "random_password" "flyway_admin" {
  length           = 32
  override_special = "_"
}

resource "random_password" "prediction_app_user" {
  length           = 32
  override_special = "_"
}
