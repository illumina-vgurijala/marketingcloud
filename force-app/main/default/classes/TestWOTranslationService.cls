/**
* @author Shivani Jain
* @date 21st Sep 2022
*
* @description
*/
@IsTest
public with sharing class TestWOTranslationService {
    /**
    *  @description - initialize test data
    **/
    @testSetup
    public static void initializeTestData() {
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = 'Test team',
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND IsActive=true LIMIT 1];
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = lstUsers[0].Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        
       
    }
    /**
    *  @description - testHandleTranslationActionError method
    **/
    static testMethod void testHandleTranslationActionError() {
        Account acc = TestDataAccount.getCustomerAccount();
        insert acc;

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact INsertion failed');
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c = true;
        insert workOrder;
        System.assert(workOrder.Id != null,'workorder id is null');

        Test.startTest();

        //SFM Request object
        SVMXC.SFM_WrapperDef.SFM_TargetRecord request = new SVMXC.SFM_WrapperDef.SFM_TargetRecord();

        // ***** HEADER OBJECT ********************************
        // SFM Header Record and associate to the SFM request
        SVMXC.SFM_WrapperDef.SFM_TargetRecordObject header = new SVMXC.SFM_WrapperDef.SFM_TargetRecordObject();
        header.objName = 'SVMXC__Service_Order__c';

        // SFM Records and associate to the SFM Header Record
        List<SVMXC.SFM_WrapperDef.SFM_StringMap> recordsAsKeyValue = new List<SVMXC.SFM_WrapperDef.SFM_StringMap>();
        SVMXC.SFM_WrapperDef.SFM_Record record = new SVMXC.SFM_WrapperDef.SFM_Record();
        record.targetRecordId = workOrder.id;
        
        // SFM Record for the SFM Records in Header
        recordsAsKeyValue.add(new SVMXC.SFM_WrapperDef.SFM_StringMap('Id', workOrder.Id));
        record.setTargetRecordAsKeyValue(recordsAsKeyValue);
        header.setRecords(new List<SVMXC.SFM_WrapperDef.SFM_Record> {record});
        request.headerRecord = header;
        
        SVMXC.SFM_WrapperDef.SFM_PageData pageData = WOTranslationService.handleTranslationAction(request);
        System.assert(pageData!= null, 'Transaltion failure');
                  
        Test.stopTest();
    }
    
    /**
    *  @description - testHandleTranslationAction1 method
    **/
    static testMethod void testHandleTranslationAction1() {
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact INsertion failed');
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c = true;
        insert workOrder;
        System.assert(workOrder.Id != null,'workorder id is null');

        Test.startTest();

        //SFM Request object
        SVMXC.SFM_WrapperDef.SFM_TargetRecord request = new SVMXC.SFM_WrapperDef.SFM_TargetRecord();

        // ***** HEADER OBJECT ********************************
        // SFM Header Record and associate to the SFM request
        SVMXC.SFM_WrapperDef.SFM_TargetRecordObject header = new SVMXC.SFM_WrapperDef.SFM_TargetRecordObject();
        header.objName = 'SVMXC__Service_Order__c';

        // SFM Records and associate to the SFM Header Record
        List<SVMXC.SFM_WrapperDef.SFM_StringMap> recordsAsKeyValue = new List<SVMXC.SFM_WrapperDef.SFM_StringMap>();
        SVMXC.SFM_WrapperDef.SFM_Record record = new SVMXC.SFM_WrapperDef.SFM_Record();
        record.targetRecordId = workOrder.id;
        
        // SFM Record for the SFM Records in Header
        recordsAsKeyValue.add(new SVMXC.SFM_WrapperDef.SFM_StringMap('Id', workOrder.Id));
        record.setTargetRecordAsKeyValue(recordsAsKeyValue);
        header.setRecords(new List<SVMXC.SFM_WrapperDef.SFM_Record> {record});
        request.headerRecord = header;


        SVMXC.SFM_WrapperDef.SFM_PageData pageData = WOTranslationService.handleTranslationAction(request);
        System.assert(pageData!= null, 'Transaltion failure');          

        Test.stopTest();
    }
    
    /**
    *  @description - testHandleTranslationAction method
    **/
    static testMethod void testHandleTranslationAction() {
        Account acc = TestDataAccount.getCustomerAccount();
        insert acc;

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact INsertion failed');
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;


        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c = true;
        insert workOrder;
        System.assert(workOrder.Id != null,'workorder id is null');

        Test.startTest();
        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Authorization' => 'Bearer gQtXZ1oTB4QzFfSSmg6ZCppUICIy1Cvo',
            'Accept' => 'application/json'
        };

        String jsonResponse = '{   \"project_id\": \"5857770162ba154068f7a6.35574900\",   \"keys\": [     {       \"key_id\": 215085875,       \"created_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",       \"created_at_timestamp\": 1663138927,       \"key_name\": {         \"ios\": \"Test14Sep22\",         \"android\": \"Test14Sep22\",         \"web\": \"Test14Sep22\",         \"other\": \"Test14Sep22\"       },       \"filenames\": {         \"ios\": \"\",         \"android\": \"\",         \"web\": \"\",         \"other\": \"\"       },       \"description\": \"Chinese to English Translation for Test14Sep22\",       \"platforms\": [         \"web\"       ],       \"tags\": [               ],       \"comments\": [               ],       \"screenshots\": [               ],       \"translations\": [         {           \"translation_id\": 1714045740,           \"segment_number\": 1,           \"key_id\": 215085875,           \"language_iso\": \"zh_TW\",           \"translation\": \"\",           \"modified_by\": 203380,           \"modified_by_email\": \"sdineshmadkaikar@deloitte.com\",           \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",           \"modified_at_timestamp\": 1663138927,           \"is_reviewed\": false,           \"reviewed_by\": 0,           \"is_unverified\": true,           \"is_fuzzy\": true,           \"words\": 0,           \"custom_translation_statuses\": [                       ],           \"task_id\": null         },         {           \"translation_id\": 1714045741,           \"segment_number\": 1,           \"key_id\": 215085875,           \"language_iso\": \"zh_CN\",           \"translation\": \"这是工单主题的中英翻译#$#\",           \"modified_by\": 203380,           \"modified_by_email\": \"sdineshmadkaikar@deloitte.com\",           \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",           \"modified_at_timestamp\": 1663138927,           \"is_reviewed\": false,           \"reviewed_by\": 0,           \"is_unverified\": false,           \"is_fuzzy\": false,           \"words\": 11,           \"custom_translation_statuses\": [                       ],           \"task_id\": null         },         {           \"translation_id\": 1714045739,           \"segment_number\": 1,           \"key_id\": 215085875,           \"language_iso\": \"ja\",           \"translation\": \"\",           \"modified_by\": 203380,           \"modified_by_email\": \"sdineshmadkaikar@deloitte.com\",           \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",           \"modified_at_timestamp\": 1663138927,           \"is_reviewed\": false,           \"reviewed_by\": 0,           \"is_unverified\": true,           \"is_fuzzy\": true,           \"words\": 0,           \"custom_translation_statuses\": [                       ],           \"task_id\": null         },         {           \"translation_id\": 1714045742,           \"segment_number\": 1,           \"key_id\": 215085875,           \"language_iso\": \"en_US\",           \"translation\": \"This is the @&%#Chinese-English translation\",           \"modified_by\": 1,           \"modified_by_email\": \"support@lokalise.co\",           \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",           \"modified_at_timestamp\": 1663138927,           \"is_reviewed\": false,           \"reviewed_by\": 0,           \"is_unverified\": false,           \"is_fuzzy\": false,           \"words\": 9,           \"custom_translation_statuses\": [                       ],           \"task_id\": null         }       ],       \"is_plural\": false,       \"plural_name\": \"\",       \"is_hidden\": false,       \"is_archived\": false,       \"context\": \"\",       \"base_words\": 11,       \"char_limit\": 0,       \"custom_attributes\": \"\",       \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",       \"modified_at_timestamp\": 1663138927,       \"translations_modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",       \"translations_modified_at_timestamp\": 1663138927     }   ],   \"errors\": [] }';
        TestWOTranslationDataSender.SingleRequestMock fakeResponse = new TestWOTranslationDataSender.SingleRequestMock(200,'ok',jsonResponse,headerKeyToValue);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        //SFM Request object
        SVMXC.SFM_WrapperDef.SFM_TargetRecord request = new SVMXC.SFM_WrapperDef.SFM_TargetRecord();

        // ***** HEADER OBJECT ********************************
        // SFM Header Record and associate to the SFM request
        SVMXC.SFM_WrapperDef.SFM_TargetRecordObject header = new SVMXC.SFM_WrapperDef.SFM_TargetRecordObject();
        header.objName = 'SVMXC__Service_Order__c';

        // SFM Records and associate to the SFM Header Record
        List<SVMXC.SFM_WrapperDef.SFM_StringMap> recordsAsKeyValue = new List<SVMXC.SFM_WrapperDef.SFM_StringMap>();
        SVMXC.SFM_WrapperDef.SFM_Record record = new SVMXC.SFM_WrapperDef.SFM_Record();
        record.targetRecordId = workOrder.id;
        
        // SFM Record for the SFM Records in Header
        recordsAsKeyValue.add(new SVMXC.SFM_WrapperDef.SFM_StringMap('Id', workOrder.Id));
        recordsAsKeyValue.add(new SVMXC.SFM_WrapperDef.SFM_StringMap('Account_Country__c', 'Japan'));
        record.setTargetRecordAsKeyValue(recordsAsKeyValue);
        header.setRecords(new List<SVMXC.SFM_WrapperDef.SFM_Record> {record});
        request.headerRecord = header;


        SVMXC.SFM_WrapperDef.SFM_PageData pageData = WOTranslationService.handleTranslationAction(request);
        System.assert(pageData!= null, 'Transaltion failure');
        
        Test.stopTest();
    }

    /**
    *  @description - testHandleTranslationActionTrue method
    **/
    static testMethod void testHandleTranslationActionTrue() {
        Account acc = TestDataAccount.getCustomerAccount();
        insert acc;

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact INsertion failed');
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c = true;
        insert workOrder;
        System.assert(workOrder.Id != null,'workorder id is null');

        Test.startTest();
        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Authorization' => 'Bearer gQtXZ1oTB4QzFfSSmg6ZCppUICIy1Cvo',
            'Accept' => 'application/json'
        };

        String jsonResponse = '{   \"project_id\": \"5857770162ba154068f7a6.35574900\",   \"keys\": [     {       \"key_id\": 215085875,       \"created_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",       \"created_at_timestamp\": 1663138927,       \"key_name\": {         \"ios\": \"Test14Sep22\",         \"android\": \"Test14Sep22\",         \"web\": \"Test14Sep22\",         \"other\": \"Test14Sep22\"       },       \"filenames\": {         \"ios\": \"\",         \"android\": \"\",         \"web\": \"\",         \"other\": \"\"       },       \"description\": \"Chinese to English Translation for Test14Sep22\",       \"platforms\": [         \"web\"       ],       \"tags\": [               ],       \"comments\": [               ],       \"screenshots\": [               ],       \"translations\": [         {           \"translation_id\": 1714045740,           \"segment_number\": 1,           \"key_id\": 215085875,           \"language_iso\": \"zh_TW\",           \"translation\": \"\",           \"modified_by\": 203380,           \"modified_by_email\": \"sdineshmadkaikar@deloitte.com\",           \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",           \"modified_at_timestamp\": 1663138927,           \"is_reviewed\": false,           \"reviewed_by\": 0,           \"is_unverified\": true,           \"is_fuzzy\": true,           \"words\": 0,           \"custom_translation_statuses\": [                       ],           \"task_id\": null         },         {           \"translation_id\": 1714045741,           \"segment_number\": 1,           \"key_id\": 215085875,           \"language_iso\": \"zh_CN\",           \"translation\": \"这是工单主题的中英翻译#$#\",           \"modified_by\": 203380,           \"modified_by_email\": \"sdineshmadkaikar@deloitte.com\",           \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",           \"modified_at_timestamp\": 1663138927,           \"is_reviewed\": false,           \"reviewed_by\": 0,           \"is_unverified\": false,           \"is_fuzzy\": false,           \"words\": 11,           \"custom_translation_statuses\": [                       ],           \"task_id\": null         },         {           \"translation_id\": 1714045739,           \"segment_number\": 1,           \"key_id\": 215085875,           \"language_iso\": \"ja\",           \"translation\": \"\",           \"modified_by\": 203380,           \"modified_by_email\": \"sdineshmadkaikar@deloitte.com\",           \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",           \"modified_at_timestamp\": 1663138927,           \"is_reviewed\": false,           \"reviewed_by\": 0,           \"is_unverified\": true,           \"is_fuzzy\": true,           \"words\": 0,           \"custom_translation_statuses\": [                       ],           \"task_id\": null         },         {           \"translation_id\": 1714045742,           \"segment_number\": 1,           \"key_id\": 215085875,           \"language_iso\": \"en_US\",           \"translation\": \"This is the @&%#Chinese-English translation\",           \"modified_by\": 1,           \"modified_by_email\": \"support@lokalise.co\",           \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",           \"modified_at_timestamp\": 1663138927,           \"is_reviewed\": false,           \"reviewed_by\": 0,           \"is_unverified\": false,           \"is_fuzzy\": false,           \"words\": 9,           \"custom_translation_statuses\": [                       ],           \"task_id\": null         }       ],       \"is_plural\": false,       \"plural_name\": \"\",       \"is_hidden\": false,       \"is_archived\": false,       \"context\": \"\",       \"base_words\": 11,       \"char_limit\": 0,       \"custom_attributes\": \"\",       \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",       \"modified_at_timestamp\": 1663138927,       \"translations_modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",       \"translations_modified_at_timestamp\": 1663138927     }   ],   \"errors\": [] }';
        TestWOTranslationDataSender.SingleRequestMock fakeResponse = new TestWOTranslationDataSender.SingleRequestMock(200,'ok',jsonResponse,headerKeyToValue);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        //SFM Request object
        SVMXC.SFM_WrapperDef.SFM_TargetRecord request = new SVMXC.SFM_WrapperDef.SFM_TargetRecord();

        // ***** HEADER OBJECT ********************************
        // SFM Header Record and associate to the SFM request
        SVMXC.SFM_WrapperDef.SFM_TargetRecordObject header = new SVMXC.SFM_WrapperDef.SFM_TargetRecordObject();
        header.objName = 'SVMXC__Service_Order__c';

        // SFM Records and associate to the SFM Header Record
        List<SVMXC.SFM_WrapperDef.SFM_StringMap> recordsAsKeyValue = new List<SVMXC.SFM_WrapperDef.SFM_StringMap>();
        SVMXC.SFM_WrapperDef.SFM_Record record = new SVMXC.SFM_WrapperDef.SFM_Record();
        record.targetRecordId = workOrder.id;
        
        // SFM Record for the SFM Records in Header
        recordsAsKeyValue.add(new SVMXC.SFM_WrapperDef.SFM_StringMap('Id', workOrder.Id));
        recordsAsKeyValue.add(new SVMXC.SFM_WrapperDef.SFM_StringMap('Account_Country__c', 'Japan'));
        record.setTargetRecordAsKeyValue(recordsAsKeyValue);
        header.setRecords(new List<SVMXC.SFM_WrapperDef.SFM_Record> {record});
        request.headerRecord = header;


        SVMXC.SFM_WrapperDef.SFM_PageData pageData = WOTranslationService.handleTranslationAction(request);
        System.assert(pageData!= null, 'Transaltion failure');
        
        Test.stopTest();
    }

    /**
    *  @description - testHandleTranslationActionFalse method
    **/
    static testMethod void testHandleTranslationActionFalse() {
        Account acc = TestDataAccount.getCustomerAccount();
        insert acc;

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact INsertion failed');
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c = true;
        insert workOrder;
        System.assert(workOrder.Id != null,'workorder id is null');

        Test.startTest();
        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Authorization' => 'Bearer gQtXZ1oTB4QzFfSSmg6ZCppUICIy1Cvo',
            'Accept' => 'application/json'
        };

        String jsonResponse = '{   \"project_id\": \"5857770162ba154068f7a6.35574900\",   \"keys\": [     {       \"key_id\": 215085875,       \"created_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",       \"created_at_timestamp\": 1663138927,       \"key_name\": {         \"ios\": \"Test14Sep22\",         \"android\": \"Test14Sep22\",         \"web\": \"Test14Sep22\",         \"other\": \"Test14Sep22\"       },       \"filenames\": {         \"ios\": \"\",         \"android\": \"\",         \"web\": \"\",         \"other\": \"\"       },       \"description\": \"Chinese to English Translation for Test14Sep22\",       \"platforms\": [         \"web\"       ],       \"tags\": [               ],       \"comments\": [               ],       \"screenshots\": [               ],       \"translations\": [         {           \"translation_id\": 1714045740,           \"segment_number\": 1,           \"key_id\": 215085875,           \"language_iso\": \"zh_TW\",           \"translation\": \"\",           \"modified_by\": 203380,           \"modified_by_email\": \"sdineshmadkaikar@deloitte.com\",           \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",           \"modified_at_timestamp\": 1663138927,           \"is_reviewed\": false,           \"reviewed_by\": 0,           \"is_unverified\": true,           \"is_fuzzy\": true,           \"words\": 0,           \"custom_translation_statuses\": [                       ],           \"task_id\": null         },         {           \"translation_id\": 1714045741,           \"segment_number\": 1,           \"key_id\": 215085875,           \"language_iso\": \"zh_CN\",           \"translation\": \"这是工单主题的中英翻译#$#\",           \"modified_by\": 203380,           \"modified_by_email\": \"sdineshmadkaikar@deloitte.com\",           \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",           \"modified_at_timestamp\": 1663138927,           \"is_reviewed\": false,           \"reviewed_by\": 0,           \"is_unverified\": false,           \"is_fuzzy\": false,           \"words\": 11,           \"custom_translation_statuses\": [                       ],           \"task_id\": null         },         {           \"translation_id\": 1714045739,           \"segment_number\": 1,           \"key_id\": 215085875,           \"language_iso\": \"ja\",           \"translation\": \"\",           \"modified_by\": 203380,           \"modified_by_email\": \"sdineshmadkaikar@deloitte.com\",           \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",           \"modified_at_timestamp\": 1663138927,           \"is_reviewed\": false,           \"reviewed_by\": 0,           \"is_unverified\": true,           \"is_fuzzy\": true,           \"words\": 0,           \"custom_translation_statuses\": [                       ],           \"task_id\": null         },         {           \"translation_id\": 1714045742,           \"segment_number\": 1,           \"key_id\": 215085875,           \"language_iso\": \"en_US\",           \"translation\": \"This is the @&%#Chinese-English translation@&%# of the @&%#ticket theme@&%#Test\",           \"modified_by\": 1,           \"modified_by_email\": \"support@lokalise.co\",           \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",           \"modified_at_timestamp\": 1663138927,           \"is_reviewed\": false,           \"reviewed_by\": 0,           \"is_unverified\": false,           \"is_fuzzy\": false,           \"words\": 9,           \"custom_translation_statuses\": [                       ],           \"task_id\": null         }       ],       \"is_plural\": false,       \"plural_name\": \"\",       \"is_hidden\": false,       \"is_archived\": false,       \"context\": \"\",       \"base_words\": 11,       \"char_limit\": 0,       \"custom_attributes\": \"\",       \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",       \"modified_at_timestamp\": 1663138927,       \"translations_modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",       \"translations_modified_at_timestamp\": 1663138927     }   ],   \"errors\": [] }';
        TestWOTranslationDataSender.SingleRequestMock fakeResponse = new TestWOTranslationDataSender.SingleRequestMock(200,'ok',jsonResponse,headerKeyToValue);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        //SFM Request object
        SVMXC.SFM_WrapperDef.SFM_TargetRecord request = new SVMXC.SFM_WrapperDef.SFM_TargetRecord();

        // ***** HEADER OBJECT ********************************
        // SFM Header Record and associate to the SFM request
        SVMXC.SFM_WrapperDef.SFM_TargetRecordObject header = new SVMXC.SFM_WrapperDef.SFM_TargetRecordObject();
        header.objName = 'SVMXC__Service_Order__c';

        // SFM Records and associate to the SFM Header Record
        List<SVMXC.SFM_WrapperDef.SFM_StringMap> recordsAsKeyValue = new List<SVMXC.SFM_WrapperDef.SFM_StringMap>();
        SVMXC.SFM_WrapperDef.SFM_Record record = new SVMXC.SFM_WrapperDef.SFM_Record();
        record.targetRecordId = workOrder.id;
        
        // SFM Record for the SFM Records in Header
        recordsAsKeyValue.add(new SVMXC.SFM_WrapperDef.SFM_StringMap('Id', workOrder.Id));
        recordsAsKeyValue.add(new SVMXC.SFM_WrapperDef.SFM_StringMap('Account_Country__c', 'Japan'));
        record.setTargetRecordAsKeyValue(recordsAsKeyValue);
        header.setRecords(new List<SVMXC.SFM_WrapperDef.SFM_Record> {record});
        request.headerRecord = header;


        SVMXC.SFM_WrapperDef.SFM_PageData pageData = WOTranslationService.handleTranslationAction(request);
        System.assert(pageData!= null, 'Transaltion failure');
        
        Test.stopTest();
    }

    /**
    *  @description - testHandleTranslationAction method
    **/
    static testMethod void testThrowErrorForBlankTranslation() {
        Account acc = TestDataAccount.getCustomerAccount();
        acc.BillingCountryCode = 'CN';
        insert acc;

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact Insertion failed');
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c = true;
        insert workOrder;
        System.assert(workOrder.Id != null,'workorder id is null');

        Test.startTest();

        //SFM Request object
        SVMXC.SFM_WrapperDef.SFM_TargetRecord request = new SVMXC.SFM_WrapperDef.SFM_TargetRecord();

        // ***** HEADER OBJECT ********************************
        // SFM Header Record and associate to the SFM request
        SVMXC.SFM_WrapperDef.SFM_TargetRecordObject header = new SVMXC.SFM_WrapperDef.SFM_TargetRecordObject();
        header.objName = 'SVMXC__Service_Order__c';

        // SFM Records and associate to the SFM Header Record
        List<SVMXC.SFM_WrapperDef.SFM_StringMap> recordsAsKeyValue = new List<SVMXC.SFM_WrapperDef.SFM_StringMap>();
        SVMXC.SFM_WrapperDef.SFM_Record record = new SVMXC.SFM_WrapperDef.SFM_Record();
        record.targetRecordId = workOrder.id;
        
        // SFM Record for the SFM Records in Header
        recordsAsKeyValue.add(new SVMXC.SFM_WrapperDef.SFM_StringMap('Id', workOrder.Id));
        record.setTargetRecordAsKeyValue(recordsAsKeyValue);
        header.setRecords(new List<SVMXC.SFM_WrapperDef.SFM_Record> {record});
        request.headerRecord = header;


        SVMXC.SFM_WrapperDef.SFM_PageData pageData = WOTranslationService.throwErrorForBlankTranslation(request);
        System.assert(pageData!= null, 'Transaltion failure');
        
        Test.stopTest();
        
    }
}