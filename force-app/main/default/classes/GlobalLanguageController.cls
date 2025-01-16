/**
* @author Akash Kumar
* @date :   2018-08-22
* @description :   US-9539: Controller class for the PPM Quick Action Component
*    @Test Class for above 90% coverage.
*    @Test Class for atleast 75% coverage.
      TestGlobalLanguageController
* Modification Log:
* -------------------------------------------------------------------------------------------------------------------------------------------------------------------
*       Akash Kumar         2018-08-22            Original Version
*       Roopal Verma        2018-09-26            Changed Post pricing message name to Post_Pricing_Message_List__c and Global_Language to Post_Pricing_Message__c 
*       Akash Kumar         2018-10-15            Added logic in populateGlobalLanguage method to set Boolean Variables in Wrapper Class to conditionally
*												  show help text messages
*       Akash Kumar         2018-10-25            Added Logic to maintain dependency between Preferred Language and Post Pricing Message List
*       Akshay Mohan        2019-03-29            DCP-21934: Added Logic to to get list of all non standard picklist values
*       Anish Pathak        2019-09-18            DCP-28436: Added logic for Brazil template with optional fields
*       Anish Pathak        2020-02-21            DCP-29629: Added logic for Canadian template with number field
*       Himanshu            2022-03-30            Code Scan Fixes 
*       Rucha Dalvi         2022-07-05            Code Scan Fixes 
*       Iram Malik          2022-07-12            Codescan Fix: Statement on a separate line
*       Adithi Acharya      2022-10-31            DCP-56437 : Removal of Rejected Quote Stage
*       Nishan Shetty       05-Jan-2023           Removed strPostPricingList for CodeScan Unused Variable Fix.
* -------------------------------------------------------------------------------------------------------------------------------------------------------------------    
*/
public with sharing class GlobalLanguageController {
	public static final String NUMBERFIELD = 'NUMBER';//added for DCP-29629
    //Codedscn - Duplicate Literals Fix
    public static final string STRING_VALUE_A = 'AAAA';
    public static final string STRING_STATIC_TYPE = 'static';
    public static final string STRING_DYNAMIC_TYPE = 'dynamic';

        /**************
    @author Akash Kumar
    @Method Name = loadData;
    @Purpose = To send data to PPM Quick Action component during page load
    @Parameters = Proposal Id
    @return = JSON String containing Proposal Object, Picklist values(metadata) and labels.
    **************/
    @AuraEnabled
    public static String loadData(String strProposalId) {
        System.debug('Proposal Id:' + strProposalId);
        String strCanadaFoundation; //DCP-29629 - added strCanadaFoundation
        Boolean booInReview;
        Boolean booApproved;
        Boolean booAccepted;
        Boolean booDenied;
        Boolean booInValidQuote;
        Boolean booQuoteswInValidAcc;
        Boolean booDisablePostpricingList;
		Boolean boolIsCountryCanadaLangEnglish = false;//DCP-29629
        List < GlobalLanguageWrapper > lstGlobalLangWrapper = new List < GlobalLanguageWrapper > ();
        Map < String, String > mapLabels = new Map < String, String > ();
        Map <String,String > prefLanguageToPostPricingList = new Map <String,String>();
        List < PickListValueWrapper > lstPstPricingMsg = new List < PickListValueWrapper >();
        List< String > lstSplittedPostPricingList = new List< String >();

        
        Set<String> setInValidAccountStatus = new Set<String>{Label.AccountStatusObsolete,Label.AccountStatusPendingObsolete};
        Set<String> setValidStages = new Set<String>{Label.QuoteStageDraft,Label.QuoteStageApprovalRequired};                                              
        mapLabels = loadLabels();
        
        Apttus_Proposal__Proposal__c objProposal = new ApttusProposalsSelector().selectProposalById(strProposalId);
		if(Label.Language_English.equals(objProposal.Preferred_Language__c) && (Label.CountryCanada.equals(objProposal.Apttus_Proposal__Account__r.BillingCountry) || Label.CountryCanada.equals(objProposal.Ship_To__r.Country__c)))
            boolIsCountryCanadaLangEnglish = true; //DCP-29629                                       
                                                
        
        booInValidQuote = (setValidStages.contains(objProposal.Apttus_Proposal__Approval_Stage__c) && objProposal.Invalid_Quote__c);
        
        booQuoteswInValidAcc = (setValidStages.contains(objProposal.Apttus_Proposal__Approval_Stage__c) && (setInValidAccountStatus.contains(objProposal.Apttus_Proposal__Opportunity__r.Account.Account_Status__c) || 
                                                                                                            setInValidAccountStatus.contains(objProposal.Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Account_Status__c) ||
                                                                                                            setInValidAccountStatus.contains(objProposal.Apttus_Proposal__Opportunity__r.Distributor__r.Account_Status__c) ||
                                                                                                            setInValidAccountStatus.contains(objProposal.Apttus_Proposal__Opportunity__r.Lessor_Customer__r.Account_Status__c)));
        
        booInReview = Label.QuoteStageInReview.equals(objProposal.Apttus_Proposal__Approval_Stage__c);
        booApproved = (Label.QuotationApprovalStatusApproved.equals(objProposal.Apttus_Proposal__Approval_Stage__c) || Label.QuoteStageGenerated.equals(objProposal.Apttus_Proposal__Approval_Stage__c)|| Label.QuoteStagePresented.equals(objProposal.Apttus_Proposal__Approval_Stage__c));
        booAccepted = Label.QuoteStageAccepted.equals(objProposal.Apttus_Proposal__Approval_Stage__c);
        booDenied = Label.QuoteStageDenied.equals(objProposal.Apttus_Proposal__Approval_Stage__c);

        if(String.isBlank(objProposal.Preferred_Language__c))
            booDisablePostpricingList = true;
        else{
            System.debug('prefLanguageToPostPricingList: ' + prefLanguageToPostPricingList);
            strCanadaFoundation = Label.CanadianFoundationForInnovation;//DCP-29629
            lstSplittedPostPricingList = populatePostPricingList(objProposal.Preferred_Language__c, objProposal.Region_Sold_To__c);
            lstPstPricingMsg.add(new PickListValueWrapper(null,System.Label.None));
            for (String str : lstSplittedPostPricingList){
				if(strCanadaFoundation.equals(str) ){//DCP-29629- added if block
                    if(boolIsCountryCanadaLangEnglish)
                    lstPstPricingMsg.add(new PickListValueWrapper(str,str));
                }else{
                    lstPstPricingMsg.add(new PickListValueWrapper(str,str));
                }
            }
        }
        System.debug('lstSplittedPostPricingList-->' +lstSplittedPostPricingList);
        
        if(lstSplittedPostPricingList.contains(objProposal.Post_Pricing_Message_List__c))
            lstGlobalLangWrapper = populateGlobalLanguage(objProposal.Post_Pricing_Message_List__c,objProposal.Id);
        else
            lstGlobalLangWrapper = populateGlobalLanguage(null,objProposal.Id);
        
        
        //DCP-21934: get all non standard picklist values for all langauges
        Set<String> setNonStandardPicklistValues = new Set<String>();
        for(Post_Pricing_Messages__c objPPM : new PostPricingMessageSelector().selectPostPricingMessageByDeveloperName('Non_Standard_Post_Pricing_Message')) {
            setNonStandardPicklistValues.add(objPPM.PicklistValue__c);
        }
        System.debug('setNonStandardPicklistValues: ' + setNonStandardPicklistValues);

        return '{"lstPstPricingMsg":'+JSON.serialize(lstPstPricingMsg)
            +',"mapUiLabels":'+JSON.serialize(mapLabels)
            +',"strPpm":'+JSON.serialize(objProposal.Post_Pricing_Message_List__c)
            +',"strGlLang":'+JSON.serialize(lstGlobalLangWrapper)
            +',"booInValidQuote": '+JSON.serialize(booInValidQuote)
            +',"booQuoteswInValidAcc": '+JSON.serialize(booQuoteswInValidAcc)
            +',"booInReview": '+JSON.serialize(booInReview)
            +',"booApproved": '+JSON.serialize(booApproved)
            +',"booAccepted": '+JSON.serialize(booAccepted)
            +',"booDenied": '+JSON.serialize(booDenied)
            +',"setNonStandardPicklistValues": '+JSON.serialize(setNonStandardPicklistValues)
            +',"booDisablePostpricingList": '+JSON.serialize(booDisablePostpricingList)+'}';
    }

    /*
    @author Akash Kumar
    @Method Name = populatePostPricingList;
    @Purpose = To return Wrapper Of Post Pricing Message LOV's;
    @Parameters = Preferred Language
    @return = List< PickListValueWrapper >
    */   
    @AuraEnabled
    public static List<string> populatePostPricingList(String strPreferredLanguage, String strRegion){

        List <String> prefLanguageToPostPricingList = new List <String>();
        List<Post_Pricing_Messages__c> lstPostPricingList = new PostPricingMessageSelector().selectPostPricingMessageByNameAndRegion(strPreferredLanguage, strRegion);
                                                                
        for(Post_Pricing_Messages__c p : lstPostPricingList) {
            prefLanguageToPostPricingList.add(p.PicklistValue__c);
        }
        return prefLanguageToPostPricingList;
    }

    /*
    @author Akash Kumar
    @Method Name = populateGlobalLanguageOnChange;
    @Purpose = To create a JSON of Global Language String on change of PPM;
    @Parameters = Post Pricing Message,Proposal Id
    @return = JSON of Global Language String
    */
    @AuraEnabled
    public static String populateGlobalLanguageOnChange(String strPpmValue, String strProposalId) {
        
        List < GlobalLanguageWrapper > lstGlobalLangWrapper = new List < GlobalLanguageWrapper > ();
        lstGlobalLangWrapper = populateGlobalLanguage(strPpmValue,strProposalId);
        return JSON.serialize(lstGlobalLangWrapper);
        
    }
    
        /*
    @author Akash Kumar
    @Method Name = populateGlobalLanguage;
    @Purpose = To return wrapper of the Global Language String;
    @Parameters = Post Pricing Message,Proposal Id
    @return = List< GlobalLanguageWrapper >
    */
    
    public static List< GlobalLanguageWrapper > populateGlobalLanguage(String sPpmValue, String sProposalId) {
        System.debug('sPpmValue-->' +sPpmValue);
        Apttus_Proposal__Proposal__c objProposal = new ApttusProposalsSelector().selectProposalById(sProposalId);
        List < GlobalLanguageWrapper > lstGlobalLangWrapper = new List < GlobalLanguageWrapper > ();
        String strGlobalLang;
        String strExistingGlobalLanguage = objProposal.Post_Pricing_Message__c;
        Post_Pricing_Messages__c objPostPricingListMdt;
		String strBrazilProjectInfo = System.Label.BrazilProjectInfo;
        String strBrazilProjectInfoWithHelpText = System.Label.BrazilProjectInfoWithHelpText;

        if(String.isNotBlank(sPpmValue)){  
            if(sPpmValue != objProposal.Post_Pricing_Message_List__c){
                objPostPricingListMdt = new PostPricingMessageSelector().selectPostPricingMessage(sPpmValue);
                strGlobalLang = objPostPricingListMdt.Value__c;
                System.debug('strGlobalLang-->' +strGlobalLang);
                List < String > lstSplitString = splitString(strGlobalLang);    
                for(Integer i=0;i<lstSplitString.size();i++){
                    GlobalLanguageWrapper glw = new GlobalLanguageWrapper();
                    glw.booQuoteNum = false;
                    glw.booInstName = false; 
                    glw.booInstNameMiSeq = false; 
                    glw.booInstNameHiSeq = false;
                    glw.booBrazilHelpText = false;
                    glw.booIsOptional = false;//DCP-28436: Initialized booBrazilHelpText,booIsOptional
                    if(strGlobalLang.contains(STRING_VALUE_A)){
						if(lstSplitString[i].contains(NUMBERFIELD)){//if block added for DCP-29629
                                glw.sType = 'dynamicNumber';
                                glw.sValue = '';
                        }
                        else if(lstSplitString[i].contains(STRING_VALUE_A)){
                                glw.sType = STRING_DYNAMIC_TYPE;
                                glw.sValue =  '';
                        }
                        else if(lstSplitString[i].contains('BBBB') || lstSplitString[i].contains('CCCC') || lstSplitString[i].contains('DDDD') || lstSplitString[i].contains('EEEE')){
                                glw.sType = STRING_DYNAMIC_TYPE;
                                glw.sValue = '';
                                glw.booQuoteNum = true;
                        }
                        else{
                                glw.sType = STRING_STATIC_TYPE;
                                glw.sValue=lstSplitString[i];
                            }

                        }
                    if(!strGlobalLang.contains(STRING_VALUE_A) && String.isNotBlank(lstSplitString[0])){
                        if(lstSplitString[i].contains('SY-410-1101')){
                                glw.sType = STRING_DYNAMIC_TYPE;
                                glw.sValue = '';
                                glw.booInstNameMiSeq  = true;
                        }   
                        else if(lstSplitString[i].contains('HiSeq 2500')){
                                glw.sType = STRING_DYNAMIC_TYPE;
                                glw.sValue = '';
                                glw.booInstNameHiSeq  = true;
                        }
                        else if(lstSplitString[i].contains('POPULATE INSTRUMENT NAME')){
                                glw.sType = STRING_DYNAMIC_TYPE;
                                glw.sValue = '';
                                glw.booInstName  = true;
                        }
                        else if(lstSplitString[i].contains('装置名')){
                                glw.sType = STRING_DYNAMIC_TYPE;
                                glw.sValue = '';
                                glw.booInstName  = true;
                        }
                        else{
                                glw.sType = STRING_STATIC_TYPE;
                                glw.sValue=lstSplitString[i];
                            }
                    }
                    if(String.isBlank(lstSplitString[0])){
                        if(math.mod(i, 2) == 0){
                            glw.sType = STRING_STATIC_TYPE;
                            glw.sValue='';
                        }
                        else{
                            glw.sType = STRING_DYNAMIC_TYPE;
                            glw.sValue='';
                            glw.booInstNameMiSeq  = false;
                        }
                    }
					if(strGlobalLang.contains(strBrazilProjectInfo) && String.isNotBlank(lstSplitString[0])){//DCP-28436: Added logic for Brazil template with optional fields
                        if(lstSplitString[i].contains(strBrazilProjectInfo)){
                                glw.sType = STRING_DYNAMIC_TYPE;
                                glw.sValue = '';
                                glw.booIsOptional = true;
                                if(lstSplitString[i].contains(strBrazilProjectInfoWithHelpText)){
                                    glw.booBrazilHelpText = true;
                                }
                        }  
                        else{
                                glw.sType = STRING_STATIC_TYPE;
                                glw.sValue=lstSplitString[i];
                            }
                    }
                    lstGlobalLangWrapper.add(glw);
                }    
            }
            else{
                objPostPricingListMdt = new PostPricingMessageSelector().selectPostPricingMessage(sPpmValue);
                strGlobalLang = objPostPricingListMdt.Value__c;
                List < String > lstSplitString = splitString(strGlobalLang);
                strExistingGlobalLanguage=objProposal.Post_Pricing_Message__c;
                for(Integer i=0;i<lstSplitString.size();i++){
                    GlobalLanguageWrapper glw = new GlobalLanguageWrapper();
                    glw.booQuoteNum = false; 
                    glw.booInstName = false; 
                    glw.booInstNameMiSeq = false; 
                    glw.booInstNameHiSeq = false;
                    glw.booBrazilHelpText = false;
                    glw.booIsOptional = false;//DCP-28436: Initialized booBrazilHelpText,booIsOptional
                    if(strGlobalLang.contains(STRING_VALUE_A)){
						if(lstSplitString[i].contains(NUMBERFIELD)){//if block added for DCP-29629
                                glw.sType = 'dynamicNumber';
                                glw.sValue = strExistingGlobalLanguage.substring(strExistingGlobalLanguage.indexOf(lstSplitString[i-1])+lstSplitString[i-1].length(),strExistingGlobalLanguage.indexOf(lstSplitString[i+1]));   
                        }
                        else if(lstSplitString[i].contains(STRING_VALUE_A)){
                            glw.sType = STRING_DYNAMIC_TYPE;
                            glw.sValue = objProposal.Name;
                        }
                        else if(lstSplitString[i].contains('BBBB') || lstSplitString[i].contains('CCCC') || lstSplitString[i].contains('DDDD') || lstSplitString[i].contains('EEEE')){
                            glw.sType = STRING_DYNAMIC_TYPE;
                            glw.sValue = strExistingGlobalLanguage.substring(strExistingGlobalLanguage.indexOf(lstSplitString[i-1])+lstSplitString[i-1].length(),strExistingGlobalLanguage.indexOf(lstSplitString[i+1]));
                            glw.booQuoteNum = true;
                        }
                        else {
                            glw.sType = STRING_STATIC_TYPE;
                            glw.sValue=lstSplitString[i];
                        }
                    }
					if(strGlobalLang.contains(strBrazilProjectInfo) && String.isNotBlank(lstSplitString[0])){//DCP-28436: Added logic for Brazil template with optional fields
                        if(lstSplitString[i].contains(strBrazilProjectInfo)){
                                glw.sType = STRING_DYNAMIC_TYPE;
                                glw.booIsOptional = true;
                                System.debug('i Value:::::::' + i);
                                if(i==lstSplitString.size()-1){
                                    glw.sValue = strExistingGlobalLanguage.substring(strExistingGlobalLanguage.indexOf(lstSplitString[i-1])+lstSplitString[i-1].length());
                                }else{
                                    glw.sValue = strExistingGlobalLanguage.substring(strExistingGlobalLanguage.indexOf(lstSplitString[i-1])+lstSplitString[i-1].length(),strExistingGlobalLanguage.indexOf(lstSplitString[i+1]));
                                }
                                if(lstSplitString[i].contains(strBrazilProjectInfoWithHelpText)){
                                    glw.booBrazilHelpText = true;
                                }
                        }  
                        else{
                                glw.sType = STRING_STATIC_TYPE;
                                glw.sValue= lstSplitString[i];
                            }
                    }
                    if(!strGlobalLang.contains(STRING_VALUE_A) && !strGlobalLang.contains('BRAZIL PROJECT INFO') && String.isNotBlank(lstSplitString[0])){
                            if(lstSplitString[i].contains('SY-410-1101')){
                                glw.sType = STRING_DYNAMIC_TYPE;
                                if(i==0)
                                glw.sValue = strExistingGlobalLanguage.substring(0,strExistingGlobalLanguage.indexOf(lstSplitString[1]));  
                                else
                                glw.sValue = strExistingGlobalLanguage.substring(strExistingGlobalLanguage.indexOf(lstSplitString[i-1])+lstSplitString[i-1].length(),strExistingGlobalLanguage.indexOf(lstSplitString[i+1]));
                                glw.booInstNameMiSeq  = true;
                            }   
                            else if(lstSplitString[i].contains('HiSeq 2500')){
                                glw.sType = STRING_DYNAMIC_TYPE;
                                glw.sValue = strExistingGlobalLanguage.substring(strExistingGlobalLanguage.indexOf(lstSplitString[i-1])+lstSplitString[i-1].length(),strExistingGlobalLanguage.indexOf(lstSplitString[i+1]));
                                glw.booInstNameHiSeq  = true;
                            }
                            else if(lstSplitString[i].contains('POPULATE INSTRUMENT NAME')){
                                glw.sType = STRING_DYNAMIC_TYPE;
                                glw.sValue = strExistingGlobalLanguage.substring(strExistingGlobalLanguage.indexOf(lstSplitString[i-1])+lstSplitString[i-1].length(),strExistingGlobalLanguage.indexOf(lstSplitString[i+1]));
                                glw.booInstName  = true;
                            }
                            else if(lstSplitString[i].contains('装置名')){
                                glw.sType = STRING_DYNAMIC_TYPE;
                                glw.sValue = strExistingGlobalLanguage.substring(strExistingGlobalLanguage.indexOf(lstSplitString[i-1])+lstSplitString[i-1].length(),strExistingGlobalLanguage.indexOf(lstSplitString[i+1]));
                                glw.booInstName  = true;
                            }
                            else{
                                glw.sType = STRING_STATIC_TYPE;
                                glw.sValue=lstSplitString[i];
                            }
                    }
                    if(String.isBlank(lstSplitString[0])){
                        if(math.mod(i, 2) == 0){
                            glw.sType = STRING_STATIC_TYPE;
                            glw.sValue = '';
                        }
                        else{
                            glw.sType = STRING_DYNAMIC_TYPE;
                            glw.sValue = strExistingGlobalLanguage;
                        }    
                    }
                    lstGlobalLangWrapper.add(glw);    
                }
            }
        }
        return lstGlobalLangWrapper;
    }
    
    /*
@Method Name = SplitString;
@Purpose = Split the string with delimiter as Pipe;
@Parameters = String 

*/
    public static List < String > splitString(String wholeString) {
        
        List < String > lstSplitString = wholeString.split('\\|');
        System.debug('lstsplitString-->' + lstsplitString);
        return lstsplitString;
    }
    
    /*
@Method Name = loadLabels;
@Purpose = load labels and error labels;
@return = Map<String,String>
*/
    private static Map < String, String > loadLabels() {
        Map < String, String > mapLabels = new Map < String, String > ();
        mapLabels.put('Post_Pricing_Message', System.Label.Post_Pricing_Message);
        mapLabels.put('Post_Pricing_Message_List',System.Label.Post_Pricing_Message_List);
        mapLabels.put('dynamic',System.Label.dynamic);
        mapLabels.put('static',System.Label.static);
        mapLabels.put('UI_ErrorMessage_PPM_AcceptPrQuote', System.Label.UI_ErrorMessage_PPM_AcceptPrQuote);
        mapLabels.put('UI_ErrorMessage_PPM_Accepted',System.Label.UI_ErrorMessage_PPM_Accepted);
        mapLabels.put('UI_ErrorMessage_PPM_Approved',System.Label.UI_ErrorMessage_PPM_Approved);
        mapLabels.put('UI_ErrorMessage_PPM_InReview',System.Label.UI_ErrorMessage_PPM_InReview);
        mapLabels.put('UI_InvalidQuoteError',System.Label.UI_InvalidQuoteError);
        mapLabels.put('UI_ErrorMessage_InValidAccountStatus',System.Label.UI_ErrorMessage_InValidAccountStatus);
        mapLabels.put('Populate_Quote_Number',System.Label.Populate_Quote_Number);
        mapLabels.put('Populate_MiSeq_Instructions',System.Label.Populate_MiSeq_Instructions);
        mapLabels.put('Populate_HiSeq_Instructions',System.Label.Populate_HiSeq_Instructions);
        mapLabels.put('Populate_Instrument_Name',System.Label.Populate_Instrument_Name);
		mapLabels.put('Brazil_PPM_Help_Text',System.Label.Brazil_PPM_Help_Text);//DCP-28436: Added brazil help text label
        
        return mapLabels;
    }
    /*
@author Akash Kumar
@Method Name = saveProposal;
@Purpose = Update Proposal;
@Parameters = Proposal Id,PPM Picklist Value,Global Language String
@return = void
*/
    @AuraEnabled
    public static String saveProposal(String strProposalId,String strPpmVal,String strGlobalLang){
        
        String retString;
        
        Apttus_Proposal__Proposal__c objProposal = new ApttusProposalsSelector().selectProposalById(strProposalId);
        
        objProposal.Post_Pricing_Message_List__c = strPpmVal;
        objProposal.Post_Pricing_Message__c = strGlobalLang;
        update objProposal;
        retString='Successfully Updated';
        
        return retString;
    }
    
    /*
@author Akash Kumar
@Class Name = GlobalLanguageWrapper;
@Purpose = Wrapper Class to hold static and dynamic values of the Global Language String;
*/
    public class GlobalLanguageWrapper {
        public String sType;
        public String sValue;
        public Boolean booQuoteNum;
        public Boolean booInstName;
        public Boolean booInstNameMiSeq;
        public Boolean booInstNameHiSeq;
        public Boolean booBrazilHelpText;
        public Boolean booIsOptional; //DCP-28436: Added booBrazilHelpText,booIsOptional
        /**
        * @author  Akash Kumar
        * @description Constructor called
        * @params NA
        * @return void
        **/
        public GlobalLanguageWrapper () {
        }
    }
}