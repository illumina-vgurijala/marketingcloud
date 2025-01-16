/*@ author       : Akash Kumar 
* @ date         : 07-02-2018
* @ Description  : FlexBundleValidationController Apex Controller
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akash Kumar          05-18-2018                  US-             Initial version
* Joshith k            11-06-2018                  DCP 11324       Modified
* Parthasarathy D      10-Oct-2022                                 Codescan Fix- Added method level comments.
* 
*/
@isTest(isparallel=true)
public class TestFlexBundleValidationController {
    /*
    *  @author      : 
    *  @description : Method to test Outboud Request Submit Scenario.
    *  @param       : 
    *  @return      : Void.
    */
    @isTest
    public static void  testSubmitOutboundRequest(){
        
        Product2 prd = new Product2(Name = 'Test Product', Apttus_Config2__ConfigurationType__c= 'Bundle', Apttus_Config2__EffectiveDate__c = Datetime.now(),
           Apttus_Config2__ExpirationDate__c = Datetime.now().adddays(2), Bundle_Channel__c = 'online', Bundle_Description__c= 'Test Bundle Description',
            Bundle_Name__c = 'Test Bundle Name', Bundle_Segment__c= 'Reproductive Health', ProductCode= 'offline',isactive=true );
        insert prd;
        // for code coverage second product with isactive false
        Product2 prd1 = new Product2(Name = 'Test Product1', Apttus_Config2__ConfigurationType__c= 'Bundle', Apttus_Config2__EffectiveDate__c = Datetime.now(),
           Apttus_Config2__ExpirationDate__c = Datetime.now().adddays(2), Bundle_Channel__c = 'online', Bundle_Description__c= 'Test Bundle Description',
            Bundle_Name__c = 'Test Bundle Name', Bundle_Segment__c= 'Reproductive Health', ProductCode= 'offline',isactive=false );
        insert prd1;
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

        new ProductOptionComponentSelector().getSObjectType();//just for code coverage
        
        Test.startTest();
            FlexBundleValidationController.submitOutboundRequest(prd.Id);
        	FlexBundleValidationController.submitOutboundRequest(prd1.Id);// inactive product sent to AEM for deactivated status
            ProductsSelector psel = new ProductsSelector();
            psel.selectProducts(new Set<Id>{ prd.Id });
        Test.stopTest();
        
        Product2 objProduct = [SELECT isactive,Product_Send_To_AEM_Status__c FROM PRoduct2 WHERE Id= :prd.Id];
        System.assertEquals('Sent', objProduct.Product_Send_To_AEM_Status__c,'Status not setting to sent');
        
       // assert for deactivated product 
       Product2 objProduct1 = [SELECT isactive,Product_Send_To_AEM_Status__c FROM PRoduct2 WHERE Id= :prd1.Id];
        System.assertEquals('Deactivated', objProduct1.Product_Send_To_AEM_Status__c);
        
        System.assert(new ProductOptionGroupsSelector()
                      .selectByIdWithOptionGroups(new Set<Id>()).isEmpty()
                      ,'Records returned without id being passed');//for code coverage
       
        
    }
}