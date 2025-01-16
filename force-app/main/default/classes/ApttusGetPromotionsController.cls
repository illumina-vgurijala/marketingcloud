/**
 * @author Kristiyan Petkov
 * @date   06-Nov-2018
 * @description   DCP-15146 Selection of Explicit Promotions
 * Modification Log:
 *  --------------------------------------------------------------------------------------------------
 *   Developer                Date                Description                                                  
 *   Kristiyan Petkov         06-Nov-2018         Original Version
 *   Saswati                  16th Sept 2019      SearchPromotions - DCP-26235
 *   Prakhar                  18th Sept 2019      SearchPromotions - DCP-26235
 *   Roopal                   4th Oct 2019        Added without sharing for checkmarx fix
 *   Raja Siva Krishna        9th Sept 2020       DCP-40230-made changes to get promotion based on region and salesOps and added records per page option
 *   Prem Ranjan              25-April-2022       CodeScan Fix:Avoid Literals in If condition
 *   Aman Tyagi               30th March 2022     CodeScan Fixes
 *   Adyasha Satapathy        12-Oct-2022         Code Scan Fixes(Method Naming Convention)
 *   Adyasha Satapathy        24-Nov-2022         POL-54: Update region references to AMEA and EUR
 *   Prem Ranjan              15-Dec-2022         POL-116 Deactivate APAC and Add AMEA, China
 *   Satya Swain              09 Dec 2022         Added Codescan fix for Variable Naming Convention
 * ---------------------------------------------------------------------------------------------------
 **/
public without sharing class ApttusGetPromotionsController {
    public static final String CONFIGID = 'Id';
    public static final String CONFIGREQUESTID = 'configRequestId';
    public static final String FLOW = 'flow';
    public static final String BUSINESSOBJECTID = 'businessObjectId';
    public String strConfigId;
    public string strConfigRequestId;
    public string strFlow;
    public String strBusinessObjectId;
    public String strPromotionsSavedSucessfully;

    Public List<IncentivesWrapper> wrapperIncentivesList;
    Public Map<Id, Apttus_Config2__Incentive__c> mapSelectedIncentives = new Map<Id, Apttus_Config2__Incentive__c>();
    public List<Apttus_Config2__Incentive__c> selectedIncentivesList {get; set;}
    public boolean display {get; set;}
    public string searchPromo {get;set;}
    public List<IncentivesWrapper> listOfsearchIncentivesWrapper {get;set;}
    public List<IncentivesWrapper> listOfselectedIncentivesWrapper {get;set;}
    public List<IncentivesWrapper> listOfTempIncentivesWrapper {get;set;}
    public List<Id> selectedIds {get;set;}
    public String objIncentive {get;set;}
    public String objdescription {get;set;}
    public String objPromoChannel{get;set;}
    public String isTicked {get;set;}
    public String incentiveId {get;set;}
    public CustomIterable objCustomIterable;
    public CustomIterable objCustomIterabl;
    public Integer pageSize {get; set;}//DCP-40230
    public String pageSizeErrorMsg {get;set;}//DCP-40230
    public Boolean shwErrorMsg {get;set;}//DCP-40230
    public String territoryRegion;//DCP-40230
    public String selectedRegion{get;set;}//DCP-40230
    //public Set<String> apacRegions = new Set<String>{'APJ','China'};//DCP-40230
    public String allRegions = Label.All_Regions_For_Promotions;//DCP-40230
    public static final Integer ONE = 1;
    public static final Integer TWO = 2;
    public static final Integer THREE = 3;
    public static final String TRUE_VALUE = 'true';
 

    //public List<Apttus_Config2__Incentive__c> listOfsearchIncentives {get;set;}
    
    /**
    *  @author      : Raja Siva Krishna
    *  @description : Region drop down options on promotion page
    *  @param       : NA
    *  @return      : NA
    */
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        List<String> lstRegions = label.UI_Regions_Pick_List_Values.Split(', ');
        for(String region:lstRegions){
            options.add(new SelectOption(region,region));
        }
        return options;
    }

    //DCP-40230: to know logged in user is salesOps or not
    Boolean userIsSalesOps = checkCurrentUserIsSalesOps(UserInfo.getProfileId());


    /**
    *  @author      : Kristiyan Petkov
    *  @description : initialize default constructor
    *  @param       : NA
    *  @return      : NA
    */
    public ApttusGetPromotionsController(){
        pageSize = integer.valueof(Label.UI_Default_Promotion_Page_Size);//DCP-40230
        selectedIds =new List<Id>();
        listOfTempIncentivesWrapper = new List <IncentivesWrapper>();      
        listOfselectedIncentivesWrapper = new List<IncentivesWrapper>();
        strConfigId = ApexPages.currentpage().getparameters().get(CONFIGID) == null ? null : ApexPages.currentpage().getparameters().get(CONFIGID).escapeHtml4();
        strConfigRequestId = ApexPages.currentpage().getparameters().get(CONFIGREQUESTID);
        strFlow = ApexPages.currentpage().getparameters().get(FLOW);
        strBusinessObjectId = ApexPages.currentpage().getparameters().get(BUSINESSOBJECTID);
        Apttus_Config2__ProductConfiguration__c prodConfig = new ApttusProductConfigurationsSelector().selectProductConfigurationById(strConfigId)[0];
        wrapperIncentivesList = new List<IncentivesWrapper>();
        territoryRegion = getTerritoryRegion(prodConfig.Apttus_Config2__AccountId__c);
        /*if(apacRegions.contains(territoryRegion))
            territoryRegion = Label.QuoteRegionAPAC;*/
        selectedRegion = territoryRegion;
        for (Apttus_Config2__Incentive__c incentive : new ApttusIncentivesPromotionsSelector().getPromotionsByUserAndRegion(userIsSalesOps,selectedRegion,allRegions,Label.Promotion_Channel_Description_For_Query)) {
            if (incentive.Name != null) {
                if (prodConfig.Promo_Name_1__c == incentive.Apttus_Config2__IncentiveCode__c || prodConfig.Promo_Name_2__c == incentive.Apttus_Config2__IncentiveCode__c || prodConfig.Promo_Name_3__c == incentive.Apttus_Config2__IncentiveCode__c) {
                    if (!mapSelectedIncentives.containsKey(incentive.id)) {
                        wrapperIncentivesList.add(new IncentivesWrapper(incentive, true));                      
                    }
                }
            }
        }
        getSelectedIncentives();
        objCustomIterable = new CustomIterable(new List<IncentivesWrapper>());        
         
        listOfsearchIncentivesWrapper =new List <IncentivesWrapper>();
        List<Apttus_Config2__Incentive__c> listOfActiveIncentives1 = new ApttusIncentivesPromotionsSelector().getPromotionsByUserAndRegion(userIsSalesOps,selectedRegion,allRegions,Label.Promotion_Channel_Description_For_Query);
        IncentivesWrapper incentiveWrapperObject;
        for(Apttus_Config2__Incentive__c objIncentive: listOfActiveIncentives1 )
        {
            if (prodConfig.Promo_Name_1__c == objIncentive.Apttus_Config2__IncentiveCode__c || prodConfig.Promo_Name_2__c == objIncentive.Apttus_Config2__IncentiveCode__c || prodConfig.Promo_Name_3__c == objIncentive.Apttus_Config2__IncentiveCode__c) {
                incentiveWrapperObject = new IncentivesWrapper(objIncentive,true);
                listOfsearchIncentivesWrapper.add(incentiveWrapperObject ); 
                listOfselectedIncentivesWrapper.add(incentiveWrapperObject); 
            }
            else{
                incentiveWrapperObject = new IncentivesWrapper(objIncentive,false);
                listOfsearchIncentivesWrapper.add(incentiveWrapperObject); 
            }
        }
         objCustomIterable = new CustomIterable(listOfsearchIncentivesWrapper);
         objCustomIterable.setPageSize  = pageSize; 
         next();
    }

    /**
    *  @author      : Kristiyan Petkov
    *  @description : populate mapSelectedIncentives with Apttus_Config2__Incentive__c records
    *  @param       : NA
    *  @return      : NA
    */
    public void getSelectedIncentives() {
        if (wrapperIncentivesList != null) {
            for (IncentivesWrapper wr : wrapperIncentivesList) {
                if (wr.bool == true) {
                    mapSelectedIncentives.put(wr.incentive.id, wr.incentive);
                } else {
                    mapSelectedIncentives.remove(wr.incentive.id);
                }
            }
        }
    }

    /**
    *  @author      : Kristiyan Petkov
    *  @description : validate and populate custom fields on the Product Configuraiton object and for saving the selected Promotion Codes.
    *  @param       : NA
    *  @return      : NA
    */
    public void save() {
        display = true;
        String strPromoJSON = '';
        selectedIncentivesList = new List<Apttus_Config2__Incentive__c>();
        selectedIncentivesList = mapSelectedIncentives.values();
        if (selectedIncentivesList.size() > THREE) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.UI_ErrorMessage_MaxAllowedPromotions));
            return;
        }
        if (strConfigId != null) {
            Apttus_Config2__ProductConfiguration__c prodConfig = new Apttus_Config2__ProductConfiguration__c(Id = strConfigId);
            prodConfig.Promo_Name_1__c = null;
            prodConfig.Promo_Name_2__c = null;
            prodConfig.Promo_Name_3__c = null;
            List<PromotionWrapper> lstSelectedPromo = new List<PromotionWrapper>();
            for (Integer idx = 0; idx < selectedIncentivesList.size(); idx++) {
                String promotion = selectedIncentivesList.get(idx).Apttus_Config2__IncentiveCode__c;
                //DCP-40230
                Integer intOfflineChannelIndex=-1;
                String promotionChannel = selectedIncentivesList.get(idx).Promo_Channel__c;
                if(String.isNotBlank(promotionChannel))
                    intOfflineChannelIndex = promotionChannel.indexOf('F');
                if(String.isNotBlank(promotionChannel) && promotionChannel.split(';').size()==2 && intOfflineChannelIndex!=-1)
                    promotionChannel=promotionChannel.substring(intOfflineChannelIndex,intOfflineChannelIndex+2);
                //DCP-40230
                lstSelectedPromo.add(new PromotionWrapper(selectedIncentivesList.get(idx).Apttus_Config2__IncentiveCode__c,promotionChannel));
                if (idx == 0) {
                    prodConfig.Promo_Name_1__c = promotion;
                } else if (idx == ONE) {
                    prodConfig.Promo_Name_2__c = promotion;
                } else if (idx == TWO) {
                    prodConfig.Promo_Name_3__c = promotion;
                }
                
            }
            strPromoJSON = JSON.serialize(lstSelectedPromo);
            system.debug('JSON Structure-->'+ strPromoJSON);
            prodConfig.Promotion_JSON__c = strPromoJSON;
            prodConfig.Is_SAP_Pricing_Completed__c = false;
            update prodConfig;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM, Label.UI_Label_Promotions_Saved_Successfuly));
            strPromotionsSavedSucessfully = Label.UI_Label_Promotions_Saved_Successfuly;
        }
    }
    
     


    /**
    *  @author      : Kushagra Desai
    *  @description : wrapper class for Storing promotion
    *  @param       : NA
    *  @return      : NA
    */
    private class PromotionWrapper {
        public string promoCode;
        public string promoChannel;
        /**
        *  @author      : Kushagra Desai
        *  @description : parameterized Constructor of class PromotionWrapper
        *  @param       : String promoCode,String promoChannel
        *  @return      : NA
        */
        public PromotionWrapper(String promoCode,String promoChannel){
            this.promoCode = promoCode;
            this.promoChannel = promoChannel;
        }

    }
    
    /**
    *  @author      : Kushagra Desai
    *  @description :
    *  @param       : NA
    *  @return      : PageReference
    */
    public PageReference typeAheadSearchPromotions() {
        string key = searchPromo;
        List<Apttus_Config2__Incentive__c> listOfActiveIncentives = new ApttusIncentivesPromotionsSelector().getPromotionsByUserAndRegion(userIsSalesOps,selectedRegion,allRegions,Label.Promotion_Channel_Description_For_Query);
        if(pageSize <= 0){
            pageSizeErrorMsg = Label.UI_ErrorMessage_Promotion_Page_Size_Validation;
            shwErrorMsg = true;
        }
        else{
            System.debug('Key Value is ======'+key); 
            listOfTempIncentivesWrapper = new List <IncentivesWrapper>();
            IncentivesWrapper incentiveWrapperObject;
            for(Apttus_Config2__Incentive__c objEachIncentive: listOfActiveIncentives){
                incentiveWrapperObject = new IncentivesWrapper(objEachIncentive,false);
                listOfTempIncentivesWrapper.add(incentiveWrapperObject);
            }
            if(key.length() > 0)
            {
                System.debug('Key Value is not null'+key);
                if(listOfActiveIncentives.size()>0)
                {
                    IncentivesWrapper incentiveWrapperObj;
                    listOfsearchIncentivesWrapper =new List<IncentivesWrapper>();
                    for(Apttus_Config2__Incentive__c oIncentive: listOfActiveIncentives )
                    {
                        Boolean boolPickRecord = false;
                        if(String.isNotBlank(oIncentive.Apttus_Config2__Description__c) && oIncentive.Apttus_Config2__Description__c.containsIgnoreCase(key))
                            boolPickRecord = true;
                        else if(String.isNotBlank(oIncentive.Apttus_Config2__IncentiveCode__c) && oIncentive.Apttus_Config2__IncentiveCode__c.containsIgnoreCase(key))
                            boolPickRecord = true;
                        else if(String.isNotBlank(oIncentive.Sales_Description__c) && oIncentive.Sales_Description__c.containsIgnoreCase(key))
                            boolPickRecord = true;
                        else if(String.isNotBlank(oIncentive.Promotion_Details__c) && oIncentive.Promotion_Details__c.containsIgnoreCase(key))
                            boolPickRecord = true;
                        if(boolPickRecord){
                            if( mapSelectedIncentives.size()>0 && mapSelectedIncentives.containsKey(oIncentive.Id) ){
                                System.debug('Pre selected');
                                incentiveWrapperObj = new IncentivesWrapper(oIncentive,true);
                                listOfsearchIncentivesWrapper.add(incentiveWrapperObj);
                            }else{
                                System.debug('Inside description if');
                                incentiveWrapperObj = new IncentivesWrapper(oIncentive,false);
                                listOfsearchIncentivesWrapper.add(incentiveWrapperObj );
                            }
                        }                       
                    }
                }
            }else{
                listOfsearchIncentivesWrapper.clear();
                for(IncentivesWrapper objWrap: listOfTempIncentivesWrapper){
                    for(integer j=0;j< listOfselectedIncentivesWrapper.size();j++){
                        if(listOfselectedIncentivesWrapper[j].incentive.Apttus_Config2__IncentiveCode__c == objWrap.incentive.Apttus_Config2__IncentiveCode__c ){
                            objWrap.bool=true;
                            break;
                        }else{
                        objWrap.bool=false;
                        }
                    }
                    listOfsearchIncentivesWrapper.add(objWrap);
                }
            }
            objCustomIterable = new CustomIterable(listOfsearchIncentivesWrapper);
            objCustomIterable.setPageSize  = pageSize; 
            shwErrorMsg = false;
            next();
        }  
        return null;
        }

    /*
    * @author :Prakhar
    */
    // Methods for Pagination
    public Boolean hasNext{             
        get { 
            return objCustomIterable.hasNext(); 
        }    
        set;  
    }

    public Boolean hasPrevious { 
        get {   
            return objCustomIterable.hasPrevious(); 
        }   
        set;
    }
     /**
    *  @author      : Kushagra Desai
    *  @description : getting value for listOfsearchIncentivesWrapper
    *  @Param  : none
    *  @Return  : void
    */
    public void next(){             
        listOfsearchIncentivesWrapper = objCustomIterable.next();        
    }

    /**
    *  @author      : Kushagra Desai
    *  @description : getting value for listOfsearchIncentivesWrapper
    *  @Param  : none
    *  @Return  : void
    */
    public void previous(){             
        listOfsearchIncentivesWrapper = objCustomIterable.previous();        
    }

    /**
    *  @author      : Kushagra Desai
    *  @description : getting value for listOfsearchIncentivesWrapper
    *  @Param  : none
    *  @Return  : void
    */
    public void first(){             
        listOfsearchIncentivesWrapper = objCustomIterable.first();        
    }

    /**
    *  @author      : Kushagra Desai
    *  @description : getting value for listOfsearchIncentivesWrapper
    *  @Param  : none
    *  @Return  : void
    */
    public void last(){             
        listOfsearchIncentivesWrapper = objCustomIterable.last();        
    }    
    
    /**
    *  @author      : Kushagra Desai
    *  @description : method for selecting and unselecting the promotion codes
    *  @Param  : none
    *  @Return  : NA
    */
    public PageReference onSelect(){   
        if(isTicked == TRUE_VALUE){
             Apttus_Config2__Incentive__c  ob = new Apttus_Config2__Incentive__c (Id=IncentiveId);            
             ob.Apttus_Config2__IncentiveCode__c = objIncentive;
             ob.Apttus_Config2__Description__c = objdescription ;
             ob.Promo_Channel__c = objPromoChannel ;
             IncentivesWrapper iW = new IncentivesWrapper(ob,true);
             listOfselectedIncentivesWrapper.add(iW); 
             mapSelectedIncentives.put(IncentiveId,ob);
         } else{
             // Unticking the element and removing it from list and map
             for(integer j=0; j< listOfselectedIncentivesWrapper.size(); j++){
                 if((listOfselectedIncentivesWrapper[j].incentive.Apttus_Config2__IncentiveCode__c == objIncentive)){
                    listOfselectedIncentivesWrapper.remove(j);
                 }
             }
             // Compares the code and if same then it is removed from list.
             mapSelectedIncentives.remove(IncentiveId);
         }     
             return null;
    }

    /**
    *  @author      : Raja Siva Krishna
    *  @description : Method to get territory region from the product config account
    *  @param       : account Id
    *  @return      : quotation territory region(sold to region)
    */
    public String getTerritoryRegion(Id accId){
        String region = '';
        Account accDetails = [SELECT Territory_Region__c FROM Account WHERE Id=:accId];
        if(accDetails != null && String.isNotBlank(accDetails.Territory_Region__c))
            region = accDetails.Territory_Region__c;
        return region;
    }  

    /**
    *  @author      : Raja Siva Krishna
    *  @description : Method to check logged in user profile is sales ops
    *  @param       : current user profile Id
    *  @return      : boolean to know user is salesOp
    */
    private static Boolean checkCurrentUserIsSalesOps(Id currentUserProfileId)
    {
        return (Profiles.getCommercialRevenueOperationsProfileId().contains(currentUserProfileId) || Profiles.getCommercialOpsQuotingUserProfileId().contains(currentUserProfileId));
    }  
}