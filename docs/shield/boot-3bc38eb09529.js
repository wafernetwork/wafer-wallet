(function(){"use strict";
var N=12,SHA256="3bc38eb095291b17cd6f148c4b07cf0e3e61ccbc774c654dde290ad6fd1939cb",TAG=SHA256.slice(0,12),view=document.getElementById("view");
function fail(m){view.textContent="";var p=document.createElement("p");p.className="note bad";p.textContent=m;view.appendChild(p)}
if(typeof DecompressionStream!=="function"||!window.crypto||!crypto.subtle){fail("This browser is too old to run the app. Update it, then reload the page.");return}
function part(i){var s=(i<10?"0":"")+i;return fetch("parts/"+TAG+"-"+s+".bin").then(function(r){if(!r.ok)throw new Error("part "+i);return r.arrayBuffer()})}
var jobs=[];for(var i=0;i<N;i++)jobs.push(part(i));
Promise.all(jobs).then(function(bufs){
var total=bufs.reduce(function(n,b){return n+b.byteLength},0),all=new Uint8Array(total),o=0;
bufs.forEach(function(b){all.set(new Uint8Array(b),o);o+=b.byteLength});
return crypto.subtle.digest("SHA-256",all).then(function(d){
var hex=Array.prototype.map.call(new Uint8Array(d),function(x){return(x<16?"0":"")+x.toString(16)}).join("");
if(hex!==SHA256)throw new Error("integrity");
return new Response(new Blob([all]).stream().pipeThrough(new DecompressionStream("gzip"))).arrayBuffer()
}).then(function(js){
var s=document.createElement("script");s.src=URL.createObjectURL(new Blob([js],{type:"text/javascript"}));
s.onerror=function(){fail("Couldn't start the app. Reload the page.")};document.body.appendChild(s)})
}).catch(function(e){fail(e&&e.message==="integrity"?"This app's code didn't match its fingerprint, so it was not run. Reload the page; if this keeps happening, don't use this site.":"Couldn't load the app. Check your connection and reload the page.")})
})();