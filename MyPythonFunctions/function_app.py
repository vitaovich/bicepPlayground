import azure.functions as func
import logging
import json

app = func.FunctionApp()

@app.function_name(name="myCosmosDbTrigger")
@app.event_grid_trigger(arg_name="event")
@app.cosmos_db_output(arg_name="documents", 
                      database_name="Models",
                      container_name="Details",
                      create_if_not_exists=True,
                      connection="MyAcc_COSMOSDB")
def EventGridTrigger(event: func.EventGridEvent, documents: func.Out[func.Document]):
    result = json.dumps({
        'id': event.id,
        'myPartitionKey': event.id,
        'data': event.get_json(),
        'topic': event.topic,
        'subject': event.subject,
        'event_type': event.event_type,
    })
    logging.info('Python EventGrid trigger processed an event: %s', result)
    documents.set(func.Document.from_json(result))
