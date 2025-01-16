/**
* Author : Tapas
* Class used to serialize a single Lookup search result item
* The Lookup controller returns a List<LookupSearchResult> when sending search result back to Lightning
*/
public class LookupSearchResultController {

    private Id id;
    private String sObjectType;
    private String icon;
    private String title;

		/*
         * description - LookupSearchResult method
         */
    public LookupSearchResultController(Id id, String sObjectType, String icon, String title) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.icon = icon;
        this.title = title;
    }

		/*
         * description - execute method
		 * return - Id
         */
    @AuraEnabled
    public Id getId() {
        return id;
    }

		/*
         * description - getSObjectType method
		 * return - String
         */
    @AuraEnabled
    public String getSObjectType() {
        return sObjectType;
    }

		/*
         * description - getIcon method
		 * return - String
         */
    @AuraEnabled
    public String getIcon() {
        return icon;
    }

		/*
         * description - getTitle method
		 * return - String
         */
    @AuraEnabled
    public String getTitle() {
        return title;
    }
}