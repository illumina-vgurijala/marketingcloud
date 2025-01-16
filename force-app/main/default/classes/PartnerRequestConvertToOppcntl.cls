/**
*    @author: Kushagra Desai
*    @date:  23-May-2019
*    @description: Controller class to get all metadata and information
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*          Saurav Bhandari               4 March 2020         Created new method updateStatusonPartnerRequest as part of DCP-32168
*          Nishan Shetty                22-April-2022         CodeScan Fix-Avoid Literals in If condition.            
*          Aman Tyagi                    30th March 2022      CodeScan Fixes
*    ------------------------------------------------------------------------------------ 
*                    
*/
public class PartnerRequestConvertToOppcntl {

    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_ONE = 1;
    //End CodeScan Fix


    /**
    *  @author Kushagra Desai
    *  @description To get the recordtype id
    *  @param MetaDataType- MetaDataType
    *  @return String Recordtypeid
    **/
    @AuraEnabled
    public static String getOppRecordTypeId(String MetaDataAPI){
        String strRecordtype = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.OpportunityRTLabelIndirectStandard).getRecordTypeId();
        strRecordtype = strRecordtype.substring(0,15);
        return strRecordtype;
    }
    /**
    *  @author Kushagra Desai
    *  @description To get Partner account
    *  @param RecordId
    *  @return String AccountRecordid
    **/
    @AuraEnabled
    public static String getPartnerAccount(String RecID){
        system.debug('Hello Here is debug');
        List<Partner_Request__c> recordDetails = [SELECT Id, CreatedBy.Contact.AccountId FROM Partner_Request__c WHERE Id =: RecID];
        Map<Id,Id> MapsetIds = UtilsCollection.getMapOfIdToId(recordDetails, 'Id', 'CreatedBy.Contact.AccountId');
        System.debug(MapsetIds.get(RecID));
        return (String)MapsetIds.get(RecID);
    }
    /**
    *  @author Kushagra Desai
    *  @description To get the assigned page layout for a given Record Type and profile
    *  @param RecordTypeID- RecordTypeId
    *  @return String strPageLayoutName
    **/
    @AuraEnabled
    public static String getPageLayoutAssignment(String RecordTypeID){
       String strPageLayoutName='';
       /*This will call tooling api as ProfileLayout object is not supported by SOQL*/
       strPageLayoutName=toolingAPISOQL('select Layout.Name from ProfileLayout where ProfileId = \'' + UserInfo.getProfileId() + '\' AND RecordTypeId = \'' + RecordTypeID + '\'');
       system.debug('--->>>'+ strPageLayoutName);
       String name = strPageLayoutName.substringBetween('"Name":"', '"');
       return name; 
    }
 
    
    /**
    *  @author Kushagra Desai
    *  @description To get the metadata for the pagelayout
    *  @param pageLayoutName
    *  @return PageLayout
    **/
    @AuraEnabled
    public static PageLayout getPageLayoutMetadata(String pageLayoutName) {
        List<String> lstComponentNameList = new List<String>{pageLayoutName};        
        if (String.isBlank(pageLayoutName)) {
            return new PageLayout();
        }        
        /*User Standard MetaData class for fetching layout details*/
        List<Metadata.Metadata> layouts =  
            Metadata.Operations.retrieve(Metadata.MetadataType.Layout, lstComponentNameList);
        if (layouts.size() == INTEGER_ONE) {
            system.debug('  layouts[0]: ' + layouts[0]);
            
            return new PageLayout((Metadata.Layout) layouts[0]);
        }
        
        return new PageLayout();
    }
    /**
    *  @author Kushagra Desai
    *  @description To return the pagelayout name using the Tooling API
    *  @param strQuery
    *  @return PageLayoutName
    **/
    static String toolingAPISOQL( String strQuery) {
        
        Http objHttp = new Http();
        HttpRequest objHttpRequest = new HttpRequest();
        objHttpRequest.setEndpoint('callout:Salesforce_Org/services/data/v43.0/tooling/query/?q='+(strQuery.replace(' ', '+')));
        objHttpRequest.setMethod('GET');
        HttpResponse objHttpResponse = objHttp.send(objHttpRequest);
        return objHttpResponse.getBody();
    } 
    /**
    *  @author Kushagra Desai
    *  @description Wrapper class for Page Layout MetaData
    *  
    **/
    public class PageLayout { 
        @AuraEnabled
        public List<PageLayoutSection> Sections { get; set; }
    
        /**
        *  @author :Kushagra Desai
        *  @description :constructor of class PageLayout and instantiating PageLayoutSection
        *  @return: NA
        *  @param :NA
        *  
        **/
        public PageLayout() {
            Sections = new List<PageLayoutSection>();
        }
    
        /**
        *  @author :Kushagra Desai
        *  @description :parameterized constructor of Class PageLayout
        *  @return: NA
        *  @param : Metadata.Layout layout
        *  
        **/
        public PageLayout(Metadata.Layout layout) {
            this();

            for (Metadata.LayoutSection section : layout.layoutSections) {
                system.debug('sction name is-'+section);
                if (section.style != Metadata.LayoutSectionStyle.CustomLinks) {
                    Sections.add(new PageLayoutSection(section));
                }
            }
        }
    }
    /**
    *  @author Kushagra Desai
    *  @description Wrapper class for Page Layout Sections
    *  
    **/
    public class PageLayoutSection {
        @AuraEnabled
        public List<PageLayoutSectionColumn> Columns { get; set;}
        
        @AuraEnabled
        public String Label { get; set; }
        
        /**
        *  @author :Kushagra Desai
        *  @description :parameterized constructor of Class PageLayoutSection
        *  and instantiating PageLayoutSectionColumn
        *  @return: NA
        *  @param : Metadata.LayoutSection section
        *  
        **/
        public PageLayoutSection(Metadata.LayoutSection section ) {
            Columns = new List<PageLayoutSectionColumn>();
            
            Label = section.label;
            
            for (Metadata.LayoutColumn column : section.layoutColumns) {
                Columns.add(new PageLayoutSectionColumn(column));
            }
        }
    }
    /**
    *  @author Kushagra Desai
    *  @description Wrapper class for Page Layout Columns
    *  
    **/
    public class PageLayoutSectionColumn { 
        @AuraEnabled
        public List<PageLayoutField> Fields { get; set; }
    
        /**
        *  @author :Kushagra Desai
        *  @description :parameterized constructor of Class PageLayoutSectionColumn
        * and instantiating PageLayoutField
        *  @return: NA
        *  @param : Metadata.LayoutColumn column
        *  
        **/  
        public PageLayoutSectionColumn(Metadata.LayoutColumn column) {
            Fields = new List<PageLayoutField>();
            
            if (column.layoutItems == null){ 
                return;
            }

            for (Metadata.LayoutItem item : column.layoutItems) {
                Fields.add(new PageLayoutField(item));
            }
        }
    }
    /**
    *  @author Kushagra Desai
    *  @description Wrapper class for Page Layout Fields
    *  
    **/
    public class PageLayoutField {
        @AuraEnabled
        public String APIName { get; set;}
        @AuraEnabled
        public String Behavior {get;set;}
    
        /**
        *  @author :Kushagra Desai
        *  @description :parameterized constructor of Class PageLayoutField
        *  @return: NA
        *  @param : Metadata.LayoutItem item
        *  
        **/  
        public PageLayoutField(Metadata.LayoutItem item) {
            APIName = item.field;
            Behavior=string.valueof(item.behavior);
        }
    }
	
	/**
    *  @author Saurav Bhandari
    *  @description Method to update the Partner Object Record Status as part of DCP-32168
    *  
    **/
    @AuraEnabled
    public static void updateStatusonPartnerRequest(String OpportunityId){
        Set<Id> setOppId = new Set<Id>();
        setOppId.add(OpportunityId);
        List<Opportunity> lstOpp = new List<Opportunity>();
        List<Partner_Request__c> lstPr = new List<Partner_Request__c>();
        OpportunitySelector clsOppSel = new OpportunitySelector();
        lstOpp = clsOppSel.selectOpportunities(setOppId);
        if(!lstOpp.isEmpty() && lstOpp.size()>0){
            Opportunity objOpp = lstOpp[0];
            lstPr = new PartnerRequestsSelector().selectInstructorLedTrainingCourses(objOpp.Partner_Request__c);
            if(!lstPr.isEmpty() && lstPr.size()>0){
                Partner_Request__c objPr = lstPr[0];
                if(String.isNotBlank(objOpp.Partner_Request__c) && objOpp.Partner_Request__r.RecordType.DeveloperName == System.Label.PartnerRequestRecordTypeReagentRentalRequest){
                    objPr.Status__c = System.Label.PartnerRequestStatusAccepted;
                    if(String.isBlank(objOpp.Type) || objOpp.Type == System.Label.OpportunityTypeStandardSale){
                        objOpp.Type = System.Label.OpportunityTypeStandardSale;
                            if(String.isBlank(objOpp.Product_Interest__c) && String.isNotBlank(objOpp.Type) && objOpp.Type == System.Label.OpportunityTypeStandardSale){
                                objOpp.Product_Interest__c = System.Label.OpportunityProductInterestInstrument;
                            }
                        Update objOpp;
                    }
                Update objPr;        
                }
        }
        }    
    }
}