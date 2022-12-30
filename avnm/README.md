# az-avnm-demo

Simple demo to showcase the Azure Virtual Network Manager

# Preparation for Azure Virtual Network Manager

Source: [Microsoft Learn](https://learn.microsoft.com/en-us/azure/virtual-network-manager/tutorial-create-secured-hub-and-spoke)

## CLI

### Create Resource Group

```
az group create --name avnm-demo-rg --location westeurope
```

### Deploy

```
az deployment group create --resource-group avmm-demo-rg --template-file avnm-demo.bicep --parameterfile avmm-demo-parameters.json
```
