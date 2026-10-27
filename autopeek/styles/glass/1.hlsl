cbuffer cb:register(b0) {float4x4 mvp;float2 tex;float time;float alpha;};
struct Input {float4 pos:SV_POSITION;float4 col:COLOR0;float2 uv:TEXCOORD0;};

float2 localUV(float2 encoded, out float visibility) {
    float status=floor(encoded.x*.5);
    float frame=floor(encoded.y*.5);
    float releaseAge=max(status-1,0)/60;
    visibility=lerp(1-smoothstep(0,.28,releaseAge),1,1-step(.5,status));
    return float2(encoded.x-status*2,encoded.y-frame*2)*2-1;
}

float4 main(Input i):SV_Target {
    float visibility;
    float2 p=localUV(i.uv,visibility);
    float radius=length(p);
    float aa=max(fwidth(radius),.0015);
    float edge=.83;
    float inside=1-smoothstep(edge-aa,edge+aa,radius);
    float rim=1-smoothstep(.012,.012+aa,abs(radius-edge));
    float rimGlow=exp(-abs(radius-edge)*65)*.12;
    // A subtle static sheen suggests tinted glass without obscuring the floor.
    float sheen=exp(-pow((p.y+.20+p.x*.38)*3.1,2))*.10;
    float fill=(.18+sheen+.08*pow(saturate(radius/edge),3))*inside;
    float highlight=saturate(.55-p.y*.5-p.x*.22);
    float rimAlpha=rim*.90+rimGlow;
    float opacity=saturate(fill+rimAlpha);
    float3 rimColor=lerp(i.col.rgb,float3(1,1,1),.30+highlight*.38);
    float3 tint=(i.col.rgb*fill+rimColor*rimAlpha)/max(fill+rimAlpha,.0001);
    return float4(tint,opacity*visibility*i.col.a);
}
