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
* @description Controller for the DataBoundMultiSelect component used in 
* many of our settings pages.  It basically takes a sobject field that
* contains a semicolon separated string of values, and displays them in
* a multiselect picklist.  On saving, it renders the selections back into
* a single semicolon separated string of values.
*/
public with sharing class STG_DataBoundMultiSelect_CTRL {

    public list<SelectOption> listSelectOption { get; set; }
    public boolean isEditMode { get; set; }
    public boolean isDisabled { get; set; }
    public SObject sobjBinding { get; set; }
    public string strField { get; set; }
    
    public STG_DataBoundMultiSelect_CTRL() {
    	isDisabled = false;
    	isEditMode = false;
    }
    
    public string strValues { 
    	get {
    		if (strValues == null) {
    			strValues = string.valueOf(sobjBinding.get(strField));
    		}
    		return strValues;
    	}
    	private set; 
    }

    public list<string> listStrValues {
        get {
            if (listStrValues == null && strValues != null) {
                listStrValues = strValues.split(';',0);
            }
            return listStrValues;
        }
        set {
        	listStrValues = value;
        	strValues = '';
            for (string str : listStrValues) {
            	strValues += str + ';';
            }
            if (strValues != '')
                strValues = strValues.left(strValues.length()-1);
            sobjBinding.put(strField, strValues);	
        }
    }
    
    
}