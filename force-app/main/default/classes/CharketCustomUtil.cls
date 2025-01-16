/**
 * Charket Customisation
 * Utility Class for Service Request WeChat Form
 *  Modification Log:
 *  -------------------------------------------------------------------------------------------------------------------
 *      Developer                      Date                Description
 *      Charket                       12-Oct-2023          Added query selector 
 *      Charket                       13-Oct-2023          Added Instrumentation 
 *  -------------------------------------------------------------------------------------------------------------------
 */
public without sharing class CharketCustomUtil {
    private static final String EMAIL_TEMPLATE_NAME = 'Charket_Verification_Code_Email';
    private static final String CHINA_QUEUE_NAME =  'China Technical Support';
    private static final String LOG_TITLE = 'CharketCustomUtil';

    /*
     * Method to send verification code through Email
     * Currently used when the "Verify Email" button is clicked on the WeChat Service Request Form
     */
    public static Boolean sendEmailVerificationCode(
        String emailVerificationCode,
        String toEmailAddress,
        String replyToEmailAddress,
        String senderDisplayName
    ) {
        ilib_LogEvent.push(LOG_TITLE + 'sendEmailVerificationCode');
        ilib_LogEvent.info('emailVerificationCode' + emailVerificationCode);
        ilib_LogEvent.info('toEmailAddress' + toEmailAddress);
        Boolean sendResult = false;
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
        List<EmailTemplate> templates = new CharketSelector().selectEmailTemplateByName(EMAIL_TEMPLATE_NAME);
        if (templates.size() > 0) {
            String subject = templates[0].Subject;
            String body = (String.isNotBlank(templates[0].Body)
                ? (templates[0].Body.replace('{!verificationcode}', emailVerificationCode))
                : '');
            String htmlValue = (String.isNotBlank(templates[0].HTMLValue)
                ? (templates[0].HTMLValue.replace('{!verificationcode}', emailVerificationCode))
                : '');
            mail.setToAddresses(new List<String>{ toEmailAddress });
            List<OrgWideEmailAddress> orgWideEmails = new CharketSelector().selectOrgWideEmailAddress(replyToEmailAddress);
            if (orgWideEmails.size() > 0) {
                mail.setOrgWideEmailAddressId(orgWideEmails[0].Id);
            } else {
                mail.setSenderDisplayName(senderDisplayName);
                mail.setReplyTo(replyToEmailAddress);
            }
            mail.setSubject(subject);
            mail.setPlainTextBody(body);
            mail.setHtmlBody(htmlValue);
            mail.setCharset('UTF-8');
            Messaging.SendEmailResult[] sendEmailResults = Messaging.SendEmail(
                new List<Messaging.SingleEmailMessage>{ mail }
            );
            sendResult = sendEmailResults[0].isSuccess();
            if (!sendResult) {
                String errorMessage = '';
                Messaging.SendEmailError[] sendErrors = sendEmailResults[0].getErrors();
                if (sendErrors != null && sendErrors.size() > 0) {
                    errorMessage = sendErrors[0].getMessage();
                    insert (new Charket__Log__c(
                        Charket__ApexCodeName__c = 'CharketCustomUtil.sendEmailVerificationCode',
                        Charket__Message__c = errorMessage,
                        Charket__Data__c = 'emailAddress:' + toEmailAddress
                    ));
                }
            }
        }
        ilib_LogEvent.pop();
        return sendResult;
    }

    /*
     * Get the WeChat Follower's WeChat Open ID
     * Used when the Service Request WeChat Form is visited via WeChat
     */
    public static Charket__WeChatFollower__c getFollower(String openId) {
        ilib_LogEvent.push(LOG_TITLE + 'getFollower');
        List<Charket__WeChatFollower__c> followers = [
            SELECT
                Id,
                Charket__WeChatAccount__c,
                DataPrivacyPolicyConsentDate__c,
                EmailVerificationCode__c,
                FirstName__c,
                Lastname__c,
                PreferredContactMethod__c,
                Email__c,
                IsEmailVerified__c,
                Mobile__c,
                CompanyName__c,
                EmailNotifiedTime__c,
                ProductSerialNumber__c,
                Charket__Contact__c,
                Charket__Contact__r.AccountId
            FROM Charket__WeChatFollower__c
            WHERE Charket__OpenId__c = :openId
        ];
        if (followers.size() > 0) {
            ilib_LogEvent.message('followers: ' + followers);
            ilib_LogEvent.pop();
            return followers[0];
        }
        ilib_LogEvent.pop();
        return null;
    }

    /*
     * Get WeChat Follower's full name
     */

    public static String getFollowerFullName(Charket__WeChatFollower__c currentFollower) {
        ilib_LogEvent.push(LOG_TITLE + 'getFollowerFullName');
        ilib_LogEvent.pop();
        return ((String.isNotBlank(currentFollower.Firstname__c))
                        ? (currentFollower.Firstname__c + ' ')
                        : '') +
                    ((String.isNotBlank(currentFollower.Lastname__c))
                        ? currentFollower.Lastname__c
                        : '');
    }

    /*
     * Get configuration settings stored in Custom Metadata Type
     */
    public static CharketSettings__mdt getCharketSetting(String wechatAccountId) {
        ilib_LogEvent.push(LOG_TITLE + 'getCharketSetting');
        if (test.isRunningtest()) {
            CharketSettings__mdt testCharketSetting = new CharketSettings__mdt(
                ReplyToEmailAddress__c = 'test@test.com',
                QRCodeImageName__c = 'bannerimage.png',
                SenderDisplayName__c = 'Acme'
            );
            return testCharketSetting;
        }
        List<CharketSettings__mdt> charketSettings = [
            SELECT
                Id,
                DeveloperName,
                QRCodeImageName__c,
                ReplyToEmailAddress__c,
                SenderDisplayName__c,
                AesKeySize__c
            FROM CharketSettings__mdt
            WHERE DeveloperName = :wechatAccountId.substring(0, 15)
        ];
        if (charketSettings.size() > 0) {
            ilib_LogEvent.message('charketSettings: ' + charketSettings);
            ilib_LogEvent.pop();
            return charketSettings[0];
        }
        ilib_LogEvent.pop();
        return null;
    }

    /*
     * Generates email verification code used to verify email addresses inputted in Service Request WeChat Form
     */
    public static String generateVerificationCode(Integer len) {
        ilib_LogEvent.push(LOG_TITLE + 'generateVerificationCode');
        final String chars = '0123456789';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx + 1);
        }
        ilib_LogEvent.pop();
        return randStr;
    }

    /* 
     * Creates a new inquiry Case that origins from WeChat
     */
    public static String saveCase(
        String subject,
        String description,
        String productSerialNumber,
        String contactInfo,
        Id contactId,
        Id accountId,
        Id followerId
    ) {
        ilib_LogEvent.push(LOG_TITLE + 'saveCase');
        Case newCase = new Case();
        newCase.ContactId = contactId;
        newCase.Subject = subject;
        newCase.Status = 'Initiated';
        newCase.Origin = 'WeChat - TS';
        newCase.Region__c = 'China';
        newCase.WeChatFollower__c = followerId;
        //query and set the Installed Product record ID using the serial number provided
        if (String.isNotBlank(productSerialNumber)) {
            List<SVMXC__Installed_Product__c> thisInstalledProducts = new CharketSelector().selectInstalledProduct(productSerialNumber);
            if (thisInstalledProducts.size() > 0) {
                newCase.SVMXC__Component__c = thisInstalledProducts[0].Id;
                newCase.Product_Serial_Number__c = productSerialNumber;
            }
        }
        String caseDescription =
            description +
            '\n---------- Contact Information ----------\n' +
            contactInfo;
        newCase.Description = caseDescription;
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Inquiry')
            .getRecordTypeId();
        newCase.OwnerId = new CharketSelector().selectGroupByName(CHINA_QUEUE_NAME)[0].Id;
        insert newCase;
        ilib_LogEvent.info('newCase: ' + newCase);
        if (newCase.Id != null) {
            newCase = new CharketSelector().selectCasesByCaseId(newCase.Id)[0];
            //inserts a new case comment with
            Comment__c originalCaseComment = new Comment__c(
                Name = 'Sent by ' +
                    newCase.WeChatFollower__r.FirstName__c +
                    ' ' +
                    newCase.WeChatFollower__r.LastName__c,
                Case__c = newCase.Id,
                Type__c = 'Original Description',
                Comment__c = description,
                RecordTypeId = Schema.SObjectType.Comment__c.getRecordTypeInfosByName()
                    .get('Case - WeChat')
                    .getRecordTypeId()
            );
            insert originalCaseComment;
            ilib_LogEvent.info('originalCaseComment: ' + originalCaseComment);
            ilib_LogEvent.pop();
            return newCase.CaseNumber;
        }
        ilib_LogEvent.pop();
        return '';
    }

    /* 
     * Get wechat oauth url
     */
    public static String getCommentCallbackUrl(Charket__WeChatAccount__c wechatAccount, String caseId) {
        ilib_LogEvent.push(LOG_TITLE + 'getCommentCallbackUrl');
        String callbackUrl = '{0}/CharketServiceRequestComment?wid={1}&cid={2}';
        callbackUrl = String.format(
            callbackUrl,
            new List<Object>{
                wechatAccount.Charket__SalesforceEndpoint__c,
                wechatAccount.Id,
                caseId
            }
        );
        Charket.WeChatApiOAuth oauth = (new Charket.WeChatClient(wechatAccount.Id)).getOAuth();
        ilib_LogEvent.pop();
        return oauth.initiate(callbackUrl, Charket.WeChatApiOAuth.Scope.base, '')
            .getUrl();
    }

    /* 
     * Encrypt wechat openId
     */
    public static String encryptOpenId(String openId, Charket__WeChatAccount__c wechatAccount, CharketSettings__mdt charketSetting) {
        ilib_LogEvent.push(LOG_TITLE + 'encryptOpenId');
        if (String.isNotBlank(openId) && wechatAccount != null) {
            try{
                String aesKey = wechatAccount.OpenIdAesKey__c;
                Integer aesKeySize = Integer.valueOf(charketSetting.AesKeySize__c);
                String algorithmName = 'AES' + aesKeySize;
                if(String.isBlank(aesKey)){
                    aesKey = EncodingUtil.base64Encode(crypto.generateAesKey(aesKeySize));
                    wechatAccount.OpenIdAesKey__c = aesKey;
                    update wechatAccount;
                }
                Blob key = EncodingUtil.base64Decode(aesKey);
                Blob data = Blob.valueOf(openId);
                Blob encrypted = Crypto.encryptWithManagedIV(algorithmName, key, data);

                ilib_LogEvent.pop();
                return EncodingUtil.base64Encode(encrypted);
            } catch(Exception ex) {
                System.debug('Exception-->' + ex.getMessage());
            }
        }
        ilib_LogEvent.pop();
        return null;
    }

    /* 
     * Decrypt wechat openId
     */
    public static String decryptOpenId(String encryptedOpenId, Charket__WeChatAccount__c wechatAccount, CharketSettings__mdt charketSetting) {
        ilib_LogEvent.push(LOG_TITLE + 'decryptOpenId');
        if (String.isNotBlank(encryptedOpenId) && wechatAccount != null) {
            try{
                String aesKey = wechatAccount.OpenIdAesKey__c;
                String algorithmName = 'AES' + charketSetting.AesKeySize__c;
                Blob key = EncodingUtil.base64Decode(aesKey);
                Blob data = EncodingUtil.base64Decode(encryptedOpenId);
                Blob decrypted = Crypto.decryptWithManagedIV(algorithmName, key, data);
    
                ilib_LogEvent.pop();
                return decrypted.toString();
            } catch (Exception ex) {
                System.debug('Exception-->' + ex.getMessage());
            }
        }
        ilib_LogEvent.pop();
        return null;
    }
    /* 
     * Create the Charket Logs
     */
    public static void addCharketLog(String apexCodeName, String message, String data){
        ilib_LogEvent.push(LOG_TITLE + 'addCharketLog');
        insert (new Charket__Log__c(
                Charket__ApexCodeName__c = apexCodeName,
                Charket__Message__c = message,
                Charket__Data__c = data
            ));
        ilib_LogEvent.pop();
    }
}