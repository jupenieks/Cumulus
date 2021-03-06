/* 
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.com Foundation
* @date 2014
* @group Settings
* @description The controller for the Autocreate Relationships panel 
*/
public with sharing class STG_PanelRelAuto_CTRL extends STG_Panel {
    
    public override string idPanel() { return 'idPanelRelAuto'; }
    
    // temporary ac used by the page for creating a new ac.
    public npe4__Relationship_Auto_Create__c acNew {
        get {
            if (acNew == null)
              acNew = new npe4__Relationship_Auto_Create__c();
            return acNew;
        }
        private set;
    }
    
    // action method for going into edit mode (to create a new ac)
    public PageReference newRelAutoCreate() {
        isEditMode = true;
        return null;
    }

    // action method to save the new ac to the database.
    public PageReference createRelAutoCreate() {  

        // validate required fields
    	if (acNew.npe4__Object__c == null || acNew.npe4__Field__c == null || acNew.npe4__Relationship_Type__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, label.healthDetailsAutoRelFieldsMissing));
            return null;    		
    	} 
    	if (acNew.npe4__Object__c == 'CampaignMember' && acNew.npe4__Campaign_Types__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, label.healthDetailsAutoRelCampaignTypeMissing));
            return null;                		
    	}    

        Savepoint sp = Database.setSavepoint();
        try {
        	acNew.Name = 'AutoCreateRel-' + system.now();
            insert acNew;
            isEditMode = false;
            listRelAutoCreate = null;
            acNew = null;
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    // action method to cancel out of creating a new ac.
    public PageReference cancelRelAutoCreate() {
        isEditMode = false;
        acNew = null;
        return null;
    }
    
    // action method and parameter for deleting an existing ac.
    public string acIdDelete { get; set; }
    public PageReference deleteAc() {
        Savepoint sp = Database.setSavepoint();
        try {
            STG_SettingsManager_CTRL.idPanelCurrent = idPanel();        
            if (acIdDelete != null) {
                npe4__Relationship_Auto_Create__c ac = new npe4__Relationship_Auto_Create__c(Id = acIdDelete);
                delete ac;
                // force reload.
                listRelAutoCreate = null;
            }
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    public list<npe4__Relationship_Auto_Create__c> listRelAutoCreate {
        get {
            if (listRelAutoCreate == null) {
                listRelAutoCreate = new list<npe4__Relationship_Auto_Create__c>();
                listRelAutoCreate = npe4__Relationship_Auto_Create__c.getAll().values();
            } 
            return listRelAutoCreate;           
        }
        private set;     
    }

    public List<SelectOption> listSOACfield {
    	get {
	        listSOACfield = new List<SelectOption>();
	        listSOACfield.add(new SelectOption('', '- none -'));
	        if (acNew.npe4__Object__c != null) {
	            map<String, Schema.SObjectField> fieldTokenMap = new Map<String, Schema.SobjectField>();
	            if (acNew.npe4__Object__c == 'Contact') {
	                fieldTokenMap = Schema.SObjectType.Contact.fields.getMap();         
	            }   
	            else if (acNew.npe4__Object__c == 'CampaignMember') {
	                fieldTokenMap = Schema.SObjectType.CampaignMember.fields.getMap();          
	            }   
	            for (String s : fieldTokenMap.keySet()) {
	                if (s.equalsIgnoreCase('ReportsToId') || (s.endsWith('__c') && !s.startsWith('npe01__') && !s.startsWith('npo02__') && !s.startsWith('npe03__'))){
	                    //if we've hit the limit, throw a warning and recommend manual entry
	                    if (system.Limits.getFieldsDescribes() == system.Limits.getLimitFieldsDescribes()) {
	                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, system.Label.npe4.RelationshipsCustomFieldOverload));                 
	                    } else {
	                        Schema.DescribeFieldResult F = fieldTokenMap.get(s).getDescribe();             
	                        List <Schema.sObjectType> sobjref = new List<Schema.sObjectType>(); 
	                        sobjref = F.getReferenceTo();
	                        for (Schema.sObjectType objT : sobjref) {
	                            if (objT == Contact.sObjectType) {
	                                listSOACfield.add(new SelectOption(F.getName(), F.getLabel()));
	                            }                   
	                        }               
	                    }           
	                }
	            }
	        }                                      
	        return listSOACfield;      
	    }
	    private set;
	}
 
    //utility to check that existing auto create rels are valid - called by Health Check
    public static void verifyAutoCreateRels(STG_PanelHealthCheck_CTRL ctrl) {
        
        map<string, npe4__Relationship_Auto_Create__c> mapAC = npe4__Relationship_Auto_Create__c.getAll();
        string strSetting = Schema.Sobjecttype.npe4__Relationship_Auto_Create__c.getLabel(); 
        boolean isValid = true;
        boolean isValidAll = true;
        
        for (string s : mapAC.keySet()){
            npe4__Relationship_Auto_Create__c ac = mapAC.get(s);
            SobjectField conField;
            isValid = true;
                        
            if (ac.npe4__Object__c == null || ac.npe4__Field__c == null || ac.npe4__Relationship_Type__c == null) {
               isValid = false;
               ctrl.createDR(strSetting, 'Error', 
                   string.format(label.healthDetailsAutoRelFieldsMissing, new string[]{strSetting}), 
                   string.format(label.healthSolutionAutoRelFieldsMissing, new string[]{label.stgNavConnections, label.stgNavRelAutoCreate}));
        	
            }
            
            if (ac.npe4__Object__c == 'Contact'){
                conField = Schema.sObjectType.Contact.fields.getMap().get(ac.npe4__Field__c); 
                if (conField == null) { 
	               isValid = false;
	               ctrl.createDR(strSetting, 'Error', 
	                   string.format(label.healthDetailsInvalidContactField, new string[]{ac.npe4__Field__c}), 
	                   string.format(label.healthSolutionAutoRelInvalidContactField, new string[]{label.stgNavConnections, label.stgNavRelAutoCreate}));
                }   
            }
            else if (ac.npe4__Object__c == 'CampaignMember'){
                conField = Schema.sObjectType.CampaignMember.fields.getMap().get(ac.npe4__Field__c); 
                if (conField == null) { 
                    isValid = false;
                    ctrl.createDR(strSetting, 'Error', 
                        string.format(label.healthDetailsInvalidCMField, new string[]{ac.npe4__Field__c}), 
                        string.format(label.healthSolutionAutoRelInvalidCMField, new string[]{label.stgNavConnections, label.stgNavRelAutoCreate}));
                } else if (ac.npe4__Campaign_Types__c == null) { 
                    isValid = false;
                    ctrl.createDR(strSetting, 'Error', 
                        label.healthDetailsAutoRelCampaignTypeMissing, 
                        string.format(label.healthSolutionAutoRelFieldsMissing, new string[]{label.stgNavConnections, label.stgNavRelAutoCreate}));
                } 
                  
            }
            
            //only if the other checks succeed, get the describe type
            if (isValid == true){
                //check Field Types
                Schema.Displaytype dt = UTIL_Describe.getFieldDisplaytype(ac.npe4__Object__c, ac.npe4__Field__c);
                if (dt != Schema.Displaytype.Reference) { 
                    isValid = false;
                    ctrl.createDR(strSetting, 'Error', 
                        string.format(label.healthDetailsAutoRelInvalidLookupField, new string[]{ac.npe4__Field__c}), 
                        string.format(label.healthSolutionAutoRelInvalidLookupField, new string[]{label.stgNavConnections, label.stgNavRelAutoCreate}));
                }               
            }
            
            if (!isValid)
                isValidAll = false;            
        }

        if (isValidAll) {
            ctrl.createDR(strSetting, 'Success', null, label.healthLabelAutoRelValid);            
        }                           
    }           
}