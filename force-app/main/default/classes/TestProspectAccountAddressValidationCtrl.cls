/*@ author       : Akshay Mohan
* @ date         : 07-02-2018
* @ Description  : ProspectAccountAddressValidationComponent Apex Controller Test class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan        	05-18-2018                 DCP-4252             Initial version
* Akshay Mohan          10-04-2018                 DCP-6494             Address Doctor integration
* Iram Malik            12-07-2022                 Codescan Fix         Statement on a separate line
*/
@isTest
public class TestProspectAccountAddressValidationCtrl {
	/*
    * @desc Check Address Validation as Sales User
    */
    @isTest
    public static void  loadPageAsSalesRep(){
        String strSalesRepProfileName = 'Sales User';
        Set<Id> setUserId = UtilsCollection.getSetOfIds([SELECT AssigneeId FROM PermissionSetAssignment 
                                                         WHERE Assignee.Profile.Name= :strSalesRepProfileName
                                                        	AND PermissionSet.Name='SL_DS_Resubmit_Prospect_Accounts']
                                                        ,'AssigneeId');
        //DCP-53342
        Account objAccount = TestDataAccount.getAccount('Defenders');
        insert objAccount;
        //End of DCP-53342
        
        User objUser = TestDataUser.findUserInProfile(strSalesRepProfileName,setUserId,true);
        
        System.assert(objUser!=null,'No Sales rep found without permission set assigned');
        String strResult;
        
        ProspectAccountAddressValidationControl.AddressWrapper wrapAdd = new ProspectAccountAddressValidationControl.AddressWrapper();
        wrapAdd.strStreet='TestStreet';
        wrapAdd.strCity='TestCity';
        wrapAdd.strCountry='TestCountry';
        wrapAdd.strState='TestState';
        wrapAdd.strZip='TestZip';
        //DCP-53342
        wrapAdd.strAccountId = objAccount.Id;
        // End of DCP-53342

        Test.setMock(HttpCalloutMock.class, new AddressDoctorHttpMock());
        Test.startTest();
        System.runAs(objUser){
            strResult=ProspectAccountAddressValidationControl.loadPage(JSON.serialize(wrapAdd));
        }
        Test.stopTest();
                
        System.assert(String.isNotBlank(strResult),'Result came as blank');
        System.assert(strResult.contains(', "booCanReSubmit" : false}'),'Can resubmit not set to false');
    }

    /*
    * @desc Check Address Validation and Load Page as Admin
    */
    @isTest
    public static void  loadPageAsSysAdmin() {
        User objUser = TestDataUser.findUserInProfile('System Administrator');        
        String strResult;
        Account objAccount = TestDataAccount.getAccount('Defenders');
        insert objAccount;
        
        ProspectAccountAddressValidationControl.AddressWrapper wrapAdd = new ProspectAccountAddressValidationControl.AddressWrapper();
        wrapAdd.strStreet='TestStreet';
        wrapAdd.strCity='TestCity';
        wrapAdd.strCountry='TestCountry';
        wrapAdd.strState='TestState';
        wrapAdd.strZip='TestZip';
        //DCP-53342
        wrapAdd.strAccountId = objAccount.Id;
        //End of DCP-53342
        
        Test.setMock(HttpCalloutMock.class, new AddressDoctorHttpMock());
        Test.startTest();
        System.runAs(objUser){
            strResult=ProspectAccountAddressValidationControl.loadPage(JSON.serialize(wrapAdd));
        }
        Test.stopTest();
        
        System.assert(String.isNotBlank(strResult),'Result came as blank');
        System.assert(strResult.contains(', "booCanReSubmit" : true}'),'Can resubmit not set to true');
    }
}