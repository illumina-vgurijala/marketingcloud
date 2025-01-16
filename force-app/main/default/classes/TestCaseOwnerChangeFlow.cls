/***************************************************************************************************************************************
* @Author:  Nidhi Hegde
* @Date:    05-Oct-2023 
* @Name :   TestCaseOwnerChangeFlow
* @Description: For Covering Case_Request_Ownership_Change_CP Flow
* ------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* ------------------------------------------------------------------------------------
* Nidhi Hegde             05-Oct-2023        Initial Version (CMCM-3826)
******************************************************************************************************************************************************************/

@isTest
public class TestCaseOwnerChangeFlow {
    
    /**
     * @author Nidhi Hegde
     * This method is responsible for changing the owner of an object.
     */
    @isTest
    public static void ownerChangeMethod() {
        
        Account objAccount1 = TestDataAccount.getAccount('Test Acc', 'USD');
        objAccount1.Account_Group__c='Distributor';
        insert objAccount1;

        //Created Contact1
        Contact objContact = TestDataContact.getNewContact(objAccount1);
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.Request_Ownership_Status__c = 'Completed';
        insert objCase;
        
        
        objCase.Ownership_Requested_By__c = UserInfo.getUserId();
        objCase.Request_Ownership_Status__c = 'Requested';
        test.startTest();
        update objCase;
        Test.stopTest();
        objCase = [Select OwnerID, Owner.ID From Case where ID = :objCase.id];
        System.assertNotEquals(null, objCase.OwnerId, 'The OwnerId should not be null.');
    }
}