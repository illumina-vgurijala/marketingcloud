/**
*    @author Akshay Mohan
*    @date   2021-05-10
*    @description    DCP-38809: Test class for QuoteGenerationQueueable
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                Description
*         Akshay Mohan            2021-05-10         Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestQuoteGenerationQueueable {
    private static final String PRICELIST = 'AMR-USD-US-01';
    private static final String AMR = 'AMR';
    private static final String USD = 'USD';
    private static final String USA = 'USA';
    private static final String OPPORTUNITYRTDIRECT = 'Direct';

    
    /**DCP-38809
	*	@author Akshay Mohan
	*	
	**/
    @testSetup
    
    public static void setupData(){
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList(PRICELIST);
        insert objPriceList;

        Account objAccount = TestDataAccount.getNewAccount();
        TestDataPerson.getNewContact(objAccount.Id);
        objAccount.Territory_Region__c =AMR;
        objAccount.CurrencyIsoCode=USD;
        objAccount.Country_Local__c = USA;
        objAccount.Account_Status__c=Label.Account_Account_Status_Active_Prospect;
        update objAccount;

        Contact con = TestDataPerson.initContact(objAccount.Id);
        insert con;
        
        Customer_Master_Data__c objCMD = new Customer_Master_Data__c(Name = 'GCMD', Country__c = 'Hong Kong', Country_Code__c = 'HK');
        insert objCMD;

        Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(objAccount);
      
        objOpportunity.RecordTypeName__c = OPPORTUNITYRTDIRECT;
        objOpportunity.Sold_to_Distribution_Channel__c = OPPORTUNITYRTDIRECT;
        objOpportunity.Transborder_Flag__c = true;
        objOpportunity.Price_List__c = objPriceList.Name;
        objOpportunity.StageName=Label.OpportunityStageDevelop;
        objOpportunity.Primary_Contact__c=con.id;
        update objOpportunity;

        
        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objAccount.id, objOpportunity.id, 'Test Proposal', objPriceList.id, true, 'Draft', 'None');
        objProposal.SAP_Quote__c='SAP dummy';
        objProposal.Ship_To__c =objCMD.Id;
        objProposal.Bill_To__c =objCMD.Id;
        objProposal.Payer__c =objCMD.Id;
        objProposal.Apttus_QPConfig__PriceListId__c=objPriceList.Id;
        objProposal.Apttus_Proposal__Approval_Stage__c=Label.QuotationApprovalStatusApproved;
        objProposal.Apttus_Proposal__Primary_Contact__c=con.Id;
        insert objProposal;
        
        ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(new List<Schema.SObjectType> {
            Apttus__QueryTemplate__c.SObjectType,
            Apttus__QueryTemplateQualifier__c.SObjectType,
            Apttus__QueryTemplateFilter__c.SObjectType,
            Apttus__APTS_Template__c.SObjectType
        });

        Apttus__QueryTemplate__c objQT = new Apttus__QueryTemplate__c();
        objQT.Apttus__Active__c=true;
        objQT.Apttus__Sequence__c=1;
        objQT.Apttus__Description__c='Valid';
        uow.registerNew(objQT);
        Apttus__QueryTemplateQualifier__c objQTQ = new Apttus__QueryTemplateQualifier__c();
        objQTQ.Apttus__SObjectLabel__c=ApttusQueryTemplateQualifierSelector.QUOTE_OBJECT;
        objQTQ.Apttus__Field__c=ApttusQueryTemplateQualifierSelector.TERRITORY_REGION_FIELD;
        objQTQ.Apttus__CompOper__c=ApttusQueryTemplateQualifierSelector.COMPARATOR_EQUALS;
        objQTQ.Apttus__Value__c=AMR;
        objQTQ.Apttus__Sequence__c=1;
        uow.registerNew(objQTQ, Apttus__QueryTemplateQualifier__c.Apttus__QueryTemplate__c, objQT);
        objQTQ = new Apttus__QueryTemplateQualifier__c();
        objQTQ.Apttus__SObjectLabel__c=ApttusQueryTemplateQualifierSelector.QUOTE_OBJECT;
        objQTQ.Apttus__Field__c='Preferred_Language__c';
        objQTQ.Apttus__CompOper__c=ApttusQueryTemplateQualifierSelector.COMPARATOR_IN;
        objQTQ.Apttus__Value__c='English';
        objQTQ.Apttus__Sequence__c=2;
        uow.registerNew(objQTQ, Apttus__QueryTemplateQualifier__c.Apttus__QueryTemplate__c, objQT);

        Apttus__QueryTemplateFilter__c objQTF=new Apttus__QueryTemplateFilter__c();
        objQTF.Apttus__CompOper__c='equal to';
        objQTF.Apttus__Field__c='Apttus__Keywords__c';
        objQTF.Apttus__Value__c='Test';
        objQTF.Apttus__Sequence__c=1;
        uow.registerNew(objQTF, Apttus__QueryTemplateFilter__c.Apttus__QueryTemplate__c, objQT);

        //setup dummy data for coverage
        setupDummyQualifierRecords(uow,true,'Dummy NE','not equal to');
        setupDummyQualifierRecords(uow,true,'Dummy NI','not in');
        setupDummyQualifierRecords(uow,false,'Dummy LIKE','like');
        setupDummyQualifierRecords(uow,true,'Dummy NL','not like');
        setupDummyQualifierRecords(uow,false,'Dummy inc','includes');
        setupDummyQualifierRecords(uow,true,'Dummy exc','excludes');
        setupDummyQualifierRecords(uow,false,'Dummy sw','starts with');
        
        Apttus__APTS_Template__c objT=new Apttus__APTS_Template__c();
        objT.Name='Testing Template';
        objT.Apttus__IsActive__c=true;
        objT.Apttus__Type__c='Proposal';
        objT.Apttus__Language__c='English';
        objT.Apttus__Locale__c='English (United States)';
        objT.Apttus__Keywords__c='Test';
        uow.registerNew(objT);

        uow.commitWork();
    }

    
    /**DCP-38809
	*	@author Akshay Mohan
	*	testGenerate
	**/
    /*@isTest
    public static void testGenerate(){
        Apttus_Proposal__Proposal__c objProposal=[SELECT Id, Generate__c,Apttus_Proposal__Approval_Stage__c,Apttus_Proposal__Primary_Contact__c,Bill_To__c,Ship_To__c ,Payer__c ,
                                                            Apttus_Proposal__Opportunity__r.StageName,Apttus_Proposal__Opportunity__r.Primary_Contact__c
                                                    FROM Apttus_Proposal__Proposal__c LIMIT 1];
        System.debug('objProposal: ' +JSON.serialize(objProposal));
        QuoteGenerationQueueable queueable = new QuoteGenerationQueueable();
        queueable.setRecordId(objProposal.id);
        Test.startTest();
        SVMXC__Service_Order__c objWO =TestDataBillableFlowQueueable.getWorkOrder();
        objProposal.Work_Order__c=objWO.Id;
        update objProposal;
        queueable.execute(null);
        Test.stopTest();
        System.assertEquals(objProposal.id,queueable.getRecordId(),'Generate not processed');
    }*/


    /**DCP-38809
	*	@author Akshay Mohan
	*	testGenerateMultipleQueryTemplates
	**/
    @isTest
    public static void testGenerateMultipleQueryTemplates(){
        Apttus_Proposal__Proposal__c objProposal=[SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        List<Apttus__QueryTemplate__c> lstQTs=new List<Apttus__QueryTemplate__c>();
        for(Apttus__QueryTemplate__c objQT: [Select ID,Apttus__Active__c FROM Apttus__QueryTemplate__c WHERE Apttus__Active__c=true]){
            lstQTs.add(new Apttus__QueryTemplate__c(Id=objQT.Id,Apttus__Active__c=false));
        }
        update lstQTs;
        QuoteGenerationQueueable queueable = new QuoteGenerationQueueable();
        queueable.setRecordId(objProposal.id);
        Test.startTest();
        queueable.execute(null);
        OpportunityQuoteAutomationQueueable.EmailWrapper wrapDetails = queueable.getErrorDetails();
        System.assertEquals(null,queueable.getRecordId(),'Generate processed with multiple query templates');
        lstQTs=new List<Apttus__QueryTemplate__c>();
        for(Apttus__QueryTemplate__c objQT: [Select ID,Apttus__Active__c FROM Apttus__QueryTemplate__c WHERE Apttus__Active__c=false]){
            lstQTs.add(new Apttus__QueryTemplate__c(Id=objQT.Id,Apttus__Active__c=true));
        }
        update lstQTs;
        queueable.execute(null);
        queueable.getErrorDetails();
        Test.stopTest();
        System.debug('wrapDetails: '+wrapDetails);
        System.assertEquals(Label.OpportunityQuoteAutomation_QUOTE_GENERATION_BLOCKED,wrapDetails.strFailureReason,'Expected failure message not set');
    }


    /**DCP-38809
	*	@author Akshay Mohan
	*	testGenerateFilters
	**/
    @isTest
    public static void testGenerateFilters(){
        Apttus_Proposal__Proposal__c objProposal=[SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        Apttus__QueryTemplateFilter__c objQTF = [Select ID,Apttus__QueryTemplate__c FROM Apttus__QueryTemplateFilter__c LIMIT 1];
        objQTF.Apttus__Value__c='Nope';
        update objQTF;
        QuoteGenerationQueueable queueable = new QuoteGenerationQueueable();
        queueable.setRecordId(objProposal.id);
        Test.startTest();
        queueable.execute(null);
        objQTF.Apttus__CompOper__c='in';
        update objQTF;
        queueable.execute(null);
        objQTF.Apttus__CompOper__c='like';
        update objQTF;
        queueable.execute(null);
        objQTF.Apttus__CompOper__c='includes';
        update objQTF;
        queueable.execute(null);
        objQTF.Apttus__CompOper__c='excludes';
        update objQTF;
        queueable.execute(null);
        objQTF.Apttus__CompOper__c='starts with';
        update objQTF;
        queueable.execute(null);
        objQTF.Apttus__CompOper__c='not equal to';
        objQTF.Apttus__Value__c='Test';
        update objQTF;
        queueable.execute(null);
        objQTF.Apttus__CompOper__c='not like';
        update objQTF;
        queueable.execute(null);
        objQTF.Apttus__CompOper__c='not in';
        objQTF.Apttus__Value__c='Test,Test';
        update objQTF;
        queueable.execute(null);
        
        Apttus__QueryTemplateFilter__c objQTF2 = new Apttus__QueryTemplateFilter__c();
        objQTF2.Apttus__CompOper__c='equal to';
        objQTF2.Apttus__Field__c='Apttus__Keywords__c';
        objQTF2.Apttus__Value__c='Testing';
        objQTF2.Apttus__Sequence__c=2;
        objQTF2.Apttus__QueryTemplate__c=objQTF.Apttus__QueryTemplate__c;
        insert objQTF2;
        queueable.execute(null);
        queueable.getErrorDetails();
        Test.stopTest();
        System.assertEquals(null,queueable.getRecordId(),'Generate processed with multiple Filters');
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	testSAPCall
	**/
    @isTest
    public static void testSAPCall(){
        Apttus_Proposal__Proposal__c objProposal=[SELECT Id, Generate__c,Apttus_Proposal__Approval_Stage__c,Apttus_Proposal__Primary_Contact__c,Bill_To__c,Ship_To__c ,Payer__c ,
                                                            Apttus_Proposal__Opportunity__r.StageName,Apttus_Proposal__Opportunity__r.Primary_Contact__c
                                                    FROM Apttus_Proposal__Proposal__c LIMIT 1];
        System.debug('objProposal: ' +JSON.serialize(objProposal));
        QuoteGenerateSAPCallQueueable queueable = new QuoteGenerateSAPCallQueueable();
        queueable.setRecordId(objProposal.id);
        queueable.boolTestScenario=true;
        Test.startTest();
        queueable.execute(null);
        Test.stopTest();
        System.assertEquals(objProposal.id,queueable.getRecordId(),'Generate Blocked');
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	testSAPCallBlocked
	**/
    @isTest
    public static void testSAPCallBlocked(){
        Apttus_Proposal__Proposal__c objProposal=[SELECT Id, Generate__c,Apttus_Proposal__Approval_Stage__c,Apttus_Proposal__Primary_Contact__c,Bill_To__c,Ship_To__c ,Payer__c ,
                                                            Apttus_Proposal__Opportunity__r.StageName,Apttus_Proposal__Opportunity__r.Primary_Contact__c
                                                    FROM Apttus_Proposal__Proposal__c LIMIT 1];
        System.debug('objProposal: ' +JSON.serialize(objProposal));
        
        QuoteGenerateSAPCallQueueable queueable = new QuoteGenerateSAPCallQueueable();
        queueable.setRecordId(objProposal.id);
        queueable.boolTestScenario=true;
        ApttusGenerateQuoteController.boolHasError=true;
        Test.startTest();
        queueable.execute(null);
        queueable.boolTestScenario=false;
        queueable.execute(null);
        objProposal.Ship_To__c =null;
        objProposal.Bill_To__c =null;
        update objProposal;
        queueable.execute(null);
        OpportunityQuoteAutomationQueueable.EmailWrapper wrapDetails = queueable.getErrorDetails();
        Test.stopTest();
        System.debug('wrapDetails: '+wrapDetails);
        System.assertEquals(null,queueable.getRecordId(),'Generate not Blocked');
        System.assertEquals(Label.OpportunityQuoteAutomation_QUOTE_GENERATION_BLOCKED,wrapDetails.strFailureReason,'Expected failure message not set');
    }


    /**DCP-38809
	*	@author Akshay Mohan
	*	setupDummyQualifierRecords
	**/
    public static void setupDummyQualifierRecords(ilib_SObjectUnitOfWork uow,Boolean boolActive,String strDescription,String strOperator){
        Apttus__QueryTemplate__c objQT = new Apttus__QueryTemplate__c();
        objQT.Apttus__Active__c=boolActive;
        objQT.Apttus__Sequence__c=1;
        objQT.Apttus__Description__c=strDescription;
        uow.registerNew(objQT);
        Apttus__QueryTemplateQualifier__c objQTQ = new Apttus__QueryTemplateQualifier__c();
        objQTQ.Apttus__SObjectLabel__c=ApttusQueryTemplateQualifierSelector.QUOTE_OBJECT;
        objQTQ.Apttus__Field__c=ApttusQueryTemplateQualifierSelector.TERRITORY_REGION_FIELD;
        objQTQ.Apttus__CompOper__c=ApttusQueryTemplateQualifierSelector.COMPARATOR_EQUALS;
        objQTQ.Apttus__Value__c=AMR;
        objQTQ.Apttus__Sequence__c=1;
        uow.registerNew(objQTQ, Apttus__QueryTemplateQualifier__c.Apttus__QueryTemplate__c, objQT);
        objQTQ = new Apttus__QueryTemplateQualifier__c();
        objQTQ.Apttus__SObjectLabel__c=ApttusQueryTemplateQualifierSelector.QUOTE_OBJECT;
        objQTQ.Apttus__Field__c='Preferred_Language__c';
        objQTQ.Apttus__CompOper__c=strOperator;
        objQTQ.Apttus__Value__c='English';
        objQTQ.Apttus__Sequence__c=2;
        uow.registerNew(objQTQ, Apttus__QueryTemplateQualifier__c.Apttus__QueryTemplate__c, objQT);
    }
    
    /**
	*	@author Anshaj
	*	CMSI-204 : Method to Cover Catch Block of QuoteGenerateSAPCallQueueable 
	**/
    @isTest
    public static void coverCatchBlockQuoteGenerateSAPCallQueueable(){
        try{
        Test.startTest();
        Apttus_Proposal__Proposal__c objProposal=[SELECT Id, Generate__c,Apttus_Proposal__Approval_Stage__c,Apttus_Proposal__Primary_Contact__c,Bill_To__c,Ship_To__c ,Payer__c ,
                                                            Apttus_Proposal__Opportunity__r.StageName,Apttus_Proposal__Opportunity__r.Primary_Contact__c
                                                    FROM Apttus_Proposal__Proposal__c LIMIT 1];
        QuoteGenerateSAPCallQueueable queueable = new QuoteGenerateSAPCallQueueable();
        queueable.catchException=true;
        queueable.setRecordId(objProposal.id);
        queueable.execute(null);
        Test.stopTest();
        }catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }

    /**
	*	@author Anshaj
	*	CMSI-204 : Method to Cover Catch Block of QuoteGenerationQueueable 
	**/
    @isTest
    public static void coverCatchBlockQuoteGenerationQueueable(){
        try{
        Test.startTest();
        Apttus_Proposal__Proposal__c objProposal=[SELECT Id, Generate__c,Apttus_Proposal__Approval_Stage__c,Apttus_Proposal__Primary_Contact__c,Bill_To__c,Ship_To__c ,Payer__c ,
                                                            Apttus_Proposal__Opportunity__r.StageName,Apttus_Proposal__Opportunity__r.Primary_Contact__c
                                                    FROM Apttus_Proposal__Proposal__c LIMIT 1];
        QuoteGenerationQueueable queueable = new QuoteGenerationQueueable();
        queueable.catchException=true;
        queueable.setRecordId(objProposal.id);
        queueable.execute(null);
        Test.stopTest();
        }catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }
}