
@description('Provide a name for the system topic.')
param systemTopicName string

@description('Provide a name for the Event Grid subscription.')
param eventSubName string

@description('Provide id for the function.')
param functionId string

@allowed([
  'AzureFunction'
])
@description('Provide a name for the Event Grid subscription.')
param endpointType string

@description('Event types to subscribe to.')
param includedEventTypes array

resource systemTopic 'Microsoft.EventGrid/systemTopics@2021-12-01' existing = {
  name:systemTopicName
}

resource eventSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2021-12-01' = {
  parent: systemTopic
  name: eventSubName
  properties: {
    destination: {
      endpointType: endpointType
      properties: {
        resourceId: functionId
      }
    }
    filter: {
      includedEventTypes: includedEventTypes
    }
  }
}
