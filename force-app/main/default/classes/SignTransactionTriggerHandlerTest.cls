@isTest
private class SignTransactionTriggerHandlerTest {


    @isTest
    static void testHandleAfterTrigger_Update() {

        List<hic_signeasy__Transaction__c> updateSignTransactions = new List<hic_signeasy__Transaction__c>();

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Type = 'Bucket of Hours',
            Amount = 10000,
            Renewal_Opportunity__c = 'No',
            contract_start_date__c = Date.today()
        );
        insert opp;

        // Create Product
        Product2 product = new Product2(Name = 'Test Product', Family = 'Services');
        insert product;

        // Create PricebookEntry
        // Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = product.Id,
            UnitPrice = 500,
            IsActive = true
        );
        insert pbe;

        // Create OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 5,
            UnitPrice = 500,
            PricebookEntryId = pbe.Id,
            Invoice_Date__c = Date.today()
        );
        insert oli;

        // Create a Project
        dftlytime__dftly_Timesheet_Project__c project = new dftlytime__dftly_Timesheet_Project__c(
            Name = 'Test Project',
            dftlytime__Billing_Account__c = acc.Id,
            dftlytime__Start_Date__c = Date.today(),
            dftlytime__Available_Budget__c = 5000
        );
        insert project;

        // Update Opportunity with Project ID
        opp.Project__c = project.Id;
        update opp;

        // Create Transaction record
        hic_signeasy__Transaction__c transRecord = new hic_signeasy__Transaction__c(
            hic_signeasy__Opportunity__c = opp.Id,
            hic_signeasy__Status__c = 'SENT'
        );
        insert transRecord;

        updateSignTransactions.add(transRecord);


        Account acc2 = new Account(Name = 'Test Account 2');
        insert acc2;

        // Create Opportunity
        Opportunity opp2 = new Opportunity(
            Name = 'Project',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc2.Id,
            Type = 'Project',
            Amount = 10000,
            Renewal_Opportunity__c = 'No',
            contract_start_date__c = Date.today()
        );
        insert opp2;

        // dftlytime__dftly_Timesheet_Project__c project12 = new dftlytime__dftly_Timesheet_Project__c(
        //     Name = 'Test Project',
        //     dftlytime__Billing_Account__c = acc.Id,
        //     dftlytime__Start_Date__c = Date.today(),
        //     dftlytime__Available_Budget__c = 5000
        // );
        // insert project12;

        // // Update Opportunity with Project ID
        // opp2.Project__c = project12.Id;
        // update opp2;

        // Create Product
        Product2 product2 = new Product2(Name = 'Test Product 2', Family = 'Services', IsActive = TRUE);
        insert product2;

        // Create PricebookEntry
        // Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1];
        Id pricebookId2 = Test.getStandardPricebookId();
        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = pricebookId2,
            Product2Id = product2.Id,
            UnitPrice = 500,
            IsActive = true
        );
        insert pbe2;

        // Create OpportunityLineItem
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = opp2.Id,
            Quantity = 5,
            UnitPrice = 500,
            PricebookEntryId = pbe2.Id,
            Invoice_Date__c = Date.today()
        );
        insert oli2;

        // Create a Project
        // dftlytime__dftly_Timesheet_Project__c project = new dftlytime__dftly_Timesheet_Project__c(
        //     Name = 'Test Project',
        //     dftlytime__Billing_Account__c = acc.Id,
        //     dftlytime__Start_Date__c = Date.today(),
        //     dftlytime__Available_Budget__c = 5000
        // );
        // insert project;

        // // Update Opportunity with Project ID
        // opp.Project__c = project.Id;
        // update opp;

        // Payment_Schedule__c ps = new Payment_Schedule__c(
        //     Opportunity__c = opp.Id,
        //     Amount__c = 1000,
        //     Invoice_Date__c = Date.today(),
        //     Product__c = product.Id
        // );
        // insert ps;

        // Create Transaction record
        hic_signeasy__Transaction__c transRecord2 = new hic_signeasy__Transaction__c(
            hic_signeasy__Opportunity__c = opp2.Id,
            hic_signeasy__Status__c = 'SENT'
        );

        insert transRecord2;

        updateSignTransactions.add(transRecord2);







        for(hic_signeasy__Transaction__c var : updateSignTransactions )
        {
            var.hic_signeasy__Status__c = 'COMPLETE';
        }
        
       
        // Update transaction to simulate completion
        //transRecord.hic_signeasy__Status__c = 'COMPLETE';
        Test.startTest();
        
        update updateSignTransactions;
        
        Test.stopTest();
        

        // // Verify Opportunity changes
        // Opportunity updatedOpp = [SELECT StageName, CloseDate, Project__c FROM Opportunity WHERE Id = :transRecord.hic_signeasy__Opportunity__c];
        // System.assertEquals('Closed Won', updatedOpp.StageName, 'The Opportunity stage should be Closed Won.');
        // System.assertEquals(Date.today(), updatedOpp.CloseDate, 'The Opportunity Close Date should be today.');
        // System.assertNotEquals(null, updatedOpp.Project__c, 'Project should be linked to the Opportunity.');

        // // Verify that a new Project was created for Bucket of Hours
        // dftlytime__dftly_Timesheet_Project__c project1 = [SELECT Id, Name, dftlytime__Total_hours__c FROM dftlytime__dftly_Timesheet_Project__c WHERE Id = :updatedOpp.Project__c LIMIT 1];
        // System.assertNotEquals(null, project1.Id, 'A new project should be created for Bucket of Hours.');
    }

    @isTest
    static void testHandleAfterTrigger_OnDemand() {
        // Fetch the transaction
        Account acc3 = new Account(Name = 'Test Account 2');
        insert acc3;
    

        // Create Opportunity
        Opportunity opp3 = new Opportunity(
            Name = 'Test Opportunity3',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc3.Id,
            Type = 'On-Demand',
            Amount = 10000,
            
            contract_start_date__c = Date.today()
        );
        insert opp3;

        hic_signeasy__Transaction__c transRecord3 = new hic_signeasy__Transaction__c(
            hic_signeasy__Opportunity__c = opp3.Id,
            hic_signeasy__Status__c = 'SENT'
        );

        insert transRecord3;

        transRecord3.hic_signeasy__Status__c = 'COMPLETE';

        Test.startTest();
        update transRecord3;
        Test.stopTest();

    }

   

    @isTest
    static void testHandleAfterTrigger_FractionalAdmin() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;


        dftlytime__dftly_Timesheet_Project__c project = new dftlytime__dftly_Timesheet_Project__c(
            Name = 'Test Project',
            dftlytime__Billing_Account__c = acc.Id,
            dftlytime__Start_Date__c = Date.today(),
            dftlytime__Available_Budget__c = 5000
        );
        insert project;




        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Type = 'Fractional Admin',
            Amount = 10000,
            Renewal_Opportunity__c = 'Yes',
            contract_start_date__c = Date.today(),
            Billing_Duration__c = 'Monthly',
            Project__c = project.Id
        );
        insert opp;

        // Create Product
        Product2 product = new Product2(Name = 'Test Product', Family = 'Services');
        insert product;

        // Create PricebookEntry
        // Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = product.Id,
            UnitPrice = 500,
            IsActive = true
        );
        insert pbe;

        // Create OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 5,
            UnitPrice = 500,
            PricebookEntryId = pbe.Id,
            Invoice_Date__c = Date.today()
        );
        insert oli;

        // Create a Project
        

        // Update Opportunity with Project ID
       

        // Create Transaction record
        hic_signeasy__Transaction__c transRecord = new hic_signeasy__Transaction__c(
            hic_signeasy__Opportunity__c = opp.Id,
            hic_signeasy__Status__c = 'SENT'
        );
        insert transRecord;




        Account acc1 = new Account(Name = 'Test Account1');
        insert acc1;

        // Create Opportunity
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity1',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc1.Id,
            Type = 'Fractional Admin',
            Amount = 10000,
            Renewal_Opportunity__c = 'No',
            contract_start_date__c = Date.today(),
            Billing_Duration__c = 'Monthly'
        );
        insert opp1;

        // Create Product
        Product2 product1 = new Product2(Name = 'Test Product1', Family = 'Services');
        insert product1;

        // Create PricebookEntry
        // Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1];
        Id pricebookId1 = Test.getStandardPricebookId();
        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = pricebookId1,
            Product2Id = product1.Id,
            UnitPrice = 500,
            IsActive = true
        );
        insert pbe1;

        // Create OpportunityLineItem
        OpportunityLineItem oli1 = new OpportunityLineItem(
            OpportunityId = opp1.Id,
            Quantity = 5,
            UnitPrice = 500,
            PricebookEntryId = pbe1.Id,
            Invoice_Date__c = Date.today()
        );
        insert oli1;

       

        // Create Transaction record
        hic_signeasy__Transaction__c transRecord1 = new hic_signeasy__Transaction__c(
            hic_signeasy__Opportunity__c = opp1.Id,
            hic_signeasy__Status__c = 'SENT'
        );
        insert transRecord1;

        

        transRecord.hic_signeasy__Status__c = 'COMPLETE';
        

        transRecord1.hic_signeasy__Status__c = 'COMPLETE';

        Test.startTest();
        update transRecord;
        update transRecord1;
        Test.stopTest();

    }


    @isTest
    static void ContractRevision() {

        Account acc = new Account(Name = 'Test Account');
        insert acc;


        dftlytime__dftly_Timesheet_Project__c project = new dftlytime__dftly_Timesheet_Project__c(
            Name = 'Test Project',
            dftlytime__Billing_Account__c = acc.Id,
            dftlytime__Start_Date__c = Date.today(),
            dftlytime__Available_Budget__c = 5000
        );
        insert project;




        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Type = 'Fractional Admin',
            Amount = 10000,
            Renewal_Opportunity__c = 'Yes',
            contract_start_date__c = Date.today(),
            Billing_Duration__c = 'Monthly',
            Project__c = project.Id
        );
        insert opp;

        // Create Product
        Product2 product = new Product2(Name = 'Test Product', Family = 'Services');
        insert product;

        // Create PricebookEntry
        // Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = product.Id,
            UnitPrice = 500,
            IsActive = true
        );
        insert pbe;

        // Create OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 5,
            UnitPrice = 500,
            PricebookEntryId = pbe.Id,
            Invoice_Date__c = Date.today()
        );
        insert oli;

        // Create a Project
        

        // Update Opportunity with Project ID
       

        // Create Transaction record
        hic_signeasy__Transaction__c transRecord = new hic_signeasy__Transaction__c(
            hic_signeasy__Opportunity__c = opp.Id,
            hic_signeasy__Status__c = 'SENT'
        );
        insert transRecord;

        transRecord.hic_signeasy__Status__c = 'COMPLETE';

        
        Test.startTest();
        update transRecord;
        Test.stopTest();
    }
}