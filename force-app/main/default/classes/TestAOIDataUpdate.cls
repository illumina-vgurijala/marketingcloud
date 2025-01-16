/**
 * Class - TestAOIDataUpdate
 * Description - Test class to check AOI update logic
 */
@isTest(SeeAllData = false)
public class TestAOIDataUpdate {
    static testMethod void testLeadUpdate(){
        String email='AOIDateUpdateLead';
        Lead objServiceLead = TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1',email+'@test.com','Germany','test1Company');
        objServiceLead.Area_Of_Interest__c='Agriculture Research;Animal Testing;Applied Microbiology;Autoimmune Disease Research;Cancer Research;Cardiovascular Disease Research;Cell And Molecular Biology Research;Clinical Oncology;Consumer Genomics;Genetic And Complex Disease Research;Genetic Health;Metabolic Disease Research;Microbiology/Virology research;Neuroscience Research;NIPT;Pharmacogenomics PGx;Healthy Screening;Plant Testing;Preconception And Fertility;Public Health;Rare and Inherited Disease';
        insert objServiceLead;
        Test.startTest();
        Database.executeBatch(new BatchUpdateAOIData());
        Test.stopTest();
    }
    static testMethod void testContactUpdate(){
        String email='AOIDateUpdateContact';
        Contact objCon1=TestDataMarketing.createContactForMarketable('testfirstname','testlastname',email+'@gmail.com','USA');
        objCon1.mailingcountrycode='US';
        objCon1.Area_Of_Interest__c='Agriculture Research;Animal Testing;Applied Microbiology;Autoimmune Disease Research;Cancer Research;Cardiovascular Disease Research;Cell And Molecular Biology Research;Clinical Oncology;Consumer Genomics;Genetic And Complex Disease Research;Genetic Health;Metabolic Disease Research;Microbiology/Virology research;Neuroscience Research;NIPT;Pharmacogenomics PGx;Healthy Screening;Plant Testing;Preconception And Fertility;Public Health;Rare and Inherited Disease';
        insert objCon1;
        Test.startTest();
        Database.executeBatch(new BatchUpdateAOIDataContact());
        Test.stopTest();
    }
}