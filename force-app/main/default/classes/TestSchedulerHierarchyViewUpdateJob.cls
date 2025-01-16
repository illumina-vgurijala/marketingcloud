/**
*    @author Govind Dubey
*    @date   10th May 2019
*    @description   Test class for scheduler class of Category and Product Association 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Govind Dubey                   10th May 2019		 INC0206147 - scheduled product batch job
*             Saddam                           08-Dec-2022             Codescan Fix , Varaible naming convention. 
*    ------------------------------------------------------------------------------------
**/

@isTest(SeeAllData=false isParallel=false) 
public class TestSchedulerHierarchyViewUpdateJob {
	@testSetup
    static void setupData()
    {   
        Apttus_Config2__ClassificationName__c category = TestDataProposal.initCategory('Illumina');
        insert category;

        Apttus_Config2__ClassificationHierarchy__c level0 = TestDataProposal.initHierarchy(category, 'Illumina', null, null, 0);
        insert level0;

        Apttus_Config2__ClassificationHierarchy__c level1 = TestDataProposal.initHierarchy(category, 'By Category', level0, level0, 1);
        insert level1;

        Apttus_Config2__ClassificationHierarchy__c level2 = TestDataProposal.initHierarchy(category, 'BaseSpace Suite', level0, level1, 2);
        insert level2;

        Apttus_Config2__ClassificationHierarchy__c level3 = TestDataProposal.initHierarchy(category, 'BaseSpace Onsite', level0, level2, 3);
        insert level3;

        Apttus_Config2__ClassificationHierarchy__c level4 = TestDataProposal.initHierarchy(category, 'BaseSpace Onsite Accessory', level0, level3, 4);
        level4.Apttus_Config2__Right__c = 2;
        level4.Apttus_Config2__Left__c = 1;
        insert level4;

	    Product2 product = TestDataMaster.createProduct(false);
        insert product;

        Apttus_Config2__ProductClassification__c productClassification = TestDataProposal.initProductClassification(level0,product);
        insert productClassification;
    }
    
    @isTest private static void runHierarchyViewUpdateJobOnInsertionOfProduct()
    {
        SchedulerHierarchyViewUpdateJob job = new SchedulerHierarchyViewUpdateJob();
        Test.startTest();
        {
            job.execute(null);
        }
        Test.stopTest();
        Product2 updatedProd = [SELECT Id, Material_Class__c,Process_For_Batch__c FROM Product2 LIMIT 1];
        system.assertEquals(false,updatedProd.Process_For_Batch__c,'Product category association batch has not been run.');
    }

    @isTest private static void runHierarchyViewUpdateJobOnUpdateOfProduct()
    {
        Product2 prod = [SELECT Id, Material_Class__c,Process_For_Batch__c FROM Product2 LIMIT 1];
        SchedulerHierarchyViewUpdateJob job = new SchedulerHierarchyViewUpdateJob();
        
        Test.startTest();
        {
            job.execute(null);
            Product2 updatedProd = [SELECT Id, Material_Class__c,Process_For_Batch__c FROM Product2 LIMIT 1];
            system.assertEquals(false,updatedProd.Process_For_Batch__c,'Product category association batch has not been run on insertion.');
            
            prod.Material_Class__c = 'Services';
            update prod;
            updatedProd = [SELECT Id, Material_Class__c,Process_For_Batch__c FROM Product2 LIMIT 1];
            system.assertEquals(true,updatedProd.Process_For_Batch__c,'Product trigger did not updated flag.');
            job.execute(null);
        }
        Test.stopTest();
        Product2 updatedProd = [SELECT Id, Material_Class__c,Process_For_Batch__c FROM Product2 LIMIT 1];
        system.assertEquals(false,updatedProd.Process_For_Batch__c,'Product category association batch has not been run when updated product.');
    }
}