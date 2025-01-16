/**
 *    @author Joshith K
 *    @date   10-July-2020
 *    @description  Test class for ApttusAgreementLineItemViewerController
 *    @Test class for 90% coverage: TestApttusAgreementLineItemViewerCntl
 *    @Test class for 75% coverage: TestApttusAgreementLineItemViewerCntl
 *    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------------
*    Developer                      Date                Description
*    Joshith k               10-July-2020         Initial Version-TASK0493822
*    Himanshu                31-March-2022         Code Scan Fixes
*    Maruthi                27-June-2022         added getFilterRecords DCP-52707
*    Nishan Shetty           29-June-2022         DCP-52703 Concatenating Product Description with Product Name if there is a Material Number.
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*
*
 */
public with sharing class ApttusAgreementLineItemViewerController {
    private static final String LOG_TITLE = 'ApttusAgreementLineItemViewerController';
    public static boolean catchExceptionGetRecords = false;
    public static boolean catchExceptionGetFilterRecords = false;
    public static boolean catchExceptionFilterLogic = false;
    public static boolean catchExceptionCheckSessionCache = false;
    public static boolean catchExceptionGetAgreement = false;
    public static boolean catchExceptionGetAgreementAura = false;
    public static final String ERROR_MSG = 'throwing custom exception';
    public static final String NA = 'N/A';
    
    /**
    * @author  Joshith K
    * @description method to get list of records of Apttus__AgreementLineItem__c
    * @param String agreementId
    * @return string
    **/
    @AuraEnabled(cacheable=true)
    public static string getRecords(String agreementId, Integer limitCount) {   
        try {
            ilib_LogEvent.push(LOG_TITLE +'.getRecords');  
            ilib_LogEvent.message('limitCountgetrecords-->'+limitCount);  
            List<Apttus__AgreementLineItem__c> agrmentLinItem=new ApttusAgreementLineItemSelectors().selectAgreementLineItemSorted(new Set<ID>{agreementId},limitCount,NULL);
            List<agreementLineWrapper> lstLineItemWrapppper= new List<agreementLineWrapper>();
            Apttus__AgreementLineItem__c objline =new Apttus__AgreementLineItem__c();     
            for(Integer indexNo=limitCount-Integer.valueof(Label.LabelViewLinesLimit) ;  !(agrmentLinItem.isEmpty()) && indexNo<agrmentLinItem.size() ; indexNo++) {
                objline = agrmentLinItem.get(indexNo);            
                if(objline.Discontinued__c != Label.UI_Label_Yes) {
                    lstLineItemWrapppper.add(new agreementLineWrapper(objline));
                }                
            }          
			ilib_LogEvent.message('lstLineItemWrapsizegetrec-->'+lstLineItemWrapppper.size());  
            ilib_LogEvent.pop();
            if(catchExceptionGetRecords == true){
                throw new AuraHandledException(ERROR_MSG);
            }                 
            return  '{"listAgreementLineItems": '+JSON.serialize(lstLineItemWrapppper)+','
            +' "hasMoreLines": "'+(limitCount > agrmentLinItem.size() ? 'no' : 'yes')+'"}';
        } catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE, e);
            throw new AuraHandledException(e.getMessage());   
        }           
    }

    /**
    * @author  Nishan Shetty [DCP-52703]
    * @description method to set material description.
    * @param AgreementLineItem Object
    * @return String
    **/
    public static String setMaterialGroupDescription(Apttus__AgreementLineItem__c objAgreementLineItem) {
        ilib_LogEvent.push(LOG_TITLE +'.setMaterialGroupDescription');
        if(objAgreementLineItem.Material_Number__c!=null) {
          if(objAgreementLineItem.Apttus__ProductId__r.Material_Group_1__c!=null) {                                         
            ilib_LogEvent.pop();  
            return (String)objAgreementLineItem.Apttus__ProductId__r.Name+'/'+objAgreementLineItem.Apttus__ProductId__r.Material_Group_1__c;
          }
            ilib_LogEvent.pop();  
          return (String)objAgreementLineItem.Apttus__ProductId__r.Name;
        } 
        ilib_LogEvent.pop();
        return (String)objAgreementLineItem.Material_Group_1_Description__c;
    }   
    
    /**
    * @author  Maruthi B
    * @description method to get list of records based on the search key
    * @param String agreementId, String searchKey
    * @return string
    **/
    @AuraEnabled(cacheable=false)
    public static string getFilterRecords(String agreementId, String searchKey, Integer limitCount) {   
        try {
            ilib_LogEvent.push(LOG_TITLE +'.getFilterRecords');  
            ilib_LogEvent.message('limitCountFilter-->'+limitCount); 
            List<agreementLineWrapper> tempLstLineItemWrapppper= new List<agreementLineWrapper>();        
            List<Apttus__AgreementLineItem__c> agrmentLinItem=new ApttusAgreementLineItemSelectors().selectAgreementLineItemSorted(new Set<ID>{agreementId},NULL,NULL);                        
            List<agreementLineWrapper> lstLineItemWrapppper= new List<agreementLineWrapper>();        
            for(Apttus__AgreementLineItem__c objline:agrmentLinItem) {
                if(String.isBlank(searchKey)) {
                    lstLineItemWrapppper.add(new agreementLineWrapper(objline));
                }else{
                    Set<String> setTempValues = new Set<String>();                
                    setTempValues = filterLogic(objline,setTempValues);
                    if(setTempValues.contains(searchKey)) {                    
                        lstLineItemWrapppper.add(new agreementLineWrapper(objline));
                    }
                }                                                                
            } 
            ilib_LogEvent.message('lstLineItemWrapppper.sizeBefore()-->'+lstLineItemWrapppper.size());             
            if(lstLineItemWrapppper.size()>Integer.valueof(Label.LabelViewLinesLimit)){                
                for(Integer indexNo=limitCount-Integer.valueof(Label.LabelViewLinesLimit) ;  indexNo<lstLineItemWrapppper.size() && indexNo<limitCount ; indexNo++) {                                                                              
                    tempLstLineItemWrapppper.add(lstLineItemWrapppper.get(indexNo));                 
                }
                lstLineItemWrapppper = tempLstLineItemWrapppper;
            }   
            ilib_LogEvent.message('lstLineItemWrapppper.sizeAfter()-->'+lstLineItemWrapppper.size());                                            
            ilib_LogEvent.pop();
            if(catchExceptionGetFilterRecords == true){
                throw new AuraHandledException(ERROR_MSG);
            }                               
            return  '{"listAgreementLineItems": '+JSON.serialize(lstLineItemWrapppper)+','
            +' "hasMoreLines": "'+(limitCount > (tempLstLineItemWrapppper.isEmpty()? 0 : tempLstLineItemWrapppper.size()) ? 'no' : 'yes')+'"}';
        } catch(Exception e) {
            catchExceptionGetFilterRecords = false;
            ApexExceptions.emit(LOG_TITLE, e);
            throw new AuraHandledException(e.getMessage());          
        }            
    }

    /**
    * @author  Maruthi B
    * @description filtering logic
    * @param Apttus__AgreementLineItem__c objline, Set<String> setTempValues
    * @return string
    **/    
    public static Set<String> filterLogic(Apttus__AgreementLineItem__c objline, Set<String> setTempValues) {   
        try {    
            ilib_LogEvent.push(LOG_TITLE +'.filterLogic');          
            if(String.isNotBlank(objline.Line_Type__c)) {
                setTempValues.add(objline.Line_Type__c.toLowerCase());
            }                
            setTempValues.add(objline.Customer_ERP_Number__c);
            if(String.isNotBlank(objline.Apttus_CMConfig__LineStatus__c)) {
                setTempValues.add(objline.Apttus_CMConfig__LineStatus__c.toLowerCase());
            }
            if(String.isNotBlank(objline.Material_Number__c) || String.isNotBlank(objline.Material_Group_1__c)) {
                setTempValues.add((objline.Material_Number__c!=null ? objline.Material_Number__c : objline.Material_Group_1__c).toLowerCase());
            }
            if(String.isNotBlank(objline.Apttus__ProductId__r.Name) || String.isNotBlank(objline.Material_Group_1_Description__c)) {
                setTempValues.add((objline.Material_Number__c!=null ? objline.Apttus__ProductId__r.Name : objline.Material_Group_1_Description__c).toLowerCase());
            }
            if(String.isNotBlank(objline.Discount_Type__c)) {
                setTempValues.add(objline.Discount_Type__c.toLowerCase());
            }                
            String strStartDate = objline.Apttus_CMConfig__StartDate__c.month()+'/'+objline.Apttus_CMConfig__StartDate__c.day()+'/'+objline.Apttus_CMConfig__StartDate__c.year();            
            String strEndDate = objline.Apttus_CMConfig__EndDate__c.month()+'/'+objline.Apttus_CMConfig__EndDate__c.day()+'/'+objline.Apttus_CMConfig__EndDate__c.year();                 
            setTempValues.add(strStartDate);
            setTempValues.add(strEndDate);                
            ilib_LogEvent.message('setTempValues-->'+JSON.serialize(setTempValues));  
            ilib_LogEvent.pop();
            if(catchExceptionFilterLogic == true){
                throw new AuraHandledException(ERROR_MSG);
            }                                            
            return setTempValues;
        } catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE, e);
            throw new AuraHandledException(e.getMessage());          
        }            
    }
    
   
	/**
    * @author Joshith K
    * @description   Wrapper class
    */
    public class agreementLineWrapper{
        public string recordid;
        public String lineType;       
        public String customerERPNumber;      
        public String accountName;        
        public string accountUrl;
        public string materialNumberGroup;
        public string materialNameGroupDesc;
        public string salesOrg;
        public string currencyValue;
        public decimal discount;
        public decimal discountPercent;
        public string discountType;
        public date startdate;
        public date enddate;
        public string ultimateconsigneeErpNumber;
        public decimal permittedmarkupPercentage;
        public decimal listPrice;
        public decimal customerPrice;
        public string lineStatus;//DCP-52707
        public string customerHistoricalDiscount; //[DGP-104]
        public string medianDiscount; //[DGP-104]
        public string maxDiscount; //[DGP-104]
        public decimal discountBeforeApproval; //[DGP-104]
        
        agreementLineWrapper(Apttus__AgreementLineItem__c objline){
            this.lineType=objline.Line_Type__c;
            this.customerERPNumber=objline.Customer_ERP_Number__c;
            this.accountName=objline.Account__r.Name;
            this.recordid=objline.Id;
            this.accountUrl=(objline.Account__r.Id!=null? '/'+objline.Account__r.Id:'');
            this.materialNumberGroup=(objline.Material_Number__c!=null ? objline.Material_Number__c : objline.Material_Group_1__c);
            this.materialNameGroupDesc=ApttusAgreementLineItemViewerController.setMaterialGroupDescription(objline);//DCP-52703
            this.salesOrg=objline.Sales_Org__c;
            this.currencyValue=objline.CurrencyIsoCode;
            this.discount=objline.Discount_Amount__c;
            this.discountPercent=objline.Discount_In_Percent__c;
            this.discountType=objline.Discount_Type__c;
            this.startdate=objline.Apttus_CMConfig__StartDate__c;
            this.enddate=objline.Apttus_CMConfig__EndDate__c;
            this.permittedmarkupPercentage=objline.Permitted_Markup_Percentage__c;
            this.ultimateconsigneeErpNumber=objline.Ultimate_Consignee_ERP_Number__c;
            this.customerPrice=objline.Customer_Price__c;
            this.listPrice=objline.Apttus__ListPrice__c;
            this.lineStatus=objline.Apttus_CMConfig__LineStatus__c;//DCP-52707
            if(objline.Do_Not_Run_Discount_Guidance__c){
                this.medianDiscount=NA;
                this.maxDiscount=NA;
                this.customerHistoricalDiscount=NA;
            }else{
                this.medianDiscount=objline.Median_Discount_Guidance__c!=null?string.valueof(objline.Median_Discount_Guidance__c):'';   //[DGP-104]
                this.maxDiscount=objline.Max_Discount_Guidance__c!=null?string.valueof(objline.Max_Discount_Guidance__c):'';    //[DGP-104]
                this.customerHistoricalDiscount=objline.Customer_Historical_Discount__c!=null?string.valueof(objline.Customer_Historical_Discount__c):''; //[DGP-104]
            }
            this.discountBeforeApproval=objline.Sales_Approval_Threshold__c;     //[DGP-104]

            
            
        }

        
    }

    @AuraEnabled 
    /**
    * @author  Joshith K
    * @description method to check session cache
    * @param String recordId
    * @return string
    **/
    public static void checkSessionCache(String recordId)
    {
        try {
            ilib_LogEvent.push(LOG_TITLE +'.checkSessionCache');          
            Cache.SessionPartition sessionPart = Cache.Session.getPartition('local.AccountPlanVariables');
            sessionPart.put('AgreementId',recordId,3600,Cache.Visibility.ALL, true);
            ilib_LogEvent.message('sessionPart-->'+sessionPart);  
            ilib_LogEvent.pop();
            if(catchExceptionCheckSessionCache == true){
                throw new AuraHandledException(ERROR_MSG);
            }                                            
        } catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE, e);
            throw new AuraHandledException(e.getMessage());          
        } 
    }
    @AuraEnabled(cacheable=true)
    /**
    * @author  Joshith K
    * @description method to get agreement record
    * @param NA
    * @return Apttus__APTS_Agreement__c
    **/
    public static Apttus__APTS_Agreement__c getAgreement()
    {   
        try {
            ilib_LogEvent.push(LOG_TITLE +'.getAgreement');    
            Cache.SessionPartition sessionPart = Cache.Session.getPartition('local.AccountPlanVariables');
            ilib_LogEvent.message('session part-->'+sessionPart);              
            if(sessionPart.contains('AgreementId')) {            
                string agreementId=(String)sessionPart.get('AgreementId');
                List<Apttus__APTS_Agreement__c> lstAgreement = new ApttusAgreementSelectors().selectAgreements(new Set<ID>{agreementId});
                if(!lstAgreement.isEmpty()) {
                    Apttus__APTS_Agreement__c objAgreement = lstAgreement[0];
                    ilib_LogEvent.message('objAgreement-->'+objAgreement); 
                    if(catchExceptionGetAgreement == true){
                        throw new AuraHandledException(ERROR_MSG);
                    }  
                    return objAgreement;
                }
            }                    
            ilib_LogEvent.pop();     
            return null;
        } catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE, e);
            throw new AuraHandledException(e.getMessage());          
        } 
    }


    @AuraEnabled 
    /**
    * @author  Joshith K
    * @description method to get agreement record
    * @param String agreementId
    * @return Apttus__APTS_Agreement__c
    **/
    public static Apttus__APTS_Agreement__c getAgreementAura(String agreementId)
    {
        try {
            ilib_LogEvent.push(LOG_TITLE +'.getAgreement');    
            ilib_LogEvent.message('agreementId-->'+agreementId);  
            List<Apttus__APTS_Agreement__c> lstAgreement = new ApttusAgreementSelectors().selectAgreements(new Set<ID>{agreementId});
            if(!lstAgreement.isEmpty()) {
                ilib_LogEvent.message('lstAgreement[0]-->'+lstAgreement[0]); 
                if(catchExceptionGetAgreementAura == true){
                    throw new AuraHandledException(ERROR_MSG);
                }                 
                return lstAgreement[0];
            }
            ilib_LogEvent.pop();
            return NULL;
        } catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE, e);
            throw new AuraHandledException(e.getMessage());          
        } 
    }  
}