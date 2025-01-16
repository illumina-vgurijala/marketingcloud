/**
*    @author Roopal Verma
*    @date   2019-07-05
*    @description  Test class for IndirectProposalTransRegionAndPaymentTerm
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*         Roopal Verma                     07-05-2019              DCP-25340, New test class made due to SOQL issue
*         Raja Siva Krishna                23-09-2020              DCP-40107 Updated data to get code coverage 
*         Adyasha Satapathy                28-Nov-2022             POL-54: Update region references to AMEA and EUR 
*     ------------------------------------------------------------------------------------------------------------------------------------**/

@isTest(SeeAllData=false isParallel=false)
public class TestApprovalTransRegionAndPaymentTerm {

	@isTest
    static void testIndirectProposalTransRegionAndPaymentTerm(){
        
        Account objAccount = TestDataAccount.initAccount();
        objAccount.Territory_Region__c ='AMR';
        objAccount.CurrencyIsoCode='USD';
        objAccount.Country_Local__c = 'USA';
        insert objAccount;

        String strPaymentTermName = 'Payment Term'; 
        String strAMEARegionName = 'AMEA'; //POL-54
        List<Custom_Approval_Matrix__c> lstMatrix = new List<Custom_Approval_Matrix__c>();

        Custom_Approval_Matrix__c initApprovalPaymentTermMatrix = TestDataProposal.initApprovalPaymentTermMatrix(strPaymentTermName, 'AMRQueue'); 
        lstMatrix.add(initApprovalPaymentTermMatrix);
        Custom_Approval_Matrix__c initApprovalPaymentTermMatrix2 = TestDataProposal.initApprovalPaymentTermMatrix(strPaymentTermName, 'AMEAQueue'); //POL-54
        initApprovalPaymentTermMatrix2.region__c = strAMEARegionName; //POL-54
        initApprovalPaymentTermMatrix2.Country__c = 'IN';
        lstMatrix.add(initApprovalPaymentTermMatrix2);
        Custom_Approval_Matrix__c initApprovalPaymentTermMatrix3 = TestDataProposal.initApprovalPaymentTermMatrix(strPaymentTermName, 'ChinaQueue'); 
        initApprovalPaymentTermMatrix3.region__c = 'China';
        lstMatrix.add(initApprovalPaymentTermMatrix3);
        Custom_Approval_Matrix__c initApprovalPaymentTermMatrix4 = TestDataProposal.initApprovalPaymentTermMatrix(strPaymentTermName, 'AMEAQueue'); //POL-54
        initApprovalPaymentTermMatrix4.region__c = strAMEARegionName; //POL-54
        initApprovalPaymentTermMatrix4.Country__c = 'JP';
        lstMatrix.add(initApprovalPaymentTermMatrix4);
        insert lstMatrix;

        Account_Sales_Area__c objSoldToSA = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','Hogy_HK010100','div1',false);
        objSoldToSA.Account__c = objAccount.Id;
        insert objSoldToSA;

        Customer_Master_Data__c objCMDUC = new Customer_Master_Data__c(Name='GCMD',ERP_Customer_Id__c = 'Gryffy',Account_Group__c=Label.AccountRelationshipBillTo),
                                objCMDSoldTo = new Customer_Master_Data__c(Name='HCMD',ERP_Customer_Id__c = 'Hogy',Account_Group__c=Label.AccountRelationshipShipTo),
                                objCMDDist = new Customer_Master_Data__c(Name='SCMD',ERP_Customer_Id__c = 'Slimy',Account_Group__c=Label.AccountGroupDistributor);

        List<Customer_Master_Data__c> lstCMD = new List<Customer_Master_Data__c>();
        lstCMD.add(objCMDUC);        
        lstCMD.add(objCMDSoldTo);
        lstCMD.add(objCMDDist);
        insert lstCMD;

        List<Account> lstAccount = new List<Account>();
        Account ucAccount = TestDataAccount.getAccount('Test UC Account');
        ucAccount.Territory_Region__c =strAMEARegionName; //POL-54
        ucAccount.CurrencyIsoCode='JPY';
        ucAccount.Is_Updated_By_System__c = true;
        lstAccount.add(ucAccount);

        Account distAccount = TestDataAccount.getAccount('Test Distributor Account');
        distAccount.Territory_Region__c ='EUR'; //POL-54
        distAccount.CurrencyIsoCode='EUR';
        distAccount.Is_Updated_By_System__c = true;
        lstAccount.add(distAccount);
        insert lstAccount;

        System.debug('Inside method : testIndirectProposalTransRegionAndPaymentTerm 1');
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
		       
		Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert objPriceList;

        System.debug('Inside method : testIndirectProposalTransRegionAndPaymentTerm 1.2');
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());

        
        
        //Opportunity objOpportunity1 = TestDataOpportunity.getNewOpportunity(objAccount1);
        Opportunity objOpportunity1 = TestDataOpportunity.initOpportunity(objAccount,Label.OpportunityRTIndirectStandard);
        objOpportunity1.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity1.Transborder_Flag__c = true;
        objOpportunity1.AccountId = objAccount.Id;
        objOpportunity1.Ultimate_Consignee__c =ucAccount.Id;
       // objOpportunity1.Distributor__c=distAccount.id;
        objOpportunity1.Price_List__c = objPriceList.Name;
        objOpportunity1.Sales_Area_Sold_To__c = 'Opp_HK010100';
        insert objOpportunity1;
        
        Test.startTest();

        System.debug('Inside method : testIndirectProposalTransRegionAndPaymentTerm 2');
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());

        Apttus_Proposal__Proposal__c objProposal1 = TestDataProposal.initProposal(objAccount.id, objOpportunity1.id, 'Test Proposal', objPriceList.id, true, 'Draft', 'None');
        objProposal1.Ultimate_Consignee__c = ucAccount.Id;
        objProposal1.Apttus_Proposal__Account__c = objAccount.Id;
        objProposal1.Apttus_Proposal__Payment_Term__c = 'Test';
        objProposal1.Bill_To__c = objCMDSoldTo.Id;
        insert objProposal1;


        System.debug('Inside method : testIndirectProposalTransRegionAndPaymentTerm 3');
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //Test.startTest();
        
        objProposal1.Apttus_Proposal__Payment_Term__c = 'NT30';
        objProposal1.Distributor__c =distAccount.Id;
        update objProposal1;

        //AMEA Region & country not JP
        objAccount.Territory_Region__c = strAMEARegionName; //POL-54
        update objAccount;
        Apttus_Proposal__Proposal__c objProposal2 = TestDataProposal.initProposal(objAccount.id, objOpportunity1.id, 'Test Proposal', objPriceList.id, true, 'Draft', 'None');
        objProposal2.Ultimate_Consignee__c = ucAccount.Id;
        objProposal2.Apttus_Proposal__Account__c = objAccount.Id;
        objProposal2.Apttus_Proposal__Payment_Term__c = 'Test';
        objProposal2.Bill_To__c = objCMDSoldTo.Id;
        insert objProposal2;
        objProposal2.Apttus_Proposal__Payment_Term__c = 'NT30';
        objProposal2.Distributor__c =distAccount.Id;
        update objProposal2;

        //AMEA Region & country JP
        objAccount.Territory_Region__c = strAMEARegionName; //POL-54
        objAccount.BillingCountry = 'Japan';
        objAccount.BillingStateCode = '';
        objAccount.BillingCountryCode = 'JP';
        update objAccount;
        Apttus_Proposal__Proposal__c objProposal4 = TestDataProposal.initProposal(objAccount.id, objOpportunity1.id, 'Test Proposal', objPriceList.id, true, 'Draft', 'None');
        objProposal4.Ultimate_Consignee__c = ucAccount.Id;
        objProposal4.Apttus_Proposal__Account__c = objAccount.Id;
        objProposal4.Apttus_Proposal__Payment_Term__c = 'Test';
        objProposal4.Bill_To__c = objCMDSoldTo.Id;
        insert objProposal4;
        objProposal4.Apttus_Proposal__Payment_Term__c = 'NT30';
        objProposal4.Distributor__c =distAccount.Id;
        update objProposal4;
        
        System.debug('Inside method : testIndirectProposalTransRegionAndPaymentTerm 4');
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());

        Apttus_Proposal__Proposal__c objProposalFinal = [Select Id, Approval_Category__c,Transregion_Flag__c,Apttus_Proposal__Account__r.Territory_Region__c,Ultimate_Consignee__r.Territory_Region__c ,Distributor__r.Territory_Region__c FROM Apttus_Proposal__Proposal__c WHERE Id = :objProposal1.Id];
        System.debug('objProposalFinal'+objProposalFinal);
        test.stopTest();
        system.assert(objProposalFinal.Approval_Category__c.contains('Region'),'Indirect Trans region approvals did not fire.');
        system.assert(objProposalFinal.Approval_Category__c.contains('Terms_of_Payment'),'Payment Terms approvals did not fire.');
       
    }

}