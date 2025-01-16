/**
 *    @author Charket
 *    @date   01-April-2024
 *    @description: Controller of the CharketCustomerCareOutOfOffice page for updating agent status to Out of Office.                
 **/
public with sharing class CharketCustomerCareOutOfOfficeController {
    public List<Charket__WeChatAgent__c> agents;
    
    /**
     *  @author  Charket
     *  @description Constructor method
     **/
    public CharketCustomerCareOutOfOfficeController(ApexPages.StandardSetController controller) {
        agents = (List<Charket__WeChatAgent__c>)controller.getSelected();
    }
    /**
     *  @author  Charket 
     *  @description init method
     **/
    public PageReference init() {
        if(agents.size() > 0){
            setAgentStatus();
        }
        return new PageReference('/lightning/o/Charket__WeChatAgent__c/list');
    }

    /**
     *  @author  Charket 
     *  @description set agent status
     **/
    private void setAgentStatus() {
        Charket__WeChatAgentStatus__c agentStatus = new CharketSelector().selectAgentStatusByName('Out of Office');
        if(agentStatus != null) {
            for(Charket__WeChatAgent__c agent : agents){
                agent.Charket__WeChatAgentStatus__c = agentStatus.Id;
            }
            update agents;
        }
    }
}