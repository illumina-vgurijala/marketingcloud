/*
    Author - Kush Shah
    User Story - DCP-51026
    Purpose - Class to handle the attachments added on Approval Email.
*    @ Test class Coverage: 85% - TestInboundAttachmentCallback.cls
*    @ Test class Coverage : 75% - TestInboundAttachmentCallback.cls

*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Adithi Acharya                23rd Sept 22        @85% Test Class :  TestInboundAttachmentCallback.cls
*               
*    ---------------------------------------------------------------------------------------------------------------------------
*/
global with sharing class InboundAttachmentCallback
implements Apttus_Approval.CustomClass.IInboundAttachmentCallback {
    public static final String QUOTATION_LINE_ITEM_OBJECT = 'Apttus_Proposal__Proposal_Line_Item__c';
    /*
    Author - Kush Shah
    Purpose - handle attachment
    */
    global Boolean handleActionAttachment(ID ctxObjectId, String approvalAction, Messaging.InboundEmail email) 
    {
        ID tempCtxObjectId = ctxObjectId;

        ilib_LogEvent.message('Sample ctxObjectId: ' + ctxObjectId);
        ilib_LogEvent.message('Sample approvalAction: ' + approvalAction);
        
        if(QUOTATION_LINE_ITEM_OBJECT == tempCtxObjectId.getSObjectType().getDescribe().getName()){
            ApttusProposalLineItemsSelector objApttusProposalLineItemsSelector = new ApttusProposalLineItemsSelector();
            tempCtxObjectId = objApttusProposalLineItemsSelector.fetchQuotationLineItemById(new Set<ID>{tempCtxObjectId})[0].Apttus_Proposal__Proposal__c;
        }
        // associate attachment to context object     
        Attachment ctxAttachment = null;
        List<Attachment> addMultipleAttachments = new List<Attachment>();
        ilib_LogEvent.message('>>>>>>>>>>>>>>>>>>>>>>>>' + email.binaryAttachments);
        ilib_LogEvent.message('>>>>>>>>>>>>>>>>>>>>>>>>' + JSON.serialize(email));
        try {

            getMultipleAttachments(ctxAttachment, tempCtxObjectId, addMultipleAttachments, email);
            
            if(!addMultipleAttachments.isEmpty()){
                insert addMultipleAttachments;
            }

        }
        catch (Exception e) {ilib_LogEvent.message('Message...  ' + e.getMessage() +'\n'+'  Type... '+ e.getTypeName() +'\n'+'  Stacktrace... '+ e.getStackTraceString());
            return false; //Test class coverage
        }
        
        // replace approval process attachment with this new attachment
        try {
            for(attachment eachAttachment : addMultipleAttachments){
                    boolean b = Apttus_Approval.ApprovalsWebService.addApprovalEmailAttachment(tempCtxObjectId, eachAttachment.Id);
                    ilib_LogEvent.message('@@@ ' + eachAttachment.name + ' attachment added successfully ' + b);
            }
            
        } catch (Exception ex) {ilib_LogEvent.message('Unable to replace approval process attachment with ' + ctxAttachment.Name +'\n' + ' Message... '+ ex.getMessage() +'\n'+'Type... ' + ex.getTypeName()+'\n'+'Stacktrace... ' + ex.getStackTraceString());
        return false;//Test class coverage
        }
        return true;
    }
    
    /*
    Author - Kush Shah
    Purpose - This will generate the list of attachments.(As part of the Code scan fix Jitesh created this method and moved the code here).
    */
    public void  getMultipleAttachments(Attachment ctxAttachment, ID tempCtxObjectId, List<Attachment> addMultipleAttachments, Messaging.InboundEmail email){

        // binary or text?
        if ((email.binaryAttachments != null) && !email.binaryAttachments.isEmpty()) {
            for (Messaging.InboundEmail.BinaryAttachment eachAttachment : email.binaryAttachments){
                ilib_LogEvent.message('@@@ Sample Binary Attachments - filename: ' + eachAttachment.filename);
                ilib_LogEvent.message('@@@ Sample Binary Attachments' + eachAttachment);
                if(!eachAttachment.mimeTypeSubType.contains('image')){
                    ctxAttachment = new Attachment(ParentId = tempCtxObjectId
                                                , Name = eachAttachment.filename 
                                                , Body = eachAttachment.body);
                    addMultipleAttachments.add(ctxAttachment);
                }
            } 
        }
        if ((email.textAttachments != null) && !email.textAttachments.isEmpty()) {
            for(Messaging.InboundEmail.TextAttachment eachAttachment : email.textAttachments){
                ilib_LogEvent.message('@@@ Sample Text Attachments - filename: ' + eachAttachment.filename);
                
                ctxAttachment = new Attachment(ParentId = tempCtxObjectId
                                               , Name = eachAttachment.filename
                                               , Body = Blob.valueOf(eachAttachment.body));
                addMultipleAttachments.add(ctxAttachment);
            }    
        }
    }
}