/**
*    @author: Rohan Rathod
*    @date:   13-Dec-2021
*    @description:  TestClass for AddElevationMemberHelper
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Rohan Rathod             13-Dec-2021           Initial Build
*            Rohan Rathod             20-Sept-2022          Code Coverage Increase
*    ------------------------------------------------------------------------------------ 
*                    
*/

@isTest
public with sharing class TestAddElevationMemberHelper {
    public static final String BUSINESS_ISSUE = 'Business Issue';
    static Case cs;
    public static String workOrderId;
    public static String strcontactId;
    public static final String STRING_ACCOUNT = 'Test Acc';
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
    public static final String STRING_WO_ORDER_TYPE = 'Service Activities';
    public static final String STRING_WO_RECORDTYPE_REMOTE_SUPPORT = 'Remote Support';
    
    /**
*  @author Rohan Rathod
*  @description Test data initialization method
*  @param 
*  @return 
**/ 
    @testSetup
    public static void initializeTestData()
    {                  
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
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
            System.assertNotEquals(null, con.id, 'Contact one should not be Null');
                        
            Contact con2 = new Contact(
                FirstName = 'NewName',
                LastName = 'TestLastNewName',
                AccountId = acc.Id,
                Email = 'abc@dcba.com',
                Phone = '1234567890',
                MailingCountryCode = 'US'
            );
            insert con2;
            System.assertNotEquals(null, con2.id, 'Contact second should not be Null');          
            //insert case        
            cs = TestDataCase.initServiceRequestCase(con);
            insert cs;
            strcontactId = con.Id;
            System.debug('ContactId 1-->'+strcontactId);
    }
    
    
    /**
*  @author Rohan Rathod
*  @description Test method for DeserializeElevationMembers for related contact creation
*  @param String
*  @return void
**/     
    @isTest
    public static void checkDeserializeElevationMembers(){
        User u = TestDataFieldService.createUser(System.label.Field_Service,false);
        Insert u;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'SS_Product_Support'];
        insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);
        System.runAs(u)
        {     
            
            Id technicalElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Technical Elevation').getRecordTypeId();
            List<string> lstInput = new List<String>();  
           /* Moved this code from below to here to avoid redundancy and avoid exception: DCP-52608  start */
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

            SVMXC__Service_Order__c workOrder = [select id,Onsite_Response_Due_Date__c,SVMXC__SM_SLA_Onsite_Response__c,
            SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
            SVMXC__Order_Status__c from 
            SVMXC__Service_Order__c where SVMXC__Case__c =: objCase.Id Limit 1];
            /* DCP-52608 end */

            Elevations__c techElev = new Elevations__c();
            techElev.RecordTypeId = technicalElevationRecordType;
            techElev.Elevation_Category__c = 'Standard Technical';
            techElev.Elevation_Status__c = 'Open';
            techElev.Work_Order__c = workOrder.Id; // DCP-52608
            insert techElev;
            
            System.assert(objCase.Id!=null, 'Case should not be null');
            workOrder.Technical_Elevation__c = techElev.Id;
            Test.startTest();
                update workOrder;            
                System.assert(workOrder.id != null, 'Work Order should not be null'); 
                workOrderId = workOrder.id;                                 
                lstInput.add('[{"typePiclst":"Watcher (Account);Watcher (Technical)","woRecId":"' + workOrderId + '", "tempAllIds":"'+ conObj.Id +'"}]');             
                AddElevationMemberHelper.DeserializeElevationMembers(lstInput);
            Test.stopTest();
            Related_Contacts__c objRC = [select id from Related_Contacts__c where Elevated_Work_Order__c=:workOrderId];
            system.assert(objRC.id != null, 'Related contacts should not be null');
          
        }     
    }
    
    /**
    * @description 
    * @author Rohan Rathod | 09-22-2022 
    **/
    @isTest static void checkExceptionElevationMembers(){
        User u = TestDataFieldService.createUser(System.label.Field_Service,false);
        Insert u;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'SS_Product_Support'];
        insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);        
        System.runAs(u)
        {     
            
            Id technicalElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Technical Elevation').getRecordTypeId();
            List<string> lstInput = new List<String>();  
           /* Moved this code from below to here to avoid redundancy and avoid exception: DCP-52608  start */
            Contact conObj= [SELECT id,AccountId FROM Contact where FirstName = 'NewName'];
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

            SVMXC__Service_Order__c workOrder = [select id,Onsite_Response_Due_Date__c,SVMXC__SM_SLA_Onsite_Response__c,
            SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
            SVMXC__Order_Status__c from 
            SVMXC__Service_Order__c where SVMXC__Case__c =: objCase.Id Limit 1];
            /* DCP-52608 end */

            Elevations__c techElev = new Elevations__c();
            techElev.RecordTypeId = technicalElevationRecordType;
            techElev.Elevation_Category__c = 'Standard Technical';
            techElev.Elevation_Status__c = 'Open';
            techElev.Work_Order__c = workOrder.Id; // DCP-52608
            insert techElev;
            
            System.assertNotEquals(null, objCase.Id, 'Case should not be null');
            workOrder.Technical_Elevation__c = techElev.Id;
            
            Test.startTest();
            update workOrder;            
            System.assertNotEquals(null, workOrder.id, 'Work Order should not be null'); 
            workOrderId = workOrder.id;                                 
            lstInput.add('[{"typePiclst":"Watcher (Account);Watcher (Technical)","woRecId":"' + workOrderId + '", "tempAllIds":"'+ conObj.Id +'"}]');

            try{
                AddElevationMemberHelper.DeserializeElevationMembers(lstInput);
            }
            catch(Exception ee){
                System.assert(ee.getMessage().contains('Please do not add a customer contact or Third Party Field Service user as a Watcher for this elevation'),'Custom Validation Exception not verified');
            }                             
            Test.stopTest();                                 
        }     
    }  
    
}