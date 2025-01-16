/**
*    @date   18-Jan-20 
*    @description    Test for Controller class of LWC lookUpFilter
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Akshay                         18-Jan-20           Initial build
*             Saddam                         10-oct-22           COdescan Fix,Comments Added.
*    ------------------------------------------------------------------------------------
*
*/
@isTest
public with sharing class TestLookupFilterController {

    /*
    *  @description  : Test SetupData Method 
    */
    @TestSetup
    static void makeData(){
        Account objAccount = TestDataAccount.getAccount('Dummy');
        objAccount.AccountNumber ='Yowy Wowy';
        insert objAccount;
        Contact objCon = TestDataPerson.initContact(objAccount.Id);
        insert objCon;
    }

    /*
    *  @description  : Test Method checkValidValues()
    */
    @isTest
    public static void checkValidValues(){
        Account objAccount = [SELECT ID,Name,AccountNumber FROM Account WHERE Name='Dummy'][0];
        
        LookupFilterController.InputDetails wrapInputs= new LookupFilterController.InputDetails();
        wrapInputs.strLookupApiName = 'OwnerId';
        wrapInputs.strObjectApiName = 'User';
        wrapInputs.strFieldFilters = 'CompanyName = Name AND AboutMe = \'abc\'';
        wrapInputs.strSearchFields = 'Name,AboutMe';
        wrapInputs.strDisplayFields='Name,AboutMe';
        wrapInputs.strOrderBy='CompanyName DESC, CreatedDate ASC';

        Test.startTest();
        String strResult1 =LookupFilterController.loadPage(objAccount.id, JSON.serialize(wrapInputs));
        System.debug('strResult1: ' + strResult1);
        String strJSON = UtilsObject.getJSONPart(strResult1, '{"wrapFields" : ', ',"strValue" : "');
        LookupFilterController.OutputFields wrapFields = (LookupFilterController.OutputFields)JSON.deserialize(strJSON, LookupFilterController.OutputFields.class);
        LookupFilterController.doSearch(objAccount.id, JSON.serialize(wrapInputs),JSON.serialize(wrapFields));
        
        wrapInputs.strFieldFilters = 'Name = \'Mine\' OR CreatedDate <= TODAY';
        wrapInputs.strSearchFields = 'Name,CreatedDate';
        wrapInputs.strDisplayFields='Name,CompanyName';
        wrapInputs.strOrderBy='CreatedDate';
        String strResult2 =LookupFilterController.loadPage(objAccount.id, JSON.serialize(wrapInputs));
        System.debug('strResult2: ' + strResult2);
        wrapInputs.strSearch = 'Dummy';
        Test.stopTest();
        
        strJSON = UtilsObject.getJSONPart(strResult1, '{"wrapFields" : ', ',"strValue" : "');
        System.debug('strJSON: ' + strJSON);
        wrapFields = (LookupFilterController.OutputFields)JSON.deserialize(strJSON, LookupFilterController.OutputFields.class);
        System.assertEquals(0, wrapFields.lstErrors.size(),'Errors found when not expected '+wrapFields.lstErrors);
        System.assertEquals(1, wrapFields.mapFieldToPositions.size(),'Incorrect source fields '+wrapFields.mapFieldToPositions);

        strJSON = UtilsObject.getJSONPart(strResult2, '{"wrapFields" : ', ',"strValue" : "');
        System.debug('strJSON: ' + strJSON);
        wrapFields = (LookupFilterController.OutputFields)JSON.deserialize(strJSON, LookupFilterController.OutputFields.class);
        System.assertEquals(0, wrapFields.mapFieldToPositions.size(),'Incorrect source fields '+wrapFields.mapFieldToPositions);
    }

    /*
    *  @description  : Test Method checkInvalidValues()
    */
    @isTest
    public static void checkInvalidValues(){
        Account objAccount = [SELECT ID,Name,AccountNumber FROM Account WHERE Name='Dummy'][0];
        
        LookupFilterController.InputDetails wrapInputs= new LookupFilterController.InputDetails();
        wrapInputs.strLookupApiName = 'Owner';
        wrapInputs.strObjectApiName = 'User';
        wrapInputs.strFieldFilters = 'Jargon = who cares ';
        wrapInputs.strSearchFields = 'Name,Blah';
        wrapInputs.strDisplayFields='Blah,AboutMe';
        wrapInputs.strOrderBy='Blu';

        Test.startTest();
        String strResult1 = LookupFilterController.loadPage(objAccount.id, JSON.serialize(wrapInputs));
        System.debug('strResult1: ' + strResult1);
        wrapInputs.strFieldFilters = 'Jargon = who care AND I -- do';
        wrapInputs.strOrderBy='good DESC, luck ASC';
        String strResult2 =LookupFilterController.loadPage(objAccount.id, JSON.serialize(wrapInputs));
        Test.stopTest();
        
        String strJSON = UtilsObject.getJSONPart(strResult1, '{"wrapFields" : ', ',"strValue" : "');
        System.debug('strJSON: ' + strJSON);
        LookupFilterController.OutputFields wrapFields = (LookupFilterController.OutputFields)JSON.deserialize(strJSON, LookupFilterController.OutputFields.class);
        System.assertEquals(6, wrapFields.lstErrors.size(),'Errors not found as expected '+wrapFields.lstErrors);
        
        strJSON = UtilsObject.getJSONPart(strResult2, '{"wrapFields" : ', ',"strValue" : "');
        System.debug('strJSON: ' + strJSON);
        wrapFields = (LookupFilterController.OutputFields)JSON.deserialize(strJSON, LookupFilterController.OutputFields.class);
        System.assertEquals(8, wrapFields.lstErrors.size(),'Errors not found as expected '+wrapFields.lstErrors);
    }

    /*
    *  @description  : Test Method checkSearch()
    */
    @isTest
    public static void checkSearch(){
        
        Contact objContact = [SELECT ID,Name FROM Contact WHERE Name<>NULL][0];
        
        LookupFilterController.InputDetails wrapInputs= new LookupFilterController.InputDetails();
        wrapInputs.strLookupApiName = 'AccountId';
        wrapInputs.strObjectApiName = 'Account';
        wrapInputs.strFieldFilters = 'Name = \'Dummy\' AND BillingCity = \'YUMMY\'';
        wrapInputs.strSearchFields = 'AccountNumber';
        wrapInputs.strDisplayFields='AccountNumber,BillingCity,Owner.Name';
        wrapInputs.strOrderBy='AccountNumber ASC';

        String strResult1 = LookupFilterController.loadPage(objContact.id, JSON.serialize(wrapInputs));
        String strJSON = UtilsObject.getJSONPart(strResult1, '{"wrapFields" : ', ',"strValue" : "');
        LookupFilterController.OutputFields wrapFields = (LookupFilterController.OutputFields)JSON.deserialize(strJSON, LookupFilterController.OutputFields.class);
        Test.startTest();
        wrapInputs.strSearch='Yowy Wowy';
        strResult1 = LookupFilterController.doSearch(objContact.id, JSON.serialize(wrapInputs),JSON.serialize(wrapFields));
        wrapInputs.strFieldFilters = 'Name = \'Dummy\' OR BillingCity = \'YUMMY\'';
        Test.stopTest();

        List<Map<String,Object>> lstResults = (List<Map<String,Object>>) JSON.deserialize(strResult1, List<Map<String,Object>>.class);
        System.assertEquals(0, lstResults.size(),'Results found when not expected');
    }
    
    /*
    *  @description  : Test Method checkSave()
    */
    @isTest
    public static void checkSave(){
        Contact objContact = [SELECT ID,Name FROM Contact WHERE Name<>NULL][0];
        
        Account objAccount = [SELECT ID,Name FROM Account WHERE Name<>NULL][0];
        LookupFilterController.InputDetails wrapInputs= new LookupFilterController.InputDetails();
        wrapInputs.strLookupApiName = 'AccountId';
        wrapInputs.strObjectApiName = 'Account';
        wrapInputs.strFieldFilters = 'Name = \'Dummy\' AND BillingCity = \'YUMMY\'';
        wrapInputs.strSearchFields = 'AccountNumber';
        wrapInputs.strDisplayFields='AccountNumber,BillingCity,Owner.Name';
        wrapInputs.strOrderBy='AccountNumber ASC';

        String strResult1 = LookupFilterController.loadPage(objContact.id, JSON.serialize(wrapInputs));
        String strJSON = UtilsObject.getJSONPart(strResult1, '{"wrapFields" : ', ',"strValue" : "');
        LookupFilterController.OutputFields wrapFields = (LookupFilterController.OutputFields)JSON.deserialize(strJSON, LookupFilterController.OutputFields.class);
        wrapFields.strLookupId=objAccount.id;
        Test.startTest();
        String strResult = LookupFilterController.doSave(objContact.id, JSON.serialize(wrapInputs),JSON.serialize(wrapFields));
        Test.stopTest();
        System.assertEquals('Success', strResult,'Save not working');
    }

    /*
    *  @description  : Test Method checkWhereExpressionParsing()
    */
    @isTest
    public static void checkWhereExpressionParsing(){
        Map<String,Set<Integer>> mapFields = new Map<String,Set<Integer>>();
        Pattern bracketPattern = Pattern.compile('\\((.*?)\\)');
        LookupFilterController.OutputFields wrapFields = new LookupFilterController.OutputFields();
        Map<String,Set<String>> mapAllFields = new Map<String,Set<String>>();
        mapAllFields.put(LookupFilterController.LHS, new Set<String>());
        mapAllFields.put(LookupFilterController.RHS, new Set<String>());
        Test.startTest();
        String strCondition = 'Custom_Field1__c=Custom_Field2__c AND (Custom_Field3__c>=Custom_Field4__c OR (Custom_Field5__c<>\'123\' AND Custom_Field6__c<=Custom_Field7__c)) AND (Custom_Field8__c!=Custom_Field9__c OR Custom_Field10__c>Custom_Field11__c) AND Custom_Field11__c<Custom_Field10__c';
        LookupFilterController.evaluateExpression(strCondition,mapAllFields,mapFields,bracketPattern,wrapFields,0);
        System.debug('mapFields: ' + mapFields);
        Map<Integer,String> cleanMap = LookupFilterController.cleanFieldPositions(strCondition,mapFields);
        System.debug('cleanMap: ' + cleanMap);
        Map<String,String> mapFieldToValues = new Map<String,String>();
        Integer dummyValue=1;
        for(String strField : cleanMap.values())
            mapFieldToValues.put(strField,strField+dummyValue++);
        String strFinalExpression = LookupFilterController.setFieldValues(strCondition,cleanMap,mapFieldToValues);
        Test.stopTest();
        System.debug('strFinalExpression: ' +strFinalExpression);
        Set<String> setFields = new Set<String>(cleanMap.values());
        for(String strField : mapFields.keySet()){
            System.assert(setFields.contains(strField),'Field not found: '+strField);
            System.assert(strFinalExpression.contains('\''+strField),'Value not set: '+strField);
        }
        System.assert(strFinalExpression.contains('Custom_Field5__c<>\'123\''),'Literal value replaced');   
        System.assert(strFinalExpression.contains('Custom_Field11__c'),'Custom_Field11__c LHS replaced');   
    }
}