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
    "name": "Turn On In Range",
    "container": {
      "xtype": "WireIt.FormContainer",
      "title": "sensor_in_range",    
      "icon": "res/icons/application_edit.png",
      "collapsible": true,
      "fields": [ 
        {"type": "select", "inputParams": {"label": "Pin", "name": "1int", "selectValues": ["2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13"] } },
        {"inputParams": {"label": "Min Value", "name": "2int", "value":"0", "required": true } }, 
        {"inputParams": {"label": "Max Value", "name": "3int", "value":"100", "required": true} } 
      ],
      "terminals": [
        {"name": "0in", "direction": [0,-1], "offsetPosition": {"left": 100, "top": -15 }},
        ],
      "legend": "If the input is in range, turn on a pin. Turn off otherwise."
	   	}
	   },
  ]
};