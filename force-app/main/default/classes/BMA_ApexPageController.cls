public with sharing class BMA_ApexPageController{
    @AuraEnabled
    public static List<bma_Intake__c> getIntakesByAccount(Id accountId) {
        return [
            SELECT Id, Name, Cloud__c, Starter_Type__c
            FROM bma_Intake__c
            WHERE Account__c = :accountId
            ORDER BY CreatedDate DESC
        ];
    }
}