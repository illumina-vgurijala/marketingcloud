/**************************************************************************************************************************************
* NAME   : TestBatchIPDataRemediation
* DESCRIPTION  : Domain class for v.
*  
*                    
* @AUTHOR : Nitin Z 
* @DATE   : 6 -Dec -2024  
*  
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
  Nitin Z                 6 -Dec -2024    

****************************************************************************************************************************************/ 


@isTest
public class TestBatchIPDataRemediation {

    public static final String REG_TYPE_ALL = 'All';
    public static final String REG_TYPE_DX = 'DX';
    public static final String REG_TYPE_RUO = 'RUO';

    public static final String PRODUCT_GROUP_ALL = 'All';
    public static final String PRODUCT_GROUP_LIMS = 'LIMS Service Contract';
    public static final String PRODUCT_GROUP_HISCAN = 'HiScan System';
    public static final String PRODUCT_GROUP_BASESPACE = 'BaseSpace Onsite System';
    public static final String STRING_OFF = 'Off';
    public static final String STRING_USD = 'USD';
    /**
       * method: testIPDataRemediationBatch
       * params:NA
       * return: void 
       * Description: this method covers the functionality of data remediation part of cmcm 12144
      **/
    @isTest
    static void testIPDataRemediationBatch()
    {   
 		
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        upsert setting;
        
        //insert account
        Account testAccount = TestDataAccount.initAccount();
        insert testAccount;
        
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location','Test Street','Ireland','123456','USD');
        objLocation.Type__c = 'Distributor';
        Insert objLocation;

        system.assertNotEquals(null,testAccount.Id,'Account is null');
        //insert instprod
        SVMXC__Installed_Product__c instProd = TestDataInstalledProduct.getNewInstalledProduct(testAccount.Id);
      
        InstalledProducts.hasRunTaps = false;
        InstalledProducts.hasRunPartnerSharing = false;
        instProd.Acceptance_Date__c=Date.today();
        instProd.SVMXC__Status__c='Decommissioned';

        update instProd;
        
        Test.startTest();
        instProd.Acceptance_Date__c=null;
        update instProd;
       
      

        IPDataRemediationHelper.MockHistoryRecord testRec=  new IPDataRemediationHelper.MockHistoryRecord('Acceptance_Date__c', Date.today(), null,(String)instProd.Id);
        List<IPDataRemediationHelper.MockHistoryRecord> mockHistoryRecords = new List<IPDataRemediationHelper.MockHistoryRecord>{};     
        mockHistoryRecords.add(testRec);
        IPDataRemediationHelper.processHistoryRecords(mockHistoryRecords,'Acceptance_Date__c');
        mockHistoryRecords.clear();
        
        mockHistoryRecords.add(new IPDataRemediationHelper.MockHistoryRecord('SVMXC__Date_Installed__c', Date.today()-2, null,(String)instProd.Id));
        IPDataRemediationHelper.processHistoryRecords(mockHistoryRecords,'SVMXC__Date_Installed__c');
        mockHistoryRecords.clear();

        mockHistoryRecords.add(new IPDataRemediationHelper.MockHistoryRecord('SVMXC__Date_Shipped__c', Date.today(), null,(String)instProd.Id));
        IPDataRemediationHelper.processHistoryRecords(mockHistoryRecords,'SVMXC__Date_Shipped__c');
        mockHistoryRecords.clear();
        
        mockHistoryRecords.add(new IPDataRemediationHelper.MockHistoryRecord('SVMXC__Site__c', objLocation.ID , null,(String)instProd.Id));
        IPDataRemediationHelper.processHistoryRecords(mockHistoryRecords,'SVMXC__Site__c');
        mockHistoryRecords.clear();
        
		    Database.executeBatch(new BatchIPDataRemediation('Acceptance_Date__c'));
        Test.stopTest();

        instProd=[select id,SVMXC__Date_Installed__c,SVMXC__Site__c from  SVMXC__Installed_Product__c where id=:instProd.ID limit 1];
        System.assertEquals(instProd.SVMXC__Site__c, objLocation.Id, 'Location Updated');
        System.assertEquals(instProd.SVMXC__Date_Installed__c,  Date.today()-2, 'Date Installed Updated');
     }
   }