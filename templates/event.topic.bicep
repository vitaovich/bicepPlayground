@description('Location for resources.')
param location string = resourceGroup().location

@description('Provide a source id to subscribe to.')
param sourceId string

@description('Provide a source id to subscribe to.')
param topicType string

@description('Provide a name for the system topic.')
param systemTopicName string = 'mystoragesystemtopic'

resource systemTopic 'Microsoft.EventGrid/systemTopics@2021-12-01' = {
  name: systemTopicName
  location: location
  properties: {
    source: sourceId
    topicType: topicType
  }
}

output systemTopicName string = systemTopic.name
