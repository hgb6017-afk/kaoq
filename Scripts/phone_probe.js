'use strict';
if (!ObjC.available) throw new Error('Objective-C runtime unavailable');
const interesting = /(dial|dialer|keypad|key|number|phone|call|recent|history|sim|subscription|line|telephony|contact)/i;
function safe(fn, fallback=null){ try{return fn();}catch(_){return fallback;} }
function mask(s){ s=String(s ?? ''); return s.replace(/\+?\d[\d\s().-]{3,}\d/g, m=>{const d=m.replace(/\D/g,''); const t=d.slice(-2); return (m.startsWith('+')?'+***':'***')+t;}); }
console.log('[PROCESS] pid='+Process.id+' main='+Process.mainModule.name+' path='+mask(Process.mainModule.path));
const processInfo=ObjC.classes.NSProcessInfo.processInfo();
console.log('[OS] '+safe(()=>processInfo.operatingSystemVersionString().toString(),'<unknown>'));
const bundle=ObjC.classes.NSBundle.mainBundle();
console.log('[BUNDLE] id='+mask(bundle.bundleIdentifier())+' executable='+mask(bundle.executablePath()));
console.log('=== INTERESTING MODULES ===');
Process.enumerateModules().forEach(m=>{ if(interesting.test(m.name)||interesting.test(m.path)) console.log('[MODULE] '+m.name+' | '+mask(m.path)); });
console.log('=== INTERESTING OBJC CLASSES ===');
ObjC.enumerateLoadedClasses({onMatch(name,owner){if(interesting.test(name)) console.log('[CLASS] '+name+' | '+mask(owner));},onComplete(){console.log('[DONE classes]');}});
ObjC.schedule(ObjC.mainQueue, ()=>{
  const app=ObjC.classes.UIApplication.sharedApplication();
  const windows=safe(()=>app.windows(),null); if(!windows){console.log('[WARN] no legacy windows list; inspect scenes manually'); return;}
  for(let i=0;i<Number(windows.count());i++){
    const w=windows.objectAtIndex_(i); const root=safe(()=>w.rootViewController(),null);
    function vc(v,d){ if(!v||d>12)return; console.log('  '.repeat(d)+'[VC] '+v.$className); const ch=safe(()=>v.childViewControllers(),null); if(ch) for(let j=0;j<Number(ch.count());j++) vc(ch.objectAtIndex_(j),d+1); const p=safe(()=>v.presentedViewController(),null); if(p) vc(p,d+1); }
    vc(root,0);
  }
});
