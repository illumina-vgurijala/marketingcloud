/**
 * @author Kristiyan Petkov
 * @date   16-Nov-2018
 * @description  Test class of DCP-15146 Selection of Explicit Promotions
 * Modification Log:
 *  --------------------------------------------------------------------------------------------------
 *   Developer                Date                Description                                                  
 *   Kristiyan Petkov         16-Nov-2018         Original Version
 *   Prakhar Kumar            20-Sept-2019        Added code coverage for CustomIterable,IncentivesWrapper Classes,ApttusGetPromotionsController
 *   Prabhsimran Singh        4-April-2020        SonarQube issues fixes
 *   Raja Siva Krishna        10-Sept-2020        DCP-40230-Made data changes for ApttusGetPromotionsController
 *   Himanshu                 20-April-2022       Code Scan Fixes    
 *   Adyasha Satapathy        12-Oct-2022         Code Scan Fixes(Method Naming Convention)
 *   Adyasha Satapathy        28-Nov-2022         POL-54: Update region references to AMEA and EUR
 *   Prem Ranjan              15-Dec-2022         POL-116 Deactivate APAC and Add AMEA, China
 * ---------------------------------------------------------------------------------------------------
 **/
@isTest(isParallel=true) 
public class TestApttusGetPromotionsController {

    public static final Integer INTEGER_QUANTITY = 2;
    public static final Integer INTEGER_SHIPPING_IN_CLOSE_QUARTER = 1;

    /**
    *  @author      : Kristiyan Petkov
    *  @description : Prepare Test Data
    */
    @testSetup
    static void setupData(){
        Account objAcc = TestDataAccount.getNewAccount();
        TestDataPerson.getNewContact(objAcc.Id);
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert objPriceList;

        objAcc.Territory_Region__c = 'AMR';//DCP-40230
        update objAcc;//DCP-40230

        Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(objAcc);
        objOpportunity.Ultimate_Consignee__c = objAcc.Id;
        objOpportunity.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity.Price_List__c = objPriceList.Name;
        update objOpportunity; 
        
        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objAcc.id, objOpportunity.id, 'Test Proposal', objPriceList.id, true, 'Draft', 'None');
        insert objProposal;
        
        Product2 objProduct = TestDataMaster.createProduct(true); 
        
        Apttus_Config2__ProductConfiguration__c testCart = TestDataProposal.getNewCart(objProposal);
        testCart.Apttus_Config2__AccountId__c = objAcc.Id;//DCP-40230
        update testCart;//DCP-40230
        
        Apttus_Config2__LineItem__c objLineItem = TestDataProposal.getNewLineItem(testCart.Id,objProduct.Id,INTEGER_QUANTITY,INTEGER_SHIPPING_IN_CLOSE_QUARTER);
        Apttus_Config2__LineItem__c objLineItem2 = TestDataProposal.getNewLineItem(testCart.Id,objProduct.Id,INTEGER_QUANTITY,INTEGER_SHIPPING_IN_CLOSE_QUARTER);
        insert new List<Apttus_Config2__LineItem__c>{objLineItem,objLineItem2};

        Apttus_Config2__Incentive__c incentive = TestDataIncentives.initIncentive();
        incentive.Apttus_Config2__ExpirationDate__c  = system.Today()+1;
        incentive.Promotion_Redemption_Method__c = 'E';
        incentive.Regions__c = 'AMR;AMEA;China';
        incentive.Promo_Channel__c = 'O1;F2';
        incentive.Promotion_Details__c = 'TestPromotionDetails2';
        incentive.Sales_Description__c = 'TestSalesDescription';
        incentive.Promotion_Channel_Description__c ='Online/Quoting;Quoting Only;Quoting Only – One Use Per UC;Quoting Only – Two Uses Per UC';
        incentive.Limit_View__C = true;

        Apttus_Config2__Incentive__c incentive2 = TestDataIncentives.initIncentive();
        incentive2.Apttus_Config2__ExpirationDate__c  = system.Today()+1;
        incentive2.Promotion_Redemption_Method__c = 'E';
        incentive2.Regions__c = 'AMR;EUR';//POL-54
        incentive2.Promo_Channel__c = 'O2;F1';
        incentive2.Promotion_Details__c = 'TestPromotionDetails';
        incentive2.Sales_Description__c = 'TestSalesDescription2';
        incentive2.Promotion_Channel_Description__c ='Online/Quoting;Quoting Only;Quoting Only – One Use Per UC';
        incentive2.Limit_View__C = false;

        Apttus_Config2__Incentive__c incentive3 = TestDataIncentives.initIncentive();
        incentive3.Apttus_Config2__ExpirationDate__c  = system.Today()+1;
        incentive3.Promotion_Redemption_Method__c = 'E';
        incentive3.Regions__c = 'AMEA';
        incentive3.Promo_Channel__c = 'O3;F3';
        incentive3.Promotion_Details__c = 'TestPromotionDetails3';
        incentive3.Sales_Description__c = 'TestSalesDescription3';
        incentive3.Promotion_Channel_Description__c ='Online/Quoting;Quoting Only';
        incentive3.Limit_View__C = true;

        List<Apttus_Config2__Incentive__c> listOfPRomotionsToInsert = new List<Apttus_Config2__Incentive__c>{incentive,incentive2, incentive3};
        insert listOfPRomotionsToInsert;
    }

    /**
    *  @author      : Kristiyan Petkov
    *  @description : Happy Path test method
    */
    @isTest
    static void applyPromotions(){
         Map<Id, Apttus_Config2__Incentive__c> mapSelectedIncentives = new Map<Id, Apttus_Config2__Incentive__c>();
         List<Apttus_Config2__Incentive__c> listSelectedIncentives = new List<Apttus_Config2__Incentive__c>();
         Boolean hasPrevious;
         Boolean hasNext;
        String strTest = 'test';        

        Opportunity objOpportunity = [Select id From Opportunity LIMIT 1];
        Apttus_Proposal__Proposal__c objProposal = [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id and Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        
        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id, Apttus_Config2__AccountId__c, Promo_Name_1__c, Promo_Name_2__c, Promo_Name_3__c  from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
        objProductConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        update objProductConfig;

        Test.setCurrentPageReference(new PageReference('Page.ApttusGetPromotions'));
        System.currentPageReference().getParameters().put('businessObjectId', objProposal.Id);
        System.currentPageReference().getParameters().put('flow', 'IndirectOppFlow');
        System.currentPageReference().getParameters().put('Id',objProductConfig.Id );

        List<Apttus_Config2__Incentive__c> listOfInsertedPromotions = [SELECT Id, Name, Apttus_Config2__IncentiveCode__c from Apttus_Config2__Incentive__c];

        for(Apttus_Config2__Incentive__c incentive : listOfInsertedPromotions){
            mapSelectedIncentives.put(incentive.id, incentive);
            listSelectedIncentives.add(incentive);
        }

        objProductConfig.Promo_Name_1__c = listSelectedIncentives[0].Apttus_Config2__IncentiveCode__c;
        objProductConfig.Promo_Name_2__c = listSelectedIncentives[1].Name;
        objProductConfig.Promo_Name_3__c = listSelectedIncentives[2].Name;
        update objProductConfig;
        
        List <IncentivesWrapper> lstIncentivesWrapperObj1 = new List <IncentivesWrapper>();
        Apttus_Config2__Incentive__c ac;
        CustomIterable ob = new CustomIterable(lstIncentivesWrapperObj1);
        List<Apttus_Config2__Incentive__c> lstAptIncentive = new List<Apttus_Config2__Incentive__c>();
        for(integer j=0;j<20;j++){
            ac = new Apttus_Config2__Incentive__c();
            ac.Apttus_Config2__IncentiveCode__c  = String.valueof(j);
            ac.Apttus_Config2__Description__c = strTest+j;
            ac.Regions__c = 'AMR;EUR;AMEA';
			ac.Promotion_Channel_Description__c = 'Online/Quoting;Quoting Only;Quoting Only – One Use Per UC;Quoting Only – Two Uses Per UC;Quoting Only – Three Uses Per UC;Online/Quoting – One User Per UC;Online/Quoting – Two Uses Per UC;Online/Quoting – Three Uses Per UC';
			ac.Limit_View__C = False;
            ac.Apttus_Config2__Sequence__c = j;
            lstAptIncentive.add(ac);
            
        }
        insert lstAptIncentive;
        for(Apttus_Config2__Incentive__c aptConfig : lstAptIncentive){
            IncentivesWrapper iW1 = new IncentivesWrapper (aptConfig,true);
            lstIncentivesWrapperObj1.add(iW1);
            
            ob.ListRequested.add(iW1);
        }
         IncentivesWrapper iW = new IncentivesWrapper (ac,true);
         List <IncentivesWrapper> lstIncentivesWrapperObj = new List <IncentivesWrapper>();
         lstIncentivesWrapperObj.add(iW);
 
        Test.startTest();
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(listSelectedIncentives);
        stdSetController.setSelected(listSelectedIncentives);
        ApttusGetPromotionsController promotionsController = new ApttusGetPromotionsController();
        promotionsController.getItems();
        promotionsController.getSelectedIncentives();
        promotionsController.save();
       
        hasNext = promotionsController.hasNext;
        hasPrevious = promotionsController.hasPrevious;
                 
        promotionsController.searchPromo = 'Description';
        promotionsController.typeAheadSearchPromotions();

        promotionsController.searchPromo = '2345';
        promotionsController.typeAheadSearchPromotions();

        promotionsController.searchPromo = 'TestIncentive';
        promotionsController.typeAheadSearchPromotions();

        promotionsController.searchPromo = 'TestSalesDescription';
        promotionsController.typeAheadSearchPromotions();

        promotionsController.searchPromo = 'PromotionDetails';
        promotionsController.typeAheadSearchPromotions();
        
        Account accDetails = [SELECT Territory_Region__c FROM Account WHERE Id=:objProductConfig.Apttus_Config2__AccountId__c];
        accDetails.Territory_Region__c = 'China';
        update accDetails;

        promotionsController.selectedRegion = 'EUR';//POL-54
        promotionsController.pageSize = 0;
        promotionsController.typeAheadSearchPromotions();

        promotionsController.listOfsearchIncentivesWrapper = new List<IncentivesWrapper>();
        List<Apttus_Config2__Incentive__c> lstAptIncentive2 = new List<Apttus_Config2__Incentive__c>();
        for(integer j=0;j<20;j++){
            ac = new Apttus_Config2__Incentive__c();
            ac.Apttus_Config2__IncentiveCode__c  = String.valueof(j);
            ac.Apttus_Config2__Description__c = strTest+j;
            ac.Apttus_Config2__Sequence__c = j;
            lstAptIncentive2.add(ac);
            
        }
        insert lstAptIncentive2;
        for(Apttus_Config2__Incentive__c aptConfig : lstAptIncentive2){
            IncentivesWrapper iW1 = new IncentivesWrapper (aptConfig,true);
            lstIncentivesWrapperObj1.add(iW1);
            ob.ListRequested.add(iW1);
            ob.InnerList.add(iW1);
            system.debug('InnerList.size======'+ob.InnerList.size());
            promotionsController.listOfsearchIncentivesWrapper.add(iW1);
        }

        CustomIterable ob1 = new CustomIterable(lstIncentivesWrapperObj1);
        CustomIterable ob11 = new CustomIterable();
        ob11.i=15;
        promotionsController.first();
        promotionsController.next();
        promotionsController.previous();
        promotionsController.searchPromo=strTest;
        promotionsController.typeAheadSearchPromotions();
        
        //removing search key
        promotionsController.pageSize = 4;
        promotionsController.searchPromo = '';
        promotionsController.typeAheadSearchPromotions();

        // covering Previous() in CustomIterable [for making size=10 one needs to populate Innerlist with 10 elements]
        List <IncentivesWrapper> lstIncentivesWrapperOb = new List <IncentivesWrapper>();
        ob11.innerlist = new  list<IncentivesWrapper >();
        List<Apttus_Config2__Incentive__c> lstAptIncentive3 = new List<Apttus_Config2__Incentive__c>();
        for(integer j=0;j<10;j++){
        Apttus_Config2__Incentive__c  ac1 = new Apttus_Config2__Incentive__c();
            ac1.Apttus_Config2__IncentiveCode__c  = String.valueof(j);
            ac1.Apttus_Config2__Description__c = strTest+j;
            ac1.Apttus_Config2__Sequence__c = j;
            lstAptIncentive3.add(ac1);
            
        }
        insert lstAptIncentive3;
        for(Apttus_Config2__Incentive__c aptConfig : lstAptIncentive3){
            IncentivesWrapper IWrap = new IncentivesWrapper (aptConfig,true);
            lstIncentivesWrapperOb.add(IWrap); 
            ob11.InnerList.add(IWrap);
        }
        
        ob11.i=10;
        ob11.setPageSize=4;
        ob11.previous();
        
        CustomIterable objectCustomIterabl = new CustomIterable(lstIncentivesWrapperOb);
        objectCustomIterabl.previous();
        
        //for onselect() if condition
        promotionsController.isTicked = 'true';
        promotionsController.objIncentive ='220';
        promotionsController.objdescription ='descript';
        promotionsController.onSelect();
        
        //for onselect() Else condition
        promotionsController.isTicked = 'false';
        promotionsController.objIncentive ='3';
        promotionsController.objdescription ='test3';
        promotionsController.listOfselectedIncentivesWrapper = new List<IncentivesWrapper>();
        promotionsController.listOfselectedIncentivesWrapper = lstIncentivesWrapperOb.clone();
        
        promotionsController.onSelect();
        promotionsController.last();
        promotionsController.objCustomIterable =new CustomIterable();
        promotionsController.objCustomIterabl=new CustomIterable();

        CustomIterable objCustomIterable  = new CustomIterable();
        objCustomIterable.InnerList = new list<IncentivesWrapper>();
        objCustomIterable.InnerList = lstIncentivesWrapperOb;
        objCustomIterable.i=0;
        objCustomIterable.setPageSize=1;
        objCustomIterable.next();
    
        objCustomIterable.i=01;
        objCustomIterable.setPageSize=0;
        objCustomIterable.hasPrevious();
        
        //Else condition of getSelectedIncentives()
        promotionsController.wrapperIncentivesList = new List<IncentivesWrapper>();
        
        Apttus_Config2__Incentive__c  ac5 = new Apttus_Config2__Incentive__c();
            ac5.Apttus_Config2__IncentiveCode__c  = String.valueof(23);
            ac5.Apttus_Config2__Description__c = strTest;
            ac5.Apttus_Config2__Sequence__c = 3;
            insert ac5;
        
        promotionsController.strFlow='Flow';
        String k = ApttusGetPromotionsController.CONFIGID;
        String m = ApttusGetPromotionsController.CONFIGREQUESTID;
        String l =ApttusGetPromotionsController.FLOW;
        String l1 = ApttusGetPromotionsController.BUSINESSOBJECTID;
        IncentivesWrapper iWobj = new IncentivesWrapper(ac5,false);
        promotionsController.wrapperIncentivesList.add(iWobj);
        promotionsController.getSelectedIncentives();  
        
        //Error part of Save() selectedIncentivesList.size()>3
        promotionsController.selectedIncentivesList = new  List<Apttus_Config2__Incentive__c>();
        promotionsController.mapSelectedIncentives = new map<Id, Apttus_Config2__Incentive__c>(); 
        List<Apttus_Config2__Incentive__c> lstAptIncentive4 = new List<Apttus_Config2__Incentive__c>();
        for(integer j=0;j<5;j++){
        Apttus_Config2__Incentive__c  ac1 = new Apttus_Config2__Incentive__c();
            ac1.Apttus_Config2__IncentiveCode__c  = String.valueof(j);
            ac1.Apttus_Config2__Description__c = strTest+j;
            ac1.Apttus_Config2__Sequence__c = j;
            lstAptIncentive4.add(ac1);
           
        }      
        insert lstAptIncentive4;
        for(Apttus_Config2__Incentive__c aptConfig : lstAptIncentive4){
            promotionsController.mapSelectedIncentives.put(aptConfig.id,aptConfig);
        }

        promotionsController.save();
        //else if part for 2 or 3 promos selection
        promotionsController.selectedIncentivesList = new  List<Apttus_Config2__Incentive__c>();	
        promotionsController.mapSelectedIncentives = new map<Id, Apttus_Config2__Incentive__c>(); 	
        List<Apttus_Config2__Incentive__c> lstAptIncentive5 = new List<Apttus_Config2__Incentive__c>();	
        for(integer j=0;j<3;j++){	
        Apttus_Config2__Incentive__c  ac1 = new Apttus_Config2__Incentive__c();	
            ac1.Apttus_Config2__IncentiveCode__c  = String.valueof(j);	
            ac1.Apttus_Config2__Description__c = strTest+j;	
            ac1.Apttus_Config2__Sequence__c = j;	
            ac1.Promotion_Redemption_Method__c = 'E';	
            ac1.Regions__c = 'AMR;EUR';//POL-54
            ac1.Promo_Channel__c = 'O2;F1';	
            lstAptIncentive5.add(ac1);	
           	
        }      	
        insert lstAptIncentive5;	
        for(Apttus_Config2__Incentive__c aptConfig : lstAptIncentive5){	
            promotionsController.mapSelectedIncentives.put(aptConfig.id,aptConfig);	
            promotionsController.selectedIncentivesList = promotionsController.mapSelectedIncentives.values();//DCP-40230	
        }	
        promotionsController.save();
        //For else part of typeAheadSearchPromotions() where search key is BLANK
        promotionsController.searchPromo = '';
        promotionsController.typeAheadSearchPromotions();
        ApttusIncentivesPromotionsSelector initCls = new ApttusIncentivesPromotionsSelector();	
        initCls.getActivePromotions();	
        initCls.getPromotions(new set<String>{'123'});	
        initCls.getPromotionsById(mapSelectedIncentives.keySet());
        Test.stopTest();
        System.assertEquals(Label.UI_Label_Promotions_Saved_Successfuly,promotionsController.strPromotionsSavedSucessfully);
    }

}