public with sharing class TTDetailTriggerHandler {
    public static Boolean disableTrigger = false;

    public static void handleBeforeTrigger(List<dftlytime__dftly_Timesheet_Detail__c> listNew, Map<Id, dftlytime__dftly_Timesheet_Detail__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete) {
        if(isInsert) {

            List<String> invoiceIds = new List<String>();

            List<String> taskIds = new List<String>();

            List<String> currentInvoices = new List<String>();

            List<String> projectIds = new List<String>();

            for(dftlytime__dftly_Timesheet_Detail__c ttDetail : listNew){

                if(ttDetail.dftlytime__dftlyTimesheetTask__c != null){

                    taskIds.add(ttDetail.dftlytime__dftlyTimesheetTask__c);

                }

                

                if(ttDetail.BM_Invoice__c != null){

                    currentInvoices.add(ttDetail.BM_Invoice__c);

                }


                if(ttDetail.dftlytime__dftlyTimesheetProject__c != null){

                    projectIds.add(ttDetail.dftlytime__dftlyTimesheetProject__c);

                }

            }

           

            Map<String, dftlytime__dftly_Timesheet_Task__c> taskMap = new Map<String, dftlytime__dftly_Timesheet_Task__c>([Select Id, dftlytime__Billable__c from dftlytime__dftly_Timesheet_Task__c where Id IN :taskIds]);


            Map<String, dftlytime__dftly_Timesheet_Project__c> prjMap = new Map<String, dftlytime__dftly_Timesheet_Project__c>([Select Id, Name, dftlytime__Start_Date__c, dftlytime__Billing_Account__c, Type__c, Agreement_Length__c, dftlytime__Total_hours__c, dftlytime__Project_Hourly_Rate__c, dftlytime__Available_Budget__c, Remaining_Budget__c,Remaining_Hours__c, Billing_Duration__c  from dftlytime__dftly_Timesheet_Project__c where Id IN :projectIds]);




            for(dftlytime__dftly_Timesheet_Detail__c ttDetail : listNew){

                dftlytime__dftly_Timesheet_Project__c project = prjMap.get(ttDetail.dftlytime__dftlyTimesheetProject__c);

                
                dftlytime__dftly_Timesheet_Task__c task = taskMap.get(ttDetail.dftlytime__dftlyTimesheetTask__c);


                if(project.Type__c == 'Fractional Admin' && task.dftlytime__Billable__c == TRUE && ttDetail.BM_Billable__c == TRUE){

                    System.debug('Found');

                    Date startTime = Date.newInstance(ttDetail.dftlytime__Start_Timestamp__c.year(), ttDetail.dftlytime__Start_Timestamp__c.month(), ttDetail.dftlytime__Start_Timestamp__c.day());

                    BM_Invoice__c[] invoices = [Select Id, Hours_Start_Date__c, Hours_End_Date__c, Status__c, Hours_Used__c from BM_Invoice__c where Hours_Start_Date__c <= :startTime and Hours_End_Date__c >= :startTime and Project__c = : project.Id limit 1];
                
                    System.debug(invoices.size());

                    if(invoices.size() > 0){

                        BM_Invoice__c invoice = invoices[0];                        

                        if(invoice.Status__c == 'New' || invoice.Status__c == 'Pending Review'){

                            ttDetail.BM_Invoice__c = invoice.Id;

                            AggregateResult sumHours;

                            AggregateResult[] sumHoursList  = [select sum(dftlytime__Time_Worked__c) TimeWorked, BM_Invoice__c from dftlytime__dftly_Timesheet_Detail__c where BM_Invoice__c = : invoice.Id GROUP BY BM_Invoice__c];


                            if(sumHoursList.size() > 0){

                                sumHours = sumHoursList[0];

                            }

                            Decimal timeWorked = 0;

                            if(sumHours != null){
    
                                timeWorked += (Decimal) sumHours.get('TimeWorked');
                            
                            }

                            Decimal milis = (Decimal)(ttDetail.dftlytime__End_Timestamp__c.getTime() - ttDetail.dftlytime__Start_Timestamp__c.getTime()) / (1000*60*60);

                            timeWorked += milis;
    
                            invoice.Hours_Used__c = timeWorked;

                            update invoice;


                        }else{
    
                            ttDetail.addError('The Invoice is Closed for this Month');
    
                        }
                    }
                }
            }
        }else if(isUpdate){

            List<String> projectIds = new List<String>();

            List<String> oldInvoiceIds = new List<String>();

            List<String> taskIds = new List<String>();

            

            for(dftlytime__dftly_Timesheet_Detail__c ttDetail2 : oldMap.values()){

                oldInvoiceIds.add(ttDetail2.BM_Invoice__c);

            }

            
            Map<String, BM_Invoice__c> oldInvoiceMap = new Map<String, BM_Invoice__c>([Select Id, Hours_Used__c,  Status__c from BM_Invoice__c where Id IN :oldInvoiceIds]);
                

            for(dftlytime__dftly_Timesheet_Detail__c ttDetail : listNew){

                if(ttDetail.dftlytime__dftlyTimesheetTask__c != null){

                    taskIds.add(ttDetail.dftlytime__dftlyTimesheetTask__c);

                }

                

                if(ttDetail.dftlytime__dftlyTimesheetProject__c != null){

                    projectIds.add(ttDetail.dftlytime__dftlyTimesheetProject__c);

                }
            }

            Map<String, dftlytime__dftly_Timesheet_Task__c> taskMap = new Map<String, dftlytime__dftly_Timesheet_Task__c>([Select Id, dftlytime__Billable__c from dftlytime__dftly_Timesheet_Task__c where Id IN :taskIds]);


            Map<String, dftlytime__dftly_Timesheet_Project__c> prjMap = new Map<String, dftlytime__dftly_Timesheet_Project__c>([Select Id, Name, dftlytime__Start_Date__c, dftlytime__Billing_Account__c, Type__c, Agreement_Length__c, dftlytime__Total_hours__c, dftlytime__Project_Hourly_Rate__c, dftlytime__Available_Budget__c, Remaining_Budget__c,Remaining_Hours__c, Billing_Duration__c  from dftlytime__dftly_Timesheet_Project__c where Id IN :projectIds]);


            for(dftlytime__dftly_Timesheet_Detail__c ttDetail : listNew){

                dftlytime__dftly_Timesheet_Project__c project = prjMap.get(ttDetail.dftlytime__dftlyTimesheetProject__c);

                
                dftlytime__dftly_Timesheet_Task__c task1 = taskMap.get(ttDetail.dftlytime__dftlyTimesheetTask__c);


                if(project.Type__c == 'Fractional Admin' && task1.dftlytime__Billable__c == TRUE && ttDetail.BM_Billable__c == TRUE){

                    if(ttDetail.dftlytime__Start_Timestamp__c.month() != oldMap.get(ttDetail.Id).dftlytime__Start_Timestamp__c.month()){

                        Date startTime = Date.newInstance(ttDetail.dftlytime__Start_Timestamp__c.year(), ttDetail.dftlytime__Start_Timestamp__c.month(), ttDetail.dftlytime__Start_Timestamp__c.day());
    
                        BM_Invoice__c[] invoices = [Select Id, Hours_Start_Date__c, Hours_End_Date__c, Status__c, Hours_Used__c from BM_Invoice__c where Hours_Start_Date__c <= :startTime and Hours_End_Date__c >= :startTime and Project__c = : project.Id limit 1];
    
                        if(invoices.size() > 0){
    
                            BM_Invoice__c newInvoice = invoices[0];

                            List<String> invocIds = new List<String>();

                            invocIds.add(newInvoice.Id);
                            
                            BM_Invoice__c oldInvoice = oldInvoiceMap.get(oldMap.get(ttDetail.Id).BM_Invoice__c);    
                            
                            invocIds.add(oldInvoice.Id);
                            
                            List<AggregateResult> sumOfWorkHoursForNewAndOldInvoicesWithOurCurrentTTDetails = new List<AggregateResult>([select sum(dftlytime__Time_Worked__c) TimeWorked, BM_Invoice__c from dftlytime__dftly_Timesheet_Detail__c where BM_Invoice__c IN : invocIds and Id <> : ttDetail.Id GROUP BY BM_Invoice__c]);

                            Map<String, AggregateResult> mapWorkHours = new Map<String, AggregateResult>();

                            for(AggregateResult workhours : sumOfWorkHoursForNewAndOldInvoicesWithOurCurrentTTDetails){

                                mapWorkHours.put(String.valueOf(workhours.get('BM_Invoice__c')), workhours);
                            
                            }
                            
    
                            if(oldInvoice.Status__c == 'New' || oldInvoice.Status__c == 'Pending Review'){
    
                                ttDetail.BM_Invoice__c = newInvoice.Id;
    
                                AggregateResult newInvoiceAggregateResult;
    
                                newInvoiceAggregateResult = mapWorkHours.get(newInvoice.Id);
    
                                Decimal timeWorkedExceptNewInvoice = 0;
    
                                if(newInvoiceAggregateResult != null){
        
                                    timeWorkedExceptNewInvoice += (Decimal) newInvoiceAggregateResult.get('TimeWorked');
                                
                                }

                                Decimal hoursWorkedInNewInvoice = (Decimal)(ttDetail.dftlytime__End_Timestamp__c.getTime() - ttDetail.dftlytime__Start_Timestamp__c.getTime()) / (1000*60*60);

                                newInvoice.Hours_Used__c = timeWorkedExceptNewInvoice + hoursWorkedInNewInvoice;
    
                                update newInvoice;

                                AggregateResult oldInvoiceAggregateResult = mapWorkHours.get(oldInvoice.Id);
    
                                Decimal hoursWorkedInOldInvoice = 0;
    
                                if(oldInvoiceAggregateResult != null){
        
                                    hoursWorkedInOldInvoice += (Decimal) oldInvoiceAggregateResult.get('TimeWorked');
                                
                                }

                                oldInvoice.Hours_Used__c = hoursWorkedInOldInvoice;

                                update oldInvoice;

                                
                            
                            }else{
        
                                ttDetail.addError('The Invoice related to this record is already Closed for this Month');
        
                            }
                        }

                    }else{

                        if((ttDetail.dftlytime__Start_Timestamp__c != oldMap.get(ttDetail.Id).dftlytime__Start_Timestamp__c) || (ttDetail.dftlytime__End_Timestamp__c != oldMap.get(ttDetail.Id).dftlytime__End_Timestamp__c) ){

                            BM_Invoice__c oldInvoice = oldInvoiceMap.get(ttDetail.BM_Invoice__c);



                            if(oldInvoice.Status__c == 'New' || oldInvoice.Status__c == 'Pending Review'){

                                List<AggregateResult> sumOfWorkHoursForInvoiceWithOurCurrentTTDetails = new List<AggregateResult>([select sum(dftlytime__Time_Worked__c) TimeWorked, BM_Invoice__c from dftlytime__dftly_Timesheet_Detail__c where BM_Invoice__c = : oldInvoice.Id and Id <> : ttDetail.Id GROUP BY BM_Invoice__c]);

                                Decimal timeWorkedExceptInvoice = 0;

                                if(sumOfWorkHoursForInvoiceWithOurCurrentTTDetails.size() > 0){

                                    timeWorkedExceptInvoice += (Decimal) sumOfWorkHoursForInvoiceWithOurCurrentTTDetails[0].get('TimeWorked');

                                }

                                Decimal hoursWorkedInNewInvoice = (Decimal)(ttDetail.dftlytime__End_Timestamp__c.getTime() - ttDetail.dftlytime__Start_Timestamp__c.getTime()) / (1000*60*60);

                                oldInvoice.Hours_Used__c = timeWorkedExceptInvoice + hoursWorkedInNewInvoice;

                                update oldInvoice;
                            
                            }else{
                                ttDetail.addError('The Invoice related to this record is already Closed for this Month');
                            }
                        }
                    }
                }
            }
        }else if(isDelete){

            List<String> invoiceIds = new List<String>();

            List<String> taskIds = new List<String>();

            List<String> projectIds = new List<String>();


            List<String> currentInvoices = new List<String>();

            for(dftlytime__dftly_Timesheet_Detail__c ttDetail : oldMap.values()){

                if(ttDetail.dftlytime__dftlyTimesheetTask__c != null){

                    taskIds.add(ttDetail.dftlytime__dftlyTimesheetTask__c);

                }

                


                if(ttDetail.dftlytime__dftlyTimesheetProject__c != null){

                    projectIds.add(ttDetail.dftlytime__dftlyTimesheetProject__c);

                }

                currentInvoices.add(ttDetail.BM_Invoice__c);

            }

            Map<String, BM_Invoice__c> invoiceMap = new Map<String, BM_Invoice__c>([Select Id, Hours_Used__c, Status__c from BM_Invoice__c where Id IN :currentInvoices]);


            Map<String, dftlytime__dftly_Timesheet_Task__c> taskMap = new Map<String, dftlytime__dftly_Timesheet_Task__c>([Select Id, dftlytime__Billable__c from dftlytime__dftly_Timesheet_Task__c where Id IN :taskIds]);


            Map<String, dftlytime__dftly_Timesheet_Project__c> prjMap = new Map<String, dftlytime__dftly_Timesheet_Project__c>([Select Id, Name, dftlytime__Start_Date__c, dftlytime__Billing_Account__c, Type__c, Agreement_Length__c, dftlytime__Total_hours__c, dftlytime__Project_Hourly_Rate__c, dftlytime__Available_Budget__c, Remaining_Budget__c,Remaining_Hours__c, Billing_Duration__c  from dftlytime__dftly_Timesheet_Project__c where Id IN :projectIds]);




            for(dftlytime__dftly_Timesheet_Detail__c ttDetail : oldMap.values()){

                dftlytime__dftly_Timesheet_Project__c project = prjMap.get(ttDetail.dftlytime__dftlyTimesheetProject__c);

                
                dftlytime__dftly_Timesheet_Task__c task1 = taskMap.get(ttDetail.dftlytime__dftlyTimesheetTask__c);

                System.debug(project);

                if(project.Type__c == 'Fractional Admin' && task1.dftlytime__Billable__c == TRUE){

                    Date startTime = Date.newInstance(ttDetail.dftlytime__Start_Timestamp__c.year(), ttDetail.dftlytime__Start_Timestamp__c.month(), ttDetail.dftlytime__Start_Timestamp__c.day());

                    BM_Invoice__c currentInvoice = invoiceMap.get(ttDetail.BM_Invoice__c);

                    if(currentInvoice != null){

                        BM_Invoice__c invoice = currentInvoice;                        

                        if(invoice.Status__c == 'New' || invoice.Status__c == 'Pending Review'){
                                
                            invoice.Hours_Used__c = invoice.Hours_Used__c - ttDetail.dftlytime__Time_Worked__c;

                            update invoice;
                        
                        }else{
    
                            ttDetail.addError('The Invoice related to this record is already Closed for this Month');
    
                        }
                    }
                }
            }
        }
    }
}