/**
*   @author Milan Savaliya
*   @date 2018-10-26
*   @description    
*   Modification Log:
*   ------------------------------------------------------------------------------------
*           Developer                   Date                Description
*           Milan                       2018-10-26
*           Joshith                                         convertAttachmentToFile
*           Govind Dubey                2019-03-09          Modified convertAttachmentToFile Logic for existing Content
*           Akshay Mohan                2021-05-11          DCP-38809: Add logic to copy file to work order
*           Adithi Acharya              2022-08-29          TASK0802930 hypercare - sendQuoteUrl Exception handling 
*   ------------------------------------------------------------------------------------
**/

public with sharing class ApttusDocumentCollateInfos extends ilib_SObjectDomain {
    //DCP-38809: Start- make private variable to store quote to work order mapping
    private Map<Id,Id> mapQuoteIdToWorkOrderId=new Map<Id,Id>();
    //DCP-38809: End- make private variable to store quote to work order mapping
    
    //TASK0802930
    public static String strApttusDocumentCollateInfos = 'ApttusDocumentCollateInfos';
    
    /**
    *   @author Milan Savaliya
    *   @description  constructor for framework
    *   @return  void
    **/
    public ApttusDocumentCollateInfos(List<Apttus_Proposal__DocumentCollateInfo__c> sObjectList) {
        super(sObjectList);
    }

    /**
    *   @author Milan Savaliya
    *   @description  constructor for framework
    *   @return  void
    **/
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        
        /**
        *   @author Milan Savaliya
        *   @description  constructor for framework
        *   @return  void
        **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new ApttusDocumentCollateInfos(sObjectList);
        }
    }


    /**
    *   @author Milan Savaliya
    *   @description  Sync Attachment to Opportunity
    *   @parameter Map of Old DocumentCollateInfo
    *   @return  void
    **/
    public override void onAfterUpdate(Map<Id, SObject> idToDocumentCollateInfoOld) {
        System.debug('###AfterUpdateCalled for ApttusDocumentCollateInfos');
        Map<String, Id> attachmentIdToProposalId = new Map<String, Id>();

        Set<String>setAttachmentId=new Set<String>();
        Set<String>setQuoteId=new Set<String>();
        Set<id>setQuoteIds=new Set<id>();
        for(Apttus_Proposal__DocumentCollateInfo__c objDocumentCollateInfo : (List<Apttus_Proposal__DocumentCollateInfo__c>)records){
            
            if(objDocumentCollateInfo.Apttus_Proposal__RelatedAttachmentId__c != NULL
                && objDocumentCollateInfo.Apttus_Proposal__ProposalId__c != NULL
                && idToDocumentCollateInfoOld.containsKey(objDocumentCollateInfo.Id)
                && objDocumentCollateInfo.Apttus_Proposal__RelatedAttachmentId__c != ((Apttus_Proposal__DocumentCollateInfo__c)idToDocumentCollateInfoOld.get(objDocumentCollateInfo.Id)).Apttus_Proposal__RelatedAttachmentId__c) {

                attachmentIdToProposalId.put(objDocumentCollateInfo.Apttus_Proposal__RelatedAttachmentId__c, objDocumentCollateInfo.Apttus_Proposal__ProposalId__c);
            }
            
                //for convert attachment linked to file type
            if(objDocumentCollateInfo.Apttus_Proposal__RelatedAttachmentId__c != NULL&& objDocumentCollateInfo.Apttus_Proposal__ProposalId__c != NULL){

                setAttachmentId.add(objDocumentCollateInfo.Apttus_Proposal__RelatedAttachmentId__c);
                setQuoteId.add(objDocumentCollateInfo.Apttus_Proposal__ProposalId__c);
                setQuoteIds.add(objDocumentCollateInfo.Apttus_Proposal__ProposalId__c);

            }

        }
        if(!attachmentIdToProposalId.isEmpty()) {
            syncAttachmentToOpp(attachmentIdToProposalId);
        }
        if(!setAttachmentId.isEmpty() && !setQuoteIds.isEmpty()){
            //DCP-38809: Start- build map of quote id to work order id
            buildMapQuoteIdToWorkId(setQuoteIds);
            //DCP-38809: End- build map of quote id to work order id
            convertAttachmentToFile(setAttachmentId,setQuoteId,setQuoteIds);
        }
        if(!setQuoteId.isEmpty()){
            List<String>lstQuoteId=new List<String>(setQuoteId);
            sendQuoteUrl(lstQuoteId[0]);

        }
    }


/**
*   @author Milan Savaliya
*   @description  Sync Attachment to Opportunity
*   @parameter Map of Attachment to ProposalId
*   @return  void
**/
    @future
    public static void syncAttachmentToOpp(Map<String, Id> attachmentIdToProposalId) {

        Set<Id> setProposalid = new Set<Id>(attachmentIdToProposalId.values());
        Map<Id, Apttus_Proposal__Proposal__c> idToProposal = new Map<Id,Apttus_Proposal__Proposal__c> (new ApttusProposalsSelector().selectByQuoteId(setProposalid));
        Map<String, Id> mapAttachmentToOpp = new Map<String, Id>();
        

        for(String strAttachmentId : attachmentIdToProposalId.keySet()) {

            Id idProposal = attachmentIdToProposalId.get(strAttachmentId);
            if(idToProposal.containsKey(idProposal)
                && idToProposal.get(idProposal).Apttus_Proposal__Primary__c
                && idToProposal.get(idProposal).Apttus_Proposal__Opportunity__c != NULL
                && idToProposal.get(idProposal).Quote_Type__c != NULL
                && idToProposal.get(idProposal).Quote_Type__c.Contains('Indirect')) {
                Id idOpportunity = idToProposal.get(idProposal).Apttus_Proposal__Opportunity__c;
                mapAttachmentToOpp.put(strAttachmentId, idOpportunity);
            }
        }

        if(!mapAttachmentToOpp.isEmpty()) {
            
            List<Attachment> lstAttachmentToInsert = new List<Attachment>();
            for(Attachment objAttachment : new AttachmentsSelector().selectById(mapAttachmentToOpp.keySet())) {

                Id idOpportunity = mapAttachmentToOpp.get(objAttachment.Id);
                if(idOpportunity != NULL) {
                    Attachment objClonedAttachment = new Attachment(Name = objAttachment.Name
                                                                    , Body = objAttachment.Body
                                                                    , ParentId = idOpportunity);
                    lstAttachmentToInsert.add(objClonedAttachment);
                }
            }
            if(!lstAttachmentToInsert.isEmpty()) {
                insert lstAttachmentToInsert;
            }
        }
    }

/**
*   @author Joshith k
*   @description  Sent FileContent to SAP
*   @parameter setAttachmentId set of attachment ids
*   @parameter setQuoteId set of strings quoteid
*   @parameter setQuoteIds set of id quote ids
*   @return  void
**/
    public void convertAttachmentToFile(set<string>setAttachmentId,set<string>setQuoteId,set<id>setQuoteIds){
        system.debug('am inside converter');
        Map<id,Attachment> idToAttachments=new Map<id,Attachment>();
       
        // Query and get current files if exist for related Quote
        Map<id,List<ContentDocumentLink>> idToContentDocumentLinks = new Map<id,List<ContentDocumentLink>>();

        for(ContentDocumentLink objConDocLink:(list<ContentDocumentLink>)new ContentDocumentLinksSelector().selectByQuoteId(setQuoteIds)){
            if(idToContentDocumentLinks.containsKey(objConDocLink.LinkedEntityId)) {
                idToContentDocumentLinks.get(objConDocLink.LinkedEntityId).add(objConDocLink);
            }
            else{
                idToContentDocumentLinks.put(objConDocLink.LinkedEntityId,new List<ContentDocumentLink>{objConDocLink});
            }
        }

        List<ContentDocumentLink> lstContentDocumentLink = new list<ContentDocumentLink>();
        List<ContentVersion> lstContentVersion = new list<ContentVersion>();
        Map<id,ContentVersion> idToContentVersion = new Map<id,ContentVersion>();
        for(Attachment objAttachment : new AttachmentsSelector().selectById(setAttachmentId)){
            idToAttachments.put(objAttachment.parentid,objAttachment);
            Boolean boolNewVersion = true;
            ContentVersion contentVersionNew = new ContentVersion(
                
                Title = objAttachment.Name,
                PathOnClient = objAttachment.Name,
                
                VersionData =objAttachment.body ,
                IsMajorVersion = true
            );
            if(!idToContentDocumentLinks.isEmpty()){
                for(ContentDocumentLink objCDL:idToContentDocumentLinks.get(objAttachment.Parentid)){
                    if(String.isNotBlank(objCDL.ContentDocument.Title)){
                        Integer intLastIndexOfCDLTitle = getLastIndexOfString(objCDL.ContentDocument.Title,'_'),
                        intLastIndexOfAttachmentTitle = getLastIndexOfString(objAttachment.Name,'_');
                        if(intLastIndexOfCDLTitle != -1 && intLastIndexOfAttachmentTitle != -1 && objCDL.ContentDocument.Title.substring(0,intLastIndexOfCDLTitle).equals(objAttachment.Name.substring(0,intLastIndexOfAttachmentTitle))){
                            contentVersionNew.ContentDocumentId = objCDL.ContentDocumentId;
                            contentVersionNew.ReasonForChange = string.valueof(System.now());
                            boolNewVersion = false;
                        }
                    }
                }
            }
            if(boolNewVersion) { idToContentVersion.put(objAttachment.Parentid,contentVersionNew); }
            else { lstContentVersion.add(contentVersionNew); }

        }
        insert lstContentVersion;
        insert idToContentVersion.values();
        Set<id>setConVersionid=new Set<id>();
        for(ContentVersion objCon:idToContentVersion.values()){
            setConVersionid.add(objCon.id);
        }
        Map<id,id>mapConVer=new Map<id,id>();
        for(ContentVersion objConVersion:new ContentVersionsSelector().selectByContentVersionId(setConVersionid)){      
            mapConVer.put(objConVersion.id,objConVersion.ContentDocumentId);
        }

        for(id  objId:idToContentVersion.keySet()){
            ContentDocumentLink conDocLink = new ContentDocumentLink();
            conDocLink.ContentDocumentId = mapConVer.get(idToContentVersion.get(objId).id);
            conDocLink.LinkedEntityId =objId;
            conDocLink.ShareType = 'I';
            lstContentDocumentLink.add(conDocLink);
            //DCP-38809: Start- check for work order copy
            copyToWorkOrder(objId,mapConVer.get(idToContentVersion.get(objId).id),lstContentDocumentLink);
            //DCP-38809: End- check for work order copy
        }

        insert lstContentDocumentLink;
    }

    /**
    *   @author Joshith K
    *   @description  getLastIndexOfString
    *   @return  void
    **/
    public static Integer getLastIndexOfString(String strText, String strSubString){
       return strText.lastIndexOf(strSubString);
    }

/**
*   @author Joshith K
*   @description  Send Quote Url To SAP
*   @parameter Set of Quote Id 
*   @return  void
**/
    @future(callout=true)
    public static void sendQuoteUrl(String quoteId) {
        try{
            String strRequstJSON=RealtimePricingRequest.createJSONForGenerateQuote(quoteId,true);
            ApttusSAPConnector.getPrice(strRequstJSON, false);
            }
            catch(Exception e){
                //catch the exception TASK0802930 hypercare
                ApexExceptions.emit(strApttusDocumentCollateInfos, quoteId,e);
            } 
    }
    
    /**
    *   @author Akshay Mohan
    *   @description  DCP-38809: Build map of quote Id to work order Id
    *   @parameter Set of Quote Id 
    *   @return  void
    **/
    public void buildMapQuoteIdToWorkId(Set<id> setQuoteIds){
        for(Apttus_Proposal__Proposal__c objProposal: new ApttusProposalsSelector().selectById(setQuoteIds)){
            if(String.isNotBlank(objProposal.Work_Order__c) && objProposal.Apttus_Proposal__Primary__c){
                mapQuoteIdToWorkOrderId.put(objProposal.id,objProposal.Work_Order__c);
            }
        }
    }

    /**
    *   @author Akshay Mohan
    *   @description  DCP-38809: Build map of quote Id to work order Id
    *   @parameter Set of Quote Id 
    *   @return  void
    **/
    public void copyToWorkOrder(Id idQuote,Id idContentDoc,List<ContentDocumentLink> lstContentDocumentLink){
        if(!mapQuoteIdToWorkOrderId.containsKey(idQuote)){
            return;
        }
        ContentDocumentLink conDocLink = new ContentDocumentLink();
        conDocLink.ContentDocumentId = idContentDoc;
        conDocLink.LinkedEntityId =mapQuoteIdToWorkOrderId.get(idQuote);
        conDocLink.ShareType = 'I';
        conDocLink.Visibility='AllUsers';
        lstContentDocumentLink.add(conDocLink);
    }
}