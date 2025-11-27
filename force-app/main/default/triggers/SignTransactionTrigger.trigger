/*****************************************************************************
@TestClass			: OppTypeBucketOfHoursTest
@Author				: Inovi
@CreatedDate		: Aug 14, 2024
@LastModifiedDate	: Aug 14, 20224
@LastModifiedBy		: BlackMoreEps
******************************************************************************/
trigger SignTransactionTrigger on hic_signeasy__Transaction__c (before insert, before update, before delete, after insert, after update, after delete) {
    if(SignTransactionTriggerHandler.disableTrigger == True) return;
    if(Trigger.isAfter){
        SignTransactionTriggerHandler.handleAfterTrigger(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete);
    }
}