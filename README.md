[bicep exercise](https://learn.microsoft.com/en-us/training/modules/build-first-bicep-template/4-exercise-define-resources-bicep-template?pivots=cli)

``` bash
az group create --name <ResourceGroupName> --location <Location>
```

az group create --name vialekhnBicep --location westus2

``` bash
az configure --defaults group=[sandbox resource group name]
```

az configure --defaults group=vialekhnBicep

az deployment group create --template-file main.bicep --parameters main.parameters.dev.json 
az deployment group create --template-file main.event.subscriptions.bicep --parameters main.parameters.dev.json 

https://learn.microsoft.com/en-us/azure/event-grid/blob-event-quickstart-bicep?tabs=CLI

https://learn.microsoft.com/en-us/training/modules/intro-azure-functions/1-introduction?ns-enrollment-type=learningpath&ns-enrollment-id=learn.create-serverless-applications

curl -X POST -H "Content-Type: application/json" -d '[{'test':'test2'}]' https://5d82-50-47-225-220.ngrok-free.app/runtime/webhooks/EventGrid?functionName=EventGridTrigger



steps to follow:
- deploy out bicep templates
- update connection strings
- connect azure function with event grid


## Conda

`conda env update --file environment.yml  --prune`
`conda activate my_jupyterlab_env`
`python -m ipykernel install --user --name my_jupyterlab_env --display-name "Conda (my_jupyterlab_env)"`
