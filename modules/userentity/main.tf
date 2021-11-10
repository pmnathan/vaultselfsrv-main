terraform {
  required_providers {
    vault = {
      configuration_aliases = [ vault.root, vault.eng ]
    }
  }
}


locals {
  department    = [for e in var.json_data.users : e.department if e.username == var.username][0]
  email    = [for e in var.json_data.users : e.email if e.username == var.username][0]
  policy  = ""
}



data "vault_auth_backend" "azure_oidc" {
  provider = vault.root
  path = "oidc"
}

resource "vault_identity_entity" "main" {
  provider = vault.root
  name      = var.username
  metadata  = {
    department = local.department
  }
}

resource "vault_identity_entity_alias" "main" {
  provider = vault.root
  name            = local.email
  mount_accessor  = data.vault_auth_backend.azure_oidc.accessor
  canonical_id    = vault_identity_entity.main.id
}

resource "vault_identity_group" "main" {
  provider = vault.root
  name     = var.username
  type     = "internal"
  member_entity_ids = [vault_identity_entity.main.id]

  metadata = {
    version = "identity_group_link_to_namespace"
  }
}


resource "vault_identity_group" "remote_identity_group" {
  provider = vault.eng
  name     = var.username
  type     = "internal"
  member_group_ids = [vault_identity_group.main.id]

  metadata = {
    version = "remote_identity_group"
  }
}