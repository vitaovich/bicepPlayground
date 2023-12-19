import azure.functions as func
import logging
import json

app = func.FunctionApp()

@app.function_name(name="myBlobEventToCosmosTrigger")
@app.event_grid_trigger(arg_name="event")
@app.cosmos_db_output(arg_name="documents", 
                      database_name="Models",
                      container_name="processed",
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

@app.function_name(name="myCosmosToBlobTrigger")
@app.cosmos_db_trigger(arg_name="documents", 
                       database_name="Models",
                       container_name="upload", 
                       connection="MyAcc_COSMOSDB",
                       lease_container_name="leases", 
                       create_lease_collection_if_not_exists="true"
                       )
@app.blob_output(arg_name="outputblob",
                path="modified-vikpwnywivhg2/test.txt",
                connection="MyOutStorage")
def test_function(documents: func.DocumentList, outputblob: func.Out[str]) -> str:
    if documents:
        logging.info('Document id: %s', documents[0]['id'])
        outputblob.set(documents[0]['id'])
    else:
        logging.info('No documents')