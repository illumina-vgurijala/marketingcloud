/**
* @desc TestApttusPreviewApprovals
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Adyasha Satapathy                28-Nov-2022             POL-54: Update region references to AMEA and EUR
*       Gerardo Garcia                   24-Jan-2024             CMCM-5310 Refactor tests.
*/
@isTest
public class TestApttusPreviewApprovals {

    @testSetup
    static void setupData(){
        User currentUser = [SELECT id FROM User WHERE id=:UserInfo.getUserId() LIMIT 1];
        User anotherAdmin;
        System.runAs(currentUser) {
            anotherAdmin = TestDataUser.initAdminUser();
            insert anotherAdmin;

            cs_Apex_Settings__c cs = new cs_Apex_Settings__c();
            cs.Bypass_All_Validations__c = true;
            cs.Bypass_All_Triggers__c = true;
            cs.SetupOwnerId = anotherAdmin.Id;
            insert cs;
        }

        System.runAs(anotherAdmin) {
            fillData();
        }
    }

    private static void fillData() {
        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=userinfo.getProfileId(),
            Channel_Partner_Agreement__c = true,
            Master_Customer_Agreement__c = true,
            Master_Service_Agreement__c = true,
            Negotiated_Terms_and_Conditions__c = true,
            Standing_Quote__c = true,
            Tender__c = true);
        insert profilevalidation;

        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        insert acc;

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        
        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '123456';
        objCMD2.ERP_Customer_Id__c = '234567';
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMEA-USD'; //POL-54
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.ERP_Account_Sales_Area_Id__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        insert acc1SalesArea;

        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(acc);
        objOpportunity.Price_List__c = priceList.Name;
        objOpportunity.RecordTypeName__c = 'Direct';
        objOpportunity.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity.Transborder_Flag__c = true;
        insert objOpportunity;
 
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, objOpportunity.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        insert proposal;

        //Added by Umesh Mor
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc.id);
        //oAgreement1.Customer_Discount_Level__c = 'Price Group';
        oAgreement1.Apttus__Total_Contract_Value__c = 100;
        oAgreement1.Justification_for_No_Agreement_Value__c = null;
        oAgreement1.Freight_Charge__c = 'Standard';
        insert oAgreement1;

        //Apttus_Approval__Approval_Request__c objAggreementApprovalRequest1 = TestDataProposal.initAgreementApprovalRequest(oAgreement1.Id);
        //End of the code Added by Umesh
        
        Product2 objProduct = TestDataMaster.createProduct(false);
        objProduct.Material_Number__c = '11234187';
        objProduct.Product_Group_Code__c = 'SQ0HSP0HCV0HV2';
        objProduct.Product_Group_Code__c = 'NovaSeq 6000 Service Contracts	';
        objProduct.Product_Category_Code__c = 'SQ0HSP';
        objProduct.Product_Category__c = 'NovaSeq';
        insert objProduct;

        Apttus_Config2__PriceListItem__c priceListItem = TestDataProposal.initPriceListItem(objProduct, priceList);
        insert priceListItem;

        insertMatrix(objProduct);

        insertRequest(proposal);
    }

    private static void insertMatrix(Product2 objProduct) {
        Apttus_Config2__ClassificationName__c category = TestDataProposal.initCategory('Test Category');
        insert category;

        List<Apttus_Config2__ClassificationHierarchy__c> lstHierarchy = new List<Apttus_Config2__ClassificationHierarchy__c>();

        Apttus_Config2__ClassificationHierarchy__c level0= TestDataProposal.initHierarchy(category, 'Level0', null, null, 0);
        lstHierarchy.add(level0);

        Apttus_Config2__ClassificationHierarchy__c level1= TestDataProposal.initHierarchy(category, 'Level1', level0, level0, 1);
        lstHierarchy.add(level1);

        Apttus_Config2__ClassificationHierarchy__c level2= TestDataProposal.initHierarchy(category, 'Level2', level0, level1, 2);
        lstHierarchy.add(level2);

        Apttus_Config2__ClassificationHierarchy__c level3= TestDataProposal.initHierarchy(category, 'Level_3', level0, level2, 3);
        lstHierarchy.add(level3);

        Apttus_Config2__ClassificationHierarchy__c level4= TestDataProposal.initHierarchy(category, 'Level_4', level0, level3, 4);
        lstHierarchy.add(level4);

        insert lstHierarchy;

        List<Approval_Hierarchy__c> lstApprovalHierarchy = new List<Approval_Hierarchy__c>();

        Approval_Hierarchy__c objPPMApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('Post_Pricing_Message');
        lstApprovalHierarchy.add(objPPMApprovalHeirarchy);
        Approval_Hierarchy__c objClmCustomApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('CLM_Custom_Hierarchy');
        lstApprovalHierarchy.add(objClmCustomApprovalHeirarchy);
        Approval_Hierarchy__c objClmSalesApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('CLM_Sales_Hierarchy');
        lstApprovalHierarchy.add(objClmSalesApprovalHeirarchy);
        Approval_Hierarchy__c objCPQCustomApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('CPQ_Custom_Hierarchy');
        lstApprovalHierarchy.add(objCPQCustomApprovalHeirarchy);
        Approval_Hierarchy__c objCPQSalesApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('CPQ_Sales_Hierarchy');
        lstApprovalHierarchy.add(objCPQSalesApprovalHeirarchy);  
        Approval_Hierarchy__c objPromotionApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('Promotion');
        lstApprovalHierarchy.add(objPromotionApprovalHeirarchy);

        insert lstApprovalHierarchy;

        Custom_Approval_Matrix__c promoApprovalMatrix = TestDataProposal.initApprovalMatrixForPromotion('Promotion', 'BOGO', '2', objPromotionApprovalHeirarchy);
        insert promoApprovalMatrix;

        Apttus_Config2__ProductClassification__c prodClassification = TestDataProposal.initProductClassification(level4, objProduct);
        insert prodClassification;
    }

    private static void insertRequest(Apttus_Proposal__Proposal__c proposal) {
        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest= new List<Apttus_Approval__Approval_Request__c>();

        Apttus_Approval__Approval_Request__c objApprovalRequest = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameTransregionLeadership;
        lstApprovalRequest.add(objApprovalRequest);
       
        Apttus_Approval__Approval_Request__c objApprovalRequest2 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest2.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameUltimateConsignee;
        lstApprovalRequest.add(objApprovalRequest2);

        Apttus_Approval__Approval_Request__c objApprovalRequest3 = TestDataProposal.initApprovalRequest(proposal.Id);
        lstApprovalRequest.add(objApprovalRequest3);

        Apttus_Approval__Approval_Request__c objApprovalRequest4 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest4.Apttus_Approval__StepSequence__c = 2.1;
        objApprovalRequest4.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameSalesDiscretionary;
        lstApprovalRequest.add(objApprovalRequest4);
        
        Apttus_Approval__Approval_Request__c objApprovalRequest5 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest5.Apttus_Approval__StepSequence__c = 3.1;
        objApprovalRequest5.Apttus_Approval__Sequence__c = '2';
        objApprovalRequest5.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameSalesDiscretionary;
        lstApprovalRequest.add(objApprovalRequest5);

        Apttus_Approval__Approval_Request__c objApprovalRequest6 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest6.Apttus_Approval__StepSequence__c = 4.1;
        lstApprovalRequest.add(objApprovalRequest6);

        Apttus_Approval__Approval_Request__c objApprovalRequest7 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest7.Apttus_Approval__StepSequence__c = 5.1;
        objApprovalRequest7.Apttus_Approval__Sequence__c = '3';
        lstApprovalRequest.add(objApprovalRequest7);

        Apttus_Approval__Approval_Request__c objApprovalRequest8 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest8.Apttus_Approval__StepSequence__c = 6.1;
        objApprovalRequest8.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameTransregionLeadership;
        lstApprovalRequest.add(objApprovalRequest8);

        Apttus_Approval__Approval_Request__c objApprovalRequest9 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest9.Apttus_Approval__StepSequence__c = 7.1;
        objApprovalRequest9.Apttus_Approval__Sequence__c = '4';
        objApprovalRequest9.Apttus_Approval__SubstepSequence__c = 1.0000;
        objApprovalRequest9.Apttus_Approval__Step_Name__c = 'Trans Border';
        lstApprovalRequest.add(objApprovalRequest9);

        Apttus_Approval__Approval_Request__c objApprovalRequest10 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest10.Apttus_Approval__StepSequence__c = 8.1;
        objApprovalRequest10.Apttus_Approval__StepLabel__c = '1';
        objApprovalRequest10.Apttus_Approval__Sequence__c = '5';
        objApprovalRequest10.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameTransregionLeadership;
        lstApprovalRequest.add(objApprovalRequest10);
        
        Apttus_Approval__Approval_Request__c objApprovalRequest11 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest11.Apttus_Approval__StepSequence__c = 8.1;
        objApprovalRequest11.Apttus_Approval__StepLabel__c = '1';
        objApprovalRequest11.Apttus_Approval__Sequence__c = '5';
        objApprovalRequest11.Apttus_Approval__SubstepSequence__c = 1.0000;
        objApprovalRequest11.Apttus_Approval__Step_Name__c ='Trans Border';

        Apttus_Approval__Approval_Request__c objApprovalRequest12 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest12.Apttus_Approval__StepSequence__c = 8.1;
        objApprovalRequest12.Apttus_Approval__StepLabel__c = '2';
        objApprovalRequest12.Apttus_Approval__Sequence__c = '6';
        objApprovalRequest12.Apttus_Approval__SubstepSequence__c = 2.0000;
        objApprovalRequest12.Apttus_Approval__Step_Name__c ='Trans Border';
        lstApprovalRequest.add(objApprovalRequest12);

        insert lstApprovalRequest;
    }

    @isTest
    static void testPreviewApprovals() {

        Opportunity objOpportunity = [SELECT id FROM Opportunity LIMIT 1];

        Apttus_Proposal__Proposal__c objProposal = [SELECT id FROM Apttus_Proposal__Proposal__c 
            WHERE Apttus_Proposal__Opportunity__c = :objOpportunity.Id 
            AND Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];

         // Create cart
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = objProposal.Id;
        Apttus_CPQApi.CPQWebService.createCart(request);

        Apttus_Config2__ProductConfiguration__c productConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];  
        productConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        update productConfig;
        
        Product2 product = [SELECT id FROM Product2 LIMIT 1];
        Apttus_Config2__PriceListItem__c objPLI = [SELECT Id,Apttus_Config2__IsQuantityReadOnly__c FROM Apttus_Config2__PriceListItem__c LIMIT 1];

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(objProposal, product);
        proposalLineItem.Apttus_QPConfig__HasIncentives__c = true;
        proposalLineItem.Apttus_QPConfig__ConfigurationId__c = productConfig.id;
        insert proposalLineItem;
    
        Test.setCurrentPageReference(new PageReference('Page.ApttusPreviewApprovals')); 
        System.currentPageReference().getParameters().put('businessObjectId', objProposal.Id);
        System.currentPageReference().getParameters().put('id', productConfig.Id);

        Test.startTest();

        ApttusPreviewApprovalsController pac = new ApttusPreviewApprovalsController();
        pac.previewApprovals();

        Test.stopTest();
        Assert.isTrue(pac.lstApprovalRequestWrapper != null, 'Error in PreviewApprovals functionality');
        Assert.areEqual('Trans-Region Leadership', pac.lstApprovalRequestWrapper.get(0).strApprovalName, 'Approval name are different.');
        Assert.areEqual('1', pac.lstApprovalRequestWrapper.get(0).lstApprovalSequence.get(0), 'Approver Level not matched.');
    }
    
    //Added by Umesh Mor
      @isTest
    static void testDisplayAgreements() {

        Test.startTest();
        //INC0291672- Added PricelistItem for material
        product2 product = [SELECT id FROM product2 where Material_Number__c = '11234187'];
        Apttus_Config2__PriceList__c objPriceList = TestDataAgreement.initPriceList('06-SGD-USD');
        insert objPriceList;
       
        Apttus_Config2__PriceListItem__c objPriceListItem = TestDataAgreement.initPriceListItem(product, objPriceList);
        insert objPriceListItem ;
        
        Apttus__APTS_Agreement__c agreement = [SELECT Id FROM Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group' ];
    
        Apttus__AgreementLineItem__c oAgreementLI1 = TestDataAgreement.initAgreementsLineItem(agreement.id);
        oAgreementLI1.Material_Group_1__c = 'BGS';
        oAgreementLI1.Line_Type__c = 'Price Group - Material';
        oAgreementLI1.Apttus_CMConfig__LineNumber__c = 4;
        oAgreementLI1.Apttus_CMConfig__ItemSequence__c = 4;
        oAgreementLI1.Discount_Type__c = '% Discount';
        oAgreementLI1.Apttus_CMConfig__StartDate__c = system.today()+1;
        oAgreementLI1.Apttus_CMConfig__EndDate__c = system.today()+2;
        oAgreementLI1.Material_Number__c = '11234187';
        oAgreementLI1.Sales_Org__c = 'HK01';
        oAgreementLI1.Customer_ERP_Number__c = '123456';
        oAgreementLI1.Distribution_Channel__c = '01';
        oAgreementLI1.CurrencyIsoCode= 'USD';
        oAgreementLI1.Discount__c = 15;
        oAgreementLI1.Price_Group__c = 'TXDR';
        oAgreementLI1.Material_Group_1__c='AIM';
        insert oAgreementLI1;
        
        Test.setCurrentPageReference(new PageReference('Page.PreviewSubmitApprovals'));
        System.currentPageReference().getParameters().put('sObjectId', agreement.Id);
        ApttusAgrementApprovalController objController = new ApttusAgrementApprovalController();
            
        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = [SELECT Id FROM Apttus_Approval__Approval_Request__c WHERE Apttus_Approval__Related_Agreement__c =: agreement.Id];
        
        Assert.isTrue(oAgreementLI1.Id != null,'Agreement not inserted correctly');
        
        if(!lstApprovalRequest.isEmpty()) {
            objController.objApprovalRequest = lstApprovalRequest.get(0);
            objController.objApprovalRequest.Apttus_Approval__Assigned_To_Name__c = 'Test Approver';
            objController.objApprovalRequest.Apttus_Approval__Approval_Status__c = 'Assigned';
            //objController.boolSkipPreviewApprovalsAPI = true;
            update objController.objApprovalRequest;
            //objController.previewAgreements();
        }
        
        Test.stopTest();
    }
}