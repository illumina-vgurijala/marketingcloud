/*@ author       : Joshith k
* @ date         : 06-11-2018
* @ Description  : DCP 11324 Test class for Batch update to Inactivate Bundle products with supressed expiration date
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Joshith k        		06-11-2018                 Initial version
* Nishan Shetty         14-Jun-2022                DCP-50962 Changes
* Vivek R               06-Oct-2022                Codescan fixes: added comments
* Satya Swain           09 Dec 2022                Added Codescan fix for Variable Naming Convention
*/
@isTest
public class TestScheduledBatchExpiredBundleProduct {

    /**
     *  @description : Method to test expired Bundle Product schedulable batch
    */
    @isTest
    public static void  testUpdateExpiredBundleProduct(){
        
	datetime myDateTime = datetime.now();
	myDateTime=myDateTime.adddays(-2);

        Product2 prd = new Product2(Name = 'Test Product', Apttus_Config2__ConfigurationType__c= 'Bundle', Apttus_Config2__EffectiveDate__c = Datetime.now(),
           Apttus_Config2__ExpirationDate__c = myDateTime, Bundle_Channel__c = 'online', Bundle_Description__c= 'Test Bundle Description',
            Bundle_Name__c = 'Test Bundle Name', Bundle_Segment__c= 'Reproductive Health', ProductCode= 'offline' ,isactive=true);
        insert prd;
        
        Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c(Name= 'sefssdf', Apttus_Config2__HierarchyLabel__c='sfdf');
        insert category;
        system.Debug('category==> '+category);

        Apttus_Config2__ClassificationHierarchy__c ob = new Apttus_Config2__ClassificationHierarchy__c(Name= 'test', Apttus_Config2__Label__c = 'tttt', Apttus_Config2__HierarchyId__c = category.Id);
        insert ob;
        System.debug('ob');

        Apttus_Config2__ProductOptionGroup__c opgrp = new Apttus_Config2__ProductOptionGroup__c(Apttus_Config2__ProductId__c = prd.Id, Apttus_Config2__OptionGroupId__c = ob.Id, Apttus_Config2__Sequence__c = 10 );
        insert opgrp;

        Apttus_Config2__ProductOptionComponent__c option = new Apttus_Config2__ProductOptionComponent__c(Apttus_Config2__ProductOptionGroupId__c = opgrp.Id,
                                                                                                         Apttus_Config2__ComponentProductId__c = prd.Id, Apttus_Config2__Sequence__c = 1);
        insert option;
	
	Test.startTest();
	ScheduledBatchExpiredBundleProduct sh1 = new ScheduledBatchExpiredBundleProduct();
    sh1.serializeInputs();//DCP-50962
    sh1.restoreInputs('test');//DCP-50962
    sh1.getDefaultBatchSize();//DCP-50962
	String sch = '0 0 23 * * ?'; 
	system.schedule('Test BatchtoUpdateExpiredBundleProduct', sch, sh1);
    Database.executeBatch(sh1);
	 Test.stopTest(); 
     product2 objproduct=[SELECT isactive,Product_Send_To_AEM_Status__c FROM PRoduct2 WHERE Id= :prd.Id];
	  System.assertEquals('Deactivated', objproduct.Product_Send_To_AEM_Status__c);
     System.assertEquals(false, objproduct.isactive);
     
	}
    
    /**
     *  @description : Method to test removal of inactive products from the bundle
    */
    @isTest
    public static void  testremoveproductfrombundle(){
        // coverage for products class
        datetime myDateTime = datetime.now();
		myDateTime=myDateTime.adddays(-2);
        Product2 prdonline = new Product2(Name = 'Test Product', Apttus_Config2__ConfigurationType__c= 'Bundle', Apttus_Config2__EffectiveDate__c = Datetime.now(),
           Apttus_Config2__ExpirationDate__c = myDateTime, Bundle_Channel__c = 'online', Bundle_Description__c= 'Test Bundle Description',
            Bundle_Name__c = 'Test Bundle Name', Bundle_Segment__c= 'Reproductive Health', ProductCode= 'offline' ,isactive=true);
        insert prdonline;
        
        Product2 prdoffline = new Product2(Name = 'Test Product', Apttus_Config2__ConfigurationType__c= 'Bundle', Apttus_Config2__EffectiveDate__c = Datetime.now(),
           Apttus_Config2__ExpirationDate__c = myDateTime, Bundle_Channel__c = 'offline', Bundle_Description__c= 'Test Bundle Description',
            Bundle_Name__c = 'Test Bundle Name', Bundle_Segment__c= 'Reproductive Health', ProductCode= 'offline' ,isactive=true);
        insert prdoffline;
        
        
        Product2 prdstandalone = new Product2(Name = 'Test Productstandalone', Apttus_Config2__ConfigurationType__c= 'Standalone', Apttus_Config2__EffectiveDate__c = Datetime.now(),
           Apttus_Config2__ExpirationDate__c = myDateTime, Bundle_Channel__c = 'offline', Bundle_Description__c= 'Test Bundle Description',
            Bundle_Name__c = 'Test Bundle Name', Bundle_Segment__c= 'Reproductive Health', ProductCode= 'offline' ,isactive=true);
        insert prdstandalone;
        
        Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c(Name= 'sefssdf', Apttus_Config2__HierarchyLabel__c='sfdf');
        insert category;
        system.Debug('category==> '+category);

        Apttus_Config2__ClassificationHierarchy__c ob = new Apttus_Config2__ClassificationHierarchy__c(Name= 'test', Apttus_Config2__Label__c = 'tttt', Apttus_Config2__HierarchyId__c = category.Id);
        insert ob;
        System.debug('ob');

        Apttus_Config2__ProductOptionGroup__c opgrp = new Apttus_Config2__ProductOptionGroup__c(Apttus_Config2__ProductId__c = prdoffline.Id, Apttus_Config2__OptionGroupId__c = ob.Id, Apttus_Config2__Sequence__c = 10 );
        insert opgrp;

        Apttus_Config2__ProductOptionComponent__c option = new Apttus_Config2__ProductOptionComponent__c(Apttus_Config2__ProductOptionGroupId__c = opgrp.Id,
                                                                                                         Apttus_Config2__ComponentProductId__c = prdstandalone.Id, Apttus_Config2__Sequence__c = 1,Apttus_Config2__ParentProductId__c=prdoffline.id);
        insert option;
        Test.startTest();
        //update standalone product in bundle as inactivate so that it will be removed from the bundle
        prdstandalone.IsActive=false;
        update prdstandalone;
      
        // update onlinebundle to change status as Deactivating
       	prdonline.IsActive=false;
        
        update prdonline;
        Test.stopTest();
        Apttus_Config2__ProductOptionComponent__c poc=[select Apttus_Config2__ProductOptionGroupId__c from Apttus_Config2__ProductOptionComponent__c  where id=:option.id];
		system.assertEquals(null, poc.Apttus_Config2__ProductOptionGroupId__c);
        product2 objproduct=[select Product_Send_To_AEM_Status__c from product2 where id=:prdonline.id];
        system.assertEquals('Deactivated',objproduct.Product_Send_To_AEM_Status__c );
        
    }
}