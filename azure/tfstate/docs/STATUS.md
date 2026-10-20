# Status: Azure Terraform port

Rolling record of the Azure port. Add new entries at the top of the change
log, and update "Current state" and "Open items" when they change.

- Subscription: `bluedragon-sre` (`8d75b8ef-999c-4f70-99a9-4eb0197f3a07`),
  pay-as-you-go, created 2026-10-20
- Tenant: Default Directory (`91737469-4965-4d2f-a72d-9ba8a531a355`)
- Account: `dentaldanplateosaurus@outlook.com` (personal Microsoft account; MFA required)
- Regions: dev = `westus2`, prod = `westus`
- Terraform 1.13.2: azurerm `~> 5.10`, random `~> 3.9`, time `~> 0.14`

## Remember

- **Never use subscription `3caa5ec0-…` for this repo.** It's the az CLI
  default and holds grid-meter's Azure state (`grid-meter-app-tfstate-rg`),
  used for interviews. Don't `az account set` away from it; this repo names
  `bluedragon-sre` in every provider and backend.
- `3caa5ec0-…` was a free trial; upgraded to pay-as-you-go 2026-10-20 (renamed
  "Azure subscription 2"), so grid-meter's state isn't disabled on 2026-10-22.

## Current state (2026-10-20)

| Layer | dev (westus2) | prod (westus) |
|---|---|---|
| `tfstate/bootstrap` (local state) | **applied** 2026-10-20: `bdtfstatedev`, `bdtflogsdev`, budget; `check_resources.sh dev` 18/18 | **applied** 2026-10-20: `bdtfstateprod`, `bdtflogsprod`; 17/17 |
| `tfstate/environments` (state in bootstrap account) | **applied** 2026-10-20, suffix `a2oowcjc`: vault `bdtfkvdeva2oowcjc`, state `bdtfstatedeva2oowcjc` (CMK); `check_resources.sh dev` 38/38 | **applied** 2026-10-20, suffix `gw3jhawh`: vault `bdtfkvprodgw3jhawh`, state `bdtfstateprodgw3jhawh` (CMK); 37/37 |

## Change log

### 2026-10-20: port `tfstate` to Azure

- Created subscription `bluedragon-sre` (portal), after upgrading the free
  trial that blocked adding subscriptions.
- Added `azure/tfstate` with the same layout as aws/gcp: `bootstrap`,
  `environments`, modules `keyvault`, `messages` (Event Grid), `storage`.
  Mapping in `../README.md`.
- Added `azure/README.az.md`.
- First bootstrap applies created the resource groups and the budget, then
  failed on the storage accounts: `MissingSubscriptionRegistration` for
  `Microsoft.Storage`. azurerm 5.x registers no providers itself, even ones
  listed in `resource_providers_to_register`. Added
  `azure/scripts/register_providers.sh` (Storage, KeyVault, ManagedIdentity,
  EventGrid, Insights, Consumption), ran it, and set
  `resource_provider_registrations = "none"` in every provider block.
- Re-applied both bootstraps (7 added each). Added `azure/scripts/
  check_resources.sh` and `estimate_costs.sh` (adapted from grid-meter-app's
  Azure scripts). Cost Management doesn't report a new subscription yet
  ("doesn't have valid WebDirect/AIRS offer type"), up to 48 hours.
- Dev environments applied (17 added; Key Vault creation took 2.5 minutes).
  `check_resources.sh dev` 38/38 after fixing two script bugs: the CLI's
  rotation-policy shape is flat (`action`, `timeAfterCreate`) and the CMK
  vault URI has no trailing slash. Estimate about $0.34/month per rotating key.
- Prod environments applied (17 added); `check_resources.sh prod` 37/37.
  Re-plan of all four roots: no changes.

## Open items

- **Event Grid topics have no subscriber** (like SNS and Pub/Sub here).
- **Cost Management** not reporting the new subscription yet; re-run
  `azure/scripts/estimate_costs.sh` after 2026-10-22.

- **New subscriptions:** run `azure/scripts/register_providers.sh` before the
  first apply.
