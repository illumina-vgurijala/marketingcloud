/**
*   @author @todd
*   @date 2018-11-29
*   @description    
*   Modification Log:
*   ------------------------------------------------------------------------------------
*           Developer                   Date                Description
*           @todd                       2018-11-29
*           @prem ranjan                2023-01-09          Code scan fix((APEX) Comment is required)
*   ------------------------------------------------------------------------------------
**/

@isTest
private class TestApttusPLIStagings {
    /**
    * @Author:@todd
    * @Description : Test Method for ApttusPLIStagingTrigger, ApttusPLIStagings
    * @param: NA
    * @return: NA
    */
    @isTest public static void zerosRemoved()
    {
        String material1 = '000000012345678';
        String material2 = '000000010000000';

        List<Apttus_PLI_Staging__c> plis = new List<Apttus_PLI_Staging__c>{
            new Apttus_PLI_Staging__c(MaterialId__c = material1),
            new Apttus_PLI_Staging__c(MaterialId__c = material2)
        };
        insert plis;

        Map<Id, Apttus_PLI_Staging__c> insertedRows = new Map<Id, Apttus_PLI_Staging__c>([SELECT Id, MaterialId__c FROM Apttus_PLI_Staging__c]);
        Apttus_PLI_Staging__c pli1 = insertedRows.get(plis.get(0).Id);
        Apttus_PLI_Staging__c pli2 = insertedRows.get(plis.get(1).Id);

        System.assertEquals('12345678', pli1.MaterialId__c);
        System.assertEquals('10000000', pli2.MaterialId__c);
    }

}