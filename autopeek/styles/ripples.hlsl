cbuffer cb:register(b0) {float4x4 mvp;float2 tex;float time;float alpha;};
struct Input {float4 pos:SV_POSITION;float4 col:COLOR0;float2 uv:TEXCOORD0;};
float ring(float distance,float width,float aa) {
 return 1-smoothstep(width,width+aa,abs(distance));
}
float polygonRadius(float2 p) {
 static const float sector=6.28318530718/20;
 float angle=atan2(p.y,p.x);
 float localAngle=angle-sector*floor(angle/sector+.5);
 return length(p)*cos(localAngle);
}
float4 main(Input i):SV_Target {
 // Integer UV offsets carry animation time and release age without native callbacks.
 float frame=floor(i.uv.y*.5);
 float status=floor(i.uv.x*.5);
 float2 uv=float2(i.uv.x-status*2,i.uv.y-frame*2);
 float elapsed=frame/60;
 float held=1-step(.5,status);
 float releaseAge=max(status-1,0)/60;
 float radius=polygonRadius(uv*2-1);
 float aa=max(fwidth(radius),.0015);
 float mainRadius=.62;
 float mainRing=ring(radius-mainRadius,.027,aa);
 float mainGlow=exp(-max(abs(radius-mainRadius)-.027,0)*60)*.25;
 float waveEnergy=0;
 [unroll]for(int j=0;j<3;j++) {
  float age=elapsed-.25-j*.8;
  float progress=frac(max(age,0)/2.4);
  float waveRadius=mainRadius+.025+progress*.27;
  float emitted=lerp(step(releaseAge,progress*2.4+.001),1,held);
  float fade=pow(1-progress,.85)*smoothstep(0,.045,progress)*step(0,age)*emitted;
  float waveLine=ring(radius-waveRadius,.012,aa);
  float waveGlow=exp(-max(abs(radius-waveRadius)-.012,0)*85)*.20;
  waveEnergy+=(waveLine+waveGlow)*fade*.9;
 }
 float boundary=1-smoothstep(.93,.985,radius);
 float mainWeight=(mainRing+mainGlow)*held;
 float energy=mainWeight+waveEnergy;
 float3 mainColor=float3(1,1,1);
 float3 color=(mainColor*mainWeight+i.col.rgb*waveEnergy)/max(energy,.0001);
 float opacity=saturate(energy)*boundary*i.col.a;
 return float4(color,opacity);
}
