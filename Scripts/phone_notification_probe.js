'use strict';
if (!ObjC.available) throw new Error('Objective-C runtime unavailable');
const NC=ObjC.classes.NSNotificationCenter;
const m=NC['- postNotificationName:object:userInfo:'];
if(!m) throw new Error('NSNotificationCenter method unavailable');
Interceptor.attach(m.implementation,{onEnter(args){try{if(args[2].isNull())return;const name=new ObjC.Object(args[2]).toString();if(/call|history|recent|phone|telephony/i.test(name))console.log('[NOTIFICATION] '+name);}catch(_){}}});
console.log('[READY] Notification names only; object/userInfo are intentionally not logged.');
