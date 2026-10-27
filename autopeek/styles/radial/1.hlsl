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
    float radius=length(p)/.94;
    // Continuous falloff: brightest at the center, fully transparent at the edge.
    float falloff=pow(saturate(1-radius),1.55);
    float core=exp(-radius*radius*10);
    float3 tint=lerp(i.col.rgb,float3(1,1,1),core*.20);
    float opacity=falloff*.80*visibility*i.col.a;
    return float4(tint,opacity);
}
