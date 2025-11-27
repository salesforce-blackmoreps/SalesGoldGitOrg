@isTest
public class RollupHoursOnTTDetails_Test {
    
    @testSetup
    static void setupTestData() {
        // Create sample Projects and Tasks
        dftlytime__dftly_Timesheet_Project__c project = new dftlytime__dftly_Timesheet_Project__c(
            Name = 'Test Project'
        );
        insert project;

        dftlytime__dftly_Timesheet_Task__c task = new dftlytime__dftly_Timesheet_Task__c(
            Name = 'Test Task'
        );
        insert task;
        
        // Create sample Timesheet Details (TT Detail records)
        dftlytime__dftly_Timesheet_Detail__c ttDetail1 = new dftlytime__dftly_Timesheet_Detail__c(
            dftlytime__dftlyTimesheetProject__c = project.Id,
            dftlytime__dftlyTimesheetTask__c = task.Id,
            dftlytime__Start_Timestamp__c = DateTime.now().addHours(-5), // 5 hours ago
            dftlytime__End_Timestamp__c = DateTime.now(), // Current time
            dftlytime__TimeApproval_Status__c = 'Approved'
        );
        
        dftlytime__dftly_Timesheet_Detail__c ttDetail2 = new dftlytime__dftly_Timesheet_Detail__c(
            dftlytime__dftlyTimesheetProject__c = project.Id,
            dftlytime__dftlyTimesheetTask__c = task.Id,
            dftlytime__Start_Timestamp__c = DateTime.now().addDays(-1).addHours(-3), // Yesterday, 3 hours ago
            dftlytime__End_Timestamp__c = DateTime.now().addDays(-1), // Yesterday
            dftlytime__TimeApproval_Status__c = 'Pending Approval'
        );
        
        insert new List<dftlytime__dftly_Timesheet_Detail__c>{ttDetail1, ttDetail2};
    }

    @isTest
    static void testRollupOnInsert() {
        Test.startTest();
        
        // Retrieve test data created during test setup
        dftlytime__dftly_Timesheet_Project__c project = [SELECT Id, dftlytime__Hours_Worked__c, dftlytime__Approved_Hours__c FROM dftlytime__dftly_Timesheet_Project__c LIMIT 1];
        dftlytime__dftly_Timesheet_Task__c task = [SELECT Id, dftlytime__Hours_Worked__c, dftlytime__Approved_Hours_Logged__c FROM dftlytime__dftly_Timesheet_Task__c LIMIT 1];

        // Create new Timesheet Detail to trigger the rollup
        dftlytime__dftly_Timesheet_Detail__c newDetail = new dftlytime__dftly_Timesheet_Detail__c(
            dftlytime__dftlyTimesheetProject__c = project.Id,
            dftlytime__dftlyTimesheetTask__c = task.Id,
            dftlytime__Start_Timestamp__c = DateTime.now().addHours(-2), // 2 hours ago
            dftlytime__End_Timestamp__c = DateTime.now(), // Current time
            dftlytime__TimeApproval_Status__c = 'Pending Approval'
        );
        insert newDetail;

        // Capture the updated project and task data after the trigger fires
        project = [SELECT dftlytime__Hours_Worked__c, dftlytime__Approved_Hours__c FROM dftlytime__dftly_Timesheet_Project__c WHERE Id = :project.Id];
        task = [SELECT dftlytime__Hours_Worked__c, dftlytime__Approved_Hours_Logged__c FROM dftlytime__dftly_Timesheet_Task__c WHERE Id = :task.Id];
        
        Test.stopTest();

        // Verify the rollup results
        // Time worked: 5 hours from ttDetail1 + 2 hours from newDetail = 7 hours total
        System.assertEquals(10, project.dftlytime__Hours_Worked__c, 'Total project hours should be 7');
        
        // Approved time worked: 5 hours from ttDetail1 + 2 hours from newDetail = 7 approved hours
        System.assertEquals( 5, project.dftlytime__Approved_Hours__c, 'Approved project hours should be 7');
        
        // Time worked on task: 5 hours from ttDetail1 + 2 hours from newDetail = 7 hours total
        System.assertEquals(10, task.dftlytime__Hours_Worked__c, 'Total task hours should be 10');
        
        // Approved time on task: 5 hours from ttDetail1 + 2 hours from newDetail = 7 approved hours
        System.assertEquals(5, task.dftlytime__Approved_Hours_Logged__c, 'Approved task hours should be 7');
    }

    @isTest
    static void testRollupOnUpdateAndDelete() {
        // Insert new Timesheet Detail
        dftlytime__dftly_Timesheet_Detail__c ttDetail = new dftlytime__dftly_Timesheet_Detail__c(
            dftlytime__dftlyTimesheetProject__c = [SELECT Id FROM dftlytime__dftly_Timesheet_Project__c LIMIT 1].Id,
            dftlytime__dftlyTimesheetTask__c = [SELECT Id FROM dftlytime__dftly_Timesheet_Task__c LIMIT 1].Id,
            dftlytime__Start_Timestamp__c = DateTime.now().addHours(-4), // 4 hours ago
            dftlytime__End_Timestamp__c = DateTime.now(), // Current time
            dftlytime__TimeApproval_Status__c = 'Pending Approval'
        );
        insert ttDetail;
        
        Test.startTest();
        
        // Update the time approval status to 'Approved'
        ttDetail.dftlytime__TimeApproval_Status__c = 'Approved';
        update ttDetail;
        
        // Delete the Timesheet Detail record
        delete ttDetail;
        
        Test.stopTest();
        
        // Re-query the project and task records after the delete
        dftlytime__dftly_Timesheet_Project__c project = [SELECT dftlytime__Hours_Worked__c, dftlytime__Approved_Hours__c FROM dftlytime__dftly_Timesheet_Project__c LIMIT 1];
        dftlytime__dftly_Timesheet_Task__c task = [SELECT dftlytime__Hours_Worked__c, dftlytime__Approved_Hours_Logged__c FROM dftlytime__dftly_Timesheet_Task__c LIMIT 1];

        // Debugging for visibility
        System.debug('Project hours after delete: ' + project.dftlytime__Hours_Worked__c);
        System.debug('Task hours after delete: ' + task.dftlytime__Hours_Worked__c);

        // Verify the rollup updates are handled on update and delete
        System.assertEquals(8, project.dftlytime__Hours_Worked__c, 'After deletion, project hours should be 8');
        System.assertEquals(5, project.dftlytime__Approved_Hours__c, 'After deletion, approved project hours should be 5');
        System.assertEquals(8, task.dftlytime__Hours_Worked__c, 'After deletion, task hours should be 8');
        System.assertEquals(5, task.dftlytime__Approved_Hours_Logged__c, 'After deletion, approved task hours should be 5');
    }
}