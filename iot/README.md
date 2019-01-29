# Helpful Azure CLI Snippets

### General Items


__Creating a IoT Hub__

```bash
ResourceGroup="IoTtest" Location="eastus"
Tier="F1"
Hub="cli-hub" Device="DirectDevice"

# Create a hub
az group create --resource-group $ResourceGroup --location $Location
az iot hub create --resource-group $ResourceGroup --location $Location --name $Hub --sku $Tier 

# Create a Device
az iot hub device-identity create --hub-name $Hub --device-id $Device
```

__Sending D2C Messages__

_Monitor IoT Hub Events in Terminal Window 1_

```bash
Hub="cli-hub" Device="DirectDevice"

# Monitor Hub for Device Events
az iot hub monitor-events --hub-name $Hub --device-id $Device
```

_Send Device to Cloud Messages in Terminal Window 2_

```bash
Hub="cli-hub" Device="DirectDevice"

# Send a Single Device to Cloud Message
az iot device send-d2c-message --hub-name $Hub --device-id $Device \
    --data "Hello Hub"

# Send messages from the Device Simulator
az iot device simulate --hub-name $Hub --device-id $Device \
    --data "Hello Hub"
```

__Sending C2D Messages__

_Monitor IoT Hub Events in Terminal Window 1_

```bash
Hub="cli-hub" Device="DirectDevice"

# Monitor Device for Cloud Events
az iot device c2d-message receive --hub-name $Hub --device-id $Device -ojsonc
```


_Send Cloud to Device Messages in Terminal Window 2_

```bash
Hub="cli-hub" Device="DirectDevice"

# Send a Single Device to Cloud Message
az iot device c2d-message send --hub-name $Hub --device-id $Device \
    --data "Hello Device"
```


__Simulating a Device__

_Monitor IoT Hub Events in Terminal Window 1_

```bash
Hub="cli-hub" Device="DirectDevice"

# Monitor Hub for Device Events
az iot hub monitor-events --hub-name $Hub --device-id $Device
```


_Monitor IoT Hub Events in Terminal Window 2_

```bash
Hub="cli-hub" Device="DirectDevice"

# Send messages from the Device Simulator
az iot device simulate --hub-name $Hub --device-id $Device \
    --data "Hello from simulator" \
    --msg-count 10 \
    --msg-interval 10
```


_Send Cloud to Device Messages in Terminal Window 3_

```bash
Hub="cli-hub" Device="DirectDevice"

# Send a Single Device to Cloud Message
az iot device c2d-message send --hub-name $Hub --device-id $Device \
    --data "Hello Device"
```