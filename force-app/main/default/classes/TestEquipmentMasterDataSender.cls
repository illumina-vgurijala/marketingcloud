/* @ author      : Mandeep Singh
 * @ date         : 7/17/2018
 * @ Description  : TestEquipmentMasterDataSender is the test class for EquipmentMasterDataSender 
 *
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID      Description
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *       
 */
@IsTest
private class TestEquipmentMasterDataSender {


    @IsTest
    static void updateInstallPrdTestMethod() {
        
        //Create Account
        Account testAccount = TestDataAccount.getAccount('Test Account1');
        testAccount.ERP_Customer_Id__c = '897';
        insert testAccount;
        
        //Create IP
        SVMXC__Installed_Product__c instProd = new SVMXC__Installed_Product__c(
            ERP_Equipment_Id__c = '1234',
            SVMXC__Company__c = testAccount.Id,
            Acceptance_Date__c = Date.valueOf('2018-10-18'),
            SVMXC__Date_Installed__c = Date.valueOf('2018-10-18')

        );
        
        insert instProd;

        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new MockHTTPCallout());

        SVMXC__Installed_Product__c inp = [Select Acceptance_Date__c From SVMXC__Installed_Product__c Where id =: instProd.id];
        inp.Acceptance_Date__c = Date.valueOf('2018-10-27');
        update inp;
        EquipmentMasterWrapper.InstalledProduct eqi = new EquipmentMasterWrapper.InstalledProduct(inp);
        new EquipmentMasterDataSender().callout(inp.id);
        Test.Stoptest();
        System.assertEquals(true, MockHTTPCallout.booResponseSuccess);

    }

}