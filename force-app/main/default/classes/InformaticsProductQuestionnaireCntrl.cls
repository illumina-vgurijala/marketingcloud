/**
*    @date   21-Oct-2019
*    @description    Controller class for LWC informaticsProductQuestionnaire
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Akshay                         21-Oct-19           Initial build
*             Prakhar                        08-Nov-19
*             KD                             20-Jan-2020        Added 'Read_Only_Fields'
*    ------------------------------------------------------------------------------------
*
*/

public without sharing class InformaticsProductQuestionnaireCntrl {
    
    
    /*
     *  @AUTHOR:  Prakhar Kumar
     *  @DESCRIPTION: method runs on Page Load
     *  @PARAM :  String strQuoteLineId,strProductId
     *  @RETURN:  String JSON of Questionnaire
     */ 
     
     @AuraEnabled(cacheable = true)
     public static  String fetchFields(String objectName,String recordID){ 
         Map<String,String> mapoflabels = new Map<String,string>{
             'Questionnaire_Header_QLI' => Label.Questionnaire_Header_QLI,
             'Questionnaire_Header_ALI' => Label.Questionnaire_Header_ALI,
             'Questionnaire_Header_OLI' => Label.Questionnaire_Header_OLI,
             'Questionnaire_Quotation_API' => Label.Questionnaire_Quotation_API,
             'Questionnaire_Asset_Line_API' => Label.Questionnaire_Asset_Line_API,
             'Questionnaire_Order_Line_API' => Label.Questionnaire_Order_Line_API,
             'UI_Questionnaire_Header_QLI_AddOnField' => Label.UI_Questionnaire_Header_QLI_AddOnField,
             'UI_Questionnaire_Header_QLI_AddOn' => Label.UI_Questionnaire_Header_QLI_AddOn
         };
         System.debug('recId===='+recordID);
         Apttus_Proposal__Proposal_Line_Item__c pli = new ApttusProposalLineItemsSelector().fetchQuotationLineItemById(new Set<Id>{recordID})[0];
         System.debug('pli: '+pli);
         InformaticProductsService.InformaticsProductWrapper wrap = InformaticProductsService.getConfig(pli);  
         System.debug('Configuration: '+wrap);
         
         return '{"Quote_Line_Item_Fields" : '+JSON.serialize(wrap!=null?wrap.strFields:null)
             +', "Required_Fields" : ' + JSON.serialize(wrap!=null?wrap.strRequiredFields:null) +
             +', "Read_Only_Fields" : '+ JSON.serialize(wrap!=null?wrap.strReadOnlyFields:null) +
			 +', "Product_Family" : '+ JSON.serialize(wrap!=null?wrap.strFamily:null) +
             +', "mapLabels" : '+JSON.serialize(mapoflabels)+ '}';
         }
         
     }