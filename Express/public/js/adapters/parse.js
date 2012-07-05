/**
 * JQuery Adapter. Expect JSON response for all queries.
 * @static 
 */
WireIt.WiringEditor.adapters.Parse = {
	/**
	 * You can configure this adapter to different schemas.
	 * url can be functions !
	 */
	config: {
		saveWiring: {
			method: 'POST',
			url: 'saveWiring'
		},
		deleteWiring: {
			method: 'POST',
			url: 'deleteWiring'
		},
		listWirings: {
			method: 'GET',
			url: 'listWirings'
		}
	},
	
	init: function() {
		// YAHOO.util.Connect.setDefaultPostHeader('application/json');
	},
	
	saveWiring: function(val, callbacks) {
	    // Should I not have this API key here? Fortunately, I can
	    // nuke the key in the backend, and then it is useless.
	    // But, still... 
		Parse.initialize("c7h5SBd5dugJ9pGGICPXI3AmnUNBPKAQnvoy4XC9", 
			"jIw7VRbIUkExwK7M8LKjXsUk5Q9LSDgBVWsx9bVN");

	  var obj = editor.getValue();
	  var props = obj.working.properties;
	  var storage_key = null;
	storage_key = "" + props.name + "_" + props.project;

  /* Store this specific project */	
	var Diagram = Parse.Object.extend("AIFTTT");	
	var query = new Parse.Query(Diagram);
	var d = null;
	// This silly song and dance checks to see if the object already exists.
	// If it does, we update the object.
	// Otherwise, we create a new object.
	query.equalTo("uid", storage_key);
	query.find({
  		success: function( results ) {		
			var existingObj = null;
			if (results.length == 0) { 
				d = new Diagram();
				d.set("username", props.name);
				d.set("project", props.project);
				d.set("uid", storage_key);
				d.set("diagram", obj);
	
				d.save(null, {
      				success: function(object) {
						callbacks.success.call(callbacks.scope, object);
      				},
      				error: function(model, error) {
        				alert ("SAVE FAIL.");
      				}
    			});
			} else {
				
			for (i = 0; i < results.length ; i++) {
				existingObj = results[i];
			}
			if (existingObj != null) {
				d = existingObj;
			}
			
			d.set("username", props.name);
			d.set("project", props.project);
			d.set("diagram", obj);
	
			d.save(null, {
      			success: function(object) {
					callbacks.success.call(callbacks.scope, object);
      			},
      		error: function(model, error) {
        		alert ("SAVE FAIL.");
      		}
    		})};
  		}
	});
	



/*
  
    $.ajax({
      url: "http://api.openkeyval.org/store/",
      data: payload,
      dataType: "jsonp",
      success: function(data){
		callbacks.success.call(callbacks.scope, data);
      }
    });
*/
	},
	
	deleteWiring: function(val, callbacks) {
	  var obj = editor.getValue();
	  var props = obj.working.properties;
	  var storage_key = 
	    props.name
	    + '_'
	    + props.project;

	var Diagram = Parse.Object.extend("AIFTTT");	
	var query = new Parse.Query(Diagram);
	var d = null;
	// This silly song and dance checks to see if the object already exists.
	// If it does, we update the object.
	// Otherwise, we create a new object.
	query.equalTo("uid", storage_key);
	query.find({
  		success: function( results ) {		
			var existingObj = null;
			if (results.length == 0) { 
			} else {
				
				for (i = 0; i < results.length ; i++) {
					d = results[i];
					d.destroy ({
						success: function (myObj) {
							callbacks.success.call(callbacks.scope, obj);
						}
					});
				}
			}
	}});
	},
	
	listWirings: function(val, callbacks) {
		Parse.initialize("c7h5SBd5dugJ9pGGICPXI3AmnUNBPKAQnvoy4XC9", 
			"jIw7VRbIUkExwK7M8LKjXsUk5Q9LSDgBVWsx9bVN");

		// this._sendRequest("listWirings", val, callbacks);
		//alert ("LIST");
		var obj = editor.getValue();
	  var props = obj.working.properties;
	  
	  var storage_key = 
	    props.name
	    + '_'
	    + props.project;
	
	var Diagram = Parse.Object.extend("AIFTTT");	
	var query = new Parse.Query(Diagram);
	query.equalTo("username", props.name);
	query.find({
  		success: function( results ) {
			res = [];
			
			if (results.length == null) {
				results = [ results ];
			}
				
			for (i = 0; i < results.length ; i++) {
				var item = results[i].get("diagram");
				
				res.push(item);
			}
			callbacks.success.call(callbacks.scope, res );
  		}
	});
	/*
    $.ajax({
      url: "http://api.openkeyval.org/" + storage_key,
      dataType: "jsonp",
      success: function(data){
		x = 3;
        callbacks.success.call(callbacks.scope, [ data ] );
      }
    });
	*/

	},
	
	_sendRequest: function(action, value, callbacks) {
	
	},
	
	runCode: function (value) {
		var obj = editor.getValue();
	  	var props = obj.working.properties;
	  	var storage_key = props.name + '_' + props.project;
		var payload = {};
		payload.diagram = obj;
		payload.username = props.name;
		payload.project = props.project;
		payload.storage_key = storage_key;

		$.ajax({
      		url: "http://localhost:8000/run/",
    		type: "POST",
      		data: JSON.stringify(payload),
      		dataType: "jsonp",
      		success: function(data){
				alert("RESPONSE: " + data);
      		}
    	});
	} // end runCode
	
};
