#List Pending Approval Requests
$PendingRequests = ((Invoke-AzRestMethod -Method GET -Path '/subscriptions/fd23378b-9b7f-4f73-b216-4dc4d09ecde7/providers/Microsoft.Authorization/roleAssignmentScheduleRequests?api-version=2020-10-01-preview').content | ConvertFrom-Json -Depth 100).Value.properties | Where-Object { $_.Status -eq "PendingApproval" } | ForEach-Object -Process {
    $ApprovalRequest = (Invoke-AzRestMethod -Method GET -Path "$($_.approvalId)?api-version=2021-01-01-preview").Content | ConvertFrom-Json -Depth 100
    [PSCustomObject]@{
        requestor         = $_.principalId
        scope             = $_.scope
        ticketId          = $_.ticketInfo.TicketNumber
        roleDefinitionId  = $_.roleDefinitionId
        approvalId        = $ApprovalRequest.id
        approvalName      = $ApprovalRequest.name
        approvalStageId   = $ApprovalRequest.properties.stages.id
        approvalStageName = $ApprovalRequest.properties.stages.Name
        createdOn         = $_.createdOn
    }
}
$PendingRequests

foreach ($Request in $PendingRequests) {

    # # # # # # # # # # # # # # # #
    #VALIDATE MAGIC TICKET ID!!!!!!!
    #
    $foundValidTicket = $true
    #
    # # # # # # # # # # # # # # # #

    #Approve or deny request
    $RequestBody = @{
        properties = @{
            displayName   = "Autoreview"
            justification = "This is a justification"
            reviewResult  = if ($foundValidTicket) { "Approve" } else { "Deny" }
        }
    } | ConvertTo-Json

    Invoke-AzRestMethod -Method PUT -Path "$($Request.approvalStageId)?api-version=2021-01-01-preview" -Payload $RequestBody -Verbose
}
