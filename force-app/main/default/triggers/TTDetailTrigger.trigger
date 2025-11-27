trigger TTDetailTrigger on dftlytime__dftly_Timesheet_Detail__c (before insert, before update, before delete, after insert, after update, after delete) {

    if(TTDetailTriggerHandler.disableTrigger == True) return;
    if(Trigger.isBefore){
        TTDetailTriggerHandler.handleBeforeTrigger(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete);
    }

}