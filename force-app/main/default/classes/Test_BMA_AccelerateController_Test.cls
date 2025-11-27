@IsTest
public class Test_BMA_AccelerateController_Test {
    // Helper method to create test data
    private static Map<String, Id> createTestData() {
        Map<String, Id> ids = new Map<String, Id>();

        // Create Project
        bma_Project__c project = new bma_Project__c(
            Name = 'Test Project',
            Cloud__c = 'Service',
            Starter_Type__c = 'Basic'
        );
        insert project;
        ids.put('projectId', project.Id);

        // Create Intake
        bma_Intake__c intake = new bma_Intake__c(
            Project__c = project.Id
        );
        insert intake;
        ids.put('intakeId', intake.Id);

        // Create Section
        BMA_Section__c section = new BMA_Section__c(
            Name = 'Test Section',
            bma_Description__c = 'Description',
            Sequence__c = 1
        );
        insert section;
        ids.put('sectionId', section.Id);
        
        bma_Question__c question = new bma_Question__c(
            Name ='Test Question',
            Question__c = 'Question Text'
        );
        insert question;
        ids.put('questionId', question.Id);

        // Create Response
        bma_Response__c response = new bma_Response__c(
            Section__c = section.Id,
            Intake__c = intake.Id,
            Question__c = question.Id,
            Object__c = 'Account',
            Current_Field__c = '1',
            Values__c = 'Value1',
            Screen__c = '1',
            Additional_Information__c = 'Info',
            Account__c = null,
            Answer_Type__c = 'Text',
            Question1__c = 'Question Text',
            Current_Sequence__c = 1
        );
        insert response;
        ids.put('responseId', response.Id);

        // Create Response Choices
        bma_Response_Choice__c choice1 = new bma_Response_Choice__c(
            Response__c = response.Id,
            Value__c = 'Option1',
            Selected__c = false
        );
        bma_Response_Choice__c choice2 = new bma_Response_Choice__c(
            Response__c = response.Id,
            Value__c = 'Option2',
            Selected__c = false
        );
        insert new List<bma_Response_Choice__c>{choice1, choice2};
        ids.put('choice1Id', choice1.Id);
        ids.put('choice2Id', choice2.Id);

        return ids;
    }
    
    @IsTest
    static void test_getSections() {
        Map<String, Id> ids = createTestData();
        Test.startTest();
        Test_BMA_AccelerateController.IntakeWrapper result =
            Test_BMA_AccelerateController.getSections(ids.get('intakeId'));
        Test.stopTest();
    }
    
    @IsTest
    static void test_getSectionDetail() {
        Map<String, Id> ids = createTestData();
        Test.startTest();
        List<Test_BMA_AccelerateController.ResoponseWrap> details =
            Test_BMA_AccelerateController.getSecttionDetail(
                ids.get('sectionId'),
                ids.get('intakeId'),
                '1'
            );
        Test.stopTest();
    }
    
    @IsTest
    static void test_updateResponseChoiceForRadioType() {
        Map<String, Id> ids = createTestData();
        List<List<String>> responseList = new List<List<String>>{
            new List<String>{ String.valueOf(ids.get('responseId')), 'Option1' }
        };

        Test.startTest();
        Test_BMA_AccelerateController.updateResponseChoiceForRadioType(responseList);
        Test.stopTest();
    }

    @IsTest
    static void test_updateResponseChoiceForCheckboxType() {
        Map<String, Id> ids = createTestData();
        List<List<String>> trueList = new List<List<String>>{
            new List<String>{ String.valueOf(ids.get('choice1Id')), 'Option1' }
        };
        List<List<String>> falseList = new List<List<String>>{
            new List<String>{ String.valueOf(ids.get('choice2Id')), 'Option2' }
        };
        List<Id> responseIdList = new List<Id>{ ids.get('responseId') };

        Test.startTest();
        Test_BMA_AccelerateController.updateResponseChoiceForCheckboxType(trueList, falseList, responseIdList);
        Test.stopTest();
    }

    @IsTest
    static void test_updateResponseChoiceForTextType() {
        Map<String, Id> ids = createTestData();
        List<List<String>> responseList = new List<List<String>>{
            new List<String>{ String.valueOf(ids.get('responseId')), 'UpdatedValue' }
        };

        Test.startTest();
        List<bma_Response_Choice__c> updated =
            Test_BMA_AccelerateController.updateResponseChoiceForTextType(responseList);
        Test.stopTest();
    }

    @IsTest
    static void test_saveCurrentSequence() {
        Map<String, Id> ids = createTestData();
        Test.startTest();
        List<bma_Response__c> updated =
            Test_BMA_AccelerateController.saveCurrentSequence(ids.get('intakeId'), 5);
        Test.stopTest();
    }

    @IsTest
    static void test_saveCurrentField() {
        Map<String, Id> ids = createTestData();
        Test.startTest();
        List<bma_Response__c> updated =
            Test_BMA_AccelerateController.saveCurrentField(
                String.valueOf(ids.get('sectionId')),
                ids.get('intakeId'),
                '10'
            );
        Test.stopTest();
    }
}