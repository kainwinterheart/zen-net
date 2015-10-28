//
//  Google Prettify
//  A showdown extension to add Google Prettify (http://code.google.com/p/google-code-prettify/)
//  hints to showdown's HTML output.
//
(function(){var a=function(a){return[{type:"output",filter:function(a){var c= a.replace(/(<pre>)?<code>/gi,function(a,b){return b?'<pre class="prettyprint" tabIndex="0"><code data-inner="1">':'<code class="prettyprint">'}); var d=document.createElement('html'); d.innerHTML=c; var e =d.getElementsByClassName('prettyprint'); for(var i in e){var z=[];var f=e[i]; var tag;try{tag=f.tagName;}catch(e){tag='';}tag=(tag||'');if(tag.toLowerCase()=='pre'){var x=f.childNodes;for(var y in x){ try{if(x[y].tagName.toLowerCase()=='code')z.push(x[y]);}catch(e){} }}else if(tag.toLowerCase()=='code'){z.push(f)}; console.log(z);for(var j in z){ var g=z[j];if(g.tagName.toLowerCase()=='code')g.innerHTML = g.innerHTML.replace(/&amp;gt;/g,'&gt;').replace(/&amp;lt;(?!\s*\/\s*(?:pre|code))/gi,'&lt;');console.log(g.innerHTML); }} return d.innerHTML;}}]};typeof window!="undefined"&&window.Showdown&&window.Showdown.extensions&&(window.Showdown.extensions.prettify=a),typeof module!="undefined"&&(module.exports=a)})();
