var ifttt = {
	
	// Set a unique name for the language
	languageName: "IFTTT",

	// inputEx fields for pipes properties
	propertiesFields: [
		// default fields (the "name" field is required by the WiringEditor):
		{"type": "string", inputParams: {"name": "name", label: "Username", typeInvite: "Enter your username." } },
		{"type": "string", inputParams: {"name": "project", label: "Project Name", typeInvite: "Name of this project." } },
		{"type": "text", inputParams: {"name": "description", label: "Description", cols: 30} },
		
		// Additional fields
		//{"type": "select", inputParams: {"name": "category", label: "Category", selectValues: ["CRAFToE", "Robotics", "Other"]} }
	],
	
	// List of node types definition
	modules: [
  {
    "name": "Read Sensor",
    "container": {
      "xtype": "WireIt.FormContainer",
      "title": "read_sensor",
      "icon": "res/icons/application_edit.png",
      "collapsible": true,
      "fields": [ 
        {"type": "select", "inputParams": {"label": "Pin", "name": "1int", "selectValues": ["A0", "A1", "A2", "A3", "A4", "A5"] } },
      ],
      "terminals": [
        {"name": "0out", "direction": [0,1], "offsetPosition": {"left": 100, "bottom": -15}}
        ],
      "legend": "Read my sensor and output its value."
	   	}
	   },	
  {
    "name": "Sensor in Range",
    "container": {
      "xtype": "WireIt.FormContainer",
      "title": "sensor_in_range",    
      "icon": "res/icons/application_edit.png",
      "collapsible": true,
      "fields": [ 
		//{ "type": "hidden", "name": "id", "value": "0" },
        {"type": "select", "inputParams": {"label": "Pin", "name": "1int", "selectValues": ["A0", "A1", "A2", "A3", "A4", "A5"] } },
        {"inputParams": {"label": "Min Value", "name": "2int", "value":"0", "required": true } }, 
        {"inputParams": {"label": "Max Value", "name": "3int", "value":"255", "required": true} } 
      ],
      "terminals": [
        //{"name": "SOURCES", "direction": [0,-1], "offsetPosition": {"left": 100, "top": -15 }},
        {"name": "0out", "direction": [0,1], "offsetPosition": {"left": 100, "bottom": -15}}
        ],
      "legend": "If my sensor reads between the Min and Max..."
	   	}
	   },
	
	
  {
    "name": "Scale Range",
    "container": {
      "xtype": "WireIt.FormContainer",
      "title": "sensor_scale_range",    
      "icon": "res/icons/application_edit.png",
      "collapsible": true,
      "fields": [ 
        {"type": "select", "inputParams": {"label": "Pin", "name": "2int", "selectValues": ["A0", "A1", "A2", "A3", "A4", "A5"] } },
        {"inputParams": {"label": "Min In", "name": "3int", "value":"0", "required": true } }, 
        {"inputParams": {"label": "Max In", "name": "4int", "value":"255", "required": true} }, 
        {"inputParams": {"label": "Min Out", "name": "5int", "value":"0", "required": true } }, 
        {"inputParams": {"label": "Max Max", "name": "6int", "value":"100", "required": true} } 
      ],
      "terminals": [
        {"name": "1in", "direction": [0,-1], "offsetPosition": {"left": 100, "top": -15 }},
        {"name": "0out", "direction": [0,1], "offsetPosition": {"left": 100, "bottom": -15}}
        ],
      "legend": "If my sensor reads between the Min and Max..."
	   	}
	   },


  {
    "name": "Turn Something On",
    "container": {
      "xtype": "WireIt.FormContainer",
      "title": "turn_pin_on",    
      "icon": "res/icons/application_edit.png",
      "collapsible": true,
      "fields": [ 
		//{ "type": "hidden", "name": "id", "value": "0" },
        {"type": "select", "inputParams": {"label": "Pin", "name": "1int", "selectValues": ["3", "4", "5", "6"] } },
      ],
      "terminals": [
        {"name": "0in", "direction": [0,-1], "offsetPosition": {"left": 100, "top": -15 }},
        ],
      "legend": "... turn on something attached to my Arduino."
    }
  },
  ]
};