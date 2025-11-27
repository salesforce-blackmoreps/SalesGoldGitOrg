@IsTest
public class ProjectBatchHandlerTest {

    @TestSetup
    static void setupTestData() {
        String PricebookId = Test.getStandardPricebookId();
        
        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;
        
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = PricebookId,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true);
        insert pricebookEntry;
        
        // Create Billing Account
        Account billingAccount = new Account(Name = 'Billing Account');
        insert billingAccount;

        // Create some dftlytime__dftly_Timesheet_Project__c records
        List<dftlytime__dftly_Timesheet_Project__c> projectList = new List<dftlytime__dftly_Timesheet_Project__c>();
        for (Integer i = 0; i < 4; i++) {
            dftlytime__dftly_Timesheet_Project__c project = new dftlytime__dftly_Timesheet_Project__c(
                Name = 'Test Project ' + i,
                dftlytime__End_Date__c = Date.today().addDays(i - 2), // Some end dates before and after today
                dftlytime__Billing_Account__c = billingAccount.Id,
                dftlytime__Project_Hourly_Rate__c = 150,
                Type__c = math.mod(i, 2) == 0 ? 'Fractional Admin' : 'On-Demand',
                dftlytime__inactive__c = FALSE
            );
            projectList.add(project);
        }
        insert projectList;

        // Create a Task
        dftlytime__dftly_Timesheet_Task__c task = new dftlytime__dftly_Timesheet_Task__c(
            Name = 'Test Task',
            dftlytime__Billable__c = true,
            Resource_Type__c = product.Id
        );
        insert task;
        
        // Create Timesheet Details for the projects
        List<dftlytime__dftly_Timesheet_Detail__c> timesheetDetails = new List<dftlytime__dftly_Timesheet_Detail__c>();
        for (dftlytime__dftly_Timesheet_Project__c project : projectList) {
            dftlytime__dftly_Timesheet_Detail__c detail = new dftlytime__dftly_Timesheet_Detail__c(
                dftlytime__dftlyTimesheetProject__c = project.Id,
                dftlytime__Start_Timestamp__c = DateTime.now().addMonths(-1),
                dftlytime__dftlyTimesheetTask__c = task.Id,
                dftlytime__End_Timestamp__c = DateTime.now().addHours(7),
                BM_Billable__c = TRUE
            );
            timesheetDetails.add(detail);
        }
        insert timesheetDetails;

        BM_Invoice__c inv1 = new BM_Invoice__c(
            Account__c = billingAccount.Id, 
            Project__c = projectList[0].Id, 
            Status__c = 'New',
            Invoice_Date__c = Date.today().addMonths(-1),
            Available_Hours__c = 100,
            Hours_Used__c = 150
            
        );
        insert inv1;
        
        BM_Invoice__c inv1thisMonth = new BM_Invoice__c(
            Account__c = billingAccount.Id, 
            Project__c = projectList[0].Id, 
            Status__c = 'New',
            Invoice_Date__c = Date.today(),
            Available_Hours__c = 100,
            Hours_Used__c = 150
            
        );
        insert inv1thisMonth;

        BM_Invoice__c inv2 = new BM_Invoice__c(
            Account__c = billingAccount.Id, 
            Project__c = projectList[2].Id, 
            Status__c = 'New',
            Invoice_Date__c = Date.today(),
            Available_Hours__c = 100,
            Hours_Used__c = 150
            
        );
        insert inv2;

        BM_Invoice__c inv3 = new BM_Invoice__c(
            Account__c = billingAccount.Id, 
            Project__c = projectList[1].Id, 
            Status__c = 'New',
            Invoice_Date__c = Date.today(),
            Available_Hours__c = 100,
            Hours_Used__c = 150
            
        );
        insert inv3;

        BM_Invoice__c inv44 = new BM_Invoice__c(
            Account__c = billingAccount.Id, 
            Project__c = projectList[3].Id, 
            Status__c = 'New',
            Invoice_Date__c = Date.today(),
            Available_Hours__c = 100,
            Hours_Used__c = 150
            
        );
        insert inv44;

        dftlytime__dftly_Timesheet_Project__c project1 = new dftlytime__dftly_Timesheet_Project__c(
                Name = 'Test Project 1',
                dftlytime__Billing_Account__c = billingAccount.Id,
                dftlytime__Project_Hourly_Rate__c = 150,
                Type__c = 'Fractional Admin',
                dftlytime__inactive__c = FALSE
            );

            insert project1;

            BM_Invoice__c inv4 = new BM_Invoice__c(
            Account__c = billingAccount.Id, 
            Project__c = project1.Id, 
            Status__c = 'New',
            Invoice_Date__c = Date.today().addMonths(-1),
            Available_Hours__c = 100,
            Hours_Used__c = 150
            
        );
        insert inv4;

        Invoice_Line__c line = new Invoice_Line__c(
            Sales_Price__c = 120, 
            Quantity__c = 50, 
            Product__c = product.Id,
            Invoice__c = inv4.Id
        );

        insert line;
    }

    @IsTest
    static void testHandleMethod() {
        // Test setup data for the actual test
        List<dftlytime__dftly_Timesheet_Project__c> projectList = [Select Id, dftlytime__Billing_Account__c, dftlytime__Total_hours__c, dftlytime__Available_Budget__c, dftlytime__Project_Hourly_Rate__c,Type__c,dftlytime__End_Date__c from dftlytime__dftly_Timesheet_Project__c where dftlytime__inactive__c = FALSE];
        Project_Invoicing__mdt invPrj = [SELECT Id, Monthly_Overages_Product__c, Fractional_Admin_Reset_Day__c, Monthly_Invoice_Day__c FROM Project_Invoicing__mdt LIMIT 1];
		List<dftlytime__dftly_Timesheet_Project__c> projectList2 = [Select Id, dftlytime__Billing_Account__c, dftlytime__Total_hours__c, dftlytime__Available_Budget__c, dftlytime__Project_Hourly_Rate__c,Type__c,dftlytime__End_Date__c from dftlytime__dftly_Timesheet_Project__c where dftlytime__inactive__c = FALSE AND Type__c='On-Demand'];
        // Start Test and stop test for Governor limits
        Test.startTest();
        // Call the method to be tested
        ProjectBatch p = new ProjectBatch(); //Schedule apex class name

        String sch = '0 26 * ? * *'; //schedule interval time

        system.schedule('One Time Pro', sch, p);
        ProjectBatchHandler.handle(projectList);
        ProjectBatchHandler.handle(projectList2);
        ProjectBatchHandler.getStdPricebookId();        
        ProjectBatchHandler.getAppropriateLines([SELECT Id FROM Invoice_Line__c], invPrj);
        Test.stopTest();
    }
    
    @IsTest
    static void testgetAppropriateTTDetails() {
        // Test setup data for the actual test
        List<dftlytime__dftly_Timesheet_Detail__c> listTimeSheetDetails = [SELECT Id, BM_Invoice_Line__r.Product__c, dftlytime__Time_Worked__c, 
                                                                   dftlytime__dftlyTimesheetTask__r.Resource_Type__c, BM_Billable__c, 
                                                                   dftlytime__dftlyTimesheetTask__r.dftlytime__Billable__c, dftlytime__Month_Year__c,
                                                                   dftlytime__dftlyTimesheetProject__c FROM dftlytime__dftly_Timesheet_Detail__c];
        //public static List<dftlytime__dftly_Timesheet_Detail__c> getAppropriateTTDetails(List<dftlytime__dftly_Timesheet_Detail__c> recrods) 
        ProjectBatchHandler.getAppropriateTTDetails(listTimeSheetDetails);          
        ProjectBatchHandler.fakeMethod();
    }
}