/**
*    @author - Bharath Kumar
*    @date   15 Oct 2018
*    @description  test clas for CoveredProductSelector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*    ------------------------------------------------------------------------------------ 
*                    
*/
@IsTest(SeeAllData=false)
public class TestCoveredProductSelector{

/**
    *  @author Bharath Kumar
    *  @description - written to increase code coverage of coveredproductsselector-selectOrderedCoveredProductsForInstalledProduct
    **/
    static testMethod void testCoveredProductSelector1(){
        Account objAccount = TestDataAccount.getAccount('Test');
        insert objAccount;
        set<Id> ipIdSet= new set<Id>();
        set<Id> cpIdSet= new set<Id>();
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip;
        SVMXC__Installed_Product__c ip1 = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip1;
        ipIdSet.add(ip.id);
        ipIdSet.add(ip1.id);
        SVMXC__Service_Plan__c sp = new SVMXC__Service_Plan__c();
        sp.Name = 'Test';
        sp.Item_Number__c = '1111';
        insert sp;
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
        set<id> prodIdSet= new set<id>();
        prodIdSet.add(prod.id);
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Status__c = 'Active';
        objServiceContract.SVMXC__Service_Plan__c = sp.Id;
        insert objServiceContract;
        set<id> srvcContractIdSet = new set<id>();
        srvcContractIdSet.add(objServiceContract.Id);
        SVMXC__Service_Contract_Products__c cp = TestDataFieldService.createCoveredProduct(ip.Id);
        cp.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert cp;
        cpIdSet.add(cp.id);
        SVMXC__Service_Contract_Products__c cp1 = TestDataFieldService.createCoveredProduct(ip1.Id);
        cp1.SVMXC__Service_Contract__c = objServiceContract.Id;
        cp1.External_ID__c ='12212121212';
        insert cp1;
        set<string> srvcContractProdExtIdSet = new set<string>();
        srvcContractProdExtIdSet.add(cp1.External_ID__c);
        CoveredProductSelector cps = new CoveredProductSelector();
        cps.selectOrderedCoveredProductsForInstalledProduct(cpIdSet);
        system.assertnotequals(null,cpIdSet.size());
        cps.selectActiveCoveredProducts(ipIdSet);
        cps.selectCoveredProductsForServiceContracts(srvcContractIdSet);
        cps.selectCoveredProductsForExternalIds(srvcContractProdExtIdSet);
        

    }
 }