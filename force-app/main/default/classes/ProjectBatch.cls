public class ProjectBatch implements Database.Batchable<sObject>, Schedulable{

    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'Select Id, dftlytime__Billing_Account__c, dftlytime__Total_hours__c, dftlytime__Available_Budget__c, dftlytime__Project_Hourly_Rate__c,Type__c,dftlytime__End_Date__c from dftlytime__dftly_Timesheet_Project__c where dftlytime__inactive__c = FALSE';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<dftlytime__dftly_Timesheet_Project__c> scope){
        ProjectBatchHandler.handle(scope);
    }
 
    public void finish(Database.BatchableContext bc){
    }
    
    public void execute(SchedulableContext sc){
        Database.executeBatch(this);            
    }
 }