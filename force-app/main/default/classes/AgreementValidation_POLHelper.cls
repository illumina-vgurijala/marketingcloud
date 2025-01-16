/***************************************************************************************************************************************
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to run logic related to Agreements 
*
 MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Sagar Madkaikar        06-Jun-2022         DCP-51199 : Modified validateIfDCIRAgreementIsGenerated() method to handle COFD Validation along with DCIR validation

****************************************************************************************************************************************/ 

public with sharing class AgreementValidation_POLHelper {

    //DCP-51199
    public static final String DOC_NAME_DCIR = 'DCIR';
    public static final String DOC_NAME_COFD = 'COFD';

    /*******************************************************************************************************
    * @description  Method to use for populate sets setPOLIdsDCIRCheck and setPOLIdsLoanerAgreementCheck
    * @param partOrderLine Part Order Record
    * @param objOldPartOrderLine Old Part Order Record
    * @return void
    */
    public static void populateSets(SVMXC__RMA_Shipment_Line__c partOrderLine, SVMXC__RMA_Shipment_Line__c objOldPartOrderLine) {
        //DCP-33468  (also including logic for mobile app DCP-33585) 
        if ((partOrderLine.Is_DCIR_Filled__c && !objOldPartOrderLine.Is_DCIR_Filled__c) 
                && (objOldPartOrderLine.Enable_DCIR__c == partOrderLine.Enable_DCIR__c)) {
            PartsOrderLines.setPOLIdsDCIRCheck.add(partOrderLine.Id);
        }
        //DCP-41581
        if (partOrderLine.Loaner_Agreement_Signed__c && !objOldPartOrderLine.Loaner_Agreement_Signed__c) {
            PartsOrderLines.setPOLIdsLoanerAgreementCheck.add(partOrderLine.Id);
        } 
        //DCP-51199 : Check if Is_CofD_Filled__c is checked by the user.
        if (partOrderLine.Is_CofD_Filled__c && !objOldPartOrderLine.Is_CofD_Filled__c) {
            PartsOrderLines.setPOLIdsCofDCheck.add(partOrderLine.Id);
        } 
    }   

    /*******************************************************************************************************
    * @description  DCP-33468 To check if DCIR agreement is genreate for POL before marking is DCIR 
    *                         Filled to true
                    DCP-51199 : This method will also check if the document is either DCIR or CofD and throw respective errors.
    * @param setPOLIds Set of Part Order Lines Ids to process
    * @param records Parts Order Lines List
    * @return void
    */
    public static void validateIfDCIRAgreementIsGenerated(set<Id> setPOLIds, List<SVMXC__RMA_Shipment_Line__c> records, String typeOfDoc) {
        Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileID());
        Map<String ,List<ContentDocumentLink>> mapPOLtocontentdoc=new Map<String ,List<ContentDocumentLink>>();
        Map<String ,List<echosign_dev1__SIGN_Agreement__c>> mapPOLtoesignAgreement=new Map<String ,List<echosign_dev1__SIGN_Agreement__c>>();
        Map<String ,List<Attachment>> mapPOLtoAttachment=new Map<String ,List<Attachment>>();
        List<Id> lstPOLId=new List<Id>(setPOLIds);

        for(ContentDocumentLink obj:new ContentDocumentLinksSelector().selectByMasterDataRequestIds(lstPOLId)){
            if(!mapPOLtocontentdoc.containsKey(obj.LinkedEntityId)){
                mapPOLtocontentdoc.put(obj.LinkedEntityId, new List<ContentDocumentLink>());
            }
            mapPOLtocontentdoc.get(obj.LinkedEntityId).add(obj);
            
        }
        if (!cp.Is_Channel_Partner__c) {
        
            for(echosign_dev1__SIGN_Agreement__c obj:new AgreementsSelector().selectPOLAgreements(setPOLIds)){
                //DCP-51199 : Moved the logic to new method to resolve Npath complexity error
                mapPOLtoesignAgreement = checkEsignAgreementDoc(mapPOLtoesignAgreement,obj);
                
            }
            for(Attachment obj:new AttachmentsSelector().selectByParentId(setPOLIds)){
               
                //DCP-51199 : Moved the logic to new method to resolve Npath complexity error
                mapPOLtoAttachment = checkAttachmentDoc(mapPOLtoAttachment,obj);
                
            }
        }
            
        for(SVMXC__RMA_Shipment_Line__c obj: records) {
            throwDCIRError(cp.Is_Channel_Partner__c, obj, mapPOLtoesignAgreement, mapPOLtoAttachment, mapPOLtocontentdoc,typeOfDoc);
        }
    }

   /* @description  DCP-51199 : Created this method to fix Npath complexity
    * @param: mapPOLtoesignAgreement Map<String ,List<echosign_dev1__SIGN_Agreement__c>>
    * @param: obj echosign_dev1__SIGN_Agreement__c
    * @param: typeOfDoc String
    * @return Map<String ,List<echosign_dev1__SIGN_Agreement__c>>
    **/
    private static Map<String ,List<echosign_dev1__SIGN_Agreement__c>> checkEsignAgreementDoc(Map<String ,List<echosign_dev1__SIGN_Agreement__c>> mapPOLtoesignAgreement, echosign_dev1__SIGN_Agreement__c obj)
    {
        if(!mapPOLtoesignAgreement.containsKey(obj.Parts_Order_Line__c)){
            mapPOLtoesignAgreement.put(obj.Parts_Order_Line__c, new List<echosign_dev1__SIGN_Agreement__c>());
        }
        mapPOLtoesignAgreement.get(obj.Parts_Order_Line__c).add(obj);
        
        return mapPOLtoesignAgreement;
    }

   /* @description  DCP-51199 : Created this method to fix Npath complexity
    * @param: mapPOLtoesignAgreement Map<String ,List<Attachment>>
    * @param: obj Attachment
    * @param: typeOfDoc String
    * @return Map<String ,List<Attachment>>
    **/
    private static Map<String ,List<Attachment>> checkAttachmentDoc(Map<String ,List<Attachment>> mapPOLtoAttachment,Attachment obj)
    {
        if(!mapPOLtoAttachment.containsKey(obj.ParentId)){
            mapPOLtoAttachment.put(obj.ParentId, new List<Attachment>());
        }
        mapPOLtoAttachment.get(obj.ParentId).add(obj);
        
        return mapPOLtoAttachment;
    }

    /*******************************************************************************************************
    * @description  Throw Error
    * @param isCPUser Is Logghed in user CP
    * @param obj SVMXC__RMA_Shipment_Line__c
    * @param mapPOLtoesignAgreement Map<String ,List<echosign_dev1__SIGN_Agreement__c>>
    * @param mapPOLtoAttachment Map<String ,List<Attachment>>
    * @param mapPOLtocontentdoc Map<String ,List<ContentDocumentLink>>
    * @return void
    */
    private static void throwDCIRError(Boolean isCPUser, SVMXC__RMA_Shipment_Line__c obj, 
                        Map<String ,List<echosign_dev1__SIGN_Agreement__c>> mapPOLtoesignAgreement,
                        Map<String ,List<Attachment>> mapPOLtoAttachment, Map<String ,List<ContentDocumentLink>> mapPOLtocontentdoc,String typeOfDoc) { //DCP-51199: Added String typeOfDoc
        if(!(!isCPUser && mapPOLtoesignAgreement!=null && mapPOLtoesignAgreement.containsKey(obj.Id) && !mapPOLtoesignAgreement.get(obj.Id).isEmpty())
                    && !(!isCPUser && mapPOLtoAttachment!=null && mapPOLtoAttachment.containsKey(obj.Id) && !mapPOLtoAttachment.get(obj.Id).isEmpty())
                    && !(mapPOLtocontentdoc!=null && mapPOLtocontentdoc.containsKey(obj.Id) && !mapPOLtocontentdoc.get(obj.Id).isEmpty())) {
           
            //DCP-51199 : Added if else to check whether the type of document is DCIR or COFD. Throw respective errors.
            if(DOC_NAME_DCIR.equals(typeOfDoc)){
                obj.addError(!isCPUser?Label.POLDCIRCheckError:Label.POLISDCIRCheckErrorCP);
            }
            else if(DOC_NAME_COFD.equals(typeOfDoc))
            {
                obj.addError(Label.POLCOFDCheckError);
            }
        }
    }

    /*******************************************************************************************************
    * @description  DCP-41581 To check if Loaner agreement is signed for POL before marking Loaner Agreement
    *                         Signed to true
    * @param setPOLIds Set of Part Order Lines Ids to process
    * @param records Parts Order Lines List
    * @return void
    */
    public static void validateIfLoanergreementIsGenerated(set<Id> setPOLIds, List<SVMXC__RMA_Shipment_Line__c> records){
        Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileID());

        Map<String ,List<ContentDocumentLink>> mapPOLtocontentdoc=new Map<String ,List<ContentDocumentLink>>();
        Map<String ,List<echosign_dev1__SIGN_Agreement__c>> mapPOLtoesignAgreement=new Map<String ,List<echosign_dev1__SIGN_Agreement__c>>();
        List<Id> lstPOLId=new List<Id>(setPOLIds);
        for(ContentDocumentLink obj:new ContentDocumentLinksSelector().selectByMasterDataRequestIds(lstPOLId)) {
            if(!mapPOLtocontentdoc.containsKey(obj.LinkedEntityId)){
                mapPOLtocontentdoc.put(obj.LinkedEntityId, new List<ContentDocumentLink>());
            }
            mapPOLtocontentdoc.get(obj.LinkedEntityId).add(obj);
        }
        if (cp.Is_Channel_Partner__c != true) {
            for(echosign_dev1__SIGN_Agreement__c obj:new AgreementsSelector().selectPOLAgreements(setPOLIds)) {
                if(!mapPOLtoesignAgreement.containsKey(obj.Parts_Order_Line__c)){
                    mapPOLtoesignAgreement.put(obj.Parts_Order_Line__c, new List<echosign_dev1__SIGN_Agreement__c>());
                }
                mapPOLtoesignAgreement.get(obj.Parts_Order_Line__c).add(obj);
            }
        }
        
        for(SVMXC__RMA_Shipment_Line__c obj: records) {
                
            if(!(cp.Is_Channel_Partner__c != true && mapPOLtoesignAgreement!=null && mapPOLtoesignAgreement.containsKey(obj.Id) && !mapPOLtoesignAgreement.get(obj.Id).isEmpty())){
                if(!(mapPOLtocontentdoc!=null && mapPOLtocontentdoc.containsKey(obj.Id) && !mapPOLtocontentdoc.get(obj.Id).isEmpty())) {
                    If(cp.Is_Channel_Partner__c != true) {
                        obj.addError(Label.POLLoanerAgreementCheckError);
                    } else {
                        obj.addError(Label.POLLoanerAgreementCheckErrorCP);
                    }

                }  
            }
        }
    }
    
}