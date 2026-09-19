'use strict';
if (!ObjC.available) throw new Error('Objective-C runtime unavailable');
const selectorPattern=/(digit|dial|key|number|input|insert|append|delete|backspace|clear|erase|paste|call|phone|sim|line|subscription|carrier|account)/i;
const classPattern=/(dial|keypad|phone|number|call|sim|line|subscription|telephony)/i;
const hooked=new Set();
function hookClass(name){ if(!classPattern.test(name))return; let k; try{k=ObjC.classes[name];}catch(_){return;} if(!k)return; for(const m of (k.$ownMethods||[])){ if(!selectorPattern.test(m))continue; try{const method=k[m]; if(!method||!method.implementation)continue; const key=method.implementation.toString(); if(hooked.has(key))continue; hooked.add(key); Interceptor.attach(method.implementation,{onEnter(){console.log('[TRACE] '+name+' '+m);}}); console.log('[HOOKED] '+name+' '+m);}catch(e){console.log('[SKIP] '+name+' '+m);}} }
ObjC.enumerateLoadedClasses({onMatch(name){hookClass(name);},onComplete(){console.log('[READY] Perform controlled keypad actions; arguments/numbers are not logged.');}});
