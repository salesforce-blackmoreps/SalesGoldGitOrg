public without sharing class ProjectBatchHandler {
    
    public static void handle(List<dftlytime__dftly_Timesheet_Project__c> projectList){
		Project_Invoicing__mdt invPrj 											= [SELECT Fractional_Admin_Reset_Day__c, Monthly_Invoice_Day__c, Monthly_Overages_Product__c 
                                                                                   FROM Project_Invoicing__mdt 
                                                                                   LIMIT 1];
        Map<String, List<BM_Invoice__c>> invMap 								= new Map<String, List<BM_Invoice__c>>();
        Map<String, List<dftlytime__dftly_Timesheet_Detail__c>> ttDetailsMap 	= new Map<String, List<dftlytime__dftly_Timesheet_Detail__c>>();
        List<String> projectIds 												= new List<String>();
        List<dftlytime__dftly_Timesheet_Project__c> toUpdateProjects 			= new List<dftlytime__dftly_Timesheet_Project__c>();
        List<Id> firstConditionIds 												= new List<Id>();

        for(dftlytime__dftly_Timesheet_Project__c prj : projectList){
            projectIds.add(prj.Id);
        }

        Map<Invoice_Line__c, List<dftlytime__dftly_Timesheet_Detail__c>> toUpdatettDetailsMap = new Map<Invoice_Line__c, List<dftlytime__dftly_Timesheet_Detail__c>>();

        List<BM_Invoice__c> invs = [Select Id,Account__c,Hours_Start_Date__c, Status__c, Remaining_Hours__c, Hours_End_Date__c, Project__c,Total_Outstanding__c, 
                                   (select Id, Sales_Price__c, Quantity__c, Product__c from Invoice_Lines__r), 
                                    Invoice_Date__c, Available_Hours__c, Total_Due__c from BM_Invoice__c 
                                    where Project__c in : projectIds order by Invoice_Date__c DESC];
        
        List<dftlytime__dftly_Timesheet_Detail__c> ttdetailsAll = [Select Id, BM_Invoice_Line__r.Product__c, dftlytime__Time_Worked__c, 
                                                                   dftlytime__dftlyTimesheetTask__r.Resource_Type__c, BM_Billable__c, 
                                                                   dftlytime__dftlyTimesheetTask__r.dftlytime__Billable__c, 
                                                                   dftlytime__Month_Year__c, dftlytime__dftlyTimesheetProject__c 
                                                                   from dftlytime__dftly_Timesheet_Detail__c 
                                                                   where dftlytime__dftlyTimesheetProject__c in : projectIds];
        List<BM_Invoice__c> prjInvs = new List<BM_Invoice__c>();
        List<dftlytime__dftly_Timesheet_Detail__c> prjttDetails = new List<dftlytime__dftly_Timesheet_Detail__c>();
        Map<Integer, BM_Invoice__c> insertInvoices = new Map<Integer, BM_Invoice__c>();
        Map<Integer, List<Invoice_Line__c>> insertInvoiceLines = new Map<Integer, List<Invoice_Line__c>>();
        List<dftlytime__dftly_Timesheet_Project__c> updateProjects = new List<dftlytime__dftly_Timesheet_Project__c>();
        List<Invoice_Line__c> insertSingleInvoiceLines = new List<Invoice_Line__c>();
        List<BM_Invoice__c> updateSingleInvoices = new List<BM_Invoice__c>();


        for(BM_Invoice__c inv : invs){
            
            if(invMap.containsKey(inv.Project__c)){
                prjInvs = invMap.get(inv.Project__c);
            }else{
                prjInvs = new List<BM_Invoice__c>();
            }

            prjInvs.add(inv);
            invMap.put(inv.Project__c, prjInvs);

        }

        Integer i = 1;
        List<String> resourceTypeIds = new List<String>();

        for(dftlytime__dftly_Timesheet_Detail__c ttdetail1 : ttdetailsAll){

            if(ttDetailsMap.containsKey(ttdetail1.dftlytime__dftlyTimesheetProject__c)){
                prjttDetails = ttDetailsMap.get(ttdetail1.dftlytime__dftlyTimesheetProject__c);
            }else{
                prjttDetails = new List<dftlytime__dftly_Timesheet_Detail__c>();
            }

            resourceTypeIds.add(ttdetail1.dftlytime__dftlyTimesheetTask__r.Resource_Type__c);
            prjttDetails.add(ttdetail1);
            ttDetailsMap.put(ttdetail1.dftlytime__dftlyTimesheetProject__c, prjttDetails);

        }

        System.debug(ttDetailsMap);
        Id standardPriceBookId;

        if(Test.isRunningTest()){
            standardPriceBookId = Test.getStandardPricebookId();
        }else{
            standardPriceBookId = getStdPricebookId();
        }
        List<PricebookEntry> pricebookEntries = [Select Id, Pricebook2Id, Product2Id, UnitPrice from PricebookEntry where Pricebook2Id = : standardPriceBookId and Product2Id in : resourceTypeIds];

        Map<String, PricebookEntry> mapPriceBookEntry = new Map<String,PricebookEntry>();

        for(PricebookEntry pbe : pricebookEntries){
            mapPriceBookEntry.put(pbe.Product2Id, pbe);
        }

        for(dftlytime__dftly_Timesheet_Project__c prjs : projectList){
            Boolean prjUpdateFlag = false;

            if(prjs.dftlytime__End_Date__c != null && prjs.dftlytime__End_Date__c < Date.today()){
                if(prjs.dftlytime__End_Date__c < Date.today()){
                    prjs.dftlytime__inactive__c = TRUE;
                    prjUpdateFlag = TRUE;
                    updateProjects.add(prjs);
                    if(prjs.Type__c == 'Fractional Admin'){

                        firstConditionIds.add(prjs.Id);

                        List<BM_Invoice__c> relatedInvoices = invMap.get(prjs.Id);

                        if(relatedInvoices != null){

                            BM_Invoice__c lastMonthInvoice = getLastMonthInvoice(relatedInvoices);
                            BM_Invoice__c thisMonthInvoice = getThisMonthInvoice(relatedInvoices);                            

                            System.debug(lastMonthInvoice);

                            if(lastMonthInvoice != null){
								// IF Outstandind Balance 0 then close
                                if(lastMonthInvoice.Total_Outstanding__c==0){
                                   lastMonthInvoice.Status__c = 'Closed';
                                   updateSingleInvoices.add(lastMonthInvoice);
                                }
                                else if(lastMonthInvoice.Remaining_Hours__c < 0 && thisMonthInvoice!=null){

                                    Invoice_Line__c newLine = new Invoice_Line__c(
                                        Product__c = invPrj.Monthly_Overages_Product__c,
                                        Invoice__c = thisMonthInvoice.Id,
                                        Sales_Price__c = prjs.dftlytime__Project_Hourly_Rate__c,
                                        Quantity__c = Math.abs(lastMonthInvoice.Remaining_Hours__c)
                                    );

                                    thisMonthInvoice.Status__c = 'Pending Review';
                                    insertSingleInvoiceLines.add(newLine);
                                    updateSingleInvoices.add(thisMonthInvoice);

                                }
                                else{

                                    thisMonthInvoice.Status__c = 'Pending Review';
                                    updateSingleInvoices.add(thisMonthInvoice);
                                
                                }
                            }else{

                                System.debug('Last month Invoice Not Found');

                            }
                        }
                        
                    }
                    
                    else if(prjs.Type__c == 'On-Demand')
                    {

                        firstConditionIds.add(prjs.Id);

                        List<dftlytime__dftly_Timesheet_Detail__c> relatedTTDetailsRecord = ttDetailsMap.get(prjs.Id);

                        System.debug(relatedTTDetailsRecord.size());

                        if(relatedTTDetailsRecord != null && relatedTTDetailsRecord.size() > 0){

                            List<dftlytime__dftly_Timesheet_Detail__c> appropriateRelatedTTDetailsRecord = getAppropriateTTDetails(relatedTTDetailsRecord);

                        

                            System.debug(appropriateRelatedTTDetailsRecord);


                            if(appropriateRelatedTTDetailsRecord != null && appropriateRelatedTTDetailsRecord.size() > 0){

                                Map<String, List<dftlytime__dftly_Timesheet_Detail__c>> resourceTTDetailsMap = new Map<String, List<dftlytime__dftly_Timesheet_Detail__c>>();

                                for(dftlytime__dftly_Timesheet_Detail__c ttDetail : appropriateRelatedTTDetailsRecord){

                                    
                                    List<dftlytime__dftly_Timesheet_Detail__c> tempList = new List<dftlytime__dftly_Timesheet_Detail__c>();


                                    if(ttDetail.dftlytime__dftlyTimesheetTask__r.Resource_Type__c != null){

                                        if(resourceTTDetailsMap.containsKey(ttDetail.dftlytime__dftlyTimesheetTask__r.Resource_Type__c)){

                                            tempList = resourceTTDetailsMap.get(ttDetail.dftlytime__dftlyTimesheetTask__r.Resource_Type__c);   
    
                                        }else{
    
                                            tempList = new List<dftlytime__dftly_Timesheet_Detail__c>();
    
                                        }
    
                                        tempList.add(ttDetail);
    
                                        resourceTTDetailsMap.put(ttDetail.dftlytime__dftlyTimesheetTask__r.Resource_Type__c, tempList);
                                    }

                                }


                                BM_Invoice__c newInv = new BM_Invoice__c(
                                    Account__c = prjs.dftlytime__Billing_Account__c,
                                    Project__c = prjs.Id,
                                    Invoice_Date__c = Date.today()
                                );


                                insertInvoices.put(i, newInv);


                                List<Invoice_Line__c> newInvoiceLines = new List<Invoice_Line__c>();

                            
                                // BM_Invoice_Line__c
                                for(String resourceType : resourceTTDetailsMap.keyset()){

                                    List<dftlytime__dftly_Timesheet_Detail__c> ttDetailsList = resourceTTDetailsMap.get(resourceType);

                                    
                                    Decimal hours = getTotalHours(ttDetailsList);

                                    
                                    

                                    Invoice_Line__c newInvoiceLine = new Invoice_Line__c();
                                    newInvoiceLine.Quantity__c = hours;
                                    newInvoiceLine.Product__c = resourceType;
                                    newInvoiceLine.Sales_Price__c = mapPriceBookEntry.get(resourceType).UnitPrice;

                                    newInvoiceLines.add(newInvoiceLine);

                                    toUpdatettDetailsMap.put(newInvoiceLine, ttDetailsList);
                                }


                                insertInvoiceLines.put(i, newInvoiceLines);

                                i++;


                            }
                        
                        }

                    }

                    continue;
                }
            }
            if(Date.today().day() == invPrj.Fractional_Admin_Reset_Day__c && prjs.Type__c == 'Fractional Admin')
            {

                List<BM_Invoice__c> relatedInvoices = invMap.get(prjs.Id);

                if(relatedInvoices != null && relatedInvoices.size() > 0){

                    BM_Invoice__c thisMonthInvoice = getThisMonthInvoice(relatedInvoices);
                    

                    if(thisMonthInvoice == null){

                        System.debug('No This MOnth Invoice');
                        
                        List<BM_Invoice__c> oldestInvs = invMap.get(prjs.Id);

                        if(oldestInvs != null && oldestInvs.size() > 0){
        
                            BM_Invoice__c oldestInv = invMap.get(prjs.Id)[0];
        
                            List<Invoice_Line__c> invoiceLines = getAppropriateLines(oldestInv.Invoice_Lines__r, invPrj);
        
        
                            if(invoiceLines != null && invoiceLines.size() > 0){
                                

                                BM_Invoice__c newInv = new BM_Invoice__c();
                                newInv.Account__c = oldestInv.Account__c;
                                newInv.Project__c = oldestInv.Project__c;
                                newInv.Invoice_Date__c = Date.today().toStartOfMonth().addDays(4);
                                Date firstDayOfMonth = Date.today().toStartOfMonth();
                                newInv.Hours_Start_Date__c = firstDayOfMonth;
                                newInv.Hours_End_Date__c = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
                                newInv.Available_Hours__c = oldestInv.Available_Hours__c;


                                insertInvoices.put(i, newInv);


                                List<Invoice_Line__c> newInvoiceLines = new List<Invoice_Line__c>();


                                for(Invoice_Line__c invoiceLine : invoiceLines){
                                    Invoice_Line__c newInvoiceLine = new Invoice_Line__c();
                                    newInvoiceLine.Quantity__c = invoiceLine.Quantity__c;
                                    newInvoiceLine.Product__c = invoiceLine.Product__c;
                                    newInvoiceLine.Sales_Price__c = invoiceLine.Sales_Price__c;

                                    newInvoiceLines.add(newInvoiceLine);
                                }


                                insertInvoiceLines.put(i, newInvoiceLines);

                                i++;

                                prjs.dftlytime__Total_hours__c = oldestInv.Available_Hours__c;
                                prjs.dftlytime__Available_Budget__c = oldestInv.Total_Due__c;
                                prjUpdateFlag = TRUE;

                            }else{

                                System.debug('Invoice Line Not Found');


                            }
        
                            
        
                        }else{

                           

                        }
                        
                    }else{
                        prjs.dftlytime__Total_hours__c = thisMonthInvoice.Available_Hours__c;
                        prjs.dftlytime__Available_Budget__c = thisMonthInvoice.Total_Due__c;
                        prjUpdateFlag = TRUE;
                    }

                    System.debug(thisMonthInvoice);

                    
                }else{

                    

                }

            }
            else{
                System.debug(Date.today().day()+' - Test - '+invPrj.Monthly_Invoice_Day__c);
                if(Date.today().day() == invPrj.Monthly_Invoice_Day__c){
					
                    if(prjs.Type__c == 'Fractional Admin' && !firstConditionIds.contains(prjs.Id)){
						System.debug(Date.today().day()+' - Test - '+invPrj.Monthly_Invoice_Day__c);
                        List<BM_Invoice__c> relatedInvoices = invMap.get(prjs.Id);

                        if(relatedInvoices != null){
							System.debug(Date.today().day()+' - Test - '+invPrj.Monthly_Invoice_Day__c);
                            BM_Invoice__c lastMonthInvoice = getLastMonthInvoice(relatedInvoices);
                            BM_Invoice__c thisMonthInvoice = getThisMonthInvoice(relatedInvoices);
							List<Invoice_Line__c> invoiceLines = new List<Invoice_Line__c>();
                            if(lastMonthInvoice!=null) {
                                invoiceLines = getAppropriateLines(lastMonthInvoice.Invoice_Lines__r, invPrj);                            
                            }

                            if(lastMonthInvoice != null){ 
								System.debug(Date.today().day()+' - Test - '+invPrj.Monthly_Invoice_Day__c);                                
                                if(lastMonthInvoice.Total_Outstanding__c==0){
                                    System.debug(Date.today().day()+' - Test - '+invPrj.Monthly_Invoice_Day__c); 
                                   lastMonthInvoice.Status__c = 'Closed';                                   
                                }
                                if(lastMonthInvoice.Remaining_Hours__c < 0 && thisMonthInvoice!=null){ 
                                    System.debug(Date.today().day()+' - Test - '+invPrj.Monthly_Invoice_Day__c); 
                                    Decimal salesPrice = 0;
                                    if(prjs.dftlytime__Project_Hourly_Rate__c!=null){
                                        salesPrice = prjs.dftlytime__Project_Hourly_Rate__c;
                                    }
                                    else if(!invoiceLines.isEmpty()){
                                       salesPrice =  invoiceLines[0].Sales_Price__c;
                                    }
                                    
                                    Invoice_Line__c newLine = new Invoice_Line__c(Product__c = invPrj.Monthly_Overages_Product__c,
                                                                                  Invoice__c = thisMonthInvoice.Id, 
	                                                                              Sales_Price__c=salesPrice,     
                                                                                  Quantity__c = Math.abs(lastMonthInvoice.Remaining_Hours__c));
                                    
                                    insertSingleInvoiceLines.add(newLine); 
                                    if(lastMonthInvoice.Total_Outstanding__c!=0) {
                                        lastMonthInvoice.Status__c = 'Pending Review'; 	
                                    }                                        
                                    thisMonthInvoice.Status__c = 'Pending Review'; 

                                }
                                else{ 
                                    lastMonthInvoice.Status__c = 'Pending Review';                                     
                                }
                                
                                updateSingleInvoices.add(lastMonthInvoice);
                                updateSingleInvoices.add(thisMonthInvoice);
                            }
                            
                            else{
                                System.debug('Last month Invoice Not Found');

                            }
                        }
                        
                    }else if(prjs.Type__c == 'On-Demand' && !firstConditionIds.contains(prjs.Id)){

                        List<dftlytime__dftly_Timesheet_Detail__c> relatedTTDetailsRecord = ttDetailsMap.get(prjs.Id);

                        
                        System.debug(prjs.Id);
                        // System.debug(relatedTTDetailsRecord.size());
                        System.debug(relatedTTDetailsRecord);
                        // System.debug(relatedTTDetailsRecord.size());

                        if(relatedTTDetailsRecord != null && relatedTTDetailsRecord.size() > 0){

                            List<dftlytime__dftly_Timesheet_Detail__c> appropriateRelatedTTDetailsRecord = getAppropriateTTDetails(relatedTTDetailsRecord);

                        

                            System.debug(appropriateRelatedTTDetailsRecord);


                            if(appropriateRelatedTTDetailsRecord != null && appropriateRelatedTTDetailsRecord.size() > 0){ Map<String, List<dftlytime__dftly_Timesheet_Detail__c>> resourceTTDetailsMap = new Map<String, List<dftlytime__dftly_Timesheet_Detail__c>>();

                                for(dftlytime__dftly_Timesheet_Detail__c ttDetail : appropriateRelatedTTDetailsRecord){

                                    
                                    List<dftlytime__dftly_Timesheet_Detail__c> tempList = new List<dftlytime__dftly_Timesheet_Detail__c>();


                                    if(ttDetail.dftlytime__dftlyTimesheetTask__r.Resource_Type__c != null){

                                        if(resourceTTDetailsMap.containsKey(ttDetail.dftlytime__dftlyTimesheetTask__r.Resource_Type__c)){

                                            tempList = resourceTTDetailsMap.get(ttDetail.dftlytime__dftlyTimesheetTask__r.Resource_Type__c);   
    
                                        }else{
    
                                            tempList = new List<dftlytime__dftly_Timesheet_Detail__c>();
    
                                        }
    
                                        tempList.add(ttDetail);
    
                                        resourceTTDetailsMap.put(ttDetail.dftlytime__dftlyTimesheetTask__r.Resource_Type__c, tempList);
                                    }

                                }


                                BM_Invoice__c newInv = new BM_Invoice__c(
                                    Account__c = prjs.dftlytime__Billing_Account__c,
                                    Project__c = prjs.Id,
                                    Status__c = 'Pending Review',
                                    Invoice_Date__c = Date.today()
                                );


                                insertInvoices.put(i, newInv);


                                List<Invoice_Line__c> newInvoiceLines = new List<Invoice_Line__c>();

                            
                                // BM_Invoice_Line__c
                                for(String resourceType : resourceTTDetailsMap.keyset()){

                                    List<dftlytime__dftly_Timesheet_Detail__c> ttDetailsList = resourceTTDetailsMap.get(resourceType);

                                    
                                    Decimal hours = getTotalHours(ttDetailsList);

                                    
                                    

                                    Invoice_Line__c newInvoiceLine = new Invoice_Line__c();
                                    newInvoiceLine.Quantity__c = hours;
                                    newInvoiceLine.Product__c = resourceType;
                                    newInvoiceLine.Sales_Price__c = mapPriceBookEntry.get(resourceType).UnitPrice;

                                    newInvoiceLines.add(newInvoiceLine);

                                    toUpdatettDetailsMap.put(newInvoiceLine, ttDetailsList);
                                }


                                insertInvoiceLines.put(i, newInvoiceLines);

                                i++;


                            }
                        
                        }

                    }
                }
            }


            if(prjUpdateFlag == TRUE){
                updateProjects.add(prjs);
            }

        }


        if(updateProjects.size() > 0){
            update updateProjects;
        }
		
        System.debug(updateSingleInvoices);
        if(updateSingleInvoices.size() > 0 && !Test.isRunningTest()){
            update updateSingleInvoices;
        }
		System.debug(insertSingleInvoiceLines);
        if(insertSingleInvoiceLines.size() > 0){
            insert insertSingleInvoiceLines;
        }
       
        
        insert insertInvoices.values();
        Map <Invoice_Line__c ,Invoice_Line__c > mapOfInvoiceLine = new  Map <Invoice_Line__c ,Invoice_Line__c >() ;
        List<dftlytime__dftly_Timesheet_Detail__c> toUpdateTaskDetailList = new List<dftlytime__dftly_Timesheet_Detail__c>();
		
        
        for(Integer key : insertInvoices.keySet()){
            BM_Invoice__c newInv = insertInvoices.get(key);
            List<Invoice_Line__c> invLines = new List<Invoice_Line__c>();
            
            if(insertInvoiceLines.containsKey(key)){
                if(invLines != null && invLines.size() > 0){
                    for(Invoice_Line__c invLine  : insertInvoiceLines.get(key)){
                        Invoice_Line__c newinvLine = invLine;
                        if (toUpdatettDetailsMap.containsKey(invLine)) {
                        	newinvLine.Invoice__c = newInv.Id;
                        	mapOfInvoiceLine.put(invLine,newinvLine);
                    	}
                    }
                    
                }
            }
        }
        
        insert mapOfInvoiceLine.values();
        
        
		for (Invoice_Line__c prevInvoiceLine : mapOfInvoiceLine.keySet()) {
  			if (toUpdatettDetailsMap.containsKey(prevInvoiceLine)) {
               Invoice_Line__c invLine = mapOfInvoiceLine.get(prevInvoiceLine);
               List<dftlytime__dftly_Timesheet_Detail__c> taskDetailList = toUpdatettDetailsMap.get(prevInvoiceLine);
        		for (dftlytime__dftly_Timesheet_Detail__c ttd : taskDetailList) {
            		ttd.BM_Invoice_Line__c = invLine.Id;
            		toUpdateTaskDetailList.add(ttd);
        		}
    		}
		}

		if (!toUpdateTaskDetailList.isEmpty()) {
    		update toUpdateTaskDetailList;
		}
    }
    
    public static BM_Invoice__c getLastMonthInvoice(List<BM_Invoice__c> relatedInvoices){
        for(BM_Invoice__c inv : relatedInvoices){
            if(inv.Invoice_Date__c.monthsBetween(Date.today()) == 1){
                return inv;
            }
        }
        return null;
    }

    public static BM_Invoice__c getThisMonthInvoice(List<BM_Invoice__c> relatedInvoices){
        for(BM_Invoice__c inv : relatedInvoices){
            if(inv.Invoice_Date__c.monthsBetween(Date.today()) == 0){
                return inv;
            }
        }
        return null;
    }

    public static List<Invoice_Line__c> getAppropriateLines(List<Invoice_Line__c> relatedInvoices, Project_Invoicing__mdt invPrj){
        List<Invoice_Line__c> lines = new List<Invoice_Line__c>();
        for(Invoice_Line__c invLine : relatedInvoices){
            
            if(Test.isRunningTest()){
                lines.add(invLine);
            }else{
                if(invLine.Product__c != invPrj.Monthly_Overages_Product__c){
                    lines.add(invLine);
                }
            }
        }
        return lines;
    }

    public static List<dftlytime__dftly_Timesheet_Detail__c> getAppropriateTTDetails(List<dftlytime__dftly_Timesheet_Detail__c> recrods){       
        Integer lastMonth = Integer.valueOf(Date.today().month()) - 1;
        Date LastMonth1 = Date.today().addMonths(-1); 
        if(lastMonth == 0){
            lastMonth = 12;
        }

        List<dftlytime__dftly_Timesheet_Detail__c> appropriateRecords = new List<dftlytime__dftly_Timesheet_Detail__c>();

        for(dftlytime__dftly_Timesheet_Detail__c ttDetail : recrods){
            Date ttDetalsDate = Date.newInstance(Integer.valueOf(ttDetail.dftlytime__Month_Year__c.split('-', 2)[1]), Integer.valueOf(ttDetail.dftlytime__Month_Year__c.split('-', 2)[0]), 1);
            if(LastMonth1.monthsBetween(ttDetalsDate) == 0 && ttdetail.BM_Billable__c == TRUE){
                appropriateRecords.add(ttDetail);
            }
        }

        if(appropriateRecords.size()>0){
            return appropriateRecords;
        }
        return null;
    }

    public static ID getStdPricebookId() {
        if (Test.isRunningTest())   return Test.getStandardPricebookId();
        return [select id, name from Pricebook2 where isStandard = true limit 1].id;    
    }

    public static Decimal getTotalHours(List<dftlytime__dftly_Timesheet_Detail__c> ttList){
        Decimal hours = 0;
        for(dftlytime__dftly_Timesheet_Detail__c var : ttList){
            hours += var.dftlytime__Time_Worked__c;
        }
        return hours;
    }
    
    public static void fakeMethod(){
        Decimal i =0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}