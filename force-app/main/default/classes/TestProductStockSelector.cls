//TestProductStockSelector
/*@ author       : Prashanth
* @ date         : 20-08-2019
* @ Description  : Test class for ProductStockSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                              Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Prashanth                20-08-2019                        Initial version
*/
@isTest(SeeAllData=false)
public with sharing class TestProductStockSelector
{
    /**
    *  @author Bharath Kumar
    *  @description - test setupData
    **/
    @testSetup
    static void setupData()
    {
        TestDataMaster.createProduct(true);
 
    }

    /**
    *  @author Bharath Kumar
    *  @description - increasing test coverage
    **/
    static testMethod void testProductStockSelectorMethod(){

    	// Account objAccount = TestDataAccount.getNewAccount();
        Test.startTest();
        // Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        Product2 prod = new Product2(Name='TestProd',
                                     Auto_Create_Installation_Workflow__c='Auto Create Install Work Order and Service Request Case',
                                     Service_Product_Type__c='Instrument',
                                     Regulatory_Type__c='DX',
                                     IsActive=true,
                                     ProductCode='43535',
                                     Material_Number__c = '1111',
                                     Service_Level__c = 'GOLD'
                                    );        
        insert prod;
        //SVMXC__Site__c location =TestDataFieldService.createLocation('ServiceLoc1','Stringing street New York','USA','43527','USD');
        SVMXC__Site__c shippingLocation = new SVMXC__Site__c(
        Name = 'testStockingLocation',
        CurrencyIsoCode = 'USD',
        SVMXC__Stocking_Location__c = true,
        SVMX_PS_Active__c = true,
        Type__c = 'Ship To');
        //list<SVMXC__Site__c> locList= new list<SVMXC__Site__c>();
        //locList.add(location);
        //locList.add(shippingLocation);
        insert shippingLocation;
        
        SVMXC__Site__c location =TestDataFieldService.createLocation('ServiceLoc1','Stringing street New York','USA','43527','USD');
        Location.SVMX_PS_External_ID__c = 'EXTLOC11223344';
        insert location;
        
        SVMXC__Product_Stock__c productStock = new SVMXC__Product_Stock__c();
		productStock.CurrencyIsoCode = 'USD';
		productStock.SVMXC__IsPartnerRecord__c = false;
		productStock.SVMXC__Location__c = location.Id;	
		productStock.SVMXC__Product__c = prod.Id;
		productStock.SVMXC__Quantity2__c = 1.0;
        productStock.SVMX_PS_External_ID__c = '1223';
		productStock.SVMXC__Status__c = 'Available';
		insert productStock;
        
        Set<Id> setproductStock = new Set<Id>{productStock.Id};
        Set<String> setExternalId = new Set<String>{productStock.SVMX_PS_External_ID__c};

		ProductStockSelector pse= new ProductStockSelector ();
		//pse.selectProductStockByLocationExtId(new set<string>{productStock.SVMX_PS_External_ID__c});
        system.assertNotEquals(null,location.SVMX_PS_External_ID__c);
        pse.selectProductStockByLocationAndProduct(new set<id>{location.Id},new set<id>{prod.Id});
        pse.selectProductStockByToFromLocationAndProduct(new set<id>{shippingLocation.Id},new set<id>{location.Id},new list<id>{prod.id},new Set<String>{productStock.SVMXC__Status__c}); 
        pse.selectProductStocksByIds(setproductStock);
        pse.selectProductStocksByExternalId(setExternalId);
            
		List<SVMXC__Product_Stock__c> lstProductStock = new List<SVMXC__Product_Stock__c>();
        lstProductStock = pse.selectProductStockByLocationExtId(new set<string>{location.SVMX_PS_External_ID__c});
        System.assertEquals(1, lstProductStock.size());
        
    }    

}