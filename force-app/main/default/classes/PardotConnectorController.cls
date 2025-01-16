/**
*    @author: Pankaj 
*    @date:   16-Jan-2019
*    @description:  Controller class for Pardot VF connector for Charket
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        24-Aug-2020        Initial Development
*            Deep Diwakar                   March-21-2023      DCP-59738: Fix overwriting of existing records with NA values
*            Deep Diwakar                   March-21-2023      NOTE - Using SFDC debug statements here because currect 
*                                                              logging framework doesn't log for Guest users (Charket User in this case)
     ------------------------------------------------------------------------------------ 
*                    
*/
public without sharing class PardotConnectorController {
    private String redirectUrl;
    private Charket__WeChatFollower__c follower;

    private static final String NA = 'N/A'; // DCP-59738: added for this story

    // DCP-59738: since this class has other variable with this name that's why prefixing it with LITERAL word
    private static final String LITERAL_FIRSTNAME = 'FirstName'; 
    private static final String LITERAL_LASTNAME = 'LastName'; 

    /*
    *  Description: Constructor PardotConnectorController created
    */
    public PardotConnectorController() {
        IsFormPanel = false;
        IsSuccessPanel = true;
        String pardotEmail = ApexPages.currentPage().getParameters().get('email');

        if (pardotEmail != null) {
            String errors = ApexPages.currentPage().getParameters().get('errors');
            if (errors == null) {
                redirectUrl = ApexPages.currentPage().getParameters().get('redirecturl');
                return;
            }
            IsSuccessPanel = false;
            return;
        }

        String followerId = ApexPages.currentPage().getParameters().get('followerId');
        if (!(String.isNotBlank(followerId) && followerId instanceof Id)) {
            return;
        }

        follower = getFollowerWithContactLead(followerId);
        if (follower == null) {
            return;
        }

        setPardotFormFieldsWithFollower(follower);
        
    }

    /*
    *  Description: Method redirectURL created
    */
    public Pagereference redirectURL() {
        if(follower != null) {
            resetCNContactMeField(follower);
        }
        
        if (String.isNotBlank(redirectUrl)) {
            return new Pagereference(redirectUrl);
        }
        
        return null;
    }

    public Boolean IsFormPanel { get; set; }
    public Boolean IsSuccessPanel { get; set; }
    public String FirstName { get; set; }
    public String LastName { get; set; }
    public String Email { get; set; }
    public String Company { get; set; }
    public String country {get;set;}
    public boolean contactMe {get;set;}
    
    /*
    *  Description: Method getFollowerWithContactLead created
    */
    private Charket__WeChatFollower__c getFollowerWithContactLead(String followerId) {
        List<Charket__WeChatFollower__c> followers = [
            SELECT 
                Id,
                Charket__Contact__c,
                Charket__Contact__r.FirstName,
                Charket__Contact__r.LastName,
                Charket__Contact__r.Email,
                Charket__Contact__r.Account.Name,
                Charket__Contact__r.Mailingcountry,
                Charket__Contact__r.CN_Contact_Me__c,
                Charket__Lead__c,
                Charket__Lead__r.FirstName,
                Charket__Lead__r.LastName,
                Charket__Lead__r.Email,
                Charket__Lead__r.Company,
                Charket__Lead__r.country,
                Charket__Lead__r.CN_Contact_Me__c
            FROM Charket__WeChatFollower__c
            WHERE Id = :followerId
            LIMIT 1
        ];

        if (followers.size() == 0) {
            return null;
        }
        return followers[0];
    }
    /*
    *  Description: Method resetCNContactMeField created
    */
    private void resetCNContactMeField(Charket__WeChatFollower__c follower){
        if(follower.Charket__Contact__c != null && follower.Charket__Contact__r.CN_Contact_Me__c==true){
            Contact objCon=new Contact(id=follower.Charket__Contact__r.Id);
            objCon.CN_Contact_Me__c=false;
            //update objCon;
            try{
               update objCon; 
            }
            catch(Exception e){
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
                
        }        
        else if(follower.Charket__Lead__c != null && follower.Charket__Lead__r.CN_Contact_Me__c==true){
            Leads.BOOLEAN_LEAD_ASSIGNMENT_INVOKED=true;
            Lead objLead=new Lead(id=follower.Charket__Lead__r.Id);
            objLead.CN_Contact_Me__c=false;
            //update objLead; 
            try{
             update objLead;  
            }
            catch(exception e){
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }
    }
    /*
    *  Description: Method setPardotFormFieldsWithFollower created
    */
    private void setPardotFormFieldsWithFollower(Charket__WeChatFollower__c follower) {
        if (follower.Charket__Contact__c != null) {
            if (follower.Charket__Contact__r.Email == null) {
                return;
            }
            setPardotFormFieldsWithContact(follower.Charket__Contact__r);
            return;
        }
        
        if (follower.Charket__Lead__c != null) {
            if (follower.Charket__Lead__r.Email == null) {
                return;
            }
            setPardotFormFieldsWithLead(follower.Charket__Lead__r);
            return;
        }
    }
    /*
    *  Description: Method setPardotFormFieldsWithContact created
    */
    private void setPardotFormFieldsWithContact(Contact contact) {
        FirstName = contact.FirstName;
        LastName = contact.LastName;
        Email = contact.Email;
        Company = contact.Account.Name;
        country=contact.mailingcountry;
        contactMe=contact.CN_Contact_Me__c;
        IsFormPanel = true;
    }
    /*
    *  Description: Method setPardotFormFieldsWithLead created
    */
    private void setPardotFormFieldsWithLead(Lead lead) {
        FirstName = lead.FirstName;
        LastName = lead.LastName;

        //DCP-59738: Adding NA issue fix
        if (String.isNotBlank(FirstName) && NA.equals(FirstName) && String.isNotBlank(LastName) && NA.equals(LastName)) {

            Map<String, String> existingValueMap = new Map<String, String>();
            existingValueMap = getExistingNameValues(lead.Email);
            System.debug('existingValueMap: ' + existingValueMap);
            FirstName = String.isBlank(existingValueMap.get(LITERAL_FIRSTNAME)) ? FirstName : existingValueMap.get(LITERAL_FIRSTNAME);
            System.debug('FirstName: ' + FirstName);
            LastName = String.isBlank(existingValueMap.get(LITERAL_LASTNAME)) ? LastName : existingValueMap.get(LITERAL_LASTNAME);
            System.debug('LastName: ' + LastName);

        }
        
        Email = lead.Email;
        Company = lead.Company;
        country=lead.country;
        contactMe=Lead.CN_Contact_Me__c;
        IsFormPanel = true;
    }

    /**
     * @author     : Deep Diwakar
     * @param      : email of WeChat user who submitted Charket form
     * @return     : map of existing lead/contact record's firstname and lastname
     * @Description: DCP-59738 - this method finds existing lead/contact record's firstname and
     *               lastname based on WeChat user email
     * @NOTE: Using SFDC debug statements here because currect logging framework doesn't log for Guest users (Charket User in this case)
    **/
    private Map<String, String> getExistingNameValues(String incomingEmail) {

        System.debug('incomingEmail: ' + incomingEmail);
        Map<String, String> resultMap = new Map<String, String>();

        List<Contact> lstContact = [Select id,FirstName, LastName, email,Date_Of_Last_Status_Change__c,lastmodifieddate,AccountId
                                        from Contact where email =: incomingEmail
                                        order by lastmodifieddate,Date_Of_Last_Status_Change__c desc];
        if (!lstContact.isEmpty()) {

            if (!String.isBlank(lstContact.get(0).FirstName)) {
                resultMap.put(LITERAL_FIRSTNAME, lstContact.get(0).FirstName);
            }

            if (!String.isBlank(lstContact.get(0).LastName)) {
                resultMap.put(LITERAL_LASTNAME, lstContact.get(0).LastName);

            }

        } else {
            List<Lead> lstLead = [select id,FirstName, LastName,email,Date_Of_Last_Status_Change__c,lastmodifieddate
                                        from Lead where email =: incomingEmail and isConverted =false
                                        order by lastmodifieddate,Date_Of_Last_Status_Change__c desc];

            if (!lstLead.isEmpty()) {

                if (!String.isBlank(lstLead.get(0).FirstName)) {
                    resultMap.put(LITERAL_FIRSTNAME, lstLead.get(0).FirstName);
                }

                if (!String.isBlank(lstLead.get(0).LastName)) {
                    resultMap.put(LITERAL_LASTNAME, lstLead.get(0).LastName);
                }

            }

        }

        System.debug('resultMap: ' + resultMap);
        return resultMap;

    }

}