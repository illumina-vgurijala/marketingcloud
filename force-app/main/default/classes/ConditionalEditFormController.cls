/**
*    @date   06-Oct-2021
*    @description    Controller class for Dragen Onchange
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Maruthi                        06-Oct-2021         Initial build
*    ------------------------------------------------------------------------------------
*
*/
public with sharing class ConditionalEditFormController {

    /*
     *  @AUTHOR:  Maruthi
     *  @DESCRIPTION: Controller class for Dragen Onchange
     *  @RETURN:  String JSON of Questionnaire
     */
    @AuraEnabled(cacheable=false)
    public static String getDragenCustomMetaData(Id recordId){
        InstanceTypeWrapper typeWrapper = new InstanceTypeWrapper(); 
        Set<Id> qliID = new Set<Id>();
        qliID.add(recordId); 
        try {                                     
            List<Dragen_Products__mdt> dragenMetaList = new DragenProductsSelector().loadAllInformaticsConfigurations();            
            List<Apttus_Proposal__Proposal_Line_Item__c> proposalLineItem = new ApttusProposalLineItemsSelector().fetchQuotationLineItemById(qliID);
            for(Dragen_Products__mdt dragenMeta : dragenMetaList){
                if(typeWrapper.instanceTypeValue == null){
                    typeWrapper.instanceTypeValue = proposalLineItem[0].Select_Instance_Type__c;
                }
                if(typeWrapper.serverConnectivity == null){
                    typeWrapper.serverConnectivity = proposalLineItem[0].Server_Connectivity__c;
                }
                if(dragenMeta.Select_Instance_Type__c == Label.Cloud) 
                {
                    typeWrapper.cloudType = new InformaticsProductWrapper(dragenMeta);
                }
                else if(dragenMeta.Select_Instance_Type__c == Label.On_Prem) 
                {
                    typeWrapper.onPremType = new InformaticsProductWrapper(dragenMeta);
                }
                else if(dragenMeta.Select_Instance_Type__c == null || dragenMeta.Select_Instance_Type__c == '')
                {
                    typeWrapper.nullType = new InformaticsProductWrapper(dragenMeta);
                }
            } 
            return JSON.serialize(typeWrapper);         
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
     *  @AUTHOR:  Maruthi
     *  @DESCRIPTION: Wrapper class for Dragen Onchange     
     */
    public class InstanceTypeWrapper
    {
        InformaticsProductWrapper onPremType ;
        InformaticsProductWrapper cloudType ;
        InformaticsProductWrapper nullType ;
        String instanceTypeValue;
        String serverConnectivity;
    }

    /*
     *  @AUTHOR:  Maruthi
     *  @DESCRIPTION: Wrapper class for Dragen Onchange     
     */
    public class InformaticsProductWrapper {
        public String strFamily,strType,strTier,strFields,strRequiredFields,strReadOnlyFields,strInstanceType;
        public Set<String> setRequiredFields,setReadOnlyFields;
        public List<String> lstCartFields, lstQuoteFields;

        /*
     *  @AUTHOR:  Maruthi
     *  @DESCRIPTION: Wrapper class Constroctor for Dragen Onchange     
     */
        public InformaticsProductWrapper(Dragen_Products__mdt config){
            strFamily = config.Product_Family__c;
            setRequiredFields = new Set<String>(config.Required_Fields__c.split(','));
            strRequiredFields = config.Required_Fields__c;
            lstCartFields = config.Line_Item__c.split(',');
            lstQuoteFields = config.Quote_Line_Item_Fields__c.split(',');
            strFields = config.Quote_Line_Item_Fields__c;
            strReadOnlyFields = config.Read_Only_Fields__c;
            strInstanceType = config.Select_Instance_Type__c;            
            if(String.isNotBlank(strReadOnlyFields))
            {
                setReadOnlyFields = new Set<String>(strReadOnlyFields.split(','));
            }                
            else{
                setReadOnlyFields = new Set<String>();
            }                
        }
    }
    
}