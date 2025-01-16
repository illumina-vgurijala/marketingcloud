<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>metazoa3__Snapshot_Push_executed_successfully</fullName>
        <description>Snapshot Push executed successfully</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>metazoa3__Snapshot_Templates/metazoa3__New_Snapshot_Deployment</template>
    </alerts>
    <rules>
        <fullName>metazoa3__Snapshot Push Executed</fullName>
        <actions>
            <name>metazoa3__Snapshot_Push_executed_successfully</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>metazoa3__snapshot_push__c.metazoa3__successful_push__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
