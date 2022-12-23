# az-afm-avnm-demo

Simple demo to showcase the Azure Firewall Manager and the Azure Virtual Network Manager

# Deploy Azure Firewall Manager

## CLI

### Create Resource Group

```
az group create --name afm-demo-rg --location westeurope
```

### Deploy

```
az deployment group create --resource-group afm-demo-rg --template-file main.bicep --parameterfile afm-demo-parameters.json
```
