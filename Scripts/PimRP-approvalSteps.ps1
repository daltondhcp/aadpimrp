#Requires -Modules Az.Accounts,Az.Resources

# List Pending Approval Requests for subscriptions. Management groups not included at this point.
# If Event based solution is used, we will not need to iterate through all available scopes since scope will be provided as input.
$subscriptions = Get-AzSubscription

$PendingRequests = @()
# Iterate through each subscription for pending approval requests
foreach ($subscription in $subscriptions) {
    $PendingRequests += ((Invoke-AzRestMethod -Method GET -Path "/subscriptions/$($subscription.id)/providers/Microsoft.Authorization/roleAssignmentScheduleRequests?api-version=2020-10-01-preview").content | ConvertFrom-Json -Depth 100).Value.properties | Where-Object { $_.Status -eq "PendingApproval" } | ForEach-Object -Process {
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
}
$PendingRequests

foreach ($Request in $PendingRequests) {

    # # # # # # # # # # # # # # # #
    #VALIDATE MAGIC TICKET ID!!!!!!!
    #
    if ($Request.ticketId -eq '12345') {
        $foundValidTicket = $true
    }
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

    Write-Output $RequestBody

    Invoke-AzRestMethod -Method PUT -Path "$($Request.approvalStageId)?api-version=2021-01-01-preview" -Payload $RequestBody -Verbose
}
