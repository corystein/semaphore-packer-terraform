# Terraform Scripts for Private Terraform Enterprise

This repository contains terraform scripts

## Deploy Terraform

Use the below command to execute the deployment

```powershell
./deploy.ps1 -WorkingDirectory "./" -ProviderTfVarsFile "./azure-spn.tfvars" -TfVarsFile "./terraform-local.tfvars"
```

## Work Items Punch List

- Update backend.tf with unique state file name - Done
- Network vnet and subnet data resource (modules/network) - Done
- Azure Storage account (modules/storage)
- Key Vault (modules/keyvault)
- PostgreSQL (modules/postgresq)
- PES public IP, nic and virtual machine (modules/pes) - In Progress
- Resize VM disk
- Encrypt VM OS disk
- Fix install script harded code paths use local files /install
- Load Balancer
- Traffic Manager
- Standby VM
- Obtain static IP's for Stage and Prod VM's
- Open firewall rules for Stage and Prod (80/443/8800/22)
- Need new DNS for both Stage and Prod
- Need new certificates for both Stage and Prod
- Need subscription info for stage and prod
- Need to get and verify SPN
- Update terraform main outputs.tf to return required values (VM fqdn, IP...)
- Resource naming pattern e.g., (PZI-XXXX-XX-XX-XXX)

## Links

[Original Source](https://github.pwc.com/PWC-Terraform-Modules/Templates/tree/master/terraform-azure-tfe)
