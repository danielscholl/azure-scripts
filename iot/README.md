# Helpful Azure CLI Snippets

### General Items


Run in Terminal 1

```bash
ResourceGroup="IoTtest"
Location="eastus"
Hub="cli-hub"
Tier="F1"
Device="DirectDevice"

# Create a hub
az group create --resource-group $ResourceGroup --location $Location
az iot hub create --resource-group $ResourceGroup --name $Hub --sku $Tier --location $Location

# Create a Device
az iot hub device-identity create --hub-name $Hub --device-id $Device

# Monitor Hub for Device Event
az iot hub monitor-events --hub-name $Hub --device-id $Device

```

Run in Terminal 2

```bash
ResourceGroup="IoTtest"
Location="eastus"
Hub="cli-hub"
Tier="F1"
Device="DirectDevice"

# Send a Single Device Message
az iot device send-d2c-message --hub-name $Hub --device-id $Device --data "Hello World"

# Send messages from the Device Simulator
az iot device simulate --hub-name $Hub --device-id $Device --data "Hello World"
```