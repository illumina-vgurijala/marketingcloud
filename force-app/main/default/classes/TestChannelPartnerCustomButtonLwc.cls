/***************************************************************************************************************************************
 * NAME   : TestChannelPartnerCustomButtonLwc
 * DESCRIPTION  : Test class for ChannelPartnerCustomButtonLwcController.
 *    
 * @AUTHOR : Nishan Shetty
 * @DATE   : 30-Aug-2021  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Nishan Shetty          30-Aug-2021           Initial Version.
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/ 
  @isTest(SeeAllData = false)  
  public class TestChannelPartnerCustomButtonLwc {
  
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
  
    /*
    *@author: Nishan Shetty
    *@Desc: Test Setup method 
    */
    @testSetup 
    static void setupData() {
        
        //Created Account1
        Account objAccount1 = TestDataAccount.getAccount('Test AccNew', 'USD');
        objAccount1.Account_Group__c='Distributor';
        insert objAccount1;

        //Created Contact1
        Contact objContact = TestDataContact.getNewContact(objAccount1);

        //Created Case
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.Request_Ownership_Status__c='Requested';
        insert objCase;

        //Created Work Order
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, objCase.Id, 'Initiated');
        objWorkOrder.Request_Ownership_Status__c='Requested';
        objWorkOrder.SVMXC__Order_Type__c = 'Installation';
        objWorkOrder.SVMXC__Company__c = objAccount1.id;
        objWorkOrder.Is_Auto_Created__c=true;
        insert objWorkOrder;
        
        //Creating Admin User
        User objUser1 = TestDataUser.findUserInProfile('System Administrator',new Set<Id>{Id.valueOf(UserInfo.getUserId())});
        TestDataUser.allowUserCreation(objUser1.Id); 
         
        //Partner User
        User objUser;

        //Partner Profile
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id;  

        System.runAs(objUser1) {
            //Created User
            objUser = TestDataUser.initPartnerUser(profileId,objContact.id);
            insert objUser;
        }         

    }

    /*
    *  @author Nishan Shetty
    *  @description Test initialize map method
    */
    @istest
    static void testInitializeMap() {
       test.startTest();
       String strJSON=ChannelPartnerCustomButtonLwcController.initializeMap();
       Map<String,String> mapLabels = (Map<String,String>)JSON.deserialize(
        UtilsObject.getJSONPart(strJSON,
        '{"mapLabels": ',
        '}'),
        Map<String,String>.class);
        System.assertEquals(4,mapLabels.size(),'Map count does not match');
       test.stopTest();
    }
  
    /*
    *  @author Nishan Shetty
    *  @description Test method for updateRequestOwnershipFields for checking Case condition without Requested Status.
    */
    @isTest
    static void testupdateRequestOwnershipFieldsCaseWithoutRequested() {
        Case objCase = [Select Id,Request_Ownership_Status__c,Ownership_Requested_By__c from Case where Request_Ownership_Status__c='Requested' Limit 1];
        objCase.Request_Ownership_Status__c=null;
        update objCase;
        test.startTest();
        String message=ChannelPartnerCustomButtonLwcController.updateRequestOwnershipFields(objCase.Id,'Case');
        test.stopTest();
        System.assertEquals('SUCCESS',message,'Channel Partner Ownership request field not updated for Case');
    }

    /*
    *  @author Nishan Shetty
    *  @description Test method for updateRequestOwnershipFields for checking Case condition with Requested Status.
    */
    @isTest
    static void testupdateRequestOwnershipFieldsCaseWithRequested() {
        Case objCase = [Select Id,Request_Ownership_Status__c,Ownership_Requested_By__c from Case where Request_Ownership_Status__c='Requested' Limit 1];
        test.startTest();
        String message=ChannelPartnerCustomButtonLwcController.updateRequestOwnershipFields(objCase.Id,'Case');
        test.stopTest();
        System.assertEquals('RAISED',message,'Channel Partner Ownership request not already raised');
    }


    /*
    *  @author Nishan Shetty
    *  @description Test method for updateRequestOwnershipFields for checking Case condition with Requested Status.
    */
    @isTest
    static void testupdateRequestOwnershipFieldsCaseAccessDenied() {
        Case objCase = [Select Id,Request_Ownership_Status__c,Ownership_Requested_By__c from Case where Request_Ownership_Status__c='Requested' Limit 1];
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id; 
        User objUser = [Select Id,ProfileId from User where ProfileId=:profileId and IsActive=true LIMIT 1];
        objCase.OwnerId=objUser.Id;
        update objCase;
        test.startTest();
        String message=ChannelPartnerCustomButtonLwcController.updateRequestOwnershipFields(objCase.Id,'Case');
        test.stopTest();
        System.assertEquals('DENIED',message,'Channel Partner Ownership request not allowed');
    }
  
  
    /*
    *  @author Nishan Shetty
    *  @description Test method for updateRequestOwnershipFields for checking Work Order condition. without requested status.
    */
    @isTest
    static void testupdateRequestOwnershipFieldsWorkOrderWithoutRequested() {
        SVMXC__Service_Order__c objWorkOrder = [Select Id,Request_Ownership_Status__c,Ownership_Requested_By__c from SVMXC__Service_Order__c where Request_Ownership_Status__c='Requested' Limit 1];
        objWorkOrder.Request_Ownership_Status__c=null;
        update objWorkOrder;
        test.startTest();
        String message=ChannelPartnerCustomButtonLwcController.updateRequestOwnershipFields(objWorkOrder.Id,'WorkOrder');
        test.stopTest();
        System.assertEquals('SUCCESS',message,'Channel Partner Ownership request field not updated for Work Order');
    }

    /*
    *  @author Nishan Shetty
    *  @description Test method for updateRequestOwnershipFields for checking Work Order condition with Requested Status.
    */
    @isTest
    static void testupdateRequestOwnershipFieldsWorkOrderWithRequested() {
        SVMXC__Service_Order__c objWorkOrder = [Select Id,Request_Ownership_Status__c,Ownership_Requested_By__c from SVMXC__Service_Order__c where Request_Ownership_Status__c='Requested' Limit 1];
        test.startTest();
        String message=ChannelPartnerCustomButtonLwcController.updateRequestOwnershipFields(objWorkOrder.Id,'WorkOrder');
        test.stopTest();
        System.assertEquals('RAISED',message,'Channel Partner Ownership request not already raised');
    }
    
    /*
    *  @author Nishan Shetty
    *  @description Test method for updateRequestOwnershipFields for denied status.
    */
    @isTest
    static void testupdateRequestOwnershipFieldsWorkOrderAccessDenied() {
        SVMXC__Service_Order__c objWorkOrder = [Select Id,Request_Ownership_Status__c,Ownership_Requested_By__c from SVMXC__Service_Order__c where Request_Ownership_Status__c='Requested' Limit 1];
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id; 
        User objUser = [Select Id,ProfileId from User where ProfileId=:profileId and IsActive=true LIMIT 1];
        objWorkOrder.OwnerId=objUser.Id;
        test.startTest();
        update objWorkOrder; 
        String message=ChannelPartnerCustomButtonLwcController.updateRequestOwnershipFields(objWorkOrder.Id,'WorkOrder');
        test.stopTest();
        System.assertEquals('DENIED',message,'Channel Partner Ownership request not allowed');
    }


  
    /*
    *  @author Nishan Shetty
    *  @description Test method for updateRequestOwnershipFields for checking Work Order exception.
    */
    @isTest
    static void testupdateRequestOwnershipFieldsWorkOrderHandleException() {
        test.startTest();
        try {
        ChannelPartnerCustomButtonLwcController.updateRequestOwnershipFields(null,'WorkOrder');
        } catch (Exception e) {
            System.assertEquals('Script-thrown exception',e.getMessage(),'Unhandled Error');
        }
        test.stopTest();
        
    }
    
  }