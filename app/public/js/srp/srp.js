function SRP()
{
    var url = document.getElementById("srp_url").value;
    var that = this;
    var authenticated = false;
    var I = document.getElementById("srp_username").value;
    var p = document.getElementById("srp_password").value;
    var xhr = null;
    var bits = 1024;
    var S = null;
    var M = null;
    var M2 = null;

    var client = new SRPClient( I, p, bits );

    var a = client.srpRandom();
    var A = client.calculateA( a );
    var Astr = A.toString( 16 );

    // *** Accessor methods ***

    this.getClient = function()
    {
        return client;
    };

    // Returns the user's identity
    this.getI = function()
    {
        return I;
    };

    // Returns the XMLHttpRequest object
    this.getxhr = function()
    {
        return xhr;
    };

    // Returns the base URL
    this.geturl = function()
    {
        return url;
    };

    // Translates the path
    this.paths = function(str)
    {
        return str;
    };

    // Get the text content of an XML node
    this.innerxml = function(node)
    {
        return node.firstChild.nodeValue;
    };

    // Check whether or not a variable is defined
    function isdefined ( variable)
    {
        return (typeof(window[variable]) != "undefined");
    };

    // *** Actions ***

    // Perform ajax requests at the specified url, with the specified parameters
    // Calling back the specified function.
    this.ajaxRequest = function(full_url, params, callback)
    {
        if( window.XMLHttpRequest)
            xhr = new XMLHttpRequest();
        else if (window.ActiveXObject){
            try{
                xhr = new ActiveXObject("Microsoft.XMLHTTP");
            }catch (e){}
        }
        else
        {
            that.error_message("Ajax not supported.");
            return;
        }
        if(xhr){
            xhr.onreadystatechange = callback;
            xhr.open("POST", full_url, true);
            xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
            xhr.send(params);
        }
        else
        {
            that.error_message("Ajax failed.");
        }
    };

    // Start the login process by identifying the user
    this.identify = function()
    {
        var handshake_url = url + that.paths("handshake/");
        var params = "I="+I+"&A="+Astr;
        that.ajaxRequest(handshake_url, params, receive_salts);
    };

    // Receive login salts from the server, start calculations
    function receive_salts()
    {
        if(xhr.readyState == 4 && xhr.status == 200) {
		    if(xhr.responseXML.getElementsByTagName("r").length > 0)
		    {
		        var response = xhr.responseXML.getElementsByTagName("r")[0];

                calculations(response.getAttribute("s"), response.getAttribute("B"), p);
                that.ajaxRequest(url+that.paths("authenticate/"), "M="+M, confirm_authentication);
		    }
		    else if(xhr.responseXML.getElementsByTagName("error").length > 0)
                that.error_message(xhr.responseXML.getElementsByTagName("error")[0]);
	    }
    };

    // Calculate S, M, and M2
    // This is the client side of the SRP specification
    function calculations(s, Bstr, pass)
    {
        var B = new BigInteger( Bstr, 16 );

        M = client.calculateM( A, B, s, a, I );
        M2 = client.calculateM2( A, B, s, a, M );
    };



    // Receive M2 from the server and verify it
    function confirm_authentication()
    {
        if(xhr.readyState == 4 && xhr.status == 200) {
            if(xhr.responseXML.getElementsByTagName("M").length > 0)
		    {
		        if(that.innerxml(xhr.responseXML.getElementsByTagName("M")[0]) == M2)
		        {
                    authenticated = true;
		            success();
	            }
		        else
		            that.error_message("Server key does not match");
		    }
		    else if (xhr.responseXML.getElementsByTagName("error").length > 0)
		        that.error_message(that.innerxml(xhr.responseXML.getElementsByTagName("error")[0]));
        }
    };

    function success()
    {
        var forward_url = document.getElementById("srp_forward").value;
        if(forward_url.charAt(0) != "#")
            window.location = forward_url;
        else
        {
            window.location = forward_url;
            that.success();
        }
    };

    this.success = function()
    {
        alert("Login successful.");
    };

    // This function is called when authentication is successful.
    // Developers can set this to other functions in specific implementations
    // and change the functionality.
    /*this.success = function()
    {
        alert("Authentication successful.");
    };*/
    // If an error occurs, raise it as an alert.
    // Developers can set this to an alternative function to handle erros differently.
    this.error_message = function(t)
    {
        alert(t);
    };
};
// This line is run while the document is loading
// It gets a list of all <script> tags and finds the last instance.
// The path to this script is the "src" attribute of that tag.
SRP.prototype.srpPath = document.getElementsByTagName('script')[document.getElementsByTagName('script').length-1].getAttribute("src");
