/**
*    @author: Vignesh 
*    @date:   04-Jun-2020
*    @description:  Test class for Users class.
*    Modification Log:
*    ------------------------------------------------------------------------------------
*    Developer                      Date             Description
*    Vignesh                     04-Jun-2020        Initial Version - DCP-37395
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest(SeeAllData = false)  
public with sharing class TestUsers{
     
     public static final String PROFILE_CUSTOMER_SERVICE = 'Customer Service';
     public static final String PROFILE_FAST_TRACK_SERVICES = 'Fast Track Services';
     
     static testmethod void testDelegatedUsers() {
        User proxyUser = TestDataUser.findUserInProfile(PROFILE_CUSTOMER_SERVICE);
        
        User proxyUser2 = TestDataUser.findUserInProfile(PROFILE_CUSTOMER_SERVICE, new set<Id>{proxyUser.Id} );
        
        User ownerRecord = TestDataUser.findUserInProfile(PROFILE_CUSTOMER_SERVICE, new set<Id>{proxyUser.Id,proxyUser2.Id});

        Map<Id,User> mapUsers = new Map<Id,User>([select id,Delegated_Approver_Email__c,Email FROM user where ID IN : new list<Id>{proxyUser.Id,proxyUser2.Id,ownerRecord.Id}]);
        
        test.starttest();
            OwnerRecord.out_of_office__c = true;
            OwnerRecord.DelegatedApproverId = ProxyUser.Id;
            update OwnerRecord;
        test.stoptest();
        
        user updatedUser = [select Id,Delegated_Approver_Email__c from user WHERE ID  = :OwnerRecord.Id];
        system.assertEquals(updatedUser.Delegated_Approver_Email__c ,mapUsers.get(ProxyUser.Id).Email , 'Delegated approver email not matching with proxy User' );
        
        OwnerRecord.out_of_office__c = true;
        OwnerRecord.DelegatedApproverId = ProxyUser2.Id;
        update OwnerRecord;
        
        user updatedUser2 = [select Id,Delegated_Approver_Email__c from user WHERE ID  = :OwnerRecord.Id];
        system.assertEquals(updatedUser2.Delegated_Approver_Email__c , mapUsers.get(ProxyUser2.Id).Email, 'Failure on Updating Delegated Approver' );
        
        OwnerRecord.out_of_office__c = false;
        OwnerRecord.DelegatedApproverId = Null;
		OwnerRecord.ProfileId = [Select Id from Profile Where Name = 'Technical Support' Limit 1].Id;
        update OwnerRecord;
        
 
        user updatedUser3 = [select Id,Delegated_Approver_Email__c from user WHERE ID  = :OwnerRecord.Id];
        system.assertEquals(Null,updatedUser3.Delegated_Approver_Email__c,'Disabling OOO didnt update user record.');
        
    }
    
    static testmethod void testError() {
        User proxyUser = TestDataUser.findUserInProfile(PROFILE_CUSTOMER_SERVICE);
        
        User proxyUser2 = TestDataUser.findUserInProfile(PROFILE_CUSTOMER_SERVICE, new set<Id>{proxyUser.Id} );
        
        User ownerRecord = TestDataUser.findUserInProfile(PROFILE_CUSTOMER_SERVICE, new set<Id>{proxyUser.Id,proxyUser2.Id});
        
        User userWithoutAccess = TestDataUser.findUserInProfile(PROFILE_FAST_TRACK_SERVICES);
        
        string errorMsg;
        OwnerRecord.out_of_office__c = true;
        OwnerRecord.DelegatedApproverId = Null;
        try{
            update OwnerRecord;
        }catch(Exception e){
            errorMsg = e.getMessage();
        }
        
        system.assert(errorMsg.contains(label.QSR_Delegated_Approver_Error_Msg_On_OOO),'Validation Rule for Missing Delegated Approver failed');
        
        
        OwnerRecord.out_of_office__c = True;
        OwnerRecord.DelegatedApproverId = userWithoutAccess.Id;
        try{
            update OwnerRecord;
        }catch(Exception e){
            errorMsg = e.getMessage();
        }
        
        system.assert(errorMsg.contains(label.Delegated_Approver_Lack_QSR_Access) , 'Assert Failed on Adding Invalid User OOO');
    }
}