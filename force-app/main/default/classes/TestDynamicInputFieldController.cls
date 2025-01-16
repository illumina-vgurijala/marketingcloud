/**
*    @author Gladis
*    @date   2021-07-02
*    @description  DCP-38876: Test Class for Dynamic Input Field
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Gladis                       2021-07-02          InitialVersion
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestDynamicInputFieldController {


    /**
     *  @author      : Gladis
     *  @description : method to test getPicklistOptions and save
     **/
    @isTest
    static void testDoSave(){
        Set<String> strReturnedValues = new Set<String>();
        Test.startTest();

        String returnValue = DynamicInputFieldController.getFieldType('Delivery_Loading_Dock__c');
        System.debug('returnValue: '+returnValue);
        
        Map<String, Object> mapAllValues = (Map < String, Object >)JSON.deserializeUntyped( returnValue );
        System.debug('fullMap -> '+mapAllValues);
        for(Object obj : (List<Object>)mapAllValues.get('lstPickvals')) 
        {
            Map <String, Object> mapValues = (Map <String, Object>)obj;
            strReturnedValues.add((String)mapValues.get('strValue'));
        }  

        Test.stopTest();
        System.assert(strReturnedValues.contains('Yes'),'Incorrect Picklist Value For Yes');
        System.assert(strReturnedValues.contains('No'),'Incorrect Picklist Value For No');
           
    }
}