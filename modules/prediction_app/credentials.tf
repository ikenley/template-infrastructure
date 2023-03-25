# -----------------------------------------------------------------------------
# Credentials for rds
# -----------------------------------------------------------------------------


resource "random_password" "flyway_admin" {
  for_each = local.users

  length           = 32
  override_special = "_"
}

resource "random_password" "prediction_app_user" {
  for_each = local.users

  length           = 32
  override_special = "_"
}
