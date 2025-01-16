/**
 * An apex page controller that exposes the site login functionality
 */
global with sharing class SiteLoginController {
    global String username {get; set;}
    global String password {get; set;}

	/*******************************************************************************************************
    * @description Allows users to log in to the current site with the given username and password, 
	*			   then takes them to the startUrl
    * @return PageReference
    */	
    global PageReference login() {
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        return Site.login(username, password, startUrl);
    }
    
	/*
	* Constructor
	*/	
   	global SiteLoginController () {}
}