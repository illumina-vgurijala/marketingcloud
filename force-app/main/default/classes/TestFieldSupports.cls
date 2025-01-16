/***************************************************************************************************************************************
* NAME   : TestFieldSupports
* DESCRIPTION  : TestClass for FieldSupport Trigger
*          
*    
* @AUTHOR : Ritika
* @DATE   : 18-Jan-2023  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Ritika                   18-Jan-2023             Initial Version
****************************************************************************************************************************************/ 

@isTest(SeeAllData = false)  
public with sharing class TestFieldSupports {
    
    /**
    *    @author Ritika
    *    @date   28-Jan-2023
    *    @description Check for Duplicate Field Support Positive Scenario 1
    */ 
    static testMethod void checkForClosedDuplicateFieldSupportPositiveScenario1(){ 
        List<User> lstUsers = [SELECT Id 
                               FROM User 
                               WHERE Profile.Name =: System.label.Field_Service
                               LIMIT 1];
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        SVMXC__Service_Group_Members__c technician1 =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
        technician1.SVMXC__Email__c='b@b.com';
        technician1.SVMXC__Active__c = true;
        insert technician1;

        Test.startTest();
        try{
            SVMXC__Service_Group_Members__c technician2 =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
            technician2.SVMXC__Email__c='b@b.com';
            technician2.SVMXC__Active__c = true;
            insert technician2;
        }catch(Exception ex){
            system.assert(ex.getMessage().containsIgnoreCase(System.label.Duplicate_Field_Support_Error),'Duplicate Record Found');
        }
        Test.stopTest();
    } 

    /**
    *    @author Ritika
    *    @date   28-Jan-2023
    *    @description Check for Duplicate Field Support Positive Scenario 2
    */ 
    static testMethod void checkForClosedDuplicateFieldSupportPositiveScenario2(){ 
        List<User> lstUsers = [SELECT Id 
                               FROM User 
                               WHERE Profile.Name =: System.label.Field_Service
                               LIMIT 1];
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        Test.startTest();
        try{
            List<SVMXC__Service_Group_Members__c> lstTechnicians = new List<SVMXC__Service_Group_Members__c>();
            SVMXC__Service_Group_Members__c technician1 =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
            technician1.SVMXC__Email__c='b@b.com';
            technician1.SVMXC__Active__c = true;
            lstTechnicians.add(technician1);
            SVMXC__Service_Group_Members__c technician2 =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
            technician2.SVMXC__Email__c='b@b.com';
            technician2.SVMXC__Active__c = true;
            lstTechnicians.add(technician2);
            insert lstTechnicians;
        }catch(Exception ex){
            system.assert(ex.getMessage().containsIgnoreCase(System.label.Duplicate_Field_Support_Error),'Duplicate Record Found');
        }
        Test.stopTest();
    }

    /**
    *    @author Ritika
    *    @date   28-Jan-2023
    *    @description Check for Duplicate Field Support Update Scenario
    */ 
    static testMethod void checkForClosedDuplicateFieldSupportUpdateScenario(){ 
        List<User> lstUsers = [SELECT Id 
                               FROM User 
                               WHERE Profile.Name =: System.label.Field_Service
                               LIMIT 1];
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        SVMXC__Service_Group_Members__c technician1 =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
        technician1.SVMXC__Email__c='b@b.com';
        technician1.SVMXC__Active__c = true;
        insert technician1;

        Test.startTest();
        SVMXC__Service_Group_Members__c technician2 =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
        technician2.SVMXC__Email__c='a@b.com';
        technician2.SVMXC__Active__c = true;
        insert technician2;
        try{
            technician2.SVMXC__Email__c='b@b.com';
            update technician2;
        }catch(Exception ex){
            system.assert(ex.getMessage().containsIgnoreCase(System.label.Duplicate_Field_Support_Error),'Duplicate Record Found');
        }
        Test.stopTest();
    }
}