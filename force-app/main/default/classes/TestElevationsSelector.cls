/***************************************************************************************************************************************
 * NAME   : TestElevationsSelector
 * DESCRIPTION  : TestClass for creating Elevations
 *           
 *    
 * @AUTHOR : Vatsal Shah
 * @DATE   : 28-February-2022  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Vatsal Shah            28-February-2022             Initial Version
 * Sheikh Shahnawaz       08-March-2022                DCP-52608
 */
@isTest
public with sharing class TestElevationsSelector {

    public static final String BUSINESS_ISSUE = 'Business Issue'; // DCP-52608
    static Case cs; // DCP-52608

        /**
    *  @author Sheikh Shahnawaz
    *  @description Test data initialization method DCP-52608
    *  @param 
    *  @return 
    **/ 
    @testSetup
    public static void initializeTestData()
    {                  
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
            acc.Account_Group__c='Distributor';
            insert acc;            
            Contact con = new Contact(
                FirstName = 'TestFirstName',
                LastName = 'TestLastName',
                AccountId = acc.Id,
                Email = 'abc@illumina.com',
                Phone = '1234567890',
                MailingCountryCode = 'US'
            );
            insert con;
            System.assert(con.id != null);          
            //insert case        
            cs = TestDataCase.initServiceRequestCase(con);
            insert cs;
    }



    /*
    *  @AUTHOR:  Vatsal  
    *  @DESCRIPTION: To cover the method of class ElevationsSelector
    *  @METHOD: selectElevationByElevationStatus
    *  @RETURN:  void
    */
    static testMethod void testselectElevationByElevationStatus() {
        User u = TestDataFieldService.createUser('System Administrator',false);
            Insert u;
            Set<Id> idSet = new Set<Id>();
            
            System.runAs(u)
            {
                Id technicalElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Technical Elevation').getRecordTypeId();
               
                /* DCP-52608  start*/

                Contact conObj= [SELECT id,AccountId FROM Contact LIMIT 1];
                Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BUSINESS_ISSUE).getRecordTypeId();
                Case objCase  = new Case(
                
                    Status = 'Initiated',
                    Subject = 'test' ,
                    Description= 'test',
                    Origin = 'Phone-CP',
                    Date_of_Issue_Awareness__c=System.today() -2,
                    Awareness_Date_Difference_Reason__c = 'Logistical delay',
                    ContactId = conObj.Id,
                    RecordTypeId = idCaseRecordTypeId
                );
                insert objCase;
                System.assertNotEquals(null, objCase.Id, 'Case Object should not be empty');

                SVMXC__Service_Order__c workOrder = [select id,Onsite_Response_Due_Date__c,SVMXC__SM_SLA_Onsite_Response__c,
                SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
                SVMXC__Order_Status__c from 
                SVMXC__Service_Order__c where SVMXC__Case__c =: objCase.Id Limit 1];
                /* DCP-52608  end*/

                Elevations__c techElev = new Elevations__c();
                techElev.RecordTypeId = technicalElevationRecordType;
                techElev.Elevation_Category__c = 'Standard Technical';
                techElev.Elevation_Status__c = 'Open';
                techElev.Work_Order__c = workOrder.Id; // DCP-52608
                insert techElev;
                System.assert(techElev.Id != null, 'Technical Elevation should not be null');
                idSet.add(techElev.Id);
            }
            ElevationsSelector evs = new ElevationsSelector();
            list<Elevations__c> lstOpenElevations = evs.selectElevationByElevationStatus(idSet, 'Open');
            system.assert(!lstOpenElevations.isEmpty(), 'List should not be empty');
            List<Elevations__c> lstElevationCategory = evs.selectElevationByCategory(idSet, 'Standard Technical');
            system.assert(!lstElevationCategory.isEmpty(), 'List should not be empty');
            evs.selectElevations(idSet);
			
    }
}