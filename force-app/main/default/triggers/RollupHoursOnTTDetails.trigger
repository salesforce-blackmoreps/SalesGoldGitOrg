trigger RollupHoursOnTTDetails on dftlytime__dftly_Timesheet_Detail__c (after insert, after update, after delete, after undelete) {

    // Sets to store project and task IDs
    Set<Id> setProjId = new Set<Id>();
    Set<Id> setTaskId = new Set<Id>();
    
    // Identify project and task IDs for updated TT Details records
    if(Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (dftlytime__dftly_Timesheet_Detail__c ttDetail : Trigger.new) {
            if (ttDetail.dftlytime__dftlyTimesheetProject__c != null) {
                setProjId.add(ttDetail.dftlytime__dftlyTimesheetProject__c);
            }
            if (ttDetail.dftlytime__dftlyTimesheetTask__c != null) {
                setTaskId.add(ttDetail.dftlytime__dftlyTimesheetTask__c);
            }
        }
    }

    // Capture project and task IDs for deleted TT Details records
    if(Trigger.isDelete) {
        for (dftlytime__dftly_Timesheet_Detail__c ttDetail : Trigger.old) {
            if (ttDetail.dftlytime__dftlyTimesheetProject__c != null) {
                setProjId.add(ttDetail.dftlytime__dftlyTimesheetProject__c);
            }
            if (ttDetail.dftlytime__dftlyTimesheetTask__c != null) {
                setTaskId.add(ttDetail.dftlytime__dftlyTimesheetTask__c);
            }
        }
    }

    // Query to summarize TT Detail records by Project and Task
    List<AggregateResult> aggregatedResults = [
        SELECT dftlytime__dftlyTimesheetProject__c, dftlytime__dftlyTimesheetTask__c, 
               SUM(dftlytime__Time_Worked__c) exp, dftlytime__TimeApproval_Status__c
        FROM dftlytime__dftly_Timesheet_Detail__c
        WHERE (dftlytime__dftlyTimesheetProject__c IN :setProjId 
               OR dftlytime__dftlyTimesheetTask__c IN :setTaskId) 
              AND dftlytime__Inactive__c = false 
              AND dftlytime__Time_Worked__c != null 
        WITH SECURITY_ENFORCED
        GROUP BY dftlytime__dftlyTimesheetProject__c, dftlytime__dftlyTimesheetTask__c, dftlytime__TimeApproval_Status__c
    ];

    // Create maps to store rollup values for Projects and Tasks
    Map<Id, Decimal> projAllHoursMap = new Map<Id, Decimal>();
    Map<Id, Decimal> projApprovedHoursMap = new Map<Id, Decimal>();
    Map<Id, Decimal> taskAllHoursMap = new Map<Id, Decimal>();
    Map<Id, Decimal> taskApprovedHoursMap = new Map<Id, Decimal>();

    // Process aggregated results and fill the maps
    for (AggregateResult result : aggregatedResults) {
        Id projId = (Id) result.get('dftlytime__dftlyTimesheetProject__c');
        Id taskId = (Id) result.get('dftlytime__dftlyTimesheetTask__c');
        Decimal workedHours = (Decimal) result.get('exp');
        String approvalStatus = (String) result.get('dftlytime__TimeApproval_Status__c');

        if (projId != null) {
            // Roll up total hours for project
            Decimal currentProjHours = projAllHoursMap.containsKey(projId) ? projAllHoursMap.get(projId) : 0;
            projAllHoursMap.put(projId, currentProjHours + workedHours);

            if (approvalStatus == 'Approved') {
                // Roll up approved hours for project
                Decimal currentProjApprovedHours = projApprovedHoursMap.containsKey(projId) ? projApprovedHoursMap.get(projId) : 0;
                projApprovedHoursMap.put(projId, currentProjApprovedHours + workedHours);
            }
        }

        if (taskId != null) {
            // Roll up total hours for task
            Decimal currentTaskHours = taskAllHoursMap.containsKey(taskId) ? taskAllHoursMap.get(taskId) : 0;
            taskAllHoursMap.put(taskId, currentTaskHours + workedHours);

            if (approvalStatus == 'Approved') {
                // Roll up approved hours for task
                Decimal currentTaskApprovedHours = taskApprovedHoursMap.containsKey(taskId) ? taskApprovedHoursMap.get(taskId) : 0;
                taskApprovedHoursMap.put(taskId, currentTaskApprovedHours + workedHours);
            }
        }
    }

    // Update project hours without querying
    List<dftlytime__dftly_Timesheet_Project__c> projectsToUpdate = new List<dftlytime__dftly_Timesheet_Project__c>();

    for (Id projId : projAllHoursMap.keySet()) {
        dftlytime__dftly_Timesheet_Project__c proj = new dftlytime__dftly_Timesheet_Project__c (
            Id = projId,
            dftlytime__Hours_Worked__c = projAllHoursMap.get(projId),
            dftlytime__Approved_Hours__c = projApprovedHoursMap.containsKey(projId) ? projApprovedHoursMap.get(projId) : 0
        );
        projectsToUpdate.add(proj);
    }

    // Update task hours without querying
    List<dftlytime__dftly_Timesheet_Task__c> tasksToUpdate = new List<dftlytime__dftly_Timesheet_Task__c>();

    for (Id taskId : taskAllHoursMap.keySet()) {
        dftlytime__dftly_Timesheet_Task__c task = new dftlytime__dftly_Timesheet_Task__c(
            Id = taskId,
            dftlytime__Hours_Worked__c = taskAllHoursMap.get(taskId),
            dftlytime__Approved_Hours_Logged__c = taskApprovedHoursMap.containsKey(taskId) ? taskApprovedHoursMap.get(taskId) : 0
        );
        tasksToUpdate.add(task);
    }

    // Perform the DML update
    if (!projectsToUpdate.isEmpty()) {
        update projectsToUpdate;
    }

    if (!tasksToUpdate.isEmpty()) {
        update tasksToUpdate;
    }
}