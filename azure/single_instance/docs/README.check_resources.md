tim@Timothys-MacBook-Air terraform % ./azure/scripts/check_resources.sh 
Usage: ./azure/scripts/check_resources.sh dev|prod
tim@Timothys-MacBook-Air terraform % ./azure/scripts/check_resources.sh dev
== azure/tfstate dev (subscription bluedragon-sre) ==

-- Providers --
  PASS  Microsoft.Storage: Registered
  PASS  Microsoft.KeyVault: Registered
  PASS  Microsoft.ManagedIdentity: Registered
  PASS  Microsoft.EventGrid: Registered
  PASS  Microsoft.Insights: Registered

-- Bootstrap (bluedragon-tfstate-dev-rg) --
  PASS  Resource group: Succeeded
  PASS  State account: Succeeded
  PASS  State shared keys off: false
  PASS  State public blob access off: false
  PASS  State TLS: TLS1_2
  PASS  State versioning: true
  PASS  State tfstate container: tfstate
  PASS  State lifecycle rule: old-versions
  PASS  State access logs setting: state-access-logs
  PASS  State blob data role for you: Storage Blob Data Contributor
  PASS  State encryption: Microsoft.Storage
  PASS  Logs account: Succeeded
  PASS  Budget (subscription-wide): 25.0

-- Environments (bluedragon-tfstate-dev-a2oowcjc-rg) --
  PASS  State blob in bootstrap account: 2026-10-20T19:42:14+00:00
  PASS  Resource group: Succeeded
  PASS  Key Vault purge protection: true
  PASS  Key Vault RBAC: true
  PASS  Key state-key enabled: true
  PASS  Key rotation policy: P90D
  PASS  Storage identity: 8c461010-070c-42e4-b6b2-b9f76f155e9a
  PASS  Suffixed state account: Succeeded
  PASS  Suffixed state shared keys off: false
  PASS  Suffixed state public blob access off: false
  PASS  Suffixed state TLS: TLS1_2
  PASS  Suffixed state versioning: true
  PASS  Suffixed state tfstate container: tfstate
  PASS  Suffixed state lifecycle rule: old-versions
  PASS  Suffixed state access logs setting: state-access-logs
  PASS  Suffixed state blob data role for you: Storage Blob Data Contributor
  PASS  Suffixed state CMK source: Microsoft.Keyvault
  PASS  Suffixed state CMK vault: https://bdtfkvdeva2oowcjc.vault.azure.net
  PASS  Suffixed logs account: Succeeded
  PASS  Event Grid system topic: Succeeded

== Summary: 38 passed, 0 failed ==
All expected resources present and configured.
tim@Timothys-MacBook-Air terraform % 

tim@Timothys-MacBook-Air terraform % ./azure/scripts/check_resources.sh 
Usage: ./azure/scripts/check_resources.sh dev|prod
tim@Timothys-MacBook-Air terraform % ./azure/scripts/check_resources.sh dev
== azure/tfstate dev (subscription bluedragon-sre) ==

-- Providers --
  PASS  Microsoft.Storage: Registered
  PASS  Microsoft.KeyVault: Registered
  PASS  Microsoft.ManagedIdentity: Registered
  PASS  Microsoft.EventGrid: Registered
  PASS  Microsoft.Insights: Registered

-- Bootstrap (bluedragon-tfstate-dev-rg) --
  PASS  Resource group: Succeeded
  PASS  State account: Succeeded
  PASS  State shared keys off: false
  PASS  State public blob access off: false
  PASS  State TLS: TLS1_2
  PASS  State versioning: true
  PASS  State tfstate container: tfstate
  PASS  State lifecycle rule: old-versions
  PASS  State access logs setting: state-access-logs
  PASS  State blob data role for you: Storage Blob Data Contributor
  PASS  State encryption: Microsoft.Storage
  PASS  Logs account: Succeeded
  PASS  Budget (subscription-wide): 25.0

-- Environments (bluedragon-tfstate-dev-a2oowcjc-rg) --
  PASS  State blob in bootstrap account: 2026-10-20T19:42:14+00:00
  PASS  Resource group: Succeeded
  PASS  Key Vault purge protection: true
  PASS  Key Vault RBAC: true
  PASS  Key state-key enabled: true
  PASS  Key rotation policy: P90D
  PASS  Storage identity: 8c461010-070c-42e4-b6b2-b9f76f155e9a
  PASS  Suffixed state account: Succeeded
  PASS  Suffixed state shared keys off: false
  PASS  Suffixed state public blob access off: false
  PASS  Suffixed state TLS: TLS1_2
  PASS  Suffixed state versioning: true
  PASS  Suffixed state tfstate container: tfstate
  PASS  Suffixed state lifecycle rule: old-versions
  PASS  Suffixed state access logs setting: state-access-logs
  PASS  Suffixed state blob data role for you: Storage Blob Data Contributor
  PASS  Suffixed state CMK source: Microsoft.Keyvault
  PASS  Suffixed state CMK vault: https://bdtfkvdeva2oowcjc.vault.azure.net
  PASS  Suffixed logs account: Succeeded
  PASS  Event Grid system topic: Succeeded

== Summary: 38 passed, 0 failed ==
All expected resources present and configured.
tim@Timothys-MacBook-Air terraform % 

tim@Timothys-MacBook-Air terraform % ./azure/scripts/check_resources.sh dev
== azure/tfstate dev (subscription bluedragon-sre) ==

-- Providers --
  PASS  Microsoft.Storage: Registered
  PASS  Microsoft.KeyVault: Registered
  PASS  Microsoft.ManagedIdentity: Registered
  PASS  Microsoft.EventGrid: Registered
  PASS  Microsoft.Insights: Registered

-- Bootstrap (bluedragon-tfstate-dev-rg) --
  PASS  Resource group: Succeeded
  PASS  State account: Succeeded
  PASS  State shared keys off: false
  PASS  State public blob access off: false
  PASS  State TLS: TLS1_2
  PASS  State versioning: true
  PASS  State tfstate container: tfstate
  PASS  State lifecycle rule: old-versions
  PASS  State access logs setting: state-access-logs
  PASS  State blob data role for you: Storage Blob Data Contributor
  PASS  State encryption: Microsoft.Storage
  PASS  Logs account: Succeeded
  PASS  Budget (subscription-wide): 25.0

-- Environments (bluedragon-tfstate-dev-a2oowcjc-rg) --
  PASS  State blob in bootstrap account: 2026-10-20T19:42:14+00:00
  PASS  Resource group: Succeeded
  PASS  Key Vault purge protection: true
  PASS  Key Vault RBAC: true
  PASS  Key state-key enabled: true
  PASS  Key rotation policy: P90D
  PASS  Storage identity: 8c461010-070c-42e4-b6b2-b9f76f155e9a
  PASS  Suffixed state account: Succeeded
  PASS  Suffixed state shared keys off: false
  PASS  Suffixed state public blob access off: false
  PASS  Suffixed state TLS: TLS1_2
  PASS  Suffixed state versioning: true
  PASS  Suffixed state tfstate container: tfstate
  PASS  Suffixed state lifecycle rule: old-versions
  PASS  Suffixed state access logs setting: state-access-logs
  PASS  Suffixed state blob data role for you: Storage Blob Data Contributor
  PASS  Suffixed state CMK source: Microsoft.Keyvault
  PASS  Suffixed state CMK vault: https://bdtfkvdeva2oowcjc.vault.azure.net
  PASS  Suffixed logs account: Succeeded
  PASS  Event Grid system topic: Succeeded

== Summary: 38 passed, 0 failed ==
All expected resources present and configured.
tim@Timothys-MacBook-Air terraform % 

