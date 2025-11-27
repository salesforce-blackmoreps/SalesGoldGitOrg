public without sharing class BMA_AccelerateController {
    public class ResoponseWrap{
        @AuraEnabled
        public String projectId;        
        @AuraEnabled
        public String obj;
        @AuraEnabled
        public String field;
        @AuraEnabled
        public String additionalInfo;
        @AuraEnabled
        public Boolean additionalInfoReq;   
        @AuraEnabled
        public String values;
        @AuraEnabled
        public Decimal sequence;
        @AuraEnabled
        public String answerType;
        @AuraEnabled
        public String question1;
        @AuraEnabled
        public String resoponseId;
        @AuraEnabled
        public String screen;                 
        @AuraEnabled
        public List<ResoponseChoiceWrap> responseChoices;
        
    }
    
    public class ResoponseChoiceWrap{
        @AuraEnabled
        public String responseId;
        @AuraEnabled
        public String value; 
        @AuraEnabled
        public String responseChoiceId;
        @AuraEnabled
        public Boolean isSelected; 
        @AuraEnabled
        public Decimal sequence; 
        
    }
    
    public class SectionWrap{
        @AuraEnabled
        public String Id;
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public Decimal Sequence;
        @AuraEnabled
        public String sidebarButtonClass; 
        @AuraEnabled
        public List<ResoponseWrap> listResponse;
        @AuraEnabled
        public List<String> listScreens;
        @AuraEnabled
        public Integer screenCount;  
        @AuraEnabled
        public Decimal currentSequence;  
        @AuraEnabled
        public String currentField;
        @AuraEnabled 
        public Integer screensCompleted;
        @AuraEnabled 
        public Boolean isCompleted;      
              
    }
    public class IntakeWrapper{
        @AuraEnabled
        public String projectId;
        @AuraEnabled
        public List<SectionWrap> sections;        
    }
    
    @AuraEnabled
    public static IntakeWrapper getSections(String intakeId) {
       System.debug('intakeId : '+intakeId);
       //projectId 				= 'a0tO100000OUMN3IAP';
        /*if(projectId==null || projectId==''){
            projectId = 'a0tO100000OUMN3IAP';
        }*/
        
       Id projectId  = [SELECT Project__c FROM bma_Intake__c WHERE Id=: intakeId LIMIT 1].Project__c;   
       LIST<bma_Project__c> project
           						= [SELECT Id,Cloud__c,Starter_Type__c FROM bma_Project__c WHERE Id =:projectId ]; 
       IntakeWrapper iwrp 		= new IntakeWrapper();
       iwrp.projectId 			= projectId;
       iwrp.sections			= new List<SectionWrap>();

        List<bma_Response__c> res = [SELECT Id, Current_Sequence__c, Current_Field__c FROM bma_Response__c WHERE Intake__c = :intakeId LIMIT 1];
        Decimal currentSeq = res[0].Current_Sequence__c;
        for(BMA_Section__c sc : [SELECT Id,Name,bma_Description__c, Sequence__c, (SELECT Section__c, Current_Sequence__c, Current_Field__c, Screen__c FROM Responses__r) 
                                 FROM BMA_Section__c 
                                 WHERE Id IN(SELECT Section__c 
                                             FROM bma_Response__c 
                                             WHERE Intake__r.Project__c=:iwrp.projectId)
                                 			 ORDER BY Sequence__c ASC])
        {
            /*List<bma_Response__c> respList = [SELECT Id, Current_Sequence__c, Current_Field__c FROM bma_Response__c 
            WHERE Intake__c = :intakeId 
            AND Section__c = sc.Id 
            AND Current_Sequence__c = :sc.Sequence__c LIMIT 1];

            Decimal currentSeq = respList[0].Current_Sequence__c;
            //List<bma_Response__c> res = [SELECT Id, Current_Sequence__c, Current_Field__c FROM bma_Response__c WHERE Intake__c = :intakeId];
            //Decimal currentSeq = res[0].Current_Sequence__c;
            String currentField = '1';
            
            for (bma_Response__c r : res){
                if (sc.Sequence__c == r.Current_Sequence__c){
                    currentField = r.Current_Field__c;
                }
            }*/
            
            SectionWrap tswp 			= new SectionWrap();
            tswp.Id 					= sc.Id;	
            tswp.Name           		= sc.Name;
            tswp.Sequence 			    = sc.Sequence__c;
            tswp.sidebarButtonClass		= 'sidebar-btn';
            tswp.listScreens 			= new List<String>();
            tswp.currentSequence        = currentSeq;
            //tswp.currentField           = currentField;
            Set<String> checkScreens	= new Set<String>();
            Integer completedScreens = 0;
        
            for(bma_Response__c r : sc.Responses__r){
                //tswp.currentSequence = r.Current_Sequence__c == null ? 0 : r.Current_Sequence__c;
                //tswp.currentField 	= r.Current_Field__c == null ? '1' : r.Current_Field__c; && r.Current_Sequence__c > maxSequence
                if(r.Screen__c!=null && !checkScreens.contains(r.Screen__c)){
                    checkScreens.add(r.Screen__c);                    
               		tswp.listScreens.add(r.Screen__c); 
                }
                completedScreens = Math.max(completedScreens, r.Current_Field__c != null ? Integer.valueOf(r.Current_Field__c) : 0);   
                tswp.screensCompleted = completedScreens;    
            }
            
            //tswp.isCompleted = tswp.listScreens.isEmpty() ? false : (completedScreens >= tswp.listScreens.size());
            tswp.screenCount = tswp.listScreens.size()>1 ? tswp.listScreens.size() : 1;
            iwrp.sections.add(tswp);
            
        } 
       return iwrp;
    }

    @AuraEnabled
    public static String getCurrentField(Id intakeId, Id sectionId) {
        List<bma_Response__c> res = 
        [SELECT Current_Field__c  FROM bma_Response__c WHERE Intake__c = :intakeId AND Section__c = :sectionId LIMIT 1];

        return res[0].Current_Field__c;
    }

    @AuraEnabled
    public static List<ResoponseWrap> getSecttionDetail(String sectionId, Id intakeId, String screen) {
        System.debug('screen : '+screen);
        Map<String,String> mapScreens = new Map<String,String>();
        bma_Intake__c intake = [SELECT Project__c FROM bma_Intake__c WHERE Id = :intakeId LIMIT 1];
        if (intake == null || intake.Project__c == null) {
            return new List<ResoponseWrap>(); // return empty if project is missing
        }
        //String projectId 				= 'a0tO100000OUMN3IAP';
        List<ResoponseWrap> listResponse   = new List<ResoponseWrap>();
        for(bma_Response__c  resp : [SELECT Id,Section__c, Question__c, Object__c, Current_Field__c, Values__c, Screen__c, Sequence__c,
                                     Additional_Information__c, Additional_Info_Required__c, Intake__c, Account__c, Answer_Type__c, Question1__c,
                                     (SELECT Id, Value__c, Sequence__c, Selected__c FROM response_Choices__r ORDER BY Sequence__c ASC)
                                     FROM bma_Response__c 
                                     WHERE Section__c=:sectionId
                                     AND Screen__c=:screen
                                     AND Intake__r.Project__c=:intake.Project__c 
                                     ORDER BY Sequence__c ASC])
        {
            ResoponseWrap rwrap 		= new ResoponseWrap();             
            rwrap.resoponseId			= resp.Id;
            rwrap.obj					= resp.Object__c;
            rwrap.field					= resp.Current_Field__c;
            rwrap.additionalInfo		= resp.Additional_Information__c;
            rwrap.additionalInfoReq		= resp.Additional_Info_Required__c;
            rwrap.values				= resp.Values__c;
            rwrap.sequence				= resp.Sequence__c;
            rwrap.answerType			= resp.Answer_Type__c;
            rwrap.question1				= resp.Question1__c;
            rwrap.screen                = resp.Screen__c;
            rwrap.responseChoices       = new List<ResoponseChoiceWrap>();
            
            
            for(bma_Response_Choice__c rc : resp.response_Choices__r){
                ResoponseChoiceWrap tc = new ResoponseChoiceWrap();
                tc.responseId = resp.Id;
                tc.value = rc.Value__c;
                tc.responseChoiceId = rc.Id;
                tc.isSelected = rc.Selected__c;
                tc.sequence = rc.Sequence__c;
                rwrap.responseChoices.add(tc);
            }
                       
            listResponse.add(rwrap);
        } 

       return listResponse; 
    } 
 
    @AuraEnabled
    public static void updateResponseChoiceForRadioType(List<List<String>> responseList){
        
        List<String> responseIds = new List<String>();
        List<String> values = new List<String>();

        for(List<String> resp : responseList){
            responseIds.add(resp[0]);
            values.add(resp[1]);
        }
        List<bma_Response_Choice__c> answeredResponses  = [SELECT Id, Selected__c, Value__c FROM bma_Response_Choice__c WHERE Response__c IN :responseIds];

        List<bma_Response_Choice__c> clearPreviousResponses = new List<bma_Response_Choice__c>();
        for(bma_Response_Choice__c res : answeredResponses){
            res.Selected__c = false ;
            clearPreviousResponses.add(res);
        }

        update clearPreviousResponses;

        //saveNewResponseForRadioAndTextTypes(responseList, responseIds, values); 
        List<bma_Response_Choice__c> selectedResponseChoices  = 
        [SELECT Id, Value__c, Selected__c, Response__c FROM bma_Response_Choice__c WHERE Response__c IN :responseIds AND Value__c IN :values];
        List<bma_Response_Choice__c> newResponsesToUpdate = new List<bma_Response_Choice__c>();
        for(List<String> resp : responseList){
            for (bma_Response_Choice__c responseChoice : selectedResponseChoices){
                if(responseChoice.Value__c == resp[1] && responseChoice.Response__c == resp[0]){
                    responseChoice.Selected__c = true;
                    newResponsesToUpdate.add(responseChoice);
                }
            }
        }
        update newResponsesToUpdate;
    }

    @AuraEnabled
    public static void updateResponseChoiceForCheckboxType(List<List<String>> responseTrueList, List<List<String>> responseFalseList, List<Id> responseIdList){
        List<String> responseTrueIds = new List<String>();
        List<String> responseFalseIds = new List<String>();
        List<String> values = new List<String>();

        for(List<String> resp : responseTrueList){
            responseTrueIds.add(resp[0]);
            values.add(resp[1]);
        }

        for(List<String> resp : responseFalseList){
            responseFalseIds.add(resp[0]);
        }

        List<bma_Response_Choice__c> allResponses  = [SELECT Id, Selected__c FROM bma_Response_Choice__c WHERE Response__c IN :responseIdList];

        List<bma_Response_Choice__c> clearPreviousResponses = new List<bma_Response_Choice__c>();
        for(bma_Response_Choice__c res : allResponses){
            if(responseTrueIds.contains(res.Id)){
                res.Selected__c = true ; 
            }
            if(responseFalseIds.contains(res.Id)){
                res.Selected__c = false ; 
            }
            clearPreviousResponses.add(res);
        }
        update clearPreviousResponses;
    }

    @AuraEnabled
    public static List<bma_Response_Choice__c> updateResponseChoiceForTextType(List<List<String>> responseList){
        
        List<String> responseIds = new List<String>();
        List<String> values = new List<String>();

        for(List<String> resp : responseList){
            responseIds.add(resp[0]);
            values.add(resp[1]);
        }

        List<bma_Response_Choice__c> allResponses  = [SELECT Id, Value__c, Response__c FROM bma_Response_Choice__c WHERE Response__c IN :responseIds];

        List<bma_Response_Choice__c> newResponsesToUpdate = new List<bma_Response_Choice__c>();
        for(List<String> resp : responseList){
            for (bma_Response_Choice__c responseChoice : allResponses){
                if(responseChoice.Response__c == resp[0]){
                    responseChoice.Value__c = resp[1];
                    newResponsesToUpdate.add(responseChoice);
                }
            }
        }
        update newResponsesToUpdate;
        return newResponsesToUpdate;    
    }

    @AuraEnabled
    public static bma_Response__c updateResponseChoiceForAdditionalInfo(Id responseId, String additionalInfo){
        // Query safely
        bma_Response__c resp = [
            SELECT Id, Additional_Information__c 
            FROM bma_Response__c 
            WHERE Id = :responseId 
            LIMIT 1
        ];
        
        if(resp != null){
            resp.Additional_Information__c = additionalInfo;
            try {
                update resp;
            } catch(Exception e){
                System.debug('Error updating Additional Info: ' + e.getMessage());
                throw e;
            }
        }       
        return resp;
    }


    /*@AuraEnabled
    public static List<bma_Response__c> updateResponseChoiceForAdditionalInfo(List<String> responseList){
        
        String responseId = responseList[0];
        String value = responseList[1];
        //List<String> values = new List<String>();

        List<bma_Response__c> response  = [SELECT Id, Additional_Information__c FROM bma_Response__c WHERE Id = :responseId LIMIT 1];

        List<bma_Response__c> newResponseToUpdate = new List<bma_Response__c>();
        //for(List<String> resp : responseList){
            for (bma_Response__c resp : response){
                resp.Additional_Information__c = value;
                newResponseToUpdate.add(resp);
            }
        //}
        update newResponseToUpdate;
        return newResponseToUpdate;    
    }*/

    /*@AuraEnabled
    public static bma_Response__c saveCurrentSequence(Id intakeId, Decimal currentSequence){
        bma_Response__c response = [
            SELECT Id, Current_Sequence__c, Current_Field__c  
            FROM bma_Response__c 
            WHERE Intake__c = :intakeId 
            LIMIT 1
        ];
        
        response.Current_Sequence__c = currentSequence;
        response.Current_Field__c = '1';
        update response;
        return response;
    }*/


    @AuraEnabled
    public static List<bma_Response__c> saveCurrentSequenceNext(Id intakeId, Decimal currentSequence){
        List<bma_Response__c> responseList = 
        [SELECT Id, Current_Sequence__c, Current_Field__c  FROM bma_Response__c WHERE Intake__c = :intakeId];
        
        List<bma_Response__c> updateSequence = new List<bma_Response__c>();
        for(bma_Response__c res : responseList)
        {
            res.Current_Sequence__c = currentSequence;
            res.Current_Field__c  = '1';
            updateSequence.add(res);
        }
        update updateSequence;

        List<bma_Response__c> test = 
        [SELECT Id, Current_Sequence__c, Current_Field__c  FROM bma_Response__c WHERE Intake__c = :intakeId];
        return test;
    }

    @AuraEnabled
    public static List<bma_Response__c> saveCurrentSequenceBack(Id intakeId, Id sectionId, Decimal currentSequence, String currentField){
        List<bma_Response__c> responseList1 = 
        [SELECT Id, Current_Sequence__c FROM bma_Response__c WHERE Intake__c = :intakeId]  ;

        List<bma_Response__c> responseList2 = 
        [SELECT Id, Current_Field__c  FROM bma_Response__c WHERE Intake__c = :intakeId AND Section__c = :sectionId];

        //String field = responseList2[0].Current_Field__c;

        List<bma_Response__c> updateSequence1 = new List<bma_Response__c>();
        List<bma_Response__c> updateSequence2 = new List<bma_Response__c>();
        for(bma_Response__c res : responseList1)
        {
            res.Current_Sequence__c = currentSequence;
            //res.Current_Field__c  = '1';
            updateSequence1.add(res);
        }
        for(bma_Response__c res : responseList2)
        {
            //res.Current_Sequence__c = currentSequence;
            res.Current_Field__c  = currentField;
            updateSequence2.add(res);
        }
        update updateSequence1;
        update updateSequence2;

        List<bma_Response__c> test = 
        [SELECT Id, Current_Sequence__c, Current_Field__c  FROM bma_Response__c WHERE Intake__c = :intakeId AND Section__c = :sectionId];
        return test;
    }

    @AuraEnabled
    public static List<bma_Response__c> saveCurrentField(String sectionId, Id intakeId, String currentField){
        List<bma_Response__c> responseList = 
        [SELECT Id, Current_Sequence__c, Current_Field__c  FROM bma_Response__c WHERE Section__c = :sectionId AND Intake__c = :intakeId];
        List<bma_Response__c> updateField = new List<bma_Response__c>();
        for(bma_Response__c res : responseList)
        {
            res.Current_Field__c  = currentField;
            updateField.add(res);
        }
        update updateField;
        return updateField;
    }  

    @AuraEnabled
    public static String UploadCompanyLogo(String base64, String filename, String companyLogoId ) {

        try {
  			String cvId;
            system.debug('Test company logo: and base64: '+base64+' and filename: '+filename);
            system.debug('Test company logo: recordId: '+companyLogoId );
            if (String.isNotEmpty(base64)) {
                //  Delete previous logos for this record
                deleteExistingLogos(companyLogoId);
              
                ContentVersion cv = createContentVersion(base64, filename);
                if (cv != null) {
                    createContentLink(cv.Id, companyLogoId);
                    cvId = cv.Id;
                    System.debug('ContentVersion'+ cvId);
                }
            }
            return cvId;
        } catch (Exception e) {
            throw new AuraHandledException('Error uploading logo: ' + e.getMessage());
        }
    }

    private static void deleteExistingLogos(Id recordId) {
        List<ContentDocumentLink> existingLinks = [
            SELECT Id, ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :recordId
        ];

        if (!existingLinks.isEmpty()) {
            List<Id> docIds = new List<Id>();
            for (ContentDocumentLink cdl : existingLinks) {
                docIds.add(cdl.ContentDocumentId);
            }

            // Delete links first
            delete existingLinks;

            // Delete docs (this deletes all versions too)
            List<ContentDocument> docs = [SELECT Id FROM ContentDocument WHERE Id IN :docIds];
            if (!docs.isEmpty()) {
                delete docs;
            }
        }
    }

    private static ContentVersion createContentVersion(String base64, String filename) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        
        
        insert cv;
        return cv;
    }

    private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersionId
        ].ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        cdl.ShareType = 'V';
        insert cdl;
        return cdl;
    }

     @AuraEnabled(cacheable=true)
    public static String getFileUrl(Id recordId) {
        List<ContentDocumentLink> cdl = [
            SELECT ContentDocument.LatestPublishedVersionId, ContentDocument.CreatedDate
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :recordId 
            ORDER BY ContentDocument.CreatedDate DESC 
            LIMIT 1
        ];
        if (!cdl.isEmpty()) {
            return '/sfc/servlet.shepherd/version/download/' + cdl[0].ContentDocument.LatestPublishedVersionId;
        }
        return null;
         
    }  
}