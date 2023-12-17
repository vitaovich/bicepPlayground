[bicep exercise](https://learn.microsoft.com/en-us/training/modules/build-first-bicep-template/4-exercise-define-resources-bicep-template?pivots=cli)

``` bash
az group create --name <ResourceGroupName> --location <Location>
```

az group create --name vialekhnBicep --location westus2

``` bash
az configure --defaults group=[sandbox resource group name]
```

az configure --defaults group=vialekhnBicep

az deployment group create --template-file main.bicep --parameters myObjId=22a14f43-816f-4fc8-8b17-08b3769ce9de


https://learn.microsoft.com/en-us/azure/event-grid/blob-event-quickstart-bicep?tabs=CLI

https://learn.microsoft.com/en-us/training/modules/intro-azure-functions/1-introduction?ns-enrollment-type=learningpath&ns-enrollment-id=learn.create-serverless-applications

curl -X POST -H "Content-Type: application/json" -d '[{'test':'test2'}]' https://5d82-50-47-225-220.ngrok-free.app/runtime/webhooks/EventGrid?functionName=EventGridTrigger
