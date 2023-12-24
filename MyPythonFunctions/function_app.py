import azure.functions as func
import logging
import json
import uuid
from datetime import datetime

app = func.FunctionApp()

@app.function_name(name="myBlobEventToCosmosTrigger")
@app.event_grid_trigger(arg_name="event")
@app.cosmos_db_output(arg_name="documents", 
                      database_name="Models",
                      container_name="processed",
                      connection="my_cosmos")
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
                       connection="my_cosmos",
                       lease_container_name="leases", 
                       create_lease_collection_if_not_exists="true"
                       )
@app.blob_output(arg_name="outputblob",
                path="modified-vikpwnywivhg2/{rand-guid}.json",
                connection="my_storage")
def test_function(documents: func.DocumentList, outputblob: func.Out[str]) -> str:
    if documents:
        logging.info('Document id: %s', documents[0]['id'])
        firstDoc = documents[0]
        myDocument = {
            'id': firstDoc['id'],
            'name':  firstDoc['name'],
            'createdOn': firstDoc['createdOn']
        }
        outputblob.set(json.dumps(myDocument))
    else:
        logging.info('No documents')

@app.route(route="http_trigger_to_cosmos", auth_level=func.AuthLevel.ANONYMOUS)
@app.cosmos_db_output(arg_name="documents", 
                      database_name="Models",
                      container_name="upload",
                      connection="my_cosmos")
def http_trigger_to_cosmos(req: func.HttpRequest, documents: func.Out[func.Document]) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    name = req.params.get('name')
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            name = req_body.get('name')

    if name:
        new_id = uuid.uuid4()
        new_name = {
            'id': str(new_id),
            'name': str(name),
            'createdOn': str(datetime.utcnow())
        }
        print('Writing to database',new_name)
        documents.set(func.Document.from_json(json.dumps(new_name)))
        return func.HttpResponse(f"Hello, {name}. This HTTP triggered function executed successfully.")
    else:
        return func.HttpResponse(
             "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.",
             status_code=200
        )