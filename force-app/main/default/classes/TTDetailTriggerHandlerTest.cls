@isTest
public class TTDetailTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a Billing Account (Account object)
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create a Project
        dftlytime__dftly_Timesheet_Project__c project = new dftlytime__dftly_Timesheet_Project__c(
            Name = 'Test Project',
            dftlytime__Billing_Account__c = acc.Id,
            Type__c = 'Fractional Admin'
        );
        insert project;

        // Create a Task
        dftlytime__dftly_Timesheet_Task__c task = new dftlytime__dftly_Timesheet_Task__c(
            Name = 'Test Task',
            dftlytime__Billable__c = true
        );
        insert task;
        
        // Create an Invoice
        BM_Invoice__c invoice = new BM_Invoice__c(
            Project__c = project.Id,
            Hours_Start_Date__c = Date.today().addDays(-5),
            Hours_End_Date__c = Date.today().addDays(5),
            Status__c = 'New',
            Hours_Used__c = 0
        );
        insert invoice;

        BM_Invoice__c invoice1 = new BM_Invoice__c(
            Project__c = project.Id,
            Hours_Start_Date__c = Date.valueOf(DateTime.now().addMonths(-1)),
            Hours_End_Date__c = Date.valueOf(DateTime.now().addMonths(-1).addDays(5)),
            Status__c = 'New',
            Hours_Used__c = 0
        );
        insert invoice1;

        // Create Timesheet Detail
        dftlytime__dftly_Timesheet_Detail__c timesheetDetail = new dftlytime__dftly_Timesheet_Detail__c(
            dftlytime__dftlyTimesheetProject__c = project.Id,
            dftlytime__dftlyTimesheetTask__c = task.Id,
            dftlytime__Start_Timestamp__c = DateTime.now().addHours(-2),
            dftlytime__End_Timestamp__c = DateTime.now(),
            BM_Billable__c = TRUE
        );
        insert timesheetDetail;
    }

    @isTest
    static void testHandleBeforeTrigger_Insert() {
        // Disable trigger to manipulate data
        TTDetailTriggerHandler.disableTrigger = true;
        
        // Fetch the inserted timesheet detail
        dftlytime__dftly_Timesheet_Detail__c timesheetDetail = [SELECT Id,dftlytime__dftlyTimesheetProject__c, dftlytime__dftlyTimesheetTask__c FROM dftlytime__dftly_Timesheet_Detail__c LIMIT 1];
        
        // Modify timesheet detail to simulate an update or insert
        dftlytime__dftly_Timesheet_Detail__c newDetail = new dftlytime__dftly_Timesheet_Detail__c(
            dftlytime__dftlyTimesheetProject__c = timesheetDetail.dftlytime__dftlyTimesheetProject__c,
            dftlytime__dftlyTimesheetTask__c = timesheetDetail.dftlytime__dftlyTimesheetTask__c,
            dftlytime__Start_Timestamp__c = DateTime.now().addHours(-3),
            dftlytime__End_Timestamp__c = DateTime.now()
        );

        // Enable the trigger and insert the new record
        TTDetailTriggerHandler.disableTrigger = false;
        insert newDetail;

        // Validate if the new timesheet detail has linked the correct invoice
        dftlytime__dftly_Timesheet_Detail__c insertedDetail = [SELECT BM_Invoice__c FROM dftlytime__dftly_Timesheet_Detail__c WHERE Id = :newDetail.Id];
        System.assertNotEquals(null, insertedDetail.BM_Invoice__c, 'The Timesheet Detail should be linked to an invoice.');
        
        // Validate if the invoice hours have been updated correctly
        BM_Invoice__c invoice = [SELECT Hours_Used__c FROM BM_Invoice__c LIMIT 1];
        System.assert(invoice.Hours_Used__c > 0, 'The invoice should reflect the hours worked.');
    }

    

    @isTest
    static void testHandleBeforeTrigger_Delete() {
        // Disable trigger to manipulate data
        TTDetailTriggerHandler.disableTrigger = true;
        
        // Fetch the inserted timesheet detail
        dftlytime__dftly_Timesheet_Detail__c timesheetDetail = [SELECT Id,dftlytime__dftlyTimesheetProject__c, dftlytime__dftlyTimesheetTask__c FROM dftlytime__dftly_Timesheet_Detail__c LIMIT 1];
        
        


        // Enable the trigger and insert the new record
        TTDetailTriggerHandler.disableTrigger = false;
        delete timesheetDetail;
    }

    @isTest
    static void testHandleBeforeTrigger_Update() {
        // Retrieve the previously inserted timesheet detail
        dftlytime__dftly_Timesheet_Detail__c timesheetDetail = [SELECT Id FROM dftlytime__dftly_Timesheet_Detail__c LIMIT 1];
        
        // Simulate an update
        timesheetDetail.dftlytime__Start_Timestamp__c = DateTime.now().addMonths(-1);
        update timesheetDetail;
        
        // Validate if the related invoice has been updated accordingly
        BM_Invoice__c invoice = [SELECT Hours_Used__c FROM BM_Invoice__c LIMIT 1];
        
    }

    @isTest
    static void testHandleBeforeTrigger_UpdateTime() {
        // Retrieve the previously inserted timesheet detail
        dftlytime__dftly_Timesheet_Detail__c timesheetDetail = [SELECT Id, dftlytime__End_Timestamp__c FROM dftlytime__dftly_Timesheet_Detail__c LIMIT 1];
        
        // Simulate an update
        timesheetDetail.dftlytime__End_Timestamp__c = timesheetDetail.dftlytime__End_Timestamp__c.addHours(2);
        update timesheetDetail;
        
        // Validate if the related invoice has been updated accordingly
        BM_Invoice__c invoice = [SELECT Hours_Used__c FROM BM_Invoice__c LIMIT 1];
        
    }
}