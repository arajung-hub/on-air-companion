(() => {
 'use strict';
 const data=window.ON_AIR_DECK;
 if(!data) return;
 const slides=data.slides, stage=document.querySelector('#stage');
 const previous=document.querySelector('#previousButton'), next=document.querySelector('#nextButton');
 const outline=document.querySelector('#outlineDialog'), videoDialog=document.querySelector('#videoDialog'), player=document.querySelector('#videoPlayer');
 let current=0;
 const text=(tag,value)=>{const el=document.createElement(tag);el.textContent=value;return el;};
 function geometry(el,e){Object.assign(el.style,{left:`${e.x}px`,top:`${e.y}px`,width:`${e.w}px`,height:`${e.h}px`});}
 function connectorPath(a,b,e){
  if(e.kind==='elbow') {const ax=a.x+a.w/2,ay=a.y+a.h,bx=b.x+b.w/2,by=b.y,m=(ay+by)/2;return `M${ax} ${ay}V${m}H${bx}V${by}`;}
  return `M${a.x+a.w} ${a.y+a.h/2}H${b.x}`;
 }
 function openVideo(src){
  document.querySelector('#videoTitle').textContent=src.includes('animals')?'동물형 초기 시각 데모':'기본형 초기 시각 데모';
  player.src=src;document.querySelector('#videoDownload').href=src;
  videoDialog.showModal(); player.play().catch(()=>{});
 }
 for(const [i,s] of slides.entries()){
  const section=document.createElement('section');section.className='slide';section.id=`page-${s.id}`;section.setAttribute('aria-label',s.title);section.hidden=i!==0;
  section.style.background=s.bg;section.style.color=s.dark?'#F6F1E8':'#1E1D1A';
  const nodes=new Map(s.elements.filter(e=>e.type==='node').map(e=>[e.id,e]));
  const edges=s.elements.filter(e=>e.type==='connect');
  if(edges.length){
   const svg=document.createElementNS('http://www.w3.org/2000/svg','svg');svg.classList.add('flow-connections');svg.setAttribute('viewBox','0 0 1280 720');svg.setAttribute('aria-hidden','true');
   const color=s.dark?'#AAA398':'#777168';
   const defs=document.createElementNS(svg.namespaceURI,'defs'), marker=document.createElementNS(svg.namespaceURI,'marker');marker.setAttribute('id',`arrow-${i}`);marker.setAttribute('viewBox','0 0 10 10');marker.setAttribute('refX','9');marker.setAttribute('refY','5');marker.setAttribute('markerWidth','5');marker.setAttribute('markerHeight','5');marker.setAttribute('orient','auto');const tri=document.createElementNS(svg.namespaceURI,'path');tri.setAttribute('d','M0 0L10 5L0 10Z');tri.setAttribute('fill',color);marker.append(tri);defs.append(marker);svg.append(defs);
   for(const e of edges){const p=document.createElementNS(svg.namespaceURI,'path');p.setAttribute('d',connectorPath(nodes.get(e.from),nodes.get(e.to),e));p.setAttribute('stroke',color);p.setAttribute('stroke-width','1.4');p.setAttribute('fill','none');p.setAttribute('marker-end',`url(#arrow-${i})`);svg.append(p);}
   section.append(svg);
  }
  for(const e of s.elements){
   if(e.type==='connect')continue;
   let el;
   if(e.type==='image'){
    el=document.createElement('div');el.className='element image';const image=document.createElement('img');image.src=`assets/${e.asset}`;image.alt=e.alt;image.draggable=false;el.append(image);
    if(e.asset.startsWith('video-')){el.classList.add('video-poster');el.tabIndex=0;el.setAttribute('role','button');el.setAttribute('aria-label',e.asset.includes('animals')?'동물형 초기 데모 재생':'기본형 초기 데모 재생');const show=()=>openVideo(e.asset.includes('animals')?data.links.animalVideo:data.links.basicVideo);el.addEventListener('click',show);el.addEventListener('keydown',ev=>{if(ev.key==='Enter'||ev.key===' '){ev.preventDefault();show();}});}
   }else{
    el=text(e.type==='link'?'a':'div',e.text);el.className=`element ${e.type}`;
    el.style.fontSize=`${e.size}px`;el.style.fontWeight=e.bold||e.type==='node'?'700':'400';el.style.lineHeight=e.lineHeight??1.4;el.style.textAlign=e.align??(e.type==='node'?'center':'left');
    if(e.role)el.dataset.role=e.role;
    if(e.role==='heading'){el.setAttribute('role','heading');el.setAttribute('aria-level','1');}
    if(e.color)el.style.color=e.color;
    if(e.type==='node'){el.classList.add('flow-node');el.style.borderColor=s.dark?'#807B72':'#D5CFC5';}
    if(e.type==='link'){el.href=e.url;if(e.video){el.addEventListener('click',ev=>{ev.preventDefault();openVideo(e.url);});}else{el.target='_blank';el.rel='noopener';}}
   }
   geometry(el,e);section.append(el);
  }
  stage.append(section);
  const dot=document.createElement('button');dot.type='button';dot.title=s.title;dot.textContent=i===0?'표지':String(i).padStart(2,'0');dot.setAttribute('aria-label',`${i+1}. ${s.title}`);dot.addEventListener('click',()=>go(i));document.querySelector('#dots').append(dot);
  const li=document.createElement('li'), jump=document.createElement('button');jump.type='button';jump.append(text('span',String(i+1).padStart(2,'0')),text('span',s.title));jump.firstChild.className='index';jump.addEventListener('click',()=>{outline.close();go(i);});li.append(jump);document.querySelector('#outlineList').append(li);
 }
 function size(){const viewport=document.querySelector('#viewport');const scale=Math.min((viewport.clientWidth-24)/1280,(viewport.clientHeight-20)/720);document.documentElement.style.setProperty('--scale',Math.max(.1,scale));}
 function go(i,hash=true){current=Math.max(0,Math.min(slides.length-1,i));[...stage.children].forEach((s,idx)=>{s.hidden=idx!==current;});document.querySelector('#counter').textContent=`${String(current+1).padStart(2,'0')} / ${String(slides.length).padStart(2,'0')}`;document.querySelector('#sectionTitle').textContent=slides[current].chapter;previous.disabled=current===0;next.disabled=current===slides.length-1;document.querySelectorAll('#dots button').forEach((b,idx)=>b.setAttribute('aria-current',String(idx===current)));document.querySelectorAll('#outlineList button').forEach((b,idx)=>b.setAttribute('aria-current',String(idx===current)));if(hash)history.replaceState(null,'',`#${slides[current].id}`);document.title=`${slides[current].title} | On Air Companion`;size();}
 function byHash(){const id=location.hash.slice(1);const index=slides.findIndex(s=>s.id===id);if(index>=0)go(index,false);}
 previous.addEventListener('click',()=>go(current-1));next.addEventListener('click',()=>go(current+1));
 document.querySelector('#outlineButton').addEventListener('click',()=>outline.showModal());document.querySelector('#outlineClose').addEventListener('click',()=>outline.close());
 document.querySelector('#fullscreenButton').addEventListener('click',()=>{if(document.fullscreenElement){document.exitFullscreen().catch(()=>{});}else document.body.requestFullscreen().catch(()=>{});});
 document.querySelector('#videoClose').addEventListener('click',()=>videoDialog.close());videoDialog.addEventListener('close',()=>{player.pause();player.removeAttribute('src');player.load();});
 document.addEventListener('keydown',ev=>{if(videoDialog.open||outline.open)return;if(['INPUT','TEXTAREA','SELECT'].includes(document.activeElement?.tagName))return;if(ev.key==='ArrowRight'||ev.key==='PageDown'||ev.key===' '){ev.preventDefault();go(current+1);}if(ev.key==='ArrowLeft'||ev.key==='PageUp'){ev.preventDefault();go(current-1);}if(ev.key==='Home'){ev.preventDefault();go(0);}if(ev.key==='End'){ev.preventDefault();go(slides.length-1);}if(ev.key.toLowerCase()==='o'){outline.showModal();}if(ev.key.toLowerCase()==='f'){document.querySelector('#fullscreenButton').click();}});
 let touchX=0;stage.addEventListener('touchstart',e=>touchX=e.changedTouches[0].clientX,{passive:true});stage.addEventListener('touchend',e=>{const d=e.changedTouches[0].clientX-touchX;if(Math.abs(d)>70)go(current+(d<0?1:-1));},{passive:true});
 window.addEventListener('resize',size);window.addEventListener('hashchange',byHash);document.addEventListener('fullscreenchange',size);go(0,false);byHash();
})();
