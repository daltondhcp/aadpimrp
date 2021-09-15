@description('The principal to assign the role to')
param principalId string

@description('Built-in role to assign')
param BuiltInroleDefinitionId string = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

@description('A new GUID used to identify the role assignment')
param roleNameGuid string = newGuid()

resource roleNameGuid_resource 'Microsoft.Authorization/roleEligibilityScheduleRequests@2020-10-01-preview' = {
  name: roleNameGuid
  properties: {
    principalId: principalId
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/${BuiltInroleDefinitionId}'
    requestType: 'AdminAssign'
  }
}
