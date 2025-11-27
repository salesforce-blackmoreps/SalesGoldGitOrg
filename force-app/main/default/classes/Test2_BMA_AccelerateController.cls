public with sharing class Test2_BMA_AccelerateController {
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