# Olson Packaging — Azure Landing Zone Baseline Deployment

This deployment provisions a minimal, repeatable Azure landing zone baseline for **Olson Packaging** using Bicep. It is designed for MSP operations and audit requirements by creating a consistent foundation for identity access, networking topology, and governance guardrails.

## What this deploys

### 1) Resource Organization
- Creates a dedicated networking resource group:
  - `netRgName` (example: `rg-olson-platform-net-prod`)

### 2) Networking (Hub/Spoke)
- Deploys hub and spoke VNets into the networking resource group:
  - Hub VNet: `hubVnetName` + `hubAddressPrefixes`
  - Spoke VNet: `spokeVnetName` + `spokeAddressPrefixes`
- Creates subnets:
  - Hub: `AzureFirewallSubnet`, `GatewaySubnet`, shared services subnet
  - Spoke: workload subnet
- Creates VNet peering:
  - Hub → Spoke
  - Spoke → Hub

### 3) Identity (RBAC via Microsoft Entra ID)
- Assigns an Azure RBAC role (Reader/Contributor) to an Entra ID principal (typically a security group):
  - `rbacPrincipalId` (Object ID)
  - `rbacRoleName` (Reader or Contributor)
- Scope: subscription (baseline access pattern)

### 4) Governance
- Azure Policy Assignment: **Allowed Locations**
  - Restricts resource deployments to approved Azure regions
  - Built-in policy definition:
    - `/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c`
- Management Lock: **CanNotDelete**
  - Applied to the landing zone networking resource group
  - Prevents accidental deletion of baseline infrastructure

## Folder contents

- `main.bicep`  
  Subscription-scope orchestration template. Creates RG, deploys modules, and outputs resource IDs.
- `parameters.json`  
  Olson Packaging customer-specific configuration (names, CIDRs, RBAC principal, allowed locations).

## Modules used

### Networking module
Path:
- `modules/networking/networking.bicep`

Purpose:
- Deploy hub & spoke VNets, subnets, and peering at resource group scope.

Key inputs:
- `location`, `tags`
- `hubVnetName`, `hubAddressPrefixes`
- `spokeVnetName`, `spokeAddressPrefixes`
- `firewallSubnetPrefix`, `gatewaySubnetPrefix`, `hubSharedSubnetPrefix`, `workloadSubnetPrefix`

Outputs:
- `hubVnetId`
- `spokeVnetId`

### Identity module (RBAC)
Path:
- `modules/identity/rbac.bicep`

Purpose:
- Assigns a role at subscription scope to an Entra principal ID.

Key inputs:
- `principalId`
- `roleName`

Outputs:
- `roleAssigned`
- `principalAssigned`

### Governance module (Policy Assignments)
Path:
- `modules/governance/policy-assignments.bicep`

Purpose:
- Creates a subscription-scope Azure Policy assignment for Allowed Locations (baseline governance guardrail).

Key inputs:
- `assignmentLocation` (metadata location)
- `namePrefix`
- `allowedLocationsPolicyDefinitionId`
- `allowedLocations`

Outputs:
- `allowedLocationsAssignmentName` (or similar output name based on module implementation)

### Governance module (Delete Lock)
Path:
- `modules/governance/delete-lock.bicep`

Purpose:
- Applies a CanNotDelete management lock to the baseline resource group.

Key inputs:
- `rgName`
- `lockName`

Outputs:
- `lockId`

## Parameters (Olson Packaging)

All customer-specific values are stored in `parameters.json`. This is what makes the deployment repeatable across customers without changing code.

Minimum required parameters (examples):
- `customerName`, `environment`, `location`, `costCenter`, `owner`
- `netRgName`
- `hubVnetName`, `hubAddressPrefixes`
- `spokeVnetName`, `spokeAddressPrefixes`
- subnet prefixes: `firewallSubnetPrefix`, `gatewaySubnetPrefix`, `hubSharedSubnetPrefix`, `workloadSubnetPrefix`
- RBAC: `rbacPrincipalId`, `rbacRoleName`
- Governance:
  - `govNamePrefix`
  - `allowedLocations`
  - `allowedLocationsPolicyDefinitionId`
  - `enableDeleteLock`

## Prerequisites

- Azure CLI installed: `az --version`
- Bicep available: `az bicep version`
- Logged into the correct tenant/subscription:
  - `az login`
  - `az account set --subscription <OLSON_SUBSCRIPTION_ID>`

Permissions required:
- To deploy resources: Contributor (or higher)
- To assign roles: Owner or User Access Administrator (or higher)
- To assign policy: Policy Contributor (or higher) OR Owner
- To create locks: Owner (or permissions to manage locks)

## Deploy (Olson Packaging)

Run from repo root:

1) Validate:
```powershell
az deployment sub validate --location eastus `
  --template-file deployments/olson/main.bicep `
  --parameters @deployments/olson/parameters.json
