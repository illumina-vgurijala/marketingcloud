/***************************************************************************************************************************************
* NAME   : UPSOrderAckEmailHandler 
* DESCRIPTION  : Match the order number recieved in email subject from UPS with the ERP Sales Order Number of Part Order.
                    Attach the email as attachment on Parts Order   
                    Forward the same email to Parts Order owner
*    
* @AUTHOR : Shruti
* @DATE   : 27-May-2019 
****************************************************************************************************************************************/
global class UPSOrderAckEmailHandler implements Messaging.InboundEmailHandler {

    private static final String REGEXSTR_SUBJECT;
    private static final Pattern PATTERN_REGEXSTR_SUBJECT;

    static {
        // Matching subject of email pattern. i.e. OrderNumber:00877875
        // The pattern match is
        // 0 ==> entire email subject line
        // 1 ==> 'OrderNumber:00877875'
        // 2 ==> '00877875'
        REGEXSTR_SUBJECT = '.*(ServiceNumber:([0-9]*)).*';
        PATTERN_REGEXSTR_SUBJECT = Pattern.compile(REGEXSTR_SUBJECT);
    }

	/*******************************************************************************************************
    * @description method to handle Inbound Email
    * @param email Messaging.InboundEmail
    * @param envelope Messaging.InboundEnvelope
    * @return Messaging.InboundEmailResult
    */	
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

        try {
            if (email.Subject != null && email.Subject.contains('Service Number:')) {
                set < String > setOrderNumber = new set < string > ();
                String subject = email.Subject.deleteWhitespace();
                Matcher m = PATTERN_REGEXSTR_SUBJECT.matcher(subject);
                if (!m.matches()) {
                    result.message = 'ERROR: UPS DC Order Acknowledgement - Cannot find Order Number in Order Acknowledgement Subject.';
                    result.success = false;
                    return result;
                } else {
                    //Added for [DCP-28140]
                    if (String.isNotBlank(m.group(2)))
                        setOrderNumber.add(m.group(2));

                }
                
                //Added for [DCP-28140]
                If(setOrderNumber != null && !setOrderNumber.isEmpty()) {
                    SVMXC__RMA_Shipment_Order__c partsOrder;
                    Attachment attchMent = null;

                    try {
                        partsOrder = findPartsOrder(setOrderNumber);
                        if (partsOrder != null) {
                            attchMent = createAttachment(partsOrder, email);
                            System.debug(attchMent);
                            sendEmailtoPOOwner(email, partsOrder);
                        } else {
                            result.message = 'ERROR: UPS DC Order Acknowledgement - Cannot find matching Order in SFDC.';
                            result.success = false;
                            return result;
                        }
                    } catch (Exception e) {
                        result.message = e.getMessage();
                        result.success = false;
                        return result;
                    }
                }
                else {
                    result.message = 'ERROR: UPS DC Order Acknowledgement - No Order number mentioned in email subject:' + email.Subject;
                    result.success = false;
                    return result;
                }

            } else {
                result.message = 'ERROR: UPS DC Order Acknowledgement - Invalid Email subject:' + email.Subject;
                result.success = false;
                return result;
            }
        } catch (Exception e) {
            result.message = e.getMessage();
            result.success = false;
            return result;
        }
        return result;
    }

    // find matching Parts Order 
    @TestVisible private SVMXC__RMA_Shipment_Order__c findPartsOrder(set < String > setOrderNumber) {
        list < SVMXC__RMA_Shipment_Order__c > lstPartsOrder = new list < SVMXC__RMA_Shipment_Order__c > ();
        lstPartsOrder = new PartsOrdersSelector().selectPartsOrdersWithName(setOrderNumber);
        if (lstPartsOrder.size() > 0)
            return lstPartsOrder[0];
        else
            return null;
    }

    // Create Attachment for the Parts Order
    @TestVisible private Attachment createAttachment(SVMXC__RMA_Shipment_Order__c partsOrder, Messaging.InboundEmail email) {
        Attachment attchMent = new Attachment();
        attchMent.ParentId = partsOrder.Id;
        attchMent.OwnerId = partsOrder.OwnerId;
        attchMent.Name = (email.Subject.endsWith('.html') ? email.Subject : email.Subject + '.html');
        attchMent.IsPrivate = false;
        attchMent.Description = email.Subject;
        Blob attchMentBlob = null;

        String emailHTMLBody = email.htmlBody;
        if (!String.isBlank(emailHTMLBody)) {
            // add <pre /> tags to format fixed width font
            emailHTMLBody = emailHTMLBody.replace('<html><body>', '<html><body><pre>');
            emailHTMLBody = emailHTMLBody.replace('</body></html>', '</pre></body></html>');
            attchMent.ContentType = 'text/html; charset=UTF-8';
            attchMentBlob = Blob.valueOf(emailHTMLBody);
        } else {
            attchMent.ContentType = 'text/plain';
            attchMentBlob = Blob.valueOf(email.plainTextBody);
        }
        attchMent.Body = attchMentBlob;
        insert attchMent;
        return attchMent;
    }
    
    //Added for [DCP-28140] - Passed partsOrder as a parameter instead of a string passed earlier.
    private void sendEmailtoPOOwner(Messaging.InboundEmail email, SVMXC__RMA_Shipment_Order__c partsOrder) {

        if (partsOrder.owner.email != null) {
            Messaging.reserveSingleEmailCapacity(1);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {
                partsOrder.owner.email
            };
            mail.setToAddresses(toAddresses);
            mail.setSubject(email.Subject);
            mail.setPlainTextBody(email.plainTextBody);
            //Added for [DCP-28140]
            string customizedBody = '<p>Order Acknowledgement</p> <p>Dear ' + partsOrder.owner.name + ',</p><p>Your Illumina order number&nbsp;' + partsOrder.Name + ' SAP - '  + partsOrder.ERP_Sales_Order_Number__c + ' has been received by UPS and the parts have been reserved to ship out today. A follow up email will be sent once shipped. Please Note: There may be delays in processing same day shipments for International Orders.</p>';
            mail.setHtmlBody(customizedBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
                mail
            });
        }

    }

}