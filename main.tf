provider "vault" {
  alias = "root"
}

provider "vault" {
  alias     = "eng"
  namespace = "engineering"
}


locals {
  raw_data  = jsondecode(file("${path.module}/users.json"))
  usernames = local.raw_data.users[*].username
}


module "main" {
  source = "./modules/userentity"
  providers = {
    vault.root = vault.root
    vault.eng  = vault.eng
  }


  for_each  = toset(local.usernames)
  username  = each.key
  json_data = local.raw_data
  
  
  depends_on = [
    vault_namespace.finance,
    vault_namespace.engineering,
  ]
}
