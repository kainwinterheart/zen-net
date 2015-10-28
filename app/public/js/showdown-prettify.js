//
//  Google Prettify
//  A showdown extension to add Google Prettify (http://code.google.com/p/google-code-prettify/)
//  hints to showdown's HTML output.
//
(function(){var a=function(a){return[{type:"output",filter:function(a){var c= a.replace(/(<pre>)?<code>/gi,function(a,b){return b?'<pre class="prettyprint" tabIndex="0"><code data-inner="1">':'<code class="prettyprint">'}); var d=document.createElement('html'); d.innerHTML=c; var e =d.getElementsByClassName('prettyprint'); for(var i in e){var f=e[i]; if(f.tagName.toLowerCase()=='pre'){f=f.childNodes;}else{f=[f]}; for(var j in f){ var g=f[j];if(g.tagName.toLowerCase()=='code')g.innerHTML = g.innerHTML.replace(/&gt;/g,'>').replace(/&lt;(?!\s*\/\s*(?:pre|code))/gi,'<'); }} return d.innerHTML;}}]};typeof window!="undefined"&&window.Showdown&&window.Showdown.extensions&&(window.Showdown.extensions.prettify=a),typeof module!="undefined"&&(module.exports=a)})();
