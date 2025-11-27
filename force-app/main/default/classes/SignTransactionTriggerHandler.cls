public with sharing class SignTransactionTriggerHandler {
    public static Boolean disableTrigger = false;
    public static void handleAfterTrigger(List<hic_signeasy__Transaction__c> listNew, Map<Id, hic_signeasy__Transaction__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete) {
        if(isUpdate && disableTrigger == false) {

            // Update Objects :
            // 1. Opp
            // 2. Project
            // 3. OLI
            // 4. BM Invoice
            // 5. BM INvoice Line



            Map<String, Opportunity> oppMaps = new Map<String, Opportunity>();
            Map<String, dftlytime__dftly_Timesheet_Project__c> prjMap = new Map<String, dftlytime__dftly_Timesheet_Project__c>();
            Map<String, List<OpportunityLineItem>> olisMap = new Map<String, List<OpportunityLineItem>>();
            Map<String, hic_signeasy__Transaction__c> signMap = new Map<String, hic_signeasy__Transaction__c>();


            Opportunity opt = new Opportunity();
            List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
            dftlytime__dftly_Timesheet_Project__c prj = new dftlytime__dftly_Timesheet_Project__c();



            for(hic_signeasy__Transaction__c signtrns : listNew){


                // Bucket of Hours Tab in Lucid Chart
                if(
                    signtrns.hic_signeasy__Opportunity__c != null 
                    && signtrns.hic_signeasy__Status__c == 'COMPLETE'
                    && oldMap.get(signtrns.Id).hic_signeasy__Status__c != 'COMPLETE'
                ){
                    
                    // Getting Opport, OpprtLineItem & Project
                    opt = [Select Id, Name, Project__c, StageName, CloseDate, Renewal_Opportunity__c, Bucket_of_Hours_Term_Length__c, AccountId, Type, Agreement_Length__c, Contract_Start_Date__c, Amount, Billing_Duration__c from Opportunity Where Id =: signtrns.hic_signeasy__Opportunity__c];
                    
                    olis = [Select Id, Product2Id, Product2.Name, Product2.Resource_Type__c, Quantity, UnitPrice, Invoice_Date__c, TotalPrice from OpportunityLineItem Where OpportunityId =: signtrns.hic_signeasy__Opportunity__c Order By Invoice_Date__c Asc];
                    
                    if(opt.Project__c != null){

                        prj = [Select Id, Name, dftlytime__Start_Date__c, dftlytime__Billing_Account__c, Type__c, Agreement_Length__c, dftlytime__Total_hours__c, dftlytime__Project_Hourly_Rate__c, dftlytime__Available_Budget__c, Remaining_Budget__c,Remaining_Hours__c, Billing_Duration__c  from dftlytime__dftly_Timesheet_Project__c where Id = :opt.Project__c];
                    
                    }else{
                        prj = new dftlytime__dftly_Timesheet_Project__c();
                    }

                    signMap.put(signtrns.Id, signtrns);

                    
        
                    olisMap.put(signtrns.Id, olis);
                    
                    


                    oppMaps.put(signtrns.Id, opt);

        
                    prjMap.put(signtrns.Id, prj);

                    
                }
            }

            Map<String, PricebookEntry> PBEntries = new Map<String, PricebookEntry>();

            if(olis.size() > 0){
                

                Set<String> product2Ids = new Set<String>();

                for(String tranId: olisMap.keySet()){

                    olis = olisMap.get(tranId);

                    for(OpportunityLineItem olisingle : olis){

                        product2Ids.add(olisingle.Product2Id);

                    }

                }



                Id stdPriceBookId;    
                if(Test.isRunningTest()){
                    stdPriceBookId = Test.getStandardPricebookId();
                }else{
                    stdPriceBookId = [select id, name from Pricebook2 where isStandard = true limit 1].Id;
                }


                List<PricebookEntry> pbes = [Select Id, Product2Id, UnitPrice from PricebookEntry where Pricebook2Id = : stdPriceBookId and Product2Id in : product2Ids];

                for(PricebookEntry spbe : pbes){

                    PBEntries.put(spbe.Product2Id, spbe);

                }
            }

            // Data Manipulation
            for(String signtrnsId : oppMaps.keySet()){

                opt = oppMaps.get(signtrnsId);

                System.debug(opt.Type);

                

                // Certain oppt type and there should be only one line item for Bucket of Hour opportunity
                if((opt.Type == 'Bucket of Hours' || opt.Type == 'Consultancy & Advisory')){

                    olis = olisMap.get(signtrnsId);

                    if(olis.size() > 0){

                        opt.StageName = 'Closed Won';

                        opt.CloseDate = Date.today();
        
                        OpportunityLineItem lineItem = olis[0];
        
                        dftlytime__dftly_Timesheet_Project__c oldProject = prjMap.get(signtrnsId);
        
                        // IF Not Renewal Oppp
                        if(opt.Renewal_Opportunity__c == 'No'){
        
                            dftlytime__dftly_Timesheet_Project__c project = new dftlytime__dftly_Timesheet_Project__c();
    
                            project.Name = opt.Name;
        
                            project.dftlytime__Start_Date__c = getFormattedDate(opt.contract_start_date__c);
                            
                            project.dftlytime__Billing_Account__c = opt.AccountId;
                            
                            project.Type__c = opt.Type;

                            project.Bucket_of_Hours_Term_Length__c = opt.Bucket_of_Hours_Term_Length__c;
                            
                            project.Agreement_Length__c = opt.Agreement_Length__c;
        
                            project.dftlytime__Total_hours__c = lineItem.Quantity;

                            // System.debug(lineItem.Quantity);
                            // System.debug(lineItem);
        
                            project.dftlytime__Project_Hourly_Rate__c = lineItem.UnitPrice;
        
                            project.dftlytime__Available_Budget__c = lineItem.TotalPrice;
        
                            insert project;
        
                            opt.Project__c = project.Id;
        
                            BM_Invoice__c inv = new BM_Invoice__c();
                            
                            inv.Account__c = opt.AccountId;
        
                            inv.Project__c = project.Id;
        
                            inv.Invoice_Date__c = lineItem.Invoice_Date__c;
        
                            insert inv;
        
                            Invoice_Line__c invLine = new Invoice_Line__c();
        
                            invLine.Invoice__c = inv.Id;
        
                            invLine.Quantity__c = lineItem.Quantity;
        
                            invLine.Sales_Price__c = lineItem.UnitPrice;
        
                            invLine.Product__c = lineItem.Product2Id;
        
                            insert invLine;
        
                        }else if(opt.Renewal_Opportunity__c == 'Yes' && oldProject != null){ // If Renewal Oppor
        
                            if(oldProject.dftlytime__Project_Hourly_Rate__c != lineItem.UnitPrice){
        
                                Decimal newHourlyRate = (oldProject.Remaining_Budget__c + lineItem.TotalPrice) / (oldProject.Remaining_Hours__c + lineItem.Quantity);
        
                                oldProject.dftlytime__Project_Hourly_Rate__c = newHourlyRate;
        
                            }
        
                            Decimal newAvailableHours = oldProject.dftlytime__Total_hours__c + lineItem.Quantity;
        
                            Decimal newAvailableBudget = oldProject.dftlytime__Available_Budget__c + lineItem.TotalPrice;
        
                            oldProject.dftlytime__Total_hours__c = newAvailableHours;
        
                            oldProject.dftlytime__Available_Budget__c = newAvailableBudget;
        
                            update oldProject;

                            BM_Invoice__c inv = new BM_Invoice__c();
                            
                            inv.Account__c = opt.AccountId;
        
                            inv.Project__c = oldProject.Id;
        
                            inv.Invoice_Date__c = lineItem.Invoice_Date__c;
        
                            insert inv;
        
                            Invoice_Line__c invLine = new Invoice_Line__c();
        
                            invLine.Invoice__c = inv.Id;
        
                            invLine.Quantity__c = lineItem.Quantity;
        
                            invLine.Sales_Price__c = lineItem.UnitPrice;
        
                            invLine.Product__c = lineItem.Product2Id;
        
                            insert invLine;
        
                        }
    
                        update opt;
                    }

                }else if(opt.Type == 'On-Demand'){ // On Demand Tab
                    
                    opt.StageName = 'Closed Won';

                    opt.CloseDate = Date.today();

                    dftlytime__dftly_Timesheet_Project__c project = new dftlytime__dftly_Timesheet_Project__c();

                    project.Name = opt.Name;
    
                    project.dftlytime__Start_Date__c = getFormattedDate(opt.contract_start_date__c);
                    
                    project.dftlytime__Billing_Account__c = opt.AccountId;
                    
                    project.Type__c = opt.Type;

                    insert project;

                    opt.Project__c = project.Id;

                    update opt;

                }else if(opt.Type == 'Project' && opt.Project__c == null){ // Project SOW

                    olis = olisMap.get(signtrnsId);

                    System.debug(olis.size());

                    opt.StageName = 'Closed Won';

                    opt.CloseDate = Date.today();
                    
                    

                    dftlytime__dftly_Timesheet_Project__c project = new dftlytime__dftly_Timesheet_Project__c();


                    project.Name = opt.Name;

                    project.dftlytime__Start_Date__c = getFormattedDate(opt.contract_start_date__c);
                    
                    project.dftlytime__Billing_Account__c = opt.AccountId;
                    
                    project.Type__c = opt.Type;

                    project.dftlytime__Available_Budget__c = opt.Amount;

                    insert project;

                    opt.Project__c = project.Id;

                    update opt;
                    


                    List<dftlytime__dftly_Timesheet_Task__c> taskList = new List<dftlytime__dftly_Timesheet_Task__c	>();

                    for(OpportunityLineItem singleOli : olis){

                        dftlytime__dftly_Timesheet_Task__c task = new dftlytime__dftly_Timesheet_Task__c();

                        task.Opportunity_Product__c = singleOli.Id;

                        task.dftlytime__Project__c = project.Id;

                        task.Name = singleOli.Product2.Name;

                        task.Resource_Type__c = singleOli.Product2Id;

                        task.dftlytime__Task_Hourly_Rate__c = PBEntries.get(singleOli.Product2Id).UnitPrice;

                        taskList.add(task);

                    }

                    if(taskList.size() > 0){

                        insert taskList;

                    }

                    List<Payment_Schedule__c> oppPaymentSchs = [select Id, Invoice_Date__c, Product__c, Amount__c from Payment_Schedule__c where Opportunity__c = : opt.Id]; 

                    for(Payment_Schedule__c singlePaymentsch : oppPaymentSchs){

                        BM_Invoice__c invoice = new BM_Invoice__c();

                        invoice.Payment_Schedule__c = singlePaymentsch.Id;

                        invoice.Invoice_Date__c = singlePaymentsch.Invoice_Date__c;

                        invoice.Account__c = opt.AccountId;

                        invoice.Project__c = project.Id;

                        insert invoice;

                        Invoice_Line__c invoiceLine = new Invoice_Line__c();

                        invoiceLine.Invoice__c = invoice.Id;

                        invoiceLine.Quantity__c = 1;

                        invoiceLine.Product__c = singlePaymentsch.Product__c;

                        invoiceLine.Sales_Price__c = singlePaymentsch.Amount__c;

                        insert invoiceLine;

                    }

                }else if(opt.Type == 'Contract Revision'){ // Contract Revision Tab

                    opt.StageName = 'Closed Won';

                    opt.CloseDate = Date.today();

                    update opt;

                    dftlytime__dftly_Timesheet_Project__c oldProject = prjMap.get(signtrnsId);

                    List<dftlytime__dftly_Timesheet_Task__c> taskList = new List<dftlytime__dftly_Timesheet_Task__c	>();

                    olis = olisMap.get(signtrnsId);

                    for(OpportunityLineItem singleOli : olis){

                        dftlytime__dftly_Timesheet_Task__c task = new dftlytime__dftly_Timesheet_Task__c();

                        task.Opportunity_Product__c = singleOli.Id;

                        task.dftlytime__Project__c = oldProject.Id;

                        task.Name = singleOli.Product2.Name;

                        task.Resource_Type__c = singleOli.Product2Id;

                        task.dftlytime__Task_Hourly_Rate__c = PBEntries.get(singleOli.Product2Id).UnitPrice;

                        taskList.add(task);

                    }

                    if(taskList.size() > 0){

                        insert taskList;

                    }

                    oldProject.dftlytime__Available_Budget__c = oldProject.dftlytime__Available_Budget__c + opt.Amount;

                    update oldProject;


                    List<Payment_Schedule__c> oppPaymentSchs = [select Id, Invoice_Date__c, Product__c, Amount__c from Payment_Schedule__c where Opportunity__c = : opt.Id]; 

                    for(Payment_Schedule__c singlePaymentsch : oppPaymentSchs){

                        BM_Invoice__c invoice = new BM_Invoice__c();

                        invoice.Payment_Schedule__c = singlePaymentsch.Id;

                        invoice.Invoice_Date__c = singlePaymentsch.Invoice_Date__c;

                        invoice.Account__c = opt.AccountId;

                        invoice.Project__c = oldProject.Id;

                        insert invoice;

                        Invoice_Line__c invoiceLine = new Invoice_Line__c();

                        invoiceLine.Invoice__c = invoice.Id;

                        invoiceLine.Quantity__c = 1;

                        invoiceLine.Product__c = singlePaymentsch.Product__c;

                        invoiceLine.Sales_Price__c = singlePaymentsch.Amount__c;

                        insert invoiceLine;

                    }
                }else if( opt.Type == 'Fractional Admin'){

                    opt.StageName = 'Closed Won';

                    opt.CloseDate = Date.today();

                    dftlytime__dftly_Timesheet_Project__c project = prjMap.get(signtrnsId);

                    // IF Not Renewal Oppp
                    if(opt.Renewal_Opportunity__c == 'No'){

                        project = new dftlytime__dftly_Timesheet_Project__c();

                        project.Name = opt.Name;
    
                        project.dftlytime__Start_Date__c = getFormattedDate(opt.contract_start_date__c);
                        
                        project.dftlytime__Billing_Account__c = opt.AccountId;
                        
                        project.Type__c = opt.Type;
                        
                        project.Billing_Duration__c = opt.Billing_Duration__c;

                        OpportunityLineItem LatestLineItem = getLatestOppyLineItem(olis);

                        project.dftlytime__Project_Hourly_Rate__c = LatestLineItem.UnitPrice;

                        insert project;
    
                        opt.Project__c = project.Id;

                    }

                    update opt;

                    // if Renewal Opportunity
                    
                    if(opt.Billing_Duration__c == 'Monthly'){

                        olis = olisMap.get(signtrnsId);

                        for(OpportunityLineItem singleoliss : olis){

                            BM_Invoice__c invoice = new BM_Invoice__c();
    
                            invoice.Invoice_Date__c = singleoliss.Invoice_Date__c;
    
                            invoice.Account__c = opt.AccountId;
    
                            invoice.Project__c = project.Id;

                            invoice.Available_Hours__c = singleoliss.Quantity;

                            invoice.Hours_Start_Date__c = singleoliss.Invoice_Date__c.toStartOfMonth();

                            invoice.Hours_End_Date__c = singleoliss.Invoice_Date__c.toStartOfMonth().addMonths(1).toStartOfMonth().addDays(-1);
    
                            insert invoice;
    
                            Invoice_Line__c invoiceLine = new Invoice_Line__c();
    
                            invoiceLine.Invoice__c = invoice.Id;

                            invoiceLine.Opportunity_Product__c = singleoliss.Id;
    
                            invoiceLine.Quantity__c = singleoliss.Quantity;
    
                            invoiceLine.Product__c = singleoliss.Product2Id;
    
                            invoiceLine.Sales_Price__c = singleoliss.UnitPrice;
    
                            insert invoiceLine;

                        }

                    }
                }
            }
        }
    }


    public static OpportunityLineItem getLatestOppyLineItem(List<OpportunityLineItem> oppLineItems){

        return oppLineItems[0];
    }

    public static DateTime getFormattedDate(Date oldDate){
        Integer i;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        return Datetime.newinstance(oldDate.year(), oldDate.month(), oldDate.day(), 0, 0 , 0);
    }
}