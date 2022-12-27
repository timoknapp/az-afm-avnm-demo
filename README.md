# az-afm-avnm-demo

Simple demo to showcase the Azure Firewall Manager and the Azure Virtual Network Manager

# Deploy Azure Firewall Manager
Source: [Microsoft Learn](https://learn.microsoft.com/en-us/azure/firewall-manager/quick-secure-virtual-hub-bicep?tabs=CLI)

## CLI

### Create Resource Group

```
az group create --name afm-demo-rg --location westeurope
```

### Deploy

```
az deployment group create --resource-group afm-demo-rg --template-file afm-demo.bicep --parameterfile afm-demo-parameters.json
```

# Deploy Azure Virtual Network Manager
Source: [Microsoft Learn](https://learn.microsoft.com/en-us/azure/virtual-network-manager/tutorial-create-secured-hub-and-spoke)
> **Warning**
> This deployment makes use of static network group members and not dynamic members over Azure Policy like in the linked tutorial.

## CLI

### Create Resource Group

```
az group create --name avnm-demo-rg --location westeurope
```

### Deploy

```
az deployment group create --resource-group avmm-demo-rg --template-file avnm-demo.bicep --parameterfile avmm-demo-parameters.json
```
